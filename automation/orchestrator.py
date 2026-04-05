#!/usr/bin/env python3
"""
orchestrator.py
───────────────
Wires the full pipeline: Agents 1-5 → job file → launcher → VS Code + JacCoder.

Flow:
  1. Run `jac run agent5_software_prompt.jac` from the project root
  2. Extract the JSON array printed after the Agent 5 output marker
  3. Pick the highest-scoring SoftwarePrompt (or all with --all)
  4. Write each prompt as a jobs/<slug>.json file
  5. Call the launcher for each job → scaffolds workspace → opens VS Code
     → companion extension triggers JacCoder automatically

Usage:
  python orchestrator.py [--all] [--no-vscode] [--dry-run]

Flags:
  --all        Launch a workspace for every prompt (default: top-scored only)
  --no-vscode  Scaffold but don't open VS Code (useful for testing)
  --dry-run    Run agents, extract output, print job files — don't launch anything
"""

import argparse
import json
import logging
import re
import subprocess
import sys
import time
from pathlib import Path

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------
SCRIPT_DIR   = Path(__file__).resolve().parent          # automation/
PROJECT_ROOT = SCRIPT_DIR.parent                        # Final1/
JOBS_DIR     = PROJECT_ROOT / "jobs"
LAUNCHER     = SCRIPT_DIR / "launcher" / "launch_generated_app.py"
AGENT5_JAC   = PROJECT_ROOT / "agent5_software_prompt.jac"

# Marker line printed by agent5_software_prompt.jac
AGENT5_MARKER = "=== Agent 5 Output: Software Prompts (Ready for Jac Coder) ==="

# ---------------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------------
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    datefmt="%H:%M:%S",
)
log = logging.getLogger("orchestrator")

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def slugify(text: str) -> str:
    text = text.lower().strip()
    text = re.sub(r"[^\w\s-]", "", text)
    text = re.sub(r"[\s_-]+", "-", text)
    return re.sub(r"^-+|-+$", "", text) or "app"


def run_agents() -> str:
    """
    Execute `jac run agent5_software_prompt.jac` from the project root.
    Streams stderr live (so the user can see agent progress) and returns
    the full stdout as a string.
    """
    log.info("Running agent pipeline (Agents 1 → 5)…")
    log.info("This may take 60-120 seconds. Agent progress streams below:")
    log.info("─" * 60)

    result = subprocess.run(
        ["jac", "run", str(AGENT5_JAC)],
        cwd=PROJECT_ROOT,
        capture_output=True,    # let stdout/stderr flow to terminal live
        text=True,
        stdout=subprocess.PIPE,  # capture stdout for parsing
    )

    log.info("─" * 60)

    if result.returncode != 0:
        log.error("Agent pipeline exited with code %d", result.returncode)
        log.error("Check the output above for errors.")
        sys.exit(1)

    return result.stdout


def extract_prompts(raw_output: str) -> list[dict]:
    """
    Find the Agent 5 output marker and parse the JSON array that follows it.
    Raises ValueError if the marker or valid JSON is not found.
    """
    marker_idx = raw_output.find(AGENT5_MARKER)
    if marker_idx == -1:
        raise ValueError(
            f"Agent 5 output marker not found in stdout.\n"
            f"Expected: '{AGENT5_MARKER}'"
        )

    json_str = raw_output[marker_idx + len(AGENT5_MARKER):].strip()

    try:
        data = json.loads(json_str)
    except json.JSONDecodeError as exc:
        raise ValueError(f"Could not parse Agent 5 JSON output: {exc}") from exc

    if not isinstance(data, list) or len(data) == 0:
        raise ValueError("Agent 5 returned an empty or non-list result.")

    log.info("Agent 5 produced %d software prompt(s).", len(data))
    return data


def select_prompts(prompts: list[dict], take_all: bool) -> list[dict]:
    """Sort by score descending; return all or just the top one."""
    sorted_prompts = sorted(prompts, key=lambda p: p.get("score", 0), reverse=True)

    if take_all:
        log.info("--all flag set: launching all %d prompts.", len(sorted_prompts))
        return sorted_prompts

    top = sorted_prompts[0]
    log.info(
        "Selecting top-scored prompt: '%s' (score %s)",
        top.get("software_name", "?"),
        top.get("score", "?"),
    )
    return [top]


def build_job_file(prompt: dict, idx: int) -> dict:
    """
    Convert a SoftwarePrompt dict (Agent 5 output) into a launcher job dict.
    """
    software_name = prompt.get("software_name", f"app-{idx}")
    slug          = slugify(software_name)
    job_id        = f"{int(time.time())}-{idx:02d}"

    return {
        "id":   job_id,
        "slug": slug,
        "prompt": prompt.get("prompt", ""),
        "build_spec": {
            "app_name":    software_name,
            "language":    "jac",
            "entry_point": "main.jac",
            "features":    prompt.get("core_features", []),
            "tech_stack":  prompt.get("tech_stack", ""),
            "ui":          "web dashboard",
        },
        "_agent5": {
            "category_name": prompt.get("category_name", ""),
            "problem":       prompt.get("problem", ""),
            "score":         prompt.get("score", 0),
            "description":   prompt.get("description", ""),
        },
    }


def save_job_file(job: dict) -> Path:
    """Write the job dict to jobs/<slug>.json and return the path."""
    JOBS_DIR.mkdir(exist_ok=True)
    job_path = JOBS_DIR / f"{job['slug']}.json"

    # Avoid clobbering an existing file with the same slug
    if job_path.exists():
        job_path = JOBS_DIR / f"{job['slug']}-{job['id']}.json"

    job_path.write_text(json.dumps(job, indent=2) + "\n")
    log.info("Saved job file: %s", job_path)
    return job_path


def launch_job(job_path: Path, no_vscode: bool) -> None:
    """Invoke the Python launcher for a single job file."""
    cmd = [sys.executable, str(LAUNCHER), str(job_path)]
    if no_vscode:
        cmd.append("--no-vscode")

    log.info("Launching: %s", " ".join(cmd))
    result = subprocess.run(cmd, cwd=PROJECT_ROOT)
    if result.returncode != 0:
        log.error("Launcher failed for %s (exit code %d)", job_path, result.returncode)
    else:
        log.info("Launcher finished for %s", job_path.name)


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

def main() -> None:
    parser = argparse.ArgumentParser(
        description="Run Agents 1-5 then hand off the best prompt to JacCoder."
    )
    parser.add_argument(
        "--all",
        action="store_true",
        help="Launch a workspace for every prompt (default: top-scored only).",
    )
    parser.add_argument(
        "--no-vscode",
        action="store_true",
        help="Scaffold workspaces but do not open VS Code.",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Run agents and print job files but do not launch anything.",
    )
    args = parser.parse_args()

    # ── Sanity checks ────────────────────────────────────────────────────────
    if not AGENT5_JAC.exists():
        log.error("Agent 5 file not found: %s", AGENT5_JAC)
        sys.exit(1)
    if not LAUNCHER.exists():
        log.error("Launcher not found: %s", LAUNCHER)
        sys.exit(1)

    # ── Step 1: Run agents ───────────────────────────────────────────────────
    raw_output = run_agents()

    # ── Step 2: Extract prompts ──────────────────────────────────────────────
    try:
        prompts = extract_prompts(raw_output)
    except ValueError as exc:
        log.error(str(exc))
        sys.exit(1)

    # Print a summary table
    log.info("─" * 60)
    log.info("Software prompts from Agent 5:")
    for i, p in enumerate(sorted(prompts, key=lambda x: x.get("score", 0), reverse=True)):
        log.info(
            "  [%d] score=%-2s  %-30s  %s",
            i + 1,
            p.get("score", "?"),
            p.get("software_name", "?"),
            p.get("category_name", ""),
        )
    log.info("─" * 60)

    # ── Step 3: Select prompts ───────────────────────────────────────────────
    selected = select_prompts(prompts, args.all)

    # ── Step 4: Build + save job files ───────────────────────────────────────
    job_paths: list[Path] = []
    for idx, prompt in enumerate(selected, start=1):
        job = build_job_file(prompt, idx)
        job_path = save_job_file(job)
        job_paths.append(job_path)

    if args.dry_run:
        log.info("--dry-run: skipping launcher. Job files written to jobs/")
        for jp in job_paths:
            log.info("  %s", jp)
        return

    # ── Step 5: Launch each job ───────────────────────────────────────────────
    for job_path in job_paths:
        launch_job(job_path, no_vscode=args.no_vscode)
        # Small gap so VS Code windows don't open simultaneously
        if len(job_paths) > 1:
            time.sleep(2)

    log.info("═" * 60)
    log.info("Pipeline complete.")
    log.info("VS Code workspace(s) opened. Check Output › JacCoder in each window.")
    log.info("═" * 60)


if __name__ == "__main__":
    main()
