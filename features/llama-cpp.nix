{ config, pkgs, ... }:

let
  # Per-model overrides for the router (see `models-preset` below). Section
  # names match the model's id, i.e. its filename under models-dir minus
  # ".gguf". MTP speculative decoding needs a model trained with an MTP
  # draft head, which most third-party fine-tunes/merges/quants don't have —
  # so it's opt-in per model here rather than a global default that fails
  # loudly ("failed to create MTP context") on every model that lacks one.
  modelsPreset = pkgs.writeText "llama-cpp-models-preset.ini" ''
    [Qwen3.6-27B-Q4_K_M]
    spec-type = draft-mtp
    spec-draft-n-max = 2
  '';
in
{
  # Local LLM server (llama.cpp llama-server, router mode).
  # OpenAI-compatible API at http://localhost:8080/v1 (+ built-in web UI on
  # the same port) for AI tools (Hermes Agent, etc.). Router mode serves every
  # model in models-dir behind one endpoint, loading/unloading on demand —
  # requests pick one via the "model" field.
  #
  # The systemd unit runs with ProtectHome, so models CANNOT live in /home:
  # drop .gguf files into /var/lib/llama-cpp/models (sudo cp).
  #
  # GPU build + capacity tuning (n-gpu-layers, ctx-size) are hardware-specific
  # → hosts/<name>/hardware.nix.
  services.llama-cpp = {
    enable = true;
    openFirewall = true;
    settings = {
      models-dir = "/var/lib/llama-cpp/models";
      models-preset = modelsPreset;
      host = "0.0.0.0";
      jinja = true; # use the model's own chat template — required for tool calling (agents)
      webui-mcp-proxy = true;
    };
  };
}
