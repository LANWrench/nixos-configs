{ config, pkgs, ... }:

{
  # Local LLM server. Serves an OpenAI-compatible API at
  # http://localhost:11434/v1 for AI tools (Hermes Agent, etc.).
  # Pull models imperatively: `ollama pull <model>`.
  # GPU acceleration is hardware-specific → hosts/<name>/hardware.nix.
  services.ollama.enable = true;
}
