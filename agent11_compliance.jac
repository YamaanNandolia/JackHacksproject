"""Agent 11: Compliance Agent - Designs legal, compliance, and operational foundations for each solution."""

import from byllm.lib { Model }
import from typing { Any }
import json;
import from env_loader { OPENAI_API_KEY, DEFAULT_MODEL_NAME }
import from agent10_partnerships { run_partnerships, PartnershipStrategy }
import from agent8_value_proposition { ValueProposition }

glob llm = Model(model_name=DEFAULT_MODEL_NAME, api_key=OPENAI_API_KEY);

"""Legal entity and incorporation recommendations."""
obj IncorporationPlan {
    has recommended_entity_type: str = "";
    has jurisdiction: str = "";
    has rationale: str = "";
    has required_registrations: list[str] = [];
    has equity_setup_notes: str = "";
    has recommended_legal_resources: list[str] = [];
}

"""Intellectual property protection strategy."""
obj IPProtection {
    has trademark_targets: list[str] = [];
    has trademark_timeline: str = "";
    has patent_recommendation: str = "";
    has required_employee_agreements: list[str] = [];
    has trade_secret_measures: list[str] = [];
}

"""A single applicable data privacy regulation with required actions."""
obj PrivacyRegulation {
    has regulation_name: str = "";
    has applicability_reason: str = "";
    has required_actions: list[str] = [];
}

"""Data privacy compliance plan."""
obj PrivacyCompliance {
    has applicable_regulations: list[PrivacyRegulation] = [];
    has minimum_implementations: list[str] = [];
    has architecture_recommendations: list[str] = [];
    has breach_notification_procedure: str = "";
}

"""Financial tracking and unit economics setup."""
obj FinancialFoundation {
    has recommended_accounting_software: str = "";
    has revenue_recognition_policy: str = "";
    has unit_economics_to_track: list[str] = [];
    has financial_model_scenarios: list[str] = [];
    has burn_and_runway_dashboard_items: list[str] = [];
    has outsourcing_recommendation: str = "";
}

"""Deal desk process configuration."""
obj DealDeskProcess {
    has review_triggers: list[str] = [];
    has approval_workflow: str = "";
    has turnaround_target: str = "";
    has tracking_fields: list[str] = [];
    has insights_to_monitor: list[str] = [];
}

"""Full compliance and operational foundation for a software solution."""
obj ComplianceFoundation {
    has software_name: str = "";
    has incorporation_plan: IncorporationPlan = IncorporationPlan();
    has ip_protection: IPProtection = IPProtection();
    has privacy_compliance: PrivacyCompliance = PrivacyCompliance();
    has financial_foundation: FinancialFoundation = FinancialFoundation();
    has deal_desk_process: DealDeskProcess = DealDeskProcess();
    has implementation_sequence: str = "";
}

"""Given partnership strategies as JSON, design compliance and operational foundations for each solution."""
def generate_compliance_foundations(strategies_json: str) -> list[ComplianceFoundation] by llm;

sem generate_compliance_foundations = """
You are a startup legal counsel, compliance expert, and operations architect.
You will receive a JSON list of partnership strategies, each containing a software_name,
partner landscape, integration priorities, and value exchange context.

For EACH strategy, produce a ComplianceFoundation with:

1. incorporation_plan: Legal entity setup tailored to this solution.
   - recommended_entity_type: the appropriate entity type (e.g., "Delaware C-Corporation" for
     VC-backed US startups, or region-appropriate alternative)
   - jurisdiction: primary jurisdiction for incorporation
   - rationale: 2 sentences explaining why this structure fits this solution's trajectory
     (consider: fundraising plans implied by the market size, data sensitivity, geography of customers)
   - required_registrations: 3-5 specific registrations or licenses needed
     (e.g., "Foreign qualification in states where employees are located", "Business license in
     primary operating state", "EIN from IRS", "Industry-specific permits if applicable")
   - equity_setup_notes: 1-2 sentences on stock option pool sizing (typically 10-15% ESOP),
     83(b) election timing for founders, and vesting schedule recommendations
   - recommended_legal_resources: 2-3 resources appropriate to stage
     (e.g., "Clerky or Stripe Atlas for initial setup", "Cooley or Orrick for Series A+",
     "Pilot.com for accounting")

2. ip_protection: Intellectual property strategy for this solution.
   - trademark_targets: 3-4 specific items to trademark (company name, product name(s), tagline,
     logo) — name them specifically based on the software_name
   - trademark_timeline: 1 sentence on when to file and expected timeline (8-12 months typical)
   - patent_recommendation: 1-2 sentences assessing whether the core technology warrants a
     provisional patent filing, or whether trade secrets are the better protection — be specific
     about what aspect might be patentable based on the solution's tech stack and features
   - required_employee_agreements: 4 specific clauses all employees and contractors must sign
     (IP assignment, invention disclosure, NDA, non-solicitation) with one sentence each on why
   - trade_secret_measures: 3 concrete operational measures to protect trade secrets
     (e.g., "Code repository access controls with audit logging", "NDA before any technical demo
     or partnership discussion", "Separate production credentials from development environments")

3. privacy_compliance: Data privacy and regulatory compliance plan.
   - applicable_regulations: list 2-4 relevant regulations based on the solution's data profile
     and likely customer geography. For each regulation include:
     * regulation_name: the specific regulation (GDPR, CCPA/CPRA, HIPAA, PCI-DSS, SOC 2, etc.)
     * applicability_reason: 1 sentence on why this regulation applies to this specific solution
     * required_actions: 3 specific, concrete actions required to comply
   - minimum_implementations: 5 baseline privacy implementations every solution needs
     (privacy policy, DPA template, data handling procedures, DSAR process, breach notification)
     — make each specific to this solution's data types
   - architecture_recommendations: 3 data architecture decisions to build in from day one
     (e.g., "Separate PII from behavioral analytics data stores", "Implement field-level encryption
     for customer-identifiable fields", "Build a data retention and deletion pipeline")
   - breach_notification_procedure: 2-3 sentences covering detection, internal escalation,
     customer notification timeline (72 hours for GDPR), and regulator reporting steps

4. financial_foundation: Financial tracking and controls setup.
   - recommended_accounting_software: the best fit accounting tool for this solution's stage and
     complexity, with a one-line rationale (QuickBooks, Xero, or NetSuite)
   - revenue_recognition_policy: 2 sentences on how to recognize revenue for this specific
     solution's pricing model under ASC 606 (ratably over contract term for subscription,
     at point of delivery for one-time, usage-based recognition for consumption pricing)
   - unit_economics_to_track: 5-6 specific unit economics metrics with their calculation method
     (e.g., "CAC by channel: total sales + marketing spend ÷ new customers acquired in period")
   - financial_model_scenarios: 3 scenario names and their key assumptions
     (base, optimistic, conservative — each with 1-sentence assumption summary)
   - burn_and_runway_dashboard_items: 4-5 specific line items for the burn and runway dashboard
   - outsourcing_recommendation: 1-2 sentences on when to hire a fractional CFO or outsourced
     accounting firm (e.g., Pilot, Bench, Kruze) based on this solution's expected revenue ramp

5. deal_desk_process: Deal desk configuration for non-standard deals.
   - review_triggers: 5 specific conditions that require deal desk review, calibrated to this
     solution's pricing model (e.g., for a per-seat SaaS: ">20% discount", "custom seat cap
     with unlimited users", "net-90 payment terms", "multi-year pre-payment", "custom SLA")
   - approval_workflow: 2-3 sentences describing the submission and approval steps
     (who submits, what information, which channel, who approves, response time)
   - turnaround_target: the maximum acceptable deal desk response time
   - tracking_fields: 4-5 data fields to log for every deal desk request
     (e.g., deal size, discount %, reason for request, approved/denied, final terms)
   - insights_to_monitor: 3-4 patterns to watch in deal desk data quarterly
     (e.g., "Frequency of discount requests by segment signals pricing misalignment",
     "Common custom clause requests reveal gaps in standard contract template")

6. implementation_sequence: 3-4 sentences describing the recommended order to tackle these
   foundations — what to do in week 1-2 (entity, banking, equity), what to set up before
   the first customer conversation (privacy policy, NDA, basic IP agreements), what to
   complete before first revenue (DPA, revenue recognition policy, accounting software), and
   what to defer until after product-market fit (deal desk formalization, full SOC 2).

Return exactly one ComplianceFoundation per partnership strategy.
""";

"""Serialize partnership strategies list to JSON string for LLM input."""
def serialize_strategies(strategies: list[PartnershipStrategy]) -> str {
    output: list[dict[str, Any]] = [];
    for s in strategies {
        item: Any = s;

        integrations_out: list[dict[str, str]] = [];
        for i in item.top_integration_partnerships {
            intg: Any = i;
            integrations_out.append(
                {
                    "platform_name": intg.platform_name,
                    "integration_depth": intg.integration_depth
                }
            );
        }

        top_partners: list[str] = [];
        for c in item.partner_landscape {
            candidate: Any = c;
            if candidate.priority_rank <= 3 {
                top_partners.append(candidate.name);
            }
        }

        output.append(
            {
                "software_name": item.software_name,
                "top_priority_partners": top_partners,
                "top_integrations": integrations_out,
                "partnership_sequencing": item.partnership_sequencing
            }
        );
    }
    return json.dumps(output, indent=2);
}

"""Run the full pipeline through Agent 10 and return compliance foundations."""
def run_compliance_foundations() -> list[ComplianceFoundation] {
    print("ComplianceAgent: Getting partnership strategies from Agent 10...");
    strategies: list[PartnershipStrategy] = run_partnerships();
    print(
        f"ComplianceAgent: Received {len(
            strategies
        )} strategies. Designing compliance and operational foundations..."
    );

    strategies_json: str = serialize_strategies(strategies);
    foundations: list[ComplianceFoundation] = generate_compliance_foundations(
        strategies_json
    );

    print(f"ComplianceAgent: Generated {len(foundations)} compliance foundations.");
    for f in foundations {
        item: Any = f;
        print(
            f"  {item.software_name}: Entity={item.incorporation_plan.recommended_entity_type}, Regulations={len(item.privacy_compliance.applicable_regulations)}, Deal desk triggers={len(item.deal_desk_process.review_triggers)}"
        );
    }
    return foundations;
}

# ── Parallel-pipeline variant ────────────────────────────────────────────────
# Called by agent9_1 when running agents 9/10/11 simultaneously.
# Receives value propositions directly (from agent 8) instead of partnership strategies.

"""Serialize value propositions for compliance foundation analysis."""
def serialize_vp_for_compliance(propositions: list[ValueProposition]) -> str {
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
                "roi_headline": roi.headline_outcome,
                "total_annual_value": roi.total_annual_value,
                "proof_points": item.proof_points
            }
        );
    }
    return json.dumps(output, indent=2);
}

"""Given value propositions as JSON, produce compliance and operational foundations for each solution."""
def generate_compliance_foundations_from_vp(vp_json: str) -> list[ComplianceFoundation] by llm;

sem generate_compliance_foundations_from_vp = """
You are a startup legal counsel, compliance expert, and operations architect.
You will receive a JSON list of value propositions, each with a software_name,
value_proposition_statement, positioning_statement, category_strategy, roi_headline,
total_annual_value, and proof_points.

For EACH value proposition produce a ComplianceFoundation with all required fields:
  incorporation_plan, ip_protection, privacy_compliance, financial_foundation,
  deal_desk_process, implementation_sequence — exactly as the schema defines.

Use the value proposition context (what the product does, who it serves, its ROI model)
to tailor each compliance and operational recommendation.

Return exactly one ComplianceFoundation per value proposition.
""";
