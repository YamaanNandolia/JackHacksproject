"""Agent 6: Business Development Agent - Market research and competitive analysis for each software solution."""

import from byllm.lib { Model }
import from typing { Any }
import json;
import from env_loader { OPENAI_API_KEY, DEFAULT_MODEL_NAME }

glob llm = Model(model_name=DEFAULT_MODEL_NAME, api_key=OPENAI_API_KEY);

"""Market sizing estimates for a software solution (TAM, SAM, SOM)."""
obj MarketSize {
    has tam: str = "";
    has sam: str = "";
    has som: str = "";
    has sizing_rationale: str = "";
}

"""A single competitor entry in the competitive landscape."""
obj Competitor {
    has name: str = "";
    has core_capabilities: str = "";
    has pricing_model: str = "";
    has target_segment: str = "";
    has strengths: str = "";
    has weaknesses: str = "";
}

"""Full business intelligence report for a software solution."""
obj BusinessReport {
    has software_name: str = "";
    has problem: str = "";
    has market_size: MarketSize = MarketSize();
    has competitors: list[Competitor] = [];
    has tailwinds: list[str] = [];
    has headwinds: list[str] = [];
    has current_buyer_alternatives: str = "";
    has pricing_intelligence: str = "";
    has positioning_recommendation: str = "";
}

"""Given software solutions as JSON, produce a business intelligence report for each."""
def generate_business_reports(solutions_json: str) -> list[BusinessReport] by llm;

sem generate_business_reports = """
You are a senior business development strategist and market researcher.
You will receive a JSON list of software solutions, each with a software_name, problem it solves, description, and core features.

For EACH solution, produce a BusinessReport with:

1. market_size: Estimate TAM, SAM, and SOM with a brief sizing_rationale.
   - TAM: total global revenue opportunity if every possible buyer used this type of solution.
   - SAM: the serviceable slice reachable with a typical SaaS go-to-market (specific geography/segment).
   - SOM: realistic capture in 2-3 years given competition and early-stage resources.
   - Express each as a dollar range (e.g., "$2B–$5B annually"). Keep sizing_rationale to 2-3 sentences.

2. competitors: List 3-5 realistic competitors (real companies or archetypes like "Excel/spreadsheets", "custom in-house scripts").
   For each include name, core_capabilities, pricing_model, target_segment, strengths, and weaknesses.

3. tailwinds: 3-4 external forces currently accelerating demand for this solution
   (e.g., regulation, technology shift, macro trend). One sentence each.

4. headwinds: 2-3 external forces that could slow adoption
   (e.g., budget freezes, buyer fatigue, incumbent lock-in). One sentence each.

5. current_buyer_alternatives: 2-3 sentences describing how buyers solve this problem today
   without a dedicated tool (spreadsheets, manual processes, agencies, doing nothing).

6. pricing_intelligence: 2-3 sentences on what pricing models buyers expect (per-seat, usage-based,
   flat-rate), typical contract length, and the rough price range the market tolerates.

7. positioning_recommendation: 1-2 sentences on the whitespace or unique angle this solution
   should occupy to differentiate from the competitors identified above.

Return exactly one BusinessReport per solution.
""";

"""Serialize a list of dicts (software prompt data) to JSON string for LLM input."""
def serialize_prompts(prompts: list[dict[str, Any]]) -> str {
    return json.dumps(prompts, indent=2);
}
