"""Qwen3.5 reference adapter registry entry."""

from __future__ import annotations

from athian_agevidence.adapters.openai_compatible import OpenAICompatibleAdapter


class Qwen35Adapter(OpenAICompatibleAdapter):
    """Reference adapter shell for Qwen3.5-compatible local runtimes."""

    adapter_id = "qwen3.5-4b-reference"
    base_model_id = "Qwen/Qwen3.5-4B"
