{
  config,
  lib,
  pkgs,
  ...
}:

# ===== EVISTR → Desktop Voice-Note Pipeline =====
# Plug the EVISTR USB recorder in → udev fires the ingest service → it pulls new
# .WAV recordings off the device, runs them through whisper (GPU) → glossary/alias
# correction → LiteLLM triage → and writes markdown notes into the local Obsidian
# vault inbox. Reuses the host-agnostic process.py engine.
#
# The recorder names files with the capture time (YYYYMMDDHHMMSS.WAV), which we
# reformat to the YYYY-MM-DD-HHmmss basename process.py expects — so `created` is
# exact. Files are deleted off the device only AFTER a note is successfully filed,
# with a local processed-archive kept under the state dir.

let
  user = "michael";
  stateDir = "/var/lib/voice-capture";
  vaultInbox = "/home/michael/Documents/Obsidian Vault/01_inbox";
  modelName = "large-v3-turbo"; # GPU makes the big model practical (top quality)
  modelFile = "${stateDir}/models/ggml-${modelName}.bin";

  # LiteLLM key: reuse the existing bare-key secret opencode already uses.
  litellmKeyFile = "/home/${user}/.config/agenix/opencode-env";

  # GPU-accelerated whisper.cpp (desktop already builds CUDA for llama.cpp).
  whisperCuda = pkgs.whisper-cpp.override { cudaSupport = true; };

  processPy = ./voice-capture/process.py;

  pipelineEnv = {
    CAPTURE_DIR = stateDir;
    VAULT_INBOX = vaultInbox;
    WHISPER_MODEL_FILE = modelFile;
    WHISPER_LANGUAGE = "en";
    GLOSSARY_FILE = "${stateDir}/glossary.txt";
    ALIASES_FILE = "${stateDir}/aliases.txt";
    PROJECTS_FILE = "${stateDir}/projects.txt";
    LITELLM_BASE_URL = "https://llm.handmc.net/v1";
    TRIAGE_MODEL = "chat-deepseek-flash"; # cheap cloud model — keeps triage off the local GPU
    CAPTURE_TZ = "America/Chicago";
    # Compressed audio kept + embedded in the vault (no separate raw archive).
    # 99_ prefix sorts the folder to the bottom of the vault file list.
    ATTACHMENTS_DIR = "${builtins.dirOf vaultInbox}/99_attachments";
    AUDIO_LINK_PREFIX = "99_attachments";
  };

  # One-time-ish prep: seed the editable glossary/alias/project files and fetch
  # the whisper model if missing. Safe to run on every plug-in (guarded).
  prepare = pkgs.writeShellApplication {
    name = "voice-capture-prepare";
    runtimeInputs = [
      pkgs.curl
      pkgs.coreutils
    ];
    text = ''
      set -euo pipefail
      mkdir -p "${stateDir}/models" "${stateDir}/state" "${stateDir}/inbox"
      # Seed editable copies only if absent (runtime edits survive redeploys).
      [ -f "${stateDir}/glossary.txt" ] || cp ${./voice-capture/glossary.txt} "${stateDir}/glossary.txt"
      [ -f "${stateDir}/aliases.txt" ]  || cp ${./voice-capture/aliases.txt}  "${stateDir}/aliases.txt"
      [ -f "${stateDir}/projects.txt" ] || cp ${./voice-capture/projects.txt} "${stateDir}/projects.txt"
      chmod u+w "${stateDir}/glossary.txt" "${stateDir}/aliases.txt" "${stateDir}/projects.txt" || true
      if [ ! -s "${modelFile}" ]; then
        echo "Fetching whisper model ${modelName} (~1.6 GB, one time)..."
        curl -L --fail -o "${modelFile}.tmp" \
          "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-${modelName}.bin"
        mv "${modelFile}.tmp" "${modelFile}"
      fi
    '';
  };

  ingest = pkgs.writeShellApplication {
    name = "evistr-ingest";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.findutils
      pkgs.gnugrep
      pkgs.util-linux
      pkgs.ffmpeg
      whisperCuda
      pkgs.python3
    ];
    text = ''
      set -euo pipefail
      INBOX="${stateDir}/inbox"
      PROCESSED="${stateDir}/state/processed"
      mkdir -p "$INBOX" "${stateDir}/state"

      # LiteLLM key for triage (bare key file, same one opencode uses).
      if [ -r "${litellmKeyFile}" ]; then
        LITELLM_API_KEY="$(tr -d '\n' < "${litellmKeyFile}")"
        export LITELLM_API_KEY
      fi

      # The EVISTR is a systemd automount at /mnt/evistr (see fileSystems below).
      # Touching the path triggers the mount; retry to absorb the udev→device
      # -ready race. No dependency on a desktop auto-mount agent.
      REC="/mnt/evistr/RECORD"
      for _ in $(seq 1 20); do
        [ -d "$REC" ] && break
        sleep 1
      done
      if [ ! -d "$REC" ]; then
        echo "EVISTR not mounted (no $REC); nothing to do."
        exit 0
      fi
      echo "Ingesting from $REC"

      # EVISTR name 20260805072409.WAV -> basename 2026-08-05-072409
      to_base() {
        local stem="''${1%.*}"
        printf '%s-%s-%s-%s' "''${stem:0:4}" "''${stem:4:2}" "''${stem:6:2}" "''${stem:8:6}"
      }

      shopt -s nullglob nocaseglob
      # 1. Copy new recordings into the inbox. Allowlist: only the recorder's own
      #    naming (YYYYMMDDHHMMSS.WAV, exactly 14 digits) is processed. Anything
      #    else — an init.wav "keep-warm" anchor, .LIB indexes, stray files — is
      #    left untouched (and warned about, so a firmware naming change that
      #    would silently drop real recordings is visible in the journal).
      for f in "$REC"/*.wav; do
        n="$(basename "$f")"
        stem="''${n%.*}"
        if ! [[ "$stem" =~ ^[0-9]{14}$ ]]; then
          echo "skip (non-recording name, left on device): $n"
          continue
        fi
        base="$(to_base "$n")"
        if [ -f "$PROCESSED" ] && grep -qxF "$base" "$PROCESSED"; then continue; fi
        cp -f "$f" "$INBOX/$base.wav"
      done

      # 2. Run the pipeline (drains inbox, writes notes, records processed).
      python3 ${processPy} || true

      # Find the newest recording (14-digit timestamps sort chronologically).
      # It is kept on the device as a "keep-warm" anchor so RECORD/ is never
      # empty — the EVISTR is slow to start recording from an empty folder. It's
      # already in the processed ledger, so it is never re-transcribed. Each new
      # recording becomes the newest, so exactly one file ever remains.
      newest=""
      for f in "$REC"/*.wav; do
        stem="''${f##*/}"; stem="''${stem%.*}"
        [[ "$stem" =~ ^[0-9]{14}$ ]] || continue
        [[ "$stem" > "$newest" ]] && newest="$stem"
      done

      # 3. Delete processed recordings off the device, EXCEPT the newest anchor.
      for f in "$REC"/*.wav; do
        n="$(basename "$f")"
        stem="''${n%.*}"
        [[ "$stem" =~ ^[0-9]{14}$ ]] || continue
        if [ "$stem" = "$newest" ]; then
          echo "keeping newest as keep-warm anchor: $n"
          continue
        fi
        base="$(to_base "$n")"
        if [ -f "$PROCESSED" ] && grep -qxF "$base" "$PROCESSED"; then
          rm -f "$f" && echo "removed $n from device"
        fi
      done
      echo "ingest complete"
    '';
  };
in
{
  systemd.services.evistr-ingest = {
    description = "Ingest EVISTR recordings and run the voice-note pipeline";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    path = [
      whisperCuda
      pkgs.ffmpeg
      pkgs.python3
      pkgs.coreutils
      pkgs.util-linux
      pkgs.gnugrep
      pkgs.findutils
    ];
    environment = pipelineEnv;
    serviceConfig = {
      Type = "oneshot";
      User = user;
      Group = "users";
      StateDirectory = "voice-capture"; # /var/lib/voice-capture, owned by michael
      ExecStartPre = "${prepare}/bin/voice-capture-prepare";
      ExecStart = "${ingest}/bin/evistr-ingest";
    };
  };

  # On-demand mount of the EVISTR (vfat), so the ingest service never depends on
  # a desktop auto-mount agent (there is none in the niri session). systemd
  # mounts it when /mnt/evistr is accessed and unmounts after 30s idle. vfat has
  # no unix perms, so uid/gid set ownership to michael → the service can read and
  # delete processed recordings off the device. UUID avoids label-space escaping.
  fileSystems."/mnt/evistr" = {
    device = "/dev/disk/by-uuid/0000-006F";
    fsType = "vfat";
    options = [
      "noauto"
      "nofail"
      "x-systemd.automount"
      "x-systemd.idle-timeout=300" # stay mounted 5 min after activity so it stays visible in Nautilus
      "x-systemd.device-timeout=5s"
      "uid=1000"
      "gid=100"
      "x-gvfs-show" # show it in Nautilus again (fstab mounts are hidden by default)
      "x-gvfs-name=EVISTR"
    ];
  };

  # Trigger the ingest when the EVISTR (USB 20d6:1101) partition appears.
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="block", ENV{DEVTYPE}=="partition", ENV{ID_VENDOR_ID}=="20d6", ENV{ID_MODEL_ID}=="1101", TAG+="systemd", ENV{SYSTEMD_WANTS}+="evistr-ingest.service"
  '';
}
