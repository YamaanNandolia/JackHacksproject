"""Backend Server: Exposes the analysis pipeline as an HTTP endpoint.
Frontend calls /walker/run_analysis to trigger agent 5 (which chains agents 1-4)
and receives trend cluster data for the results page.
Frontend calls /walker/run_business_pipeline to trigger agents 6-11 business analysis."""

import from typing { Any }
import from agent5_software_prompt { run_software_prompts, SoftwarePrompt }
import from agent9_1_orchestrator { run_full_pipeline, serialize_bundles }

"""Run agents 1-5 and report trend clusters for the frontend results page."""
walker:pub run_analysis {
    can analyze with Root entry {
        print("run_analysis: walker started");
        try {
            prompts: list[SoftwarePrompt] = run_software_prompts();
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
