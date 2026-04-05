"""Agent 5: Software Prompt Generator - Creates a software development prompt for each problem."""

import from byllm.lib { Model }
import from typing { Any }
import json;
import os;
import from env_loader { OPENAI_API_KEY, DEFAULT_MODEL_NAME }
import from agent4_problem_creator { run_problem_creation, ProblemStatement }

glob llm = Model(model_name=DEFAULT_MODEL_NAME, api_key=OPENAI_API_KEY);

"""A fully-formed software development prompt for a given problem."""
obj SoftwarePrompt {
    has category_name: str = "";
    has problem: str = "";
    has score: int = 0;
    has software_name: str = "";
    has description: str = "";
    has core_features: list[str] = [];
    has tech_stack: str = "";
    has prompt: str = "";
}

"""Given problem statements as JSON, generate a software development prompt for each."""
def generate_software_prompts(problems_json: str) -> list[SoftwarePrompt] by llm;

sem generate_software_prompts = """
You are a software architect and product designer. You will receive a JSON list of problem statements,
each with a category_name, problem, score, and reasoning.

For EACH problem, design a small, focused software application that directly addresses it:
  - software_name: a short, catchy app name
  - description: one paragraph describing what the app does and who it's for
  - core_features: a list of 3-5 key features the app must have (be specific)
  - tech_stack: recommended technologies (e.g., "Python backend, React frontend, REST API")
  - prompt: a complete, detailed prompt that a Jac language AI coder could use to build this software.
    The prompt should describe the full app: purpose, features, data model, and UI behavior.
    It should be self-contained — someone reading only the prompt should understand exactly what to build.

Return one SoftwarePrompt per problem.
""";

"""Persist the final structured prompts for machine consumption when requested."""
def maybe_write_output_file(output: list[dict[str, Any]]) -> None {
    output_path: str = os.getenv("AGENT5_OUTPUT_JSON", "");
    if output_path == "" {
        return;
    }

    f: Any = open(output_path, "w");
    f.write(json.dumps(output, indent=2) + "\n");
    f.close();
    print(f"SoftwarePromptAgent: Wrote structured output to {output_path}");
}

"""Serialize problem statements list to JSON string for LLM input."""
def serialize_problems(problems: list[ProblemStatement]) -> str {
    output: list[dict[str, Any]] = [];
    for p in problems {
        item: Any = p;
        output.append(
            {
                "category_name": item.category_name,
                "problem": item.problem,
                "score": item.score,
                "reasoning": item.reasoning
            }
        );
    }
    return json.dumps(output, indent=2);
}

"""Run the full Agents 1-5 pipeline and return software prompts.
Exported so downstream agents (6-11) can import and call this directly."""
def run_software_prompts() -> list[SoftwarePrompt] {
    print("SoftwarePromptAgent: Getting problem statements from Agent 4...");
    problems: list[ProblemStatement] = run_problem_creation();
    print(
        f"SoftwarePromptAgent: Received {len(
            problems
        )} problems. Generating software prompts..."
    );
    problems_json: str = serialize_problems(problems);
    software_prompts: list[SoftwarePrompt] = generate_software_prompts(problems_json);
    print(
        f"SoftwarePromptAgent: Generated {len(software_prompts)} software prompts."
    );
    return software_prompts;
}

walker SoftwarePromptAgent {
    can run with Root entry {
        software_prompts: list[SoftwarePrompt] = run_software_prompts();
        report software_prompts;
    }
}

with entry:__main__ {
    result: Any = root() spawn SoftwarePromptAgent();
    prompts: list[SoftwarePrompt] = result.reports[0];
    output: list[dict[str, Any]] = [];
    for sp in prompts {
        item: Any = sp;
        output.append(
            {
                "category_name": item.category_name,
                "problem": item.problem,
                "score": item.score,
                "software_name": item.software_name,
                "description": item.description,
                "core_features": item.core_features,
                "tech_stack": item.tech_stack,
                "prompt": item.prompt
            }
        );
    }
    maybe_write_output_file(output);
    print("\n=== Agent 5 Output: Software Prompts (Ready for Jac Coder) ===");
    print(json.dumps(output, indent=2));
}
