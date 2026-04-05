"""Agent 8: Value Proposition Agent - Crafts value proposition, positioning, and ROI model for each solution."""

import from byllm.lib { Model }
import from typing { Any }
import json;
import from env_loader { OPENAI_API_KEY, DEFAULT_MODEL_NAME }
import from agent7_pricing { CustomerModel }

glob llm = Model(model_name=DEFAULT_MODEL_NAME, api_key=OPENAI_API_KEY);

"""A single line item in the ROI / value quantification model."""
obj ROILineItem {
    has metric: str = "";
    has current_state: str = "";
    has expected_improvement: str = "";
    has annual_value: str = "";
}

"""The full value quantification / ROfI model for a solution."""
obj ROIModel {
    has headline_outcome: str = "";
    has line_items: list[ROILineItem] = [];
    has total_annual_value: str = "";
    has payback_period: str = "";
    has key_assumptions: list[str] = [];
}

"""Full value proposition and positioning package for a software solution."""
obj ValueProposition {
    has software_name: str = "";
    has value_proposition_statement: str = "";
    has positioning_statement: str = "";
    has category_strategy: str = "";
    has category_rationale: str = "";
    has persona_messages: list[str] = [];
    has roi_model: ROIModel = ROIModel();
    has proof_points: list[str] = [];
}

"""Given customer models as JSON, craft a full value proposition package for each solution."""
def generate_value_propositions(models_json: str) -> list[ValueProposition] by llm;

sem generate_value_propositions = """
You are a B2B messaging strategist, positioning expert, and revenue consultant.
You will receive a JSON list of customer models, each containing a software_name, ICP details,
buyer personas with their goals/pain points/language, and lead scoring context.

For EACH customer model, produce a ValueProposition with:

1. value_proposition_statement: A single crisp sentence following this formula:
   "We help [specific ICP customer] [achieve specific outcome] by [how you do it differently]."
   - Name the exact customer type from the ICP (not generic)
   - Quantify the outcome if possible (e.g., "reduce time-to-close by 40%")
   - Explain the mechanism that makes you different from current alternatives
   - Must be understandable in under 10 seconds by someone with no product context

2. positioning_statement: One structured paragraph following this format:
   "For [target customer] who [key pain/need], [software_name] is a [product category] that
   [primary differentiator]. Unlike [main alternative], we [proof of difference]."

3. category_strategy: Exactly one of: "existing_category", "new_subcategory", or "new_category"

4. category_rationale: 2 sentences explaining why that category strategy is the right choice
   given the competitive landscape and the buyer's existing mental model.

5. persona_messages: One tailored one-liner message per buyer persona (Champion, Economic Buyer,
   Technical Evaluator, Blocker) written in the language that persona cares about.
   Format each as: "[Role]: [message]"

6. roi_model: A concrete value quantification model a salesperson can use.
   - headline_outcome: the single most compelling outcome headline (e.g., "$340K additional revenue/year")
   - line_items: 3-5 ROI line items. For each:
     * metric: what is being measured (e.g., "Hours saved on manual reporting")
     * current_state: what the buyer experiences today (e.g., "8 hours/week per analyst")
     * expected_improvement: the improvement your solution delivers (e.g., "75% reduction")
     * annual_value: the dollar or time value of that improvement (e.g., "$62,400/year per analyst")
   - total_annual_value: the total combined value across all line items
   - payback_period: how quickly a buyer recoups the investment (e.g., "< 3 months")
   - key_assumptions: 3-4 conservative assumptions the model is built on, so the buyer
     understands and trusts the numbers (e.g., "Assumes 10 analysts at $80K fully-loaded cost")

7. proof_points: 3-4 concrete, specific evidence statements that make the value prop credible
   (e.g., benchmark data, industry statistics, early customer results, analyst findings).
   Each should be one sentence and reference a specific number or source type.

Return exactly one ValueProposition per customer model.
""";

"""Serialize customer models list to JSON string for LLM input."""
def serialize_models(models: list[CustomerModel]) -> str {
    output: list[dict[str, Any]] = [];
    for m in models {
        item: Any = m;
        icp: Any = item.icp;

        personas_out: list[dict[str, Any]] = [];
        for p in item.buyer_personas {
            persona: Any = p;
            personas_out.append(
                {
                    "role": persona.role,
                    "typical_titles": persona.typical_titles,
                    "top_goals": persona.top_goals,
                    "top_pain_points": persona.top_pain_points,
                    "kpis": persona.kpis,
                    "common_objections": persona.common_objections,
                    "key_language": persona.key_language
                }
            );
        }

        output.append(
            {
                "software_name": item.software_name,
                "icp": {
                    "industry_vertical": icp.industry_vertical,
                    "company_size_revenue": icp.company_size_revenue,
                    "company_size_headcount": icp.company_size_headcount,
                    "geography": icp.geography,
                    "tech_stack_signals": icp.tech_stack_signals,
                    "business_model": icp.business_model
                },
                "buyer_personas": personas_out
            }
        );
    }
    return json.dumps(output, indent=2);
}

