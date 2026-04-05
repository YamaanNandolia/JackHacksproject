"""Agent 9: Sales Infrastructure Agent - Designs the full sales system for each solution."""

import from byllm.lib { Model }
import from typing { Any }
import json;
import from env_loader { OPENAI_API_KEY, DEFAULT_MODEL_NAME }
import from agent8_value_proposition { run_value_propositions, ValueProposition }

glob llm = Model(model_name=DEFAULT_MODEL_NAME, api_key=OPENAI_API_KEY);

"""CRM configuration recommendation."""
obj CRMSetup {
    has recommended_crm: str = "";
    has crm_rationale: str = "";
    has deal_stages: list[str] = [];
    has required_fields_per_stage: list[str] = [];
    has key_dashboard_metrics: list[str] = [];
}

"""A single pipeline stage with its entry and exit criteria."""
obj PipelineStage {
    has stage_name: str = "";
    has description: str = "";
    has exit_criteria: list[str] = [];
}

"""The outreach tooling stack recommendation."""
obj OutreachStack {
    has email_sequencer: str = "";
    has linkedin_tool: str = "";
    has call_recorder: str = "";
    has scheduling_tool: str = "";
    has data_enrichment: str = "";
    has integration_notes: str = "";
}

"""A single cold outreach email in a sequence."""
obj EmailTemplate {
    has step: int = 0;
    has channel: str = "";
    has subject_line: str = "";
    has body: str = "";
    has cta: str = "";
}

"""Demo flow structure for the product."""
obj DemoFlow {
    has opening_recap: str = "";
    has aha_moment: str = "";
    has core_walkthrough_steps: list[str] = [];
    has persona_variations: list[str] = [];
    has sandbox_suggestion: str = "";
}

"""A required commercial document with its purpose and key terms to watch."""
obj CommercialDocument {
    has document_name: str = "";
    has purpose: str = "";
    has key_terms_to_negotiate: list[str] = [];
}

"""Full sales infrastructure plan for a software solution."""
obj SalesInfrastructure {
    has software_name: str = "";
    has crm_setup: CRMSetup = CRMSetup();
    has pipeline_stages: list[PipelineStage] = [];
    has outreach_stack: OutreachStack = OutreachStack();
    has prospect_list_strategy: str = "";
    has email_sequence: list[EmailTemplate] = [];
    has demo_flow: DemoFlow = DemoFlow();
    has commercial_documents: list[CommercialDocument] = [];
}

"""Given value propositions as JSON, design a complete sales infrastructure for each solution."""
def generate_sales_infrastructure(propositions_json: str) -> list[SalesInfrastructure] by llm;

sem generate_sales_infrastructure = """
You are a revenue operations architect and B2B sales expert.
You will receive a JSON list of value propositions, each containing a software_name,
value proposition statement, positioning statement, category strategy, persona messages,
ROI model, and proof points.

For EACH value proposition, produce a SalesInfrastructure with:

1. crm_setup: CRM configuration tailored to this solution.
   - recommended_crm: choose one of "HubSpot", "Salesforce", "Pipedrive", or "Close"
     based on the solution's complexity, ICP size, and expected deal volume
   - crm_rationale: 1-2 sentences justifying that CRM choice
   - deal_stages: list of 6-8 pipeline stage names (e.g., "Lead", "Qualified", "Discovery",
     "Demo", "Proposal", "Negotiation", "Closed Won", "Closed Lost")
   - required_fields_per_stage: one entry per stage transition describing required fields
     (e.g., "Lead → Qualified: ICP match confirmed, pain point documented, authority verified")
   - key_dashboard_metrics: 4-5 metrics to track on the CRM dashboard
     (e.g., "Pipeline value by stage", "Avg days per stage", "Win rate by ICP segment")

2. pipeline_stages: Detailed breakdown of each stage.
   For each of the 6-8 stages list:
   - stage_name: the stage label
   - description: what is happening in this stage (1 sentence)
   - exit_criteria: 2-3 specific, verifiable conditions that must be true to advance
     (no vague "rep feels good about it" — use evidence-based criteria)

3. outreach_stack: Specific tool recommendations for this solution's go-to-market.
   - email_sequencer: best tool for this solution (Apollo, Outreach, Salesloft, Instantly, or Lemlist)
     with one-line rationale
   - linkedin_tool: "LinkedIn Sales Navigator" plus one key filter tip for this ICP
   - call_recorder: best tool (Gong, Chorus, or Fireflies) with one-line rationale
   - scheduling_tool: best tool (Calendly, SavvyCal, or Chili Piper) with one-line rationale
   - data_enrichment: best data tool (Apollo, ZoomInfo, Clay, or Clearbit) for this ICP
   - integration_notes: 1-2 sentences on the most important CRM integrations to set up

4. prospect_list_strategy: 2-3 sentences on how to build the initial prospect list —
   which filters to apply in Sales Navigator, how to segment by vertical or use case,
   what data enrichment steps to run, and how often to refresh the list.

5. email_sequence: A 5-step outreach sequence. For each step provide:
   - step: the step number (1–5)
   - channel: "email" or "linkedin"
   - subject_line: a specific, non-generic subject line (for email steps)
   - body: the message body (under 150 words for email, under 100 words for LinkedIn).
     Step 1 leads with the pain and a proof point. Steps 2-4 each add a new angle
     (a case study, an industry insight, a different pain, the ROI number).
     Step 5 is a polite breakup message that leaves the door open.
   - cta: the specific call to action (e.g., "Worth a 15-min call this week?")

6. demo_flow: How to structure the product demo for this solution.
   - opening_recap: how to open by recapping the prospect's pain discovered in discovery (2 sentences)
   - aha_moment: the single feature or workflow to show within the first 3 minutes that
     makes prospects lean forward (1 sentence)
   - core_walkthrough_steps: 4-6 ordered steps in the demo narrative
   - persona_variations: 2-3 variations to adapt the demo for different buying committee roles
     (e.g., "For the Champion: focus on daily workflow; For the Economic Buyer: lead with ROI slide")
   - sandbox_suggestion: how to let prospects self-explore after the demo (1 sentence)

7. commercial_documents: List the 5 required legal/commercial documents.
   For each include:
   - document_name: the document type (MSA, SaaS Subscription Agreement, SLA, DPA, NDA)
   - purpose: one sentence on what it covers and why it's needed
   - key_terms_to_negotiate: 2-3 specific clauses to watch for this solution's context
     (e.g., for a data-heavy solution: data ownership, breach notification window, GDPR compliance)

Return exactly one SalesInfrastructure per value proposition.
""";

"""Serialize value propositions list to JSON string for LLM input."""
def serialize_propositions(propositions: list[ValueProposition]) -> str {
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

"""Run the full pipeline through Agent 8 and return sales infrastructure plans."""
def run_sales_infrastructure() -> list[SalesInfrastructure] {
    print("SalesInfrastructureAgent: Getting value propositions from Agent 8...");
    propositions: list[ValueProposition] = run_value_propositions();
    print(
        f"SalesInfrastructureAgent: Received {len(
            propositions
        )} propositions. Designing sales infrastructure..."
    );

    propositions_json: str = serialize_propositions(propositions);
    plans: list[SalesInfrastructure] = generate_sales_infrastructure(propositions_json);

    print(f"SalesInfrastructureAgent: Generated {len(plans)} sales infrastructure plans.");
    for p in plans {
        item: Any = p;
        print(
            f"  {item.software_name}: CRM={item.crm_setup.recommended_crm}, Stages={len(item.pipeline_stages)}, Sequence steps={len(item.email_sequence)}"
        );
    }
    return plans;
}

"""Export: run full pipeline through Agent 9 and return sales infrastructure plans for downstream agents."""
def run_sales_plans() -> list[SalesInfrastructure] {
    return run_sales_infrastructure();
}
