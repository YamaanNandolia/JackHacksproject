"""
Marketing Agent 1 (Part 2, Agent 1): Marketing Brief Generator

Consumes the finalized Part 1 business-strategy output and transforms it into
a reusable Marketing Brief for downstream marketing agents.

Does NOT recalculate strategy, market sizing, pricing, or financials.
Does NOT invent claims — extracts and reshapes only.

Upstream: Replace the PART1_PLACEHOLDER comment with the real import once Part 1 is finalized.
"""

import from byllm.lib { Model }
import from typing { Any }
import json;
import from env_loader { ANTHROPIC_API_KEY }

# NOTE: Replace with real upstream module once Part 1 is finalized:
# import from part1_final_strategy { run_final_strategy }

glob llm = Model(model_name="anthropic/claude-sonnet-4-20250514", api_key=str(ANTHROPIC_API_KEY));

# with entry {
#     print("ANTHROPIC key loaded: " + str(ANTHROPIC_API_KEY != ""));
#     print("Model: anthropic/claude-sonnet-4-20250514");
# }

# ── Input: marketing-relevant slice of Part 1 ─────────────────────────────────

"""
Flattened subset of Part 1 fields that are relevant to marketing.
Values are sourced verbatim from Part 1 — do not modify or recalculate.
"""
obj Part1MarketingFields {
    has startup_name: str = "";
    has one_liner: str = "";
    has category: str = "";
    has primary_icp_segment: str = "";
    has buyer_titles: list[str] = [];
    has user_titles: list[str] = [];
    has company_size: str = "";
    has industries: list[str] = [];
    has competitor_summary: list[Any] = [];
    has pricing_model: str = "";
    has price_point: str = "";
    has average_acv: int = 0;
    has price_sensitivity_notes: list[str] = [];
    has cost_of_inaction: str = "";
    has roi_calculator_inputs: list[Any] = [];
    has business_case_template_summary: str = "";
    has cac_payback_months: int = 0;
    has key_assumptions: list[str] = [];
    has key_risks: list[str] = [];
    has upstream_missing_inputs: list[str] = [];
}

# ── Output objects ─────────────────────────────────────────────────────────────

"""Startup identity for marketing copy. Mapped verbatim from Part 1 startup_summary."""
obj MarketingStartupSummary {
    has product_name: str = "";
    has one_liner: str = "";
    has category: str = "";
}

"""Single primary ICP driving all downstream marketing. One segment only — no blended personas."""
obj PrimaryICP {
    has segment_name: str = "";
    has economic_buyer_title: str = "";
    has primary_user_title: str = "";
    has company_size: str = "";
    has target_industries: list[str] = [];
}

"""Before/after narrative grounded in upstream roi_framework and icp context. No invented scenarios."""
obj ValueNarrative {
    has pain_before_product: str = "";
    has outcome_after_product: str = "";
    has core_value_props: list[str] = [];
}

"""Marketing-visible pricing snapshot sourced from Part 1 pricing_packaging. No new pricing strategy."""
obj PricingSnapshot {
    has pricing_model: str = "";
    has starting_price: str = "";
    has average_acv: int = 0;
}

"""ROI proof points sourced verbatim from Part 1 roi_framework. No new calculations."""
obj ROIProof {
    has cost_of_inaction: str = "";
    has expected_roi_summary: str = "";
    has payback_window: str = "";
}

"""
Complete reusable Marketing Brief for Part 2.
Downstream agents (landing page, email, ads, demand gen) consume this as their sole input.
Every field must be traceable to a Part 1 source — nothing invented.
"""
obj MarketingBrief {
    has startup_summary: MarketingStartupSummary = MarketingStartupSummary();
    has priority_icp: PrimaryICP = PrimaryICP();
    has icp_problem_statement: str = "";
    has value_narrative: ValueNarrative = ValueNarrative();
    has pricing_snapshot: PricingSnapshot = PricingSnapshot();
    has roi_proof: ROIProof = ROIProof();
    has proof_points: list[str] = [];
    has competitive_context: list[str] = [];
    has message_priorities: list[str] = [];
    has brand_positioning_angle: str = "";
    has marketing_risks_and_constraints: list[str] = [];
    has missing_inputs: list[str] = [];
}

# ── LLM transformation ────────────────────────────────────────────────────────

def extract_marketing_brief(upstream: Part1MarketingFields) -> MarketingBrief by llm();

sem extract_marketing_brief = """
Transform upstream Part 1 B2B strategy fields into a Marketing Brief.
Extract and reshape only — never recalculate metrics, never invent unsupported claims.
Prefer upstream wording verbatim. Choose one primary ICP; if multiple exist note the
ambiguity in missing_inputs. For every absent or empty source field, leave the output
field empty and add a specific descriptive entry to missing_inputs.
""";

# ── Part 1 dict → typed input ─────────────────────────────────────────────────

"""Extract the marketing-relevant fields from the raw Part 1 output dict."""
def build_part1_fields(part1: dict[str, Any]) -> Part1MarketingFields {
    p: Any = part1;

    startup: Any = p.get("startup_summary", {});
    icp: Any = p.get("icp", {});
    market: Any = p.get("market", {});
    pricing: Any = p.get("pricing_packaging", {});
    roi: Any = p.get("roi_framework", {});
    unit_econ: Any = p.get("unit_economics", {});

    fields: Part1MarketingFields = Part1MarketingFields();
    f: Any = fields;

    f.startup_name                  = startup.get("startup_name", "");
    f.one_liner                     = startup.get("one_liner", "");
    f.category                      = startup.get("category", "");

    f.primary_icp_segment           = icp.get("primary_segment", "");
    f.buyer_titles                  = icp.get("buyer_titles", []);
    f.user_titles                   = icp.get("user_titles", []);
    f.company_size                  = icp.get("company_size", "");
    f.industries                    = icp.get("industries", []);

    f.competitor_summary            = market.get("competitor_summary", []);

    f.pricing_model                 = pricing.get("pricing_model", "");
    f.price_point                   = pricing.get("price_point", "");
    f.average_acv                   = pricing.get("average_acv", 0);
    f.price_sensitivity_notes       = pricing.get("price_sensitivity_notes", []);

    f.cost_of_inaction              = roi.get("cost_of_inaction", "");
    f.roi_calculator_inputs         = roi.get("roi_calculator_inputs", []);
    f.business_case_template_summary = roi.get("business_case_template_summary", "");

    f.cac_payback_months            = unit_econ.get("cac_payback_months", 0);

    f.key_assumptions               = p.get("key_assumptions", []);
    f.key_risks                     = p.get("key_risks", []);
    f.upstream_missing_inputs       = p.get("missing_inputs", []);

    return fields;
}

# ── Public pipeline entry-point ───────────────────────────────────────────────

"""
Generate a Marketing Brief from a raw Part 1 output dict.
Importable by downstream marketing agents:
    import from market_agent1 { run_marketing_brief, MarketingBrief }
"""
def run_marketing_brief(part1: dict[str, Any]) -> MarketingBrief {
    print("MarketingBriefAgent: Building typed input from Part 1 output...");
    upstream: Part1MarketingFields = build_part1_fields(part1);
    print("MarketingBriefAgent: Extracting Marketing Brief...");
    brief: MarketingBrief = extract_marketing_brief(upstream);
    print("MarketingBriefAgent: Done.");
    return brief;
}

# ── Walker ────────────────────────────────────────────────────────────────────

"""
Part 2 entry walker. Inject part1_data before spawning.
Replace PART1_PLACEHOLDER comment with real upstream import once Part 1 is ready.
"""
walker MarketingBriefAgent {
    has part1_data: dict[str, Any] = {};

    can run with Root entry {
        print("MarketingBriefAgent: Starting Part 2 — Marketing Brief generation.");

        # PART1_PLACEHOLDER — replace when Part 1 module is ready:
        #   import from part1_final_strategy { run_final_strategy }
        #   self.part1_data = run_final_strategy();

        if len(self.part1_data) == 0 {
            print("WARNING: part1_data is empty — missing_inputs will be fully populated.");
        }

        brief: MarketingBrief = run_marketing_brief(self.part1_data);
        report brief;

        missing_count: int = len(brief.missing_inputs);
        print(f"MarketingBriefAgent: Done. {missing_count} missing input(s) flagged.");
    }
}

# ── Standalone entry for testing ──────────────────────────────────────────────

with entry {
    # Replace with real Part 1 output when available:
    #   import from part1_final_strategy { run_final_strategy }
    #   part1_payload: dict[str, Any] = run_final_strategy();
    # Or load from file:
    #   f: Any = open("part1_output.json", "r");
    #   part1_payload: dict[str, Any] = json.loads(f.read());
    #   f.close();
    part1_payload: dict[str, Any] = {};

    agent: MarketingBriefAgent = MarketingBriefAgent(part1_data=part1_payload);
    result: Any = root() spawn agent;
    brief: MarketingBrief = result.reports[0];
    b: Any = brief;

    ss: Any = b.startup_summary;
    icp: Any = b.priority_icp;
    vn: Any = b.value_narrative;
    ps: Any = b.pricing_snapshot;
    roi: Any = b.roi_proof;

    output: dict[str, Any] = {
        "startup_summary": {
            "product_name": ss.product_name,
            "one_liner": ss.one_liner,
            "category": ss.category
        },
        "priority_icp": {
            "segment_name": icp.segment_name,
            "economic_buyer": icp.economic_buyer_title,
            "main_user": icp.primary_user_title,
            "company_size": icp.company_size,
            "industries": icp.target_industries
        },
        "problem_statement": b.icp_problem_statement,
        "value_narrative": {
            "before_state": vn.pain_before_product,
            "after_state": vn.outcome_after_product,
            "core_value_props": vn.core_value_props
        },
        "pricing_summary": {
            "pricing_model": ps.pricing_model,
            "starting_price": ps.starting_price,
            "average_acv": ps.average_acv
        },
        "roi_summary": {
            "cost_of_inaction": roi.cost_of_inaction,
            "expected_roi": roi.expected_roi_summary,
            "payback_window": roi.payback_window
        },
        "proof_points": b.proof_points,
        "competitive_context": b.competitive_context,
        "message_priorities": b.message_priorities,
        "brand_angle": b.brand_positioning_angle,
        "risks_or_constraints": b.marketing_risks_and_constraints,
        "missing_inputs": b.missing_inputs
    };

    print("\n=== Marketing Agent 1 Output: Marketing Brief (Part 2 Kickoff) ===");
    print(json.dumps(output, indent=2));
}
