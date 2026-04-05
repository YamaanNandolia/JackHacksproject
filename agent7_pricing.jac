"""Agent 7: Customer Persona Agent - Models the ideal customer profile and buying committee for each solution."""

import from byllm.lib { Model }
import from typing { Any }
import json;
import from env_loader { OPENAI_API_KEY, DEFAULT_MODEL_NAME }
import from agent6_business_orchestrator { run_business_reports, BusinessReport }

glob llm = Model(model_name=DEFAULT_MODEL_NAME, api_key=OPENAI_API_KEY);

"""Ideal Customer Profile firmographics and fit criteria."""
obj ICP {
    has industry_vertical: str = "";
    has company_size_revenue: str = "";
    has company_size_headcount: str = "";
    has geography: str = "";
    has tech_stack_signals: str = "";
    has business_model: str = "";
    has disqualifying_criteria: list[str] = [];
    has buying_triggers: list[str] = [];
}

"""A single stakeholder persona in the buying committee."""
obj BuyerPersona {
    has role: str = "";
    has typical_titles: list[str] = [];
    has top_goals: list[str] = [];
    has top_pain_points: list[str] = [];
    has kpis: list[str] = [];
    has discovery_channels: list[str] = [];
    has common_objections: list[str] = [];
    has key_language: str = "";
}

"""A lead scoring rule with a criterion and its point value."""
obj ScoringRule {
    has criterion: str = "";
    has dimension: str = "";
    has points: int = 0;
}

"""Full customer model for a software solution."""
obj CustomerModel {
    has software_name: str = "";
    has icp: ICP = ICP();
    has buyer_personas: list[BuyerPersona] = [];
    has lead_scoring_rules: list[ScoringRule] = [];
    has qualified_lead_threshold: int = 0;
}

"""Given business intelligence reports as JSON, produce a full customer model for each solution."""
def generate_customer_models(reports_json: str) -> list[CustomerModel] by llm;

sem generate_customer_models = """
You are a go-to-market strategist and customer research expert specializing in B2B SaaS.
You will receive a JSON list of business intelligence reports, each containing a software_name,
the problem it solves, market sizing, competitors, tailwinds, headwinds, buyer alternatives,
pricing intelligence, and positioning recommendation.

For EACH report, produce a CustomerModel with:

1. icp: The Ideal Customer Profile — be ruthlessly specific, not generic.
   - industry_vertical: the specific industry or segment (e.g., "B2B SaaS companies in financial services")
   - company_size_revenue: revenue band of best-fit companies (e.g., "$10M–$100M ARR")
   - company_size_headcount: headcount range (e.g., "100–500 employees")
   - geography: primary target geography (e.g., "North America, English-speaking markets")
   - tech_stack_signals: tools or platforms that signal a good fit (e.g., "uses Salesforce, runs on AWS")
   - business_model: the buyer's business model type (e.g., "subscription-based SaaS, marketplace")
   - disqualifying_criteria: 3-4 explicit reasons to walk away from a prospect (one sentence each)
   - buying_triggers: 4-5 events or changes that create urgency to buy (one sentence each,
     e.g., new funding round, new executive hire, failed audit, rapid headcount growth)

2. buyer_personas: Model 3-4 stakeholder roles in the buying committee. For each:
   - role: one of "Champion", "Economic Buyer", "Technical Evaluator", or "Blocker"
   - typical_titles: 2-3 job titles that fill this role
   - top_goals: 3 professional goals this person is trying to achieve
   - top_pain_points: 3 things that keep them up at night related to the problem
   - kpis: 2-3 metrics their boss uses to evaluate them
   - discovery_channels: how they find new tools (e.g., peer recommendations, G2, LinkedIn, conferences)
   - common_objections: 2-3 objections they typically raise when evaluating this type of solution
   - key_language: the specific words and phrases this persona uses to describe the problem
     (2-3 sentences written in their voice)

3. lead_scoring_rules: 8-10 scoring rules used to rank prospects. For each rule:
   - criterion: the specific signal being measured (e.g., "Industry matches ICP vertical")
   - dimension: either "fit" (ICP match) or "engagement" (behavior/intent signal)
   - points: integer point value (fit rules typically 5-15 pts, engagement rules typically 5-25 pts)

4. qualified_lead_threshold: the minimum total score that routes a lead to sales for immediate
   outreach (integer, typically 50-70 based on the rules above).

Return exactly one CustomerModel per report.
""";

"""Serialize business reports list to JSON string for LLM input."""
def serialize_reports(reports: list[BusinessReport]) -> str {
    output: list[dict[str, Any]] = [];
    for r in reports {
        item: Any = r;
        ms: Any = item.market_size;
        competitors_out: list[dict[str, str]] = [];
        for c in item.competitors {
            comp: Any = c;
            competitors_out.append(
                {
                    "name": comp.name,
                    "target_segment": comp.target_segment,
                    "weaknesses": comp.weaknesses
                }
            );
        }
        output.append(
            {
                "software_name": item.software_name,
                "problem": item.problem,
                "market_size": {
                    "tam": ms.tam,
                    "sam": ms.sam,
                    "som": ms.som
                },
                "competitors": competitors_out,
                "tailwinds": item.tailwinds,
                "headwinds": item.headwinds,
                "current_buyer_alternatives": item.current_buyer_alternatives,
                "pricing_intelligence": item.pricing_intelligence,
                "positioning_recommendation": item.positioning_recommendation
            }
        );
    }
    return json.dumps(output, indent=2);
}

"""Run the full pipeline through Agent 6 and return customer models."""
def run_customer_modeling() -> list[CustomerModel] {
    print("CustomerPersonaAgent: Getting business reports from Agent 6...");
    reports: list[BusinessReport] = run_business_reports();
    print(
        f"CustomerPersonaAgent: Received {len(
            reports
        )} reports. Modeling customer profiles and buyer personas..."
    );

    reports_json: str = serialize_reports(reports);
    models: list[CustomerModel] = generate_customer_models(reports_json);

    print(f"CustomerPersonaAgent: Generated {len(models)} customer models.");
    for m in models {
        item: Any = m;
        print(
            f"  {item.software_name}: ICP={item.icp.industry_vertical}, Personas={len(item.buyer_personas)}, Scoring rules={len(item.lead_scoring_rules)}"
        );
    }
    return models;
}

"""Export: run full pipeline through Agent 7 and return customer models for downstream agents."""
def run_customer_models() -> list[CustomerModel] {
    return run_customer_modeling();
}
