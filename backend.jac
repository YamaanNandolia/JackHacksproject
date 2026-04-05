"""Backend Server: Exposes the analysis pipeline as an HTTP endpoint.
Frontend calls /walker/run_analysis to trigger agent 5 (which chains agents 1-4)
and receives trend cluster data for the results page.
Frontend calls /walker/run_business_pipeline to trigger agents 6-11 business analysis."""

import from typing { Any }
import json;
import os;
import re;
import subprocess;
import threading;
import from pathlib { Path }
import from datetime { datetime, timezone }
import from agent5_software_prompt { run_software_prompts, SoftwarePrompt }
import from agent9_1_orchestrator { run_full_pipeline, serialize_bundles }

glob _BACKEND_DIR = Path(__file__).resolve().parent;
glob _LAUNCHER = _BACKEND_DIR / "automation" / "launcher" / "launch_generated_app.py";
glob _JOBS_DIR = _BACKEND_DIR / "jobs";

def _fire_vscode_launcher(prompts: list) -> None {
    if not prompts {
        return;
    }
    sp: Any = prompts[0];
    ts: str = datetime.now(timezone.utc).strftime("%Y%m%d%H%M%S");
    job_id: str = f"{ts}-01";
    raw: str = re.sub(r"[^\w\s-]", "", str(sp.software_name).lower().strip());
    slug: str = re.sub(r"[\s_-]+", "-", raw).strip("-") or "app";
    job: dict = {
        "id": job_id,
        "slug": slug,
        "prompt": str(sp.prompt),
        "build_spec": {
            "app_name": str(sp.software_name),
            "language": "jac",
            "entry_point": "main.jac",
            "features": [str(f) for f in (sp.core_features or [])],
            "tech_stack": str(sp.tech_stack) if sp.tech_stack else "jac",
            "ui": "web dashboard"
        },
        "_agent5": {
            "category_name": str(sp.category_name),
            "problem": str(sp.problem),
            "score": sp.score if sp.score else 0,
            "description": str(sp.description) if sp.description else ""
        }
    };
    _JOBS_DIR.mkdir(exist_ok=True);
    job_path: Path = _JOBS_DIR / f"{job_id}.json";
    job_path.write_text(json.dumps(job, indent=2) + "\n");
    print(f"Backend: job written → {job_path}");
    def _run() -> None {
        try {
            subprocess.run(["python3", str(_LAUNCHER), str(job_path)], cwd=str(_BACKEND_DIR), timeout=300);
        } except Exception as e {
            print(f"Backend: launcher error: {e}");
        }
    }
    threading.Thread(target=_run, daemon=True).start();
    print(f"Backend: VS Code launcher fired for '{sp.software_name}'");
}

with entry {
    cache_path: str = os.getenv("AGENT5_OUTPUT_JSON", "");
    if cache_path != "" and os.path.exists(cache_path) {
        os.remove(cache_path);
        print(f"Startup: removed stale cache {cache_path}");
    }
}

"""Run agents 1-5 and report trend clusters for the frontend results page."""
walker:pub run_analysis {
    can analyze with Root entry {
        print("run_analysis: walker started");
        try {
            prompts: list[SoftwarePrompt] = run_software_prompts();
            _fire_vscode_launcher(list(prompts));

            cache_path: str = os.getenv("AGENT5_OUTPUT_JSON", "");
            if cache_path != "" {
                cache_data: list[dict[str, Any]] = [];
                for sp in prompts {
                    item: Any = sp;
                    cache_data.append({
                        "category_name": item.category_name,
                        "problem": item.problem,
                        "score": item.score,
                        "software_name": item.software_name,
                        "description": item.description,
                        "core_features": item.core_features,
                        "tech_stack": item.tech_stack,
                        "prompt": item.prompt
                    });
                }
                f: Any = open(cache_path, "w");
                f.write(json.dumps(cache_data, indent=2));
                f.close();
                print(f"run_analysis: cached {len(cache_data)} prompts to {cache_path}");
            }

            output: list[dict[str, Any]] = [];
            idx: int = 0;
            for sp in prompts {
                item: Any = sp;
                signals: list[dict[str, str]] = [];
                fi: int = 0;
                for feature in item.core_features {
                    if fi < 4 {
                        signals.append({"id": f"{idx}_{fi}", "text": feature});
                        fi = fi + 1;
                    }
                }
                output.append(
                    {
                        "id": str(idx),
                        "label": item.category_name,
                        "title": item.software_name,
                        "signals": signals,
                        "problemStatement": item.problem
                    }
                );
                idx = idx + 1;
            }
            print(f"run_analysis: reporting {len(output)} clusters");
            report output;
        } except Exception as e {
            print(f"run_analysis ERROR: {e}");
            report [];
        }
    }
}

"""Run agents 6-11 business pipeline and return full analysis bundles."""
walker:pub run_business_pipeline {
    can analyze with Root entry {
        print("run_business_pipeline: walker started");
        try {
            bundles: list = run_full_pipeline();
            output: list[dict[str, Any]] = serialize_bundles(bundles);
            print(f"run_business_pipeline: reporting {len(output)} bundles");
            report output;
        } except Exception as e {
            print(f"run_business_pipeline ERROR: {e}");
            report [];
        }
    }
}
