"""Pytest plugin hooks for projects using Agevidence."""

from __future__ import annotations

import os


def pytest_addoption(parser):
    """Register Agevidence-specific pytest options."""

    parser.addoption("--agevidence-verifier-command", action="store", default=None, help="Rust verifier command for Agevidence tests.")


def pytest_configure(config):
    """Expose Agevidence test markers and verifier configuration."""

    config.addinivalue_line("markers", "agevidence: mark tests that exercise Agevidence primitives or verification.")
    command = config.getoption("--agevidence-verifier-command")
    if command:
        os.environ["AGEVIDENCE_VERIFIER_COMMAND"] = command
