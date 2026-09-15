#!/usr/bin/env python3
"""Voice-note ingestion pipeline orchestrator.

Drains /srv/capture/inbox one file at a time (the systemd oneshot that runs
this is serialised with a flock, so only one instance touches the GPU/CPU at a
time). For each captured audio file it: settles -> dedupes -> transcribes ->
corrects -> triages -> writes a markdown note into the Syncthing-shared vault.

THE ONE RULE (PRD Section 6): a note must ALWAYS land. Transcription and triage
are best-effort; the vault-write stage runs unconditionally. Every upstream
stage either supplies its output or supplies a documented empty value.

All configuration comes from the environment (set by the systemd unit); tool
binaries (ffmpeg/ffprobe/whisper) are found on PATH. Nothing here is hardcoded
to a host.
"""

import datetime as dt
import json
import os
import re
import shutil
import subprocess
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path
from zoneinfo import ZoneInfo

# ---------------------------------------------------------------------------
# Config (from the environment; the systemd unit supplies these)
# ---------------------------------------------------------------------------
CAPTURE_DIR = Path(os.environ.get("CAPTURE_DIR", "/srv/capture"))
INBOX = CAPTURE_DIR / "inbox"
WORK = CAPTURE_DIR / "work"
FAILED = CAPTURE_DIR / "failed"
STATE = CAPTURE_DIR / "state"
PROCESSED = STATE / "processed"

VAULT_INBOX = Path(os.environ.get("VAULT_INBOX", str(CAPTURE_DIR / "vault" / "inbox")))
# Compressed audio (the kept copy) is written here and embedded in the note.
# Defaults to a sibling `99_attachments/` next to the inbox inside the vault.
ATTACHMENTS_DIR = Path(os.environ.get("ATTACHMENTS_DIR", str(VAULT_INBOX.parent / "99_attachments")))
# Vault-relative prefix used in the note's `audio:` link / embed.
AUDIO_LINK_PREFIX = os.environ.get("AUDIO_LINK_PREFIX", "99_attachments")

WHISPER_MODEL_FILE = os.environ.get("WHISPER_MODEL_FILE", "")
WHISPER_LANGUAGE = os.environ.get("WHISPER_LANGUAGE", "en")

GLOSSARY_FILE = Path(os.environ.get("GLOSSARY_FILE", str(CAPTURE_DIR / "glossary.txt")))
ALIASES_FILE = Path(os.environ.get("ALIASES_FILE", str(CAPTURE_DIR / "aliases.txt")))
PROJECTS_FILE = Path(os.environ.get("PROJECTS_FILE", str(CAPTURE_DIR / "projects.txt")))

LITELLM_BASE_URL = os.environ.get("LITELLM_BASE_URL", "http://172.30.20.105:4000/v1")
LITELLM_API_KEY = os.environ.get("LITELLM_API_KEY", "")
TRIAGE_MODEL = os.environ.get("TRIAGE_MODEL", "triage-deepseek-flash")

MIN_DURATION_SEC = float(os.environ.get("MIN_DURATION_SEC", "2.0"))
SILENCE_DB = float(os.environ.get("SILENCE_DB", "-50"))
SETTLE_INTERVAL = float(os.environ.get("SETTLE_INTERVAL", "2"))
SETTLE_MAX = int(os.environ.get("SETTLE_MAX", "30"))

TZ = ZoneInfo(os.environ.get("CAPTURE_TZ", "America/Chicago"))

TELEGRAM_BOT_TOKEN = os.environ.get("TELEGRAM_BOT_TOKEN", "")
TELEGRAM_CHAT_ID = os.environ.get("TELEGRAM_CHAT_ID", "")

# whisper.cpp's binary has been renamed across versions; accept any of them.
WHISPER_BINS = ["whisper-cli", "whisper-cpp", "main"]

FILENAME_RE = re.compile(r"^(\d{4})-(\d{2})-(\d{2})-(\d{2})(\d{2})(\d{2})$")


def log(msg: str) -> None:
    print(msg, flush=True)


# ---------------------------------------------------------------------------
# Notifications (best-effort; MUST NEVER raise or block the pipeline)
# ---------------------------------------------------------------------------
def notify(msg: str) -> None:
    if not TELEGRAM_BOT_TOKEN or not TELEGRAM_CHAT_ID:
        log(f"[notify skipped, no token] {msg}")
        return
    try:
        url = f"https://api.telegram.org/bot{TELEGRAM_BOT_TOKEN}/sendMessage"
        data = json.dumps({"chat_id": TELEGRAM_CHAT_ID, "text": msg}).encode()
        req = urllib.request.Request(
            url, data=data, headers={"Content-Type": "application/json"}
        )
        urllib.request.urlopen(req, timeout=10).read()
    except Exception as e:  # noqa: BLE001 - notifications never gate the pipeline
        log(f"[notify failed: {e}] {msg}")


# ---------------------------------------------------------------------------
# Small subprocess helpers
# ---------------------------------------------------------------------------
def run(cmd: list, **kw):
    return subprocess.run(cmd, capture_output=True, text=True, **kw)


def find_whisper() -> str:
    for name in WHISPER_BINS:
        found = shutil.which(name)
        if found:
            return found
    raise FileNotFoundError("no whisper binary found on PATH")


# ---------------------------------------------------------------------------
# Stage: settling (PRD 8.1) - tolerate slow/partial Syncthing writes
# ---------------------------------------------------------------------------
def settle(path: Path) -> bool:
    """Return True once the file size is stable, False if it never settles."""
    last = -1
    for _ in range(SETTLE_MAX):
        try:
            size = path.stat().st_size
        except FileNotFoundError:
            return False
        if size == last and size > 0:
            return True
        last = size
        time.sleep(SETTLE_INTERVAL)
    return False


# ---------------------------------------------------------------------------
# Stage: probing (duration + silence)
# ---------------------------------------------------------------------------
def probe_duration(path: Path) -> float:
    r = run([
        "ffprobe", "-v", "error", "-show_entries", "format=duration",
        "-of", "default=noprint_wrappers=1:nokey=1", str(path),
    ])
    try:
        return float(r.stdout.strip())
    except ValueError:
        return 0.0


def transcode(src: Path, wav_dst: Path, m4a_dst: Path) -> None:
    """One decode, two outputs: the 16 kHz mono PCM WAV whisper needs, and a
    small mono AAC .m4a (the kept, embeddable copy for the vault)."""
    m4a_dst.parent.mkdir(parents=True, exist_ok=True)
    r = run([
        "ffmpeg", "-y", "-i", str(src),
        # whisper input
        "-map", "0:a", "-ar", "16000", "-ac", "1", "-c:a", "pcm_s16le", str(wav_dst),
        # kept copy: mono AAC ~64k (~20x smaller than the raw WAV, plays on iOS)
        "-map", "0:a", "-ac", "1", "-c:a", "aac", "-b:a", "64k", str(m4a_dst),
    ])
    if r.returncode != 0:
        raise RuntimeError(f"ffmpeg convert failed: {r.stderr.strip()[:400]}")


def mean_volume_db(wav: Path) -> float:
    """Parse ffmpeg volumedetect mean_volume. Returns a very negative number on
    failure so a probe error never masquerades as silence-or-not incorrectly;
    callers treat parse failure as 'not silent'."""
    r = run([
        "ffmpeg", "-i", str(wav), "-af", "volumedetect",
        "-f", "null", "/dev/null",
    ])
    if re.search(r"mean_volume:\s*-inf\s*dB", r.stderr):
        return -999.0  # pure digital silence
    m = re.search(r"mean_volume:\s*(-?\d+(?:\.\d+)?)\s*dB", r.stderr)
    if m:
        return float(m.group(1))
    return 0.0  # unknown -> treat as not silent


# ---------------------------------------------------------------------------
# Stage: transcription (PRD 8.2)
# ---------------------------------------------------------------------------
def _run_whisper(whisper: str, wav: Path, out_prefix: Path, extra: list):
    return run([
        whisper,
        "--model", WHISPER_MODEL_FILE,
        "--file", str(wav),
        "--language", WHISPER_LANGUAGE,
        "--no-timestamps",
        "--output-txt",
        "--output-file", str(out_prefix),
    ] + extra)


def transcribe(wav: Path, out_prefix: Path) -> str:
    whisper = find_whisper()
    if not WHISPER_MODEL_FILE or not Path(WHISPER_MODEL_FILE).exists():
        raise RuntimeError(f"whisper model missing: {WHISPER_MODEL_FILE}")
    txt = out_prefix.with_suffix(".txt")

    # Try the GPU first. If it can't get VRAM (e.g. a large model is loaded in
    # llama.cpp → CUDA OOM), fall back to CPU so a busy GPU never costs us a
    # transcript — just a slower one for that note.
    r = _run_whisper(whisper, wav, out_prefix, [])
    if r.returncode != 0 or not txt.exists():
        log(f"   GPU transcription failed ({r.stderr.strip()[:200]}); retrying on CPU")
        r = _run_whisper(whisper, wav, out_prefix, ["--no-gpu"])
    if r.returncode != 0 or not txt.exists():
        raise RuntimeError(f"whisper failed (GPU and CPU): {r.stderr.strip()[:400]}")
    return txt.read_text().strip()


# ---------------------------------------------------------------------------
# Stage: glossary correction (PRD 8.3) - deterministic, always-on safety net
# ---------------------------------------------------------------------------
def load_glossary() -> list:
    if not GLOSSARY_FILE.exists():
        return []
    terms = []
    for line in GLOSSARY_FILE.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        for term in line.split(","):
            term = term.strip()
            if term:
                terms.append(term)
    return terms


def load_aliases() -> list:
    """Parse aliases.txt into [(compiled_regex, canonical)]. Format per line:
    `Canonical <= variant1, variant2, ...` (variants may be multi-word)."""
    if not ALIASES_FILE.exists():
        return []
    out = []
    for line in ALIASES_FILE.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "<=" not in line:
            continue
        canon, rhs = line.split("<=", 1)
        canon = canon.strip()
        for variant in rhs.split(","):
            variant = variant.strip()
            if variant:
                out.append((re.compile(rf"\b{re.escape(variant)}\b", re.IGNORECASE), canon))
    return out


def correct(text: str) -> str:
    """Deterministic jargon correction. First map whisper's garbled phonetic
    forms to the canonical term (aliases), then re-case correctly-spelled terms
    (glossary). Mechanical only - context-aware cleanup happens in triage."""
    if not text:
        return text
    for rx, canon in load_aliases():
        text = rx.sub(canon, text)
    for term in load_glossary():
        pattern = re.compile(rf"\b{re.escape(term)}\b", re.IGNORECASE)
        text = pattern.sub(term, text)
    return text


# ---------------------------------------------------------------------------
# Stage: triage (PRD 8.4) - LiteLLM gateway, NOT a Hermes profile
# ---------------------------------------------------------------------------
VALID_TYPES = {"task", "idea", "reference", "unsorted"}

SYSTEM_PROMPT = """\
You triage a single short personal voice note for a homelab/IT operator.
Return ONLY a strict JSON object, no prose, no markdown fences, matching:
{
  "title": "string, under 80 chars",
  "type": "task | idea | reference | unsorted",
  "project": "string slug from the active-project list, or null",
  "summary": "string, 2-3 sentences",
  "action_items": [
    {"task": "imperative top-level action", "notes": ["supporting detail or sub-step"]}
  ],
  "confidence": 0.0
}
Guidance:
- action_items: capture only GENUINELY DISTINCT, independent top-level tasks —
  usually just 1-3. Do NOT split a single effort into multiple tasks. Supporting
  details, sub-steps, considerations, and options belong in that task's "notes"
  array, never as separate tasks. "notes" may be empty ([]).
- If the note is an idea/reference/thought with nothing actionable, use [].
- Fix obvious domain-jargon transcription errors using context.
- Resolve vague references (e.g. "the Caltrans thing") to a project slug when the
  active-project list makes it unambiguous, else null.
- confidence is your 0-1 certainty in the classification."""


def fallback_triage(transcript: str) -> dict:
    return {
        "title": (transcript[:60] or "Untitled voice note"),
        "type": "unsorted",
        "project": None,
        "summary": "",
        "action_items": [],
        "confidence": 0.0,
    }


def read_projects() -> str:
    if PROJECTS_FILE.exists():
        return PROJECTS_FILE.read_text().strip()
    return "(none)"


def call_litellm(transcript: str) -> str:
    now = dt.datetime.now(TZ).isoformat()
    user = (
        f"Current datetime: {now}\n\n"
        f"Active projects (slugs):\n{read_projects()}\n\n"
        f"Voice note transcript:\n{transcript}"
    )
    body = json.dumps({
        "model": TRIAGE_MODEL,
        "temperature": 0.2,
        "response_format": {"type": "json_object"},
        "messages": [
            {"role": "system", "content": SYSTEM_PROMPT},
            {"role": "user", "content": user},
        ],
    }).encode()
    req = urllib.request.Request(
        f"{LITELLM_BASE_URL}/chat/completions",
        data=body,
        headers={
            "Content-Type": "application/json",
            "Authorization": f"Bearer {LITELLM_API_KEY}",
        },
    )
    with urllib.request.urlopen(req, timeout=120) as resp:
        payload = json.loads(resp.read())
    return payload["choices"][0]["message"]["content"]


def parse_triage(raw: str) -> dict:
    """Parse + validate. Raises on any problem so the caller can retry/substitute."""
    cleaned = raw.strip()
    # Strip accidental markdown fences.
    if cleaned.startswith("```"):
        cleaned = re.sub(r"^```[a-zA-Z]*\n?", "", cleaned)
        cleaned = re.sub(r"\n?```$", "", cleaned).strip()
    data = json.loads(cleaned)
    if data.get("type") not in VALID_TYPES:
        raise ValueError(f"bad type: {data.get('type')!r}")
    conf = float(data.get("confidence", 0.0))
    if conf < 0.5:
        raise ValueError(f"low confidence: {conf}")
    # Normalise/guard shapes.
    data["title"] = str(data.get("title") or "")[:120]
    data["summary"] = str(data.get("summary") or "")
    proj = data.get("project")
    data["project"] = None if proj in (None, "", "null") else str(proj)
    # Normalise action_items to [{task, notes:[...]}]. Accept the nested shape,
    # and defensively coerce a plain string (older/looser model output) to a
    # task with no notes.
    norm = []
    for item in (data.get("action_items") or []):
        if isinstance(item, dict):
            task = str(item.get("task") or "").strip()
            if not task:
                continue
            notes = [str(n).strip() for n in (item.get("notes") or []) if str(n).strip()]
            norm.append({"task": task, "notes": notes})
        else:
            t = str(item).strip()
            if t:
                norm.append({"task": t, "notes": []})
    data["action_items"] = norm
    data["confidence"] = conf
    return data


def triage(transcript: str) -> dict:
    if not transcript.strip():
        return fallback_triage(transcript)
    for attempt in range(2):  # initial try + one retry on parse failure
        try:
            return parse_triage(call_litellm(transcript))
        except (urllib.error.URLError, KeyError, TimeoutError) as e:
            log(f"[triage call failed attempt {attempt}: {e}]")
            break  # transport failure -> don't burn the retry, just substitute
        except (ValueError, json.JSONDecodeError) as e:
            log(f"[triage parse failed attempt {attempt}: {e}]")
            continue
    return fallback_triage(transcript)


# ---------------------------------------------------------------------------
# Stage: vault write (PRD 8.5) - UNCONDITIONAL
# ---------------------------------------------------------------------------
def yaml_str(value) -> str:
    """A JSON-encoded string is always a valid YAML double-quoted scalar, so
    titles with colons/leading specials can never break the frontmatter (A9)."""
    return json.dumps("" if value is None else str(value))


def created_iso(basename: str) -> str:
    m = FILENAME_RE.match(basename)
    if not m:
        # Fall back to now() rather than losing the note; still not mtime.
        return dt.datetime.now(TZ).isoformat()
    y, mo, d, h, mi, s = (int(x) for x in m.groups())
    return dt.datetime(y, mo, d, h, mi, s, tzinfo=TZ).isoformat()


def write_note(basename, tri, transcript, duration, audio_rel,
               silent, transcription_failed) -> Path:
    fm = [
        "---",
        f"created: {created_iso(basename)}",
        f"duration: {int(round(duration))}",
        "source: voice",
        f"type: {tri['type']}",
        f"project: {yaml_str(tri['project']) if tri['project'] else 'null'}",
        f"confidence: {tri['confidence']}",
        f"audio: {yaml_str(audio_rel) if audio_rel else 'null'}",
        f"transcription_failed: {str(transcription_failed).lower()}",
        f"silent: {str(silent).lower()}",
        "---",
        "",
        f"# {tri['title'] or 'Untitled voice note'}",
        "",
    ]
    body = list(fm)
    # Playable audio embed right under the title (Obsidian plays it inline).
    if audio_rel:
        body += [f"![[{audio_rel}]]", ""]
    if tri["summary"]:
        body += [tri["summary"], ""]
    if tri["action_items"]:
        body += ["## Actions"]
        for item in tri["action_items"]:
            body += [f"- [ ] {item['task']}"]
            body += [f"    - {note}" for note in item.get("notes", [])]
        body += [""]
    body += ["## Transcript", "", transcript or "", ""]

    VAULT_INBOX.mkdir(parents=True, exist_ok=True)
    dst = VAULT_INBOX / f"{basename}.md"
    tmp = VAULT_INBOX / f".{basename}.md.tmp"
    tmp.write_text("\n".join(body))
    os.replace(tmp, dst)  # atomic; Syncthing/Obsidian never see a partial file
    return dst


# ---------------------------------------------------------------------------
# Idempotency state
# ---------------------------------------------------------------------------
def already_processed(basename: str) -> bool:
    if not PROCESSED.exists():
        return False
    return basename in PROCESSED.read_text().splitlines()


def mark_processed(basename: str) -> None:
    STATE.mkdir(parents=True, exist_ok=True)
    with PROCESSED.open("a") as f:
        f.write(basename + "\n")


# ---------------------------------------------------------------------------
# Per-file pipeline
# ---------------------------------------------------------------------------
def process_one(path: Path) -> None:
    basename = path.stem
    audio_ext = path.suffix or ".m4a"
    log(f"== processing {path.name}")

    # 1. Settle (tolerate partial/slow writes).
    if not settle(path):
        log("   never settled -> failed/")
        FAILED.mkdir(parents=True, exist_ok=True)
        try:
            shutil.move(str(path), str(FAILED / path.name))
        except Exception:  # noqa: BLE001
            pass
        notify(f"Voice capture {path.name} never finished syncing; moved to failed/.")
        return

    # 2. Idempotency (A4).
    if already_processed(basename):
        log("   already processed -> deleting duplicate")
        path.unlink(missing_ok=True)
        return

    # 3. Duration gate - accidental triggers (A2).
    duration = probe_duration(path)
    if duration < MIN_DURATION_SEC:
        log(f"   duration {duration:.2f}s < {MIN_DURATION_SEC}s -> discard")
        path.unlink(missing_ok=True)
        return

    # 4. Working copy. Keep the inbox original until success so a crash mid-run
    #    leaves the file to be reprocessed on the next sweep (A10).
    workdir = WORK / basename
    if workdir.exists():
        shutil.rmtree(workdir)
    workdir.mkdir(parents=True)
    audio = workdir / f"audio{audio_ext}"
    shutil.copy2(path, audio)

    silent = False
    transcription_failed = False
    transcript = ""

    # 5. Transcode (one pass -> whisper WAV + kept .m4a) and transcribe.
    wav = workdir / "audio16k.wav"
    m4a = ATTACHMENTS_DIR / f"{basename}.m4a"
    try:
        transcode(audio, wav, m4a)
        if mean_volume_db(wav) < SILENCE_DB:
            silent = True
            (workdir / "raw.txt").write_text("")
            log("   silent audio")
            notify(f"Voice capture {basename} was silent; note filed empty.")
        else:
            transcript = transcribe(wav, workdir / "raw")
    except Exception as e:  # noqa: BLE001 - degrade, do not lose the note
        transcription_failed = True
        transcript = ""
        (workdir / "raw.txt").write_text("")
        log(f"   transcription failed: {e}")
        notify(f"Voice capture {basename} transcription failed: {e}")

    # Embed the .m4a only if it was actually produced.
    audio_rel = f"{AUDIO_LINK_PREFIX}/{basename}.m4a" if m4a.exists() else None

    # 6. Correct (deterministic; on failure fall back to raw).
    try:
        corrected = correct(transcript)
    except Exception as e:  # noqa: BLE001
        log(f"   correction failed: {e}")
        corrected = transcript
    (workdir / "corrected.txt").write_text(corrected)

    # 7. Triage (never blocks the write).
    try:
        tri = triage(corrected)
    except Exception as e:  # noqa: BLE001
        log(f"   triage crashed, substituting stub: {e}")
        tri = fallback_triage(corrected)
    (workdir / "triage.json").write_text(json.dumps(tri, indent=2))

    # 8. Vault write - UNCONDITIONAL.
    dst = write_note(
        basename, tri, corrected, duration, audio_rel,
        silent, transcription_failed,
    )
    log(f"   wrote {dst}")

    # 9. Commit: mark processed, drop inbox original + workdir. The kept audio
    #    already lives in the vault's 99_attachments (no separate raw archive).
    mark_processed(basename)
    path.unlink(missing_ok=True)
    shutil.rmtree(workdir, ignore_errors=True)


def main() -> int:
    for d in (INBOX, WORK, FAILED, STATE, VAULT_INBOX, ATTACHMENTS_DIR):
        d.mkdir(parents=True, exist_ok=True)

    # Sorted glob tolerates out-of-order arrival deterministically.
    files = sorted(p for p in INBOX.iterdir() if p.is_file() and not p.name.startswith("."))
    if not files:
        log("inbox empty")
        return 0
    for path in files:
        try:
            process_one(path)
        except Exception as e:  # noqa: BLE001 - one bad file must not stop the queue
            log(f"!! unhandled error on {path.name}: {e}")
            notify(f"Voice pipeline hit an unhandled error on {path.name}: {e}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
