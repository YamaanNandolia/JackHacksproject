"""Agent 10: Partnerships Agent - Maps and prioritizes strategic partnerships for each solution."""

import from byllm.lib { Model }
import from typing { Any }
import json;
import from env_loader { OPENAI_API_KEY, DEFAULT_MODEL_NAME }
import from agent9_sales_infrastructure { SalesInfrastructure }
import from agent8_value_proposition { ValueProposition }

glob llm = Model(model_name=DEFAULT_MODEL_NAME, api_key=OPENAI_API_KEY);

"""A single potential partner candidate assessed across key dimensions."""
obj PartnerCandidate {
    has name: str = "";
    has partner_type: str = "";
    has icp_overlap: str = "";
    has complementary_value: str = "";
    has execution_difficulty: str = "";
    has startup_friendliness: str = "";
    has priority_rank: int = 0;
}

"""A prioritized technology integration with rationale and approach."""
obj IntegrationPartnership {
    has platform_name: str = "";
    has integration_rationale: str = "";
    has integration_depth: str = "";
    has customer_ask_frequency: str = "";
    has product_value_created: str = "";
    has first_milestone: str = "";
}

"""The value exchange analysis for a specific partner relationship."""
obj ValueExchange {
    has partner_name: str = "";
    has value_to_partner: list[str] = [];
    has value_to_us: list[str] = [];
    has asymmetry_acknowledgment: str = "";
    has ways_to_add_value_at_small_scale: list[str] = [];
}

"""A co-selling test plan for an informal joint deal."""
obj CoSellingTest {
    has partner_name: str = "";
    has target_account_profile: str = "";
    has joint_activities: list[str] = [];
    has success_signals: list[str] = [];
    has formalization_trigger: str = "";
}

"""Full partnership strategy for a software solution."""
obj PartnershipStrategy {
    has software_name: str = "";
    has partner_landscape: list[PartnerCandidate] = [];
    has top_integration_partnerships: list[IntegrationPartnership] = [];
    has value_exchanges: list[ValueExchange] = [];
    has co_selling_tests: list[CoSellingTest] = [];
    has partnership_sequencing: str = "";
}

"""Given sales infrastructure plans as JSON, design a full partnership strategy for each solution."""
def generate_partnership_strategies(plans_json: str) -> list[PartnershipStrategy] by llm;

sem generate_partnership_strategies = """
You are a strategic partnerships and business development expert specializing in B2B SaaS ecosystems.
You will receive a JSON list of sales infrastructure plans, each containing a software_name,
CRM choice, pipeline stages, outreach stack, and prospect list strategy.

For EACH plan, produce a PartnershipStrategy with:

1. partner_landscape: Map 8-12 specific, named partner candidates across all five types.
   For each candidate include:
   - name: the actual company name (e.g., "Salesforce", "Zapier", "AWS Marketplace", "Accenture")
   - partner_type: one of "technology", "channel", "referral", "co-selling", or "platform"
   - icp_overlap: 1 sentence on how much their customer base overlaps with this solution's ICP
   - complementary_value: 1 sentence on whether the integration is a "must-have" or "nice-to-have"
     and why customers benefit from using both together
   - execution_difficulty: one of "low", "medium", or "high" with a 1-sentence reason
   - startup_friendliness: one of "high", "medium", or "low" — how welcoming this partner is
     to early-stage companies (e.g., AWS Activate = high; Salesforce AppExchange = medium)
   - priority_rank: integer 1-12 ranking the candidate by overall opportunity
     (1 = highest priority, based on overlap × value × ease)

2. top_integration_partnerships: The top 3 technology integrations to build first.
   For each include:
   - platform_name: the specific tool to integrate with
   - integration_rationale: why this is the highest-leverage first integration (1-2 sentences)
   - integration_depth: one of "lightweight" (Zapier/webhook/API connector) or "native"
     (deep two-way sync, embedded UI, or data pipeline)
   - customer_ask_frequency: estimate of how often prospects ask for this integration
     (e.g., "Asked in >60% of sales conversations")
   - product_value_created: the specific workflow or data flow this integration enables (1 sentence)
   - first_milestone: the first concrete deliverable for this integration
     (e.g., "Bi-directional contact sync via REST API, live within 6 weeks")

3. value_exchanges: For the top 3 priority partners, detail the mutual value exchange.
   For each include:
   - partner_name: the partner this analysis applies to
   - value_to_partner: 3 specific things the partner gains from this relationship
   - value_to_us: 3 specific things we gain from this relationship
   - asymmetry_acknowledgment: 1 honest sentence about which side benefits more at this stage,
     and why the stronger partner would still care
   - ways_to_add_value_at_small_scale: 2-3 concrete actions a small startup can take to bring
     real value to a large partner without needing scale
     (e.g., "Become a reference case study in their niche vertical", "Build the deepest integration
     in their ecosystem for this use case", "Source warm intros from our shared customers")

4. co_selling_tests: Design 2 informal co-selling tests before any formal agreement.
   For each test include:
   - partner_name: which partner to run this test with
   - target_account_profile: describe the type of joint prospect to target
     (a company that is already a customer of the partner and fits our ICP)
   - joint_activities: 3-4 specific activities to do together in this test deal
     (e.g., "Co-present a 30-min joint demo", "Share mutual account intelligence",
     "Partner rep joins our discovery call as a subject-matter expert")
   - success_signals: 3 observable outcomes that would prove the partnership model works
     (e.g., "Partner sourced at least 1 warm intro", "Deal closed 30% faster than solo deals",
     "Prospect cited the integration as a deciding factor")
   - formalization_trigger: the specific evidence threshold that would justify signing a
     formal partnership agreement (e.g., "2 closed deals sourced through the partner within 90 days")

5. partnership_sequencing: 3-4 sentences describing the recommended order to pursue partnerships —
   which to start immediately (month 1-2), which to build toward (month 3-6), and which to
   defer until the product and GTM are more mature. Explain the reasoning behind the sequence.

Return exactly one PartnershipStrategy per sales infrastructure plan.
""";

"""Serialize sales infrastructure plans to JSON string for LLM input."""
def serialize_plans(plans: list[SalesInfrastructure]) -> str {
    output: list[dict[str, Any]] = [];
    for p in plans {
        item: Any = p;
        crm: Any = item.crm_setup;
        stack: Any = item.outreach_stack;
        output.append(
            {
                "software_name": item.software_name,
                "crm": crm.recommended_crm,
                "deal_stages": crm.deal_stages,
                "email_sequencer": stack.email_sequencer,
                "data_enrichment": stack.data_enrichment,
                "prospect_list_strategy": item.prospect_list_strategy
            }
        );
    }
    return json.dumps(output, indent=2);
}

# ── Parallel-pipeline variant ────────────────────────────────────────────────
# Called by agent9_1 when running agents 9/10/11 simultaneously.
# Receives value propositions directly (from agent 8) instead of sales plans.

"""Serialize value propositions for partnership strategy analysis."""
def serialize_vp_for_partnerships(propositions: list[ValueProposition]) -> str {
    output: list[dict[str, Any]] = [];
    for vp in propositions {
        item: Any = vp;
        roi: Any = item.roi_model;
        output.append(
            {
                "software_name": item.software_name,
                "value_proposition_statement": item.value_proposition_statement,
                "positioning_statement": item.positioning_statement,
                "category_strategy": item.category_strategy,
                "persona_messages": item.persona_messages,
                "roi_headline": roi.headline_outcome,
                "total_annual_value": roi.total_annual_value,
                "proof_points": item.proof_points
            }
        );
    }
    return json.dumps(output, indent=2);
}

"""Given value propositions as JSON, produce a full partnership strategy for each solution."""
def generate_partnership_strategies_from_vp(vp_json: str) -> list[PartnershipStrategy] by llm;

sem generate_partnership_strategies_from_vp = """
You are a strategic partnerships and business development expert specializing in B2B SaaS ecosystems.
You will receive a JSON list of value propositions, each with a software_name,
value_proposition_statement, positioning_statement, category_strategy, persona_messages,
roi_headline, total_annual_value, and proof_points.

For EACH value proposition produce a PartnershipStrategy with all required fields:
  partner_landscape, top_integration_partnerships, value_exchanges, co_selling_tests,
  partnership_sequencing — exactly as the schema defines.

Use the value proposition context to identify the most relevant partners, technology
integrations, and co-selling opportunities that amplify the stated value.

Return exactly one PartnershipStrategy per value proposition.
""";
