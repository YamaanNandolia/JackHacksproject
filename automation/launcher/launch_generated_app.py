#!/usr/bin/env python3
"""
JacCoder Launcher
-----------------
Accepts a JSON job file, scaffolds a generated_apps/job_<id>_<slug>/ workspace,
writes PROMPT.md / BUILD_SPEC.json / .jaccoder-job.json into it, optionally
initialises a minimal Jac project, and opens the folder in VS Code.

Usage:
    python launch_generated_app.py <path-to-job.json>
"""

import argparse
import json
import logging
import re
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

# ---------------------------------------------------------------------------
# Logging setup
# ---------------------------------------------------------------------------
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    datefmt="%H:%M:%S",
)
log = logging.getLogger("jaccoder-launcher")

# ---------------------------------------------------------------------------
# Paths (resolved relative to this file's location)
# ---------------------------------------------------------------------------
LAUNCHER_DIR = Path(__file__).resolve().parent          # automation/launcher/
PROJECT_ROOT = LAUNCHER_DIR.parent.parent               # Final1/
GENERATED_APPS_DIR = PROJECT_ROOT / "generated_apps"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def slugify(text: str) -> str:
    """Convert an arbitrary string to a safe directory-name slug."""
    text = text.lower().strip()
    text = re.sub(r"[^\w\s-]", "", text)
    text = re.sub(r"[\s_-]+", "-", text)
    text = re.sub(r"^-+|-+$", "", text)
    return text or "app"


def load_job(job_path: Path) -> dict:
    """Load and minimally validate the job JSON file."""
    if not job_path.exists():
        log.error("Job file not found: %s", job_path)
        sys.exit(1)

    try:
        with job_path.open() as f:
            job = json.load(f)
    except json.JSONDecodeError as exc:
        log.error("Invalid JSON in job file: %s", exc)
        sys.exit(1)

    # Required fields
    missing = [k for k in ("id", "slug", "prompt") if k not in job]
    if missing:
        log.error("Job file is missing required fields: %s", missing)
        sys.exit(1)

    return job


def create_workspace(job: dict) -> Path:
    """Create the workspace directory and return its path."""
    job_id = str(job["id"])
    slug = slugify(str(job["slug"]))
    workspace_name = f"job_{job_id}_{slug}"
    workspace = GENERATED_APPS_DIR / workspace_name

    if workspace.exists():
        log.warning("Workspace already exists, reusing: %s", workspace)
    else:
        workspace.mkdir(parents=True)
        log.info("Created workspace: %s", workspace)

    return workspace


def write_prompt_md(workspace: Path, job: dict) -> None:
    """Write PROMPT.md — the human-readable prompt for the Jac Coder."""
    prompt_text = job["prompt"]
    content = f"# JacCoder Prompt\n\n{prompt_text}\n"
    (workspace / "PROMPT.md").write_text(content)
    log.info("Wrote PROMPT.md")


def write_build_spec(workspace: Path, job: dict) -> None:
    """Write BUILD_SPEC.json — structured build parameters."""
    build_spec = job.get("build_spec", {})

    # Inject defaults if the job did not supply them
    build_spec.setdefault("app_name", job.get("slug", "generated-app"))
    build_spec.setdefault("language", "jac")
    build_spec.setdefault("entry_point", "main.jac")
    build_spec.setdefault("features", [])

    (workspace / "BUILD_SPEC.json").write_text(
        json.dumps(build_spec, indent=2) + "\n"
    )
    log.info("Wrote BUILD_SPEC.json")


def write_job_meta(workspace: Path, job: dict, job_path: Path) -> None:
    """Write .jaccoder-job.json — full job metadata + launch provenance."""
    meta = {
        **job,
        "_meta": {
            "launched_at": datetime.now(timezone.utc).isoformat(),
            "source_job_file": str(job_path.resolve()),
            "workspace": str(workspace.resolve()),
            "launcher_version": "1.0.0",
        },
    }
    (workspace / ".jaccoder-job.json").write_text(
        json.dumps(meta, indent=2) + "\n"
    )
    log.info("Wrote .jaccoder-job.json")


def scaffold_jac_project(workspace: Path, job: dict) -> None:
    """
    Optionally initialise a minimal Jac project if main.jac is absent.
    Writes: main.jac  jac.toml
    """
    main_jac = workspace / "main.jac"
    if main_jac.exists():
        log.info("main.jac already present — skipping scaffold")
        return

    app_name = job.get("build_spec", {}).get("app_name", job.get("slug", "app"))

    main_jac.write_text(
        f'"""Generated Jac application: {app_name}"""\n\n'
        "# TODO: implement the application described in PROMPT.md\n\n"
        "with entry {\n"
        f'    print("Hello from {app_name}!");\n'
        "}\n"
    )
    log.info("Scaffolded main.jac")

    jac_toml = workspace / "jac.toml"
    if not jac_toml.exists():
        jac_toml.write_text(
            f'[project]\nname = "{app_name}"\nversion = "0.1.0"\n\n'
            "[plugins]\nbyllm = {}\n"
        )
        log.info("Scaffolded jac.toml")


def open_in_vscode(workspace: Path) -> None:
    """Open the workspace folder in a new VS Code window."""
    try:
        subprocess.run(
            ["code", "--new-window", str(workspace)],
            check=True,
        )
        log.info("Opened workspace in VS Code: %s", workspace)
    except FileNotFoundError:
        log.warning(
            "VS Code CLI ('code') not found in PATH. "
            "Open manually: %s",
            workspace,
        )
    except subprocess.CalledProcessError as exc:
        log.warning("VS Code exited with code %d — workspace may still have opened.", exc.returncode)


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

def main() -> None:
    parser = argparse.ArgumentParser(
        description="JacCoder Launcher — scaffold and open a generated app workspace."
    )
    parser.add_argument(
        "job_file",
        help="Path to the JSON job file describing the app to generate.",
    )
    parser.add_argument(
        "--no-scaffold",
        action="store_true",
        help="Skip the minimal Jac project scaffold even if main.jac is missing.",
    )
    parser.add_argument(
        "--no-vscode",
        action="store_true",
        help="Do not open VS Code after scaffolding.",
    )
    args = parser.parse_args()

    job_path = Path(args.job_file)
    log.info("Loading job file: %s", job_path)

    job = load_job(job_path)
    log.info("Job ID=%s  Slug=%s", job["id"], job["slug"])

    workspace = create_workspace(job)

    write_prompt_md(workspace, job)
    write_build_spec(workspace, job)
    write_job_meta(workspace, job, job_path)

    if not args.no_scaffold:
        scaffold_jac_project(workspace, job)

    if not args.no_vscode:
        open_in_vscode(workspace)

    log.info("Done. Workspace ready at: %s", workspace)
    print(f"\nWorkspace: {workspace}")


if __name__ == "__main__":
    main()
