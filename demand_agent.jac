"""
Demand Agent (Part 2, Agent 2): Demand Generation Execution Agent

Downstream from market_agent1 (Marketing Brief Generator).
Consumes a structured MarketingBrief and produces concrete demand-generation
outputs: channel plans, campaign messaging, landing page directions, lead
magnets, nurture sequences, paid experiment ideas, and execution priorities.

Does NOT redo strategy, TAM/SAM/SOM, pricing, unit economics, or financial modeling.
Does NOT invent traction, customer logos, benchmarks, or unsupported claims.
Extracts and executes only — everything is grounded in the upstream brief.

Upstream: import from market_agent1 { run_marketing_brief, MarketingBrief }
"""

import from byllm.lib { Model }
import from typing { Any }
import json;
import from env_loader { ANTHROPIC_API_KEY }
import from market_agent1 { run_marketing_brief, MarketingBrief }

glob llm = Model(model_name="anthropic/claude-sonnet-4-20250514", api_key=str(ANTHROPIC_API_KEY));

# ── Input: typed marketing brief slice for demand gen ─────────────────────────

"""
Marketing brief fields consumed by demand gen. All values sourced from upstream
MarketingBrief — do not modify, recalculate, or extend upstream strategy.
"""
obj DemandGenInput {
    has product_name: str = "";
    has one_liner: str = "";
    has category: str = "";
    has segment_name: str = "";
    has economic_buyer_title: str = "";
    has primary_user_title: str = "";
    has company_size: str = "";
    has target_industries: list[str] = [];
    has icp_problem_statement: str = "";
    has pain_before_product: str = "";
    has outcome_after_product: str = "";
    has core_value_props: list[str] = [];
    has pricing_model: str = "";
    has starting_price: str = "";
    has average_acv: int = 0;
    has cost_of_inaction: str = "";
    has expected_roi_summary: str = "";
    has payback_window: str = "";
    has proof_points: list[str] = [];
    has competitive_context: list[str] = [];
    has message_priorities: list[str] = [];
    has brand_positioning_angle: str = "";
    has marketing_risks_and_constraints: list[str] = [];
    has upstream_missing_inputs: list[str] = [];
}

# ── Output objects ─────────────────────────────────────────────────────────────

"""Channel plan and campaign theme derived from ICP and product context. No invented benchmarks."""
obj DemandStrategy {
    has primary_goal: str = "";
    has secondary_goals: list[str] = [];
    has recommended_channels: list[str] = [];
    has channel_rationale: list[str] = [];
    has target_funnel_stages: list[str] = [];
    has core_campaign_theme: str = "";
}

"""Conversion-focused messaging grounded in ICP pain, ROI, and competitive context."""
obj CampaignMessaging {
    has primary_persona: str = "";
    has secondary_personas: list[str] = [];
    has top_pain_points: list[str] = [];
    has buyer_triggers: list[str] = [];
    has message_pillars: list[str] = [];
    has positioning_statement: str = "";
    has differentiation_angles: list[str] = [];
}

"""
Landing page recommendations tied to ICP pain and conversion goal.
Headlines and CTAs may be creative and outcome-oriented.
Subheadlines must NOT imply customer adoption, percentages, or results unless
those numbers appear explicitly in the upstream brief. No guarantee language.
If evidence for a claim is absent, frame it as the promise/hypothesis, not a fact.
"""
obj LandingPageStrategy {
    has headline_options: list[str] = [];
    has subheadline_options: list[str] = [];
    has cta_options: list[str] = [];
    has page_angles: list[str] = [];
    has conversion_elements: list[str] = [];
}

"""
Pipeline-generating asset ideas. Ideas must match ICP sophistication and buying stage.
Webinar and lead magnet ideas must be educational or problem-framing in format —
NOT customer story, case study, or testimonial formats unless customers are
explicitly present in the upstream brief. Calculator ideas should be framed as
'what you could save/gain' hypotheticals, not stated outcomes.
"""
obj LeadGenerationAssets {
    has lead_magnet_ideas: list[str] = [];
    has webinar_ideas: list[str] = [];
    has newsletter_angles: list[str] = [];
    has calculator_or_tool_ideas: list[str] = [];
    has demo_offer_ideas: list[str] = [];
}

"""A single step in a nurture or outbound sequence."""
obj NurtureStep {
    has step_number: int = 0;
    has channel: str = "";
    has goal: str = "";
    has message_outline: list[str] = [];
    has cta: str = "";
}

"""Multi-touch nurture sequence from first touch to pipeline conversion."""
obj NurtureAndConversion {
    has target_persona: str = "";
    has sequence_goal: str = "";
    has touchpoints: list[NurtureStep] = [];
}

"""Paid channel and experiment ideas. No invented CPCs, CTRs, or conversion rates."""
obj PaidAndExperimentation {
    has test_ideas: list[str] = [];
    has offers_to_test: list[str] = [];
    has audience_tests: list[str] = [];
    has landing_page_tests: list[str] = [];
    has success_metrics: list[str] = [];
}

"""
Proof and objection handling strictly grounded in the upstream brief.
proof_points_to_feature: only items explicitly listed in brief.proof_points — never invented.
social_proof_needs: list these as GAPS or recommended proof assets to acquire, not existing claims.
  Format each as: 'Need: [type of proof] — [why it matters for this ICP]'
objection_handling_angles: frame as rational, evidence-based responses. No fake quotes,
  no 'customers say', no implied win stories unless the brief explicitly provides them.
"""
obj TrustAndObjectionPlan {
    has proof_points_to_feature: list[str] = [];
    has social_proof_needs: list[str] = [];
    has objection_handling_angles: list[str] = [];
}

"""Ordered execution plan split into immediate, near-term, and future actions."""
obj ExecutionPriorities {
    has do_now: list[str] = [];
    has do_next: list[str] = [];
    has do_later: list[str] = [];
}

"""
Complete demand generation execution plan.
Every recommendation must be traceable to an upstream brief field.
No invented traction, logos, benchmarks, or claims.
"""
obj DemandGenPlan {
    has demand_strategy: DemandStrategy = DemandStrategy();
    has campaign_messaging: CampaignMessaging = CampaignMessaging();
    has landing_page_strategy: LandingPageStrategy = LandingPageStrategy();
    has lead_generation_assets: LeadGenerationAssets = LeadGenerationAssets();
    has nurture_and_conversion: NurtureAndConversion = NurtureAndConversion();
    has paid_and_experimentation: PaidAndExperimentation = PaidAndExperimentation();
    has trust_and_objection_plan: TrustAndObjectionPlan = TrustAndObjectionPlan();
    has execution_priorities: ExecutionPriorities = ExecutionPriorities();
    has missing_inputs: list[str] = [];
    has assumptions: list[str] = [];
}

# ── LLM transformation ────────────────────────────────────────────────────────

def generate_demand_plan(brief: DemandGenInput) -> DemandGenPlan by llm();

sem generate_demand_plan = """
You are a senior B2B SaaS demand gen strategist. Transform the upstream brief into
a complete DemandGenPlan. Be specific and usable — but strictly evidence-bound.

Execution rules:
- Extract and execute only. No new strategy, pricing, TAM/SAM/SOM, or financials.
- If the ICP is narrow and high-intent, prioritize direct-response and sales-assisted channels.
- If proof is limited, lean into pain clarity, ROI framing, and educational content.
- If measurable gains exist in the brief, make them central to hooks and CTAs.
- If competition is heavy, differentiate on outcomes and workflow fit — not feature lists.

Evidence rules (critical — violations make this agent harmful):
- Never state or imply customer adoption, customer results, or traction unless explicitly
  present in brief.proof_points. If absent, treat them as proof gaps, not facts.
- Never invent percentages, time savings, or quantitative outcomes (e.g. 'cut by 40%',
  'saves 5 hours/week') unless the exact figure appears in the upstream brief.
- Never use: 'already', 'customers are', 'teams have', 'guarantee', 'proven',
  'enterprise adoption', 'similar companies', or any language implying existing evidence
  that is not present in the brief.
- Never invent case studies, testimonials, competitive win stories, or benchmark data.
- When evidence is absent: convert the claim into a hypothesis, proof recommendation,
  or missing input. Use language like 'designed to', 'intended to', 'can help teams',
  'early hypothesis', or 'proof needed'.
- Headlines and CTAs can be aspirational and outcome-oriented — but must not assert
  facts not in the brief.
""";

# ── Brief dict → typed input ──────────────────────────────────────────────────

"""Flatten the upstream MarketingBrief object into the demand gen typed input."""
def build_demand_input(brief: MarketingBrief) -> DemandGenInput {
    b: Any = brief;
    ss: Any = b.startup_summary;
    icp: Any = b.priority_icp;
    vn: Any = b.value_narrative;
    ps: Any = b.pricing_snapshot;
    roi: Any = b.roi_proof;

    inp: DemandGenInput = DemandGenInput();
    i: Any = inp;

    i.product_name                 = ss.product_name;
    i.one_liner                    = ss.one_liner;
    i.category                     = ss.category;
    i.segment_name                 = icp.segment_name;
    i.economic_buyer_title         = icp.economic_buyer_title;
    i.primary_user_title           = icp.primary_user_title;
    i.company_size                 = icp.company_size;
    i.target_industries            = icp.target_industries;
    i.icp_problem_statement        = b.icp_problem_statement;
    i.pain_before_product          = vn.pain_before_product;
    i.outcome_after_product        = vn.outcome_after_product;
    i.core_value_props             = vn.core_value_props;
    i.pricing_model                = ps.pricing_model;
    i.starting_price               = ps.starting_price;
    i.average_acv                  = ps.average_acv;
    i.cost_of_inaction             = roi.cost_of_inaction;
    i.expected_roi_summary         = roi.expected_roi_summary;
    i.payback_window               = roi.payback_window;
    i.proof_points                 = b.proof_points;
    i.competitive_context          = b.competitive_context;
    i.message_priorities           = b.message_priorities;
    i.brand_positioning_angle      = b.brand_positioning_angle;
    i.marketing_risks_and_constraints = b.marketing_risks_and_constraints;
    i.upstream_missing_inputs      = b.missing_inputs;

    return inp;
}

# ── Public pipeline entry-point ───────────────────────────────────────────────

"""
Generate a DemandGenPlan from an upstream MarketingBrief object.
Importable by downstream agents:
    import from demand_agent { run_demand_agent, DemandGenPlan }
"""
def run_demand_agent(brief: MarketingBrief) -> DemandGenPlan {
    print("DemandAgent: Building typed input from Marketing Brief...");
    inp: DemandGenInput = build_demand_input(brief);
    print("DemandAgent: Generating demand generation plan...");
    plan: DemandGenPlan = generate_demand_plan(inp);
    print("DemandAgent: Done.");
    return plan;
}

# ── Walker ────────────────────────────────────────────────────────────────────

"""
Demand gen walker. Receives a raw Part 1 dict, runs the full upstream
marketing brief pipeline, then generates the demand plan on top.
Replace part1_data with a real upstream call when Part 1 is finalized:
    import from part1_final_strategy { run_final_strategy }
    self.part1_data = run_final_strategy();
"""
walker DemandAgent {
    has part1_data: dict[str, Any] = {};

    can run with Root entry {
        print("DemandAgent: Starting demand generation pipeline.");

        if len(self.part1_data) == 0 {
            print("WARNING: part1_data is empty — missing_inputs will be fully populated.");
        }

        print("DemandAgent: Generating upstream Marketing Brief...");
        brief: MarketingBrief = run_marketing_brief(self.part1_data);

        plan: DemandGenPlan = run_demand_agent(brief);
        report plan;

        missing_count: int = len(plan.missing_inputs);
        print(f"DemandAgent: Done. {missing_count} missing input(s) flagged.");
    }
}

# ── Standalone serializer helper ──────────────────────────────────────────────

"""Serialize a DemandGenPlan to a nested output dict for JSON printing."""
def serialize_plan(plan: DemandGenPlan) -> dict[str, Any] {
    p: Any = plan;
    ds: Any = p.demand_strategy;
    cm: Any = p.campaign_messaging;
    lp: Any = p.landing_page_strategy;
    lg: Any = p.lead_generation_assets;
    nc: Any = p.nurture_and_conversion;
    pe: Any = p.paid_and_experimentation;
    tp: Any = p.trust_and_objection_plan;
    ep: Any = p.execution_priorities;

    touchpoints_out: list[dict[str, Any]] = [];
    for step in nc.touchpoints {
        s: Any = step;
        touchpoints_out.append(
            {
                "step_number": s.step_number,
                "channel": s.channel,
                "goal": s.goal,
                "message_outline": s.message_outline,
                "cta": s.cta
            }
        );
    }

    return {
        "demand_strategy": {
            "primary_goal": ds.primary_goal,
            "secondary_goals": ds.secondary_goals,
            "recommended_channels": ds.recommended_channels,
            "channel_rationale": ds.channel_rationale,
            "target_funnel_stages": ds.target_funnel_stages,
            "core_campaign_theme": ds.core_campaign_theme
        },
        "campaign_messaging": {
            "primary_persona": cm.primary_persona,
            "secondary_personas": cm.secondary_personas,
            "top_pain_points": cm.top_pain_points,
            "buyer_triggers": cm.buyer_triggers,
            "message_pillars": cm.message_pillars,
            "positioning_statement": cm.positioning_statement,
            "differentiation_angles": cm.differentiation_angles
        },
        "landing_page_strategy": {
            "headline_options": lp.headline_options,
            "subheadline_options": lp.subheadline_options,
            "cta_options": lp.cta_options,
            "page_angles": lp.page_angles,
            "conversion_elements": lp.conversion_elements
        },
        "lead_generation_assets": {
            "lead_magnet_ideas": lg.lead_magnet_ideas,
            "webinar_ideas": lg.webinar_ideas,
            "newsletter_angles": lg.newsletter_angles,
            "calculator_or_tool_ideas": lg.calculator_or_tool_ideas,
            "demo_offer_ideas": lg.demo_offer_ideas
        },
        "nurture_and_conversion": {
            "target_persona": nc.target_persona,
            "sequence_goal": nc.sequence_goal,
            "touchpoints": touchpoints_out
        },
        "paid_and_experimentation": {
            "test_ideas": pe.test_ideas,
            "offers_to_test": pe.offers_to_test,
            "audience_tests": pe.audience_tests,
            "landing_page_tests": pe.landing_page_tests,
            "success_metrics": pe.success_metrics
        },
        "trust_and_objection_plan": {
            "proof_points_to_feature": tp.proof_points_to_feature,
            "social_proof_needs": tp.social_proof_needs,
            "objection_handling_angles": tp.objection_handling_angles
        },
        "execution_priorities": {
            "do_now": ep.do_now,
            "do_next": ep.do_next,
            "do_later": ep.do_later
        },
        "missing_inputs": p.missing_inputs,
        "assumptions": p.assumptions
    };
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
    part1_payload: dict[str, Any] = {
        "startup_summary": {
            "startup_name": "PipelinePilot",
            "one_liner": "AI workflow software for outbound sales teams",
            "category": "B2B SaaS",
            "target_market": "mid-market sales orgs"
        },
        "icp": {
            "primary_segment": "B2B SaaS companies",
            "buyer_titles": ["VP Sales", "Head of Revenue"],
            "user_titles": ["SDR Manager", "AE"],
            "company_size": "50-500 employees",
            "industries": ["Software", "SaaS"],
            "addressable_accounts_estimate": 2500
        },
        "market": {
            "tam": {"value": 5000000000, "method": "blended", "notes": "Outbound sales software market"},
            "sam": {"value": 300000000, "notes": "Mid-market B2B SaaS slice"},
            "som": {"value": 10000000, "time_horizon": "2-3 years", "notes": "Initial obtainable share"},
            "market_growth_rate": "18% YoY",
            "competitor_summary": ["Apollo", "Outreach", "Salesloft"]
        },
        "pricing_packaging": {
            "pricing_model": "per seat",
            "price_point": "$99/user/month",
            "average_acv": 12000,
            "tiers": [
                {"name": "Starter", "price": "$99/user/month", "included_features": ["sequence automation", "basic analytics"]},
                {"name": "Growth", "price": "$149/user/month", "included_features": ["advanced analytics", "team workflows"]}
            ],
            "discounting_rules": ["Max 10% without approval"],
            "price_sensitivity_notes": ["Mid-market buyers compare against Outreach and Apollo"]
        },
        "unit_economics": {
            "cac": 4500,
            "ltv": 36000,
            "ltv_cac_ratio": 8,
            "cac_payback_months": 10,
            "gross_margin_percent": 82,
            "break_even_notes": "Break-even achievable with 150 customers"
        },
        "roi_framework": {
            "roi_calculator_inputs": ["rep time saved", "meetings booked", "admin hours reduced"],
            "cost_of_inaction": "Manual prospecting wastes rep time and slows pipeline generation",
            "business_case_template_summary": "Teams reduce admin time and increase meetings booked"
        },
        "retention_expansion": {
            "grr_target": "90%+",
            "nrr_target": "110%+",
            "expansion_revenue_target": "30%+",
            "churn_targets": {"logo_churn": "<10%", "revenue_churn": "<8%"},
            "churn_reasons": ["budget cuts", "poor onboarding"],
            "retention_notes": "Expansion through additional seats"
        },
        "key_assumptions": ["Primary buyer is sales leadership"],
        "key_risks": ["Crowded market", "Needs clearer differentiation"],
        "missing_inputs": []
    };

    agent: DemandAgent = DemandAgent(part1_data=part1_payload);
    result: Any = root() spawn agent;
    plan: DemandGenPlan = result.reports[0];

    output: dict[str, Any] = serialize_plan(plan);

    print("\n=== Demand Agent Output: Demand Generation Plan ===");
    print(json.dumps(output, indent=2));
}
