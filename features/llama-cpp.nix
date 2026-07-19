{ config, pkgs, ... }:

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
    settings = {
      models-dir = "/var/lib/llama-cpp/models";
      jinja = true; # use the model's own chat template — required for tool calling (agents)
      webui-mcp-proxy = true;
      # MTP speculative decoding: model self-drafts 2 tokens/pass, ~1.5-2x faster
      # generation, identical output. Requires every model in models-dir to have
      # an MTP head (Qwen3.6+ "MTP" ggufs) — move per-model via models-preset if
      # a non-MTP model is ever added.
      spec-type = "draft-mtp";
      spec-draft-n-max = 2;
    };
  };
}
