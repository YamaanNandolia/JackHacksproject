"""Backend Server: Exposes the analysis pipeline as an HTTP endpoint.
Frontend calls /walker/run_analysis to trigger agent 5 (which chains agents 1-4)
and receives trend cluster data for the results page."""

import from typing { Any }
import from agent5_software_prompt { run_software_prompts, SoftwarePrompt }

"""Run agents 1-5 and report trend clusters for the frontend results page."""
walker:pub run_analysis {
    can analyze with `root entry {
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
        report output;
    }
}
