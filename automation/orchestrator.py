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
import os
import re
import subprocess
import sys
import threading
import time
from pathlib import Path

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------
SCRIPT_DIR    = Path(__file__).resolve().parent          # automation/
PROJECT_ROOT  = SCRIPT_DIR.parent                        # Final1/
JOBS_DIR      = PROJECT_ROOT / "jobs"
LAUNCHER      = SCRIPT_DIR / "launcher" / "launch_generated_app.py"
AGENT5_JAC    = PROJECT_ROOT / "agent5_software_prompt.jac"
AGENT9_1_JAC  = PROJECT_ROOT / "agent9_1_orchestrator.jac"
RUNS_DIR      = PROJECT_ROOT / "logs" / "pipeline_runs"

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


def stream_reader(stream, log_file, mirror_to, captured: list[str] | None = None) -> None:
    """
    Stream subprocess output line-by-line.
    Optionally mirror it to a terminal stream and/or capture it in memory.
    """
    try:
        for line in iter(stream.readline, ""):
            if mirror_to is not None:
                print(line, end="", file=mirror_to, flush=True)
            log_file.write(line)
            log_file.flush()
            if captured is not None:
                captured.append(line)
    finally:
        stream.close()


def run_agents(run_dir: Path) -> Path:
    """
    Execute `jac run agent5_software_prompt.jac` from the project root.
    Streams stdout/stderr live, tees them to run logs, and returns the
    expected Agent 5 machine-output JSON path.
    """
    stdout_log = run_dir / "agent_pipeline.stdout.log"
    stderr_log = run_dir / "agent_pipeline.stderr.log"
    prompts_json = run_dir / "agent5_prompts.json"

    log.info("Running agent pipeline (Agents 1 → 5)…")
    log.info("This may take 60-120 seconds. Agent progress streams below:")
    log.info("Stdout log: %s", stdout_log)
    log.info("Stderr log: %s", stderr_log)
    log.info("Agent 5 JSON output: %s", prompts_json)
    log.info("─" * 60)

    env = os.environ.copy()
    env["AGENT5_OUTPUT_JSON"] = str(prompts_json)

    proc = subprocess.Popen(
        ["jac", "run", str(AGENT5_JAC)],
        cwd=PROJECT_ROOT,
        env=env,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        bufsize=1,
    )

    stdout_captured: list[str] = []
    with stdout_log.open("w") as stdout_f, stderr_log.open("w") as stderr_f:
        stdout_thread = threading.Thread(
            target=stream_reader,
            args=(proc.stdout, stdout_f, sys.stdout, stdout_captured),
            daemon=True,
        )
        stderr_thread = threading.Thread(
            target=stream_reader,
            args=(proc.stderr, stderr_f, sys.stderr, None),
            daemon=True,
        )
        stdout_thread.start()
        stderr_thread.start()
        returncode = proc.wait()
        stdout_thread.join()
        stderr_thread.join()

    log.info("─" * 60)

    if returncode != 0:
        log.error("Agent pipeline exited with code %d", returncode)
        log.error("Check terminal output and logs in %s", run_dir)
        sys.exit(1)

    # Fallback compatibility for older Agent 5 behavior that only prints JSON.
    if not prompts_json.exists():
        raw_stdout = "".join(stdout_captured)
        prompts = extract_prompts(raw_stdout)
        prompts_json.write_text(json.dumps(prompts, indent=2) + "\n")
        log.info("Agent 5 JSON file was not written by Jac; saved parsed output to %s", prompts_json)

    return prompts_json


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


def load_prompts_from_file(prompts_path: Path) -> list[dict]:
    """Load Agent 5 structured prompts from its dedicated JSON output file."""
    if not prompts_path.exists():
        raise ValueError(f"Agent 5 JSON output file not found: {prompts_path}")

    try:
        data = json.loads(prompts_path.read_text())
    except json.JSONDecodeError as exc:
        raise ValueError(f"Could not parse Agent 5 JSON file '{prompts_path}': {exc}") from exc

    if not isinstance(data, list) or len(data) == 0:
        raise ValueError("Agent 5 JSON file contained an empty or non-list result.")

    log.info("Loaded %d software prompt(s) from %s", len(data), prompts_path)
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


def launch_all_jobs(job_paths: list[Path], no_vscode: bool) -> None:
    """Launch every job workspace (runs in a background thread alongside the business pipeline)."""
    log.info("═" * 40)
    log.info("LAUNCHPAD thread started — launching %d workspace(s).", len(job_paths))
    for job_path in job_paths:
        launch_job(job_path, no_vscode=no_vscode)
        if len(job_paths) > 1:
            time.sleep(2)
    log.info("LAUNCHPAD thread complete.")
    log.info("═" * 40)


def run_business_pipeline(prompts_path: Path, run_dir: Path) -> None:
    """
    Run the business pipeline (Agents 6-11) in a background thread.

    Passes AGENT5_OUTPUT_JSON so agent9.1 loads the cached agent5 output
    instead of re-running agents 1-5.
    Agents 9, 10, 11 run simultaneously inside agent9.1 via threading.
    """
    if not AGENT9_1_JAC.exists():
        log.error("agent9_1_orchestrator.jac not found — skipping business pipeline.")
        return

    log.info("═" * 40)
    log.info("BUSINESS PIPELINE thread started (Agents 6 → 11).")
    log.info("agent9.1 JAC  : %s", AGENT9_1_JAC)
    log.info("Agent5 cache  : %s", prompts_path)
    log.info("═" * 40)

    biz_stdout_log = run_dir / "business_pipeline.stdout.log"
    biz_stderr_log = run_dir / "business_pipeline.stderr.log"

    env = os.environ.copy()
    env["AGENT5_OUTPUT_JSON"] = str(prompts_path)

    proc = subprocess.Popen(
        ["jac", "run", str(AGENT9_1_JAC)],
        cwd=PROJECT_ROOT,
        env=env,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        bufsize=1,
    )

    with biz_stdout_log.open("w") as stdout_f, biz_stderr_log.open("w") as stderr_f:
        t_out = threading.Thread(
            target=stream_reader,
            args=(proc.stdout, stdout_f, sys.stdout, None),
            daemon=True,
        )
        t_err = threading.Thread(
            target=stream_reader,
            args=(proc.stderr, stderr_f, sys.stderr, None),
            daemon=True,
        )
        t_out.start()
        t_err.start()
        returncode = proc.wait()
        t_out.join()
        t_err.join()

    if returncode != 0:
        log.error("Business pipeline exited with code %d. See %s", returncode, run_dir)
    else:
        log.info("BUSINESS PIPELINE thread complete (Agents 6-11). Logs: %s", run_dir)
    log.info("═" * 40)


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

def main() -> None:
    parser = argparse.ArgumentParser(
        description="Run Agents 1-5 → Launchpad + Business pipeline (6-11) simultaneously."
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
    run_id = time.strftime("%Y%m%d-%H%M%S")
    run_dir = RUNS_DIR / run_id
    run_dir.mkdir(parents=True, exist_ok=True)
    prompts_path = run_agents(run_dir)

    # ── Step 2: Extract prompts ──────────────────────────────────────────────
    try:
        prompts = load_prompts_from_file(prompts_path)
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
        log.info("--dry-run: skipping launcher and business pipeline. Job files:")
        for jp in job_paths:
            log.info("  %s", jp)
        return

    # ── Step 5: Launchpad + Business pipeline — start SIMULTANEOUSLY ──────────
    log.info("═" * 60)
    log.info("Starting Launchpad and Business pipeline simultaneously…")
    log.info("  Thread A → Launchpad  : VS Code workspace(s) + JacCoder")
    log.info("  Thread B → Business   : Agents 6→7→8 then 9/10/11 in parallel")
    log.info("═" * 60)

    launchpad_thread = threading.Thread(
        target=launch_all_jobs,
        args=(job_paths, args.no_vscode),
        name="Launchpad",
        daemon=False,
    )
    business_thread = threading.Thread(
        target=run_business_pipeline,
        args=(prompts_path, run_dir),
        name="BusinessPipeline",
        daemon=False,
    )

    launchpad_thread.start()
    business_thread.start()

    launchpad_thread.join()
    business_thread.join()

    log.info("═" * 60)
    log.info("All done.")
    log.info("  Launchpad  → VS Code workspace(s) opened + JacCoder triggered.")
    log.info("  Business   → Agents 6-11 complete. Logs in %s", run_dir)
    log.info("═" * 60)


if __name__ == "__main__":
    main()
