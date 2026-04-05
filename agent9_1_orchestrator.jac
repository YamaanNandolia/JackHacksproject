"""Agent 9.1: Orchestrator - Runs Agents 6-11 business pipeline.

Called by orchestrator.py AFTER agent5 has run and written AGENT5_OUTPUT_JSON.
Loads that cached output so agents 1-5 are never re-executed.

Pipeline order:
  Load      → read AGENT5_OUTPUT_JSON (agents 1-5 already ran)
  Agent 6   → generate_business_reports()     [sequential]
  Agent 7   → generate_customer_models()      [sequential]
  Agent 8   → generate_value_propositions()   [sequential]
  Agents 9,10,11 → parallel threads, all receive agent 8 value_props as input
"""

import from typing { Any }
import json;
import os;
import threading;
import from env_loader { OPENAI_API_KEY }

import from agent5_software_prompt { run_software_prompts, SoftwarePrompt }
import from agent6_business_orchestrator {
    serialize_prompts,
    generate_business_reports,
    BusinessReport
}
import from agent7_pricing {
    serialize_reports,
    generate_customer_models,
    CustomerModel
}
import from agent8_value_proposition {
    serialize_models,
    generate_value_propositions,
    ValueProposition
}
import from agent9_sales_infrastructure {
    serialize_propositions,
    generate_sales_infrastructure,
    SalesInfrastructure
}
import from agent10_partnerships {
    serialize_vp_for_partnerships,
    generate_partnership_strategies_from_vp,
    PartnershipStrategy
}
import from agent11_compliance {
    serialize_vp_for_compliance,
    generate_compliance_foundations_from_vp,
    ComplianceFoundation
}

"""Combined output bundle for one solution across all pipeline stages."""
obj OrchestratorBundle {
    has software_name: str = "";
    has business_report: BusinessReport = BusinessReport();
    has customer_model: CustomerModel = CustomerModel();
    has value_proposition: ValueProposition = ValueProposition();
    has sales_infrastructure: SalesInfrastructure = SalesInfrastructure();
    has partnership_strategy: PartnershipStrategy = PartnershipStrategy();
    has compliance_foundation: ComplianceFoundation = ComplianceFoundation();
}

# ── Thread worker helpers ────────────────────────────────────────────────────

"""Worker: generate sales infrastructure and store result in out_list[0]."""
def _run_sales(json_str: str, out_list: list) -> None {
    out_list.append(generate_sales_infrastructure(json_str));
}

"""Worker: generate partnership strategies and store result in out_list[0]."""
def _run_partnerships(json_str: str, out_list: list) -> None {
    out_list.append(generate_partnership_strategies_from_vp(json_str));
}

"""Worker: generate compliance foundations and store result in out_list[0]."""
def _run_compliance(json_str: str, out_list: list) -> None {
    out_list.append(generate_compliance_foundations_from_vp(json_str));
}

"""Run the Agents 6-11 business pipeline.

If AGENT5_OUTPUT_JSON env-var points to an existing file the software prompts
are loaded from it (agents 1-5 already ran and their output was cached by
orchestrator.py).  Otherwise agents 1-5 are re-run in-process.

Agents 9, 10, and 11 all receive agent 8's value propositions as their input
and run simultaneously in separate threads."""
def run_full_pipeline() -> list[OrchestratorBundle] {
    print("\n=== Agent 9.1 Orchestrator: Starting business pipeline (Agents 6 → 11) ===\n");

    # ── Load or run agents 1-5 ───────────────────────────────────────────────
    software_prompts: list[SoftwarePrompt] = [];
    cached_path: str = os.getenv("AGENT5_OUTPUT_JSON", "");

    if cached_path != "" and os.path.exists(cached_path) {
        print(f"Phase 1/4  [Agents 1-5] Loading cached output from {cached_path}...");
        f: Any = open(cached_path, "r");
        raw: str = f.read();
        f.close();
        cached_data: Any = json.loads(raw);
        for entry in cached_data {
            d: Any = entry;
            sp: SoftwarePrompt = SoftwarePrompt(
                category_name=d["category_name"],
                problem=d["problem"],
                score=d["score"],
                software_name=d["software_name"],
                description=d["description"],
                core_features=d["core_features"],
                tech_stack=d["tech_stack"],
                prompt=d["prompt"]
            );
            software_prompts.append(sp);
        }
        print(f"           [Agents 1-5] Loaded {len(software_prompts)} software prompts.\n");
    } else {
        print("Phase 1/4  [Agents 1-5] Running agents 1-5 (no cache found)...");
        software_prompts = run_software_prompts();
        print(f"           [Agents 1-5] Done — {len(software_prompts)} software prompts.\n");
    }

    # ── Sequential: agents 6 → 7 → 8 ────────────────────────────────────────
    print("Phase 2/4  [Agent 6]   Running market research and competitive analysis...");
    prompts_as_dicts: list[dict[str, Any]] = [];
    for sp in software_prompts {
        item: Any = sp;
        prompts_as_dicts.append(
            {
                "software_name": item.software_name,
                "problem": item.problem,
                "description": item.description,
                "core_features": item.core_features,
                "tech_stack": item.tech_stack
            }
        );
    }
    solutions_json: str = serialize_prompts(prompts_as_dicts);
    business_reports: list[BusinessReport] = generate_business_reports(solutions_json);
    print(f"           [Agent 6]   Done — {len(business_reports)} business reports.\n");

    print("Phase 3/4  [Agent 7]   Modeling customer profiles and buyer personas...");
    reports_json: str = serialize_reports(business_reports);
    customer_models: list[CustomerModel] = generate_customer_models(reports_json);
    print(f"           [Agent 7]   Done — {len(customer_models)} customer models.\n");

    print("Phase 4/4  [Agent 8]   Crafting value propositions and ROI models...");
    models_json: str = serialize_models(customer_models);
    value_props: list[ValueProposition] = generate_value_propositions(models_json);
    print(f"           [Agent 8]   Done — {len(value_props)} value propositions.\n");

    # ── Parallel: agents 9, 10, 11 — all receive value_props as input ────────
    print("Phase 5/4  [Agents 9/10/11] Launching in parallel threads...");
    props_json: str = serialize_propositions(value_props);
    vp_json: str = serialize_vp_for_partnerships(value_props);
    vp_compliance_json: str = serialize_vp_for_compliance(value_props);

    results9: list = [];
    results10: list = [];
    results11: list = [];

    t9: Any = threading.Thread(target=_run_sales, args=(props_json, results9));
    t10: Any = threading.Thread(target=_run_partnerships, args=(vp_json, results10));
    t11: Any = threading.Thread(target=_run_compliance, args=(vp_compliance_json, results11));

    t9.start();
    t10.start();
    t11.start();
    t9.join();
    t10.join();
    t11.join();

    sales_plans: list[SalesInfrastructure] = results9[0];
    partnerships: list[PartnershipStrategy] = results10[0];
    compliance_foundations: list[ComplianceFoundation] = results11[0];

    print(f"           [Agent 9]   Done — {len(sales_plans)} sales infrastructure plans.");
    print(f"           [Agent 10]  Done — {len(partnerships)} partnership strategies.");
    print(f"           [Agent 11]  Done — {len(compliance_foundations)} compliance foundations.\n");

    count: int = min(
        len(software_prompts),
        len(business_reports),
        len(customer_models),
        len(value_props),
        len(sales_plans),
        len(partnerships),
        len(compliance_foundations)
    );
    print(
        f"Bundling {count} solutions (prompts={len(software_prompts)}, biz={len(business_reports)}, customers={len(customer_models)}, vp={len(value_props)}, sales={len(sales_plans)}, partners={len(partnerships)}, compliance={len(compliance_foundations)})."
    );

    bundles: list[OrchestratorBundle] = [];
    for idx in range(count) {
        sp_item: Any = software_prompts[idx];
        br: Any = business_reports[idx];
        cm: Any = customer_models[idx];
        vp: Any = value_props[idx];
        sp: Any = sales_plans[idx];
        ps: Any = partnerships[idx];
        cf: Any = compliance_foundations[idx];
        bundle: OrchestratorBundle = OrchestratorBundle(
            software_name=sp_item.software_name,
            business_report=br,
            customer_model=cm,
            value_proposition=vp,
            sales_infrastructure=sp,
            partnership_strategy=ps,
            compliance_foundation=cf
        );
        bundles.append(bundle);
    }

    print(f"=== Orchestrator complete: {len(bundles)} full solution bundles assembled. ===\n");
    return bundles;
}

walker OrchestratorAgent {
    can run with Root entry {
        bundles: list[OrchestratorBundle] = run_full_pipeline();
        report bundles;
    }
}

"""Serialize a list of OrchestratorBundles into a JSON-friendly list of dicts."""
def serialize_bundles(bundles: list[OrchestratorBundle]) -> list[dict[str, Any]] {
    output: list[dict[str, Any]] = [];
    for b in bundles {
        bundle: Any = b;

        # Agent 6 — Business Intelligence
        br: Any = bundle.business_report;
        br_ms: Any = br.market_size;
        competitors_out: list[dict[str, str]] = [];
        for c in br.competitors {
            comp: Any = c;
            competitors_out.append(
                {
                    "name": comp.name,
                    "core_capabilities": comp.core_capabilities,
                    "pricing_model": comp.pricing_model,
                    "target_segment": comp.target_segment,
                    "strengths": comp.strengths,
                    "weaknesses": comp.weaknesses
                }
            );
        }

        # Agent 7 — Customer Model
        cm: Any = bundle.customer_model;
        cm_icp: Any = cm.icp;
        personas_out: list[dict[str, Any]] = [];
        for p in cm.buyer_personas {
            persona: Any = p;
            personas_out.append(
                {
                    "role": persona.role,
                    "typical_titles": persona.typical_titles,
                    "top_goals": persona.top_goals,
                    "top_pain_points": persona.top_pain_points,
                    "kpis": persona.kpis,
                    "discovery_channels": persona.discovery_channels,
                    "common_objections": persona.common_objections,
                    "key_language": persona.key_language
                }
            );
        }
        scoring_out: list[dict[str, Any]] = [];
        for s in cm.lead_scoring_rules {
            rule: Any = s;
            scoring_out.append(
                {
                    "criterion": rule.criterion,
                    "dimension": rule.dimension,
                    "points": rule.points
                }
            );
        }

        # Agent 8 — Value Proposition
        vp: Any = bundle.value_proposition;
        vp_roi: Any = vp.roi_model;
        roi_lines_out: list[dict[str, str]] = [];
        for li in vp_roi.line_items {
            line: Any = li;
            roi_lines_out.append(
                {
                    "metric": line.metric,
                    "current_state": line.current_state,
                    "expected_improvement": line.expected_improvement,
                    "annual_value": line.annual_value
                }
            );
        }

        # Agent 9 — Sales Infrastructure
        sp: Any = bundle.sales_infrastructure;
        sp_crm: Any = sp.crm_setup;
        sp_stack: Any = sp.outreach_stack;
        sp_demo: Any = sp.demo_flow;
        stages_out: list[dict[str, Any]] = [];
        for st in sp.pipeline_stages {
            stage: Any = st;
            stages_out.append(
                {
                    "stage_name": stage.stage_name,
                    "description": stage.description,
                    "exit_criteria": stage.exit_criteria
                }
            );
        }
        sequence_out: list[dict[str, Any]] = [];
        for e in sp.email_sequence {
            step: Any = e;
            sequence_out.append(
                {
                    "step": step.step,
                    "channel": step.channel,
                    "subject_line": step.subject_line,
                    "body": step.body,
                    "cta": step.cta
                }
            );
        }
        docs_out: list[dict[str, Any]] = [];
        for d in sp.commercial_documents {
            doc: Any = d;
            docs_out.append(
                {
                    "document_name": doc.document_name,
                    "purpose": doc.purpose,
                    "key_terms_to_negotiate": doc.key_terms_to_negotiate
                }
            );
        }

        # Agent 10 — Partnerships
        ps: Any = bundle.partnership_strategy;
        landscape_out: list[dict[str, Any]] = [];
        for c in ps.partner_landscape {
            candidate: Any = c;
            landscape_out.append(
                {
                    "name": candidate.name,
                    "partner_type": candidate.partner_type,
                    "icp_overlap": candidate.icp_overlap,
                    "complementary_value": candidate.complementary_value,
                    "execution_difficulty": candidate.execution_difficulty,
                    "startup_friendliness": candidate.startup_friendliness,
                    "priority_rank": candidate.priority_rank
                }
            );
        }
        integrations_out: list[dict[str, Any]] = [];
        for i in ps.top_integration_partnerships {
            intg: Any = i;
            integrations_out.append(
                {
                    "platform_name": intg.platform_name,
                    "integration_rationale": intg.integration_rationale,
                    "integration_depth": intg.integration_depth,
                    "customer_ask_frequency": intg.customer_ask_frequency,
                    "product_value_created": intg.product_value_created,
                    "first_milestone": intg.first_milestone
                }
            );
        }
        exchanges_out: list[dict[str, Any]] = [];
        for ex in ps.value_exchanges {
            exchange: Any = ex;
            exchanges_out.append(
                {
                    "partner_name": exchange.partner_name,
                    "value_to_partner": exchange.value_to_partner,
                    "value_to_us": exchange.value_to_us,
                    "asymmetry_acknowledgment": exchange.asymmetry_acknowledgment,
                    "ways_to_add_value_at_small_scale": exchange.ways_to_add_value_at_small_scale
                }
            );
        }
        cosell_out: list[dict[str, Any]] = [];
        for t in ps.co_selling_tests {
            test: Any = t;
            cosell_out.append(
                {
                    "partner_name": test.partner_name,
                    "target_account_profile": test.target_account_profile,
                    "joint_activities": test.joint_activities,
                    "success_signals": test.success_signals,
                    "formalization_trigger": test.formalization_trigger
                }
            );
        }

        # Agent 11 — Compliance
        cf: Any = bundle.compliance_foundation;
        cf_inc: Any = cf.incorporation_plan;
        cf_ip: Any = cf.ip_protection;
        cf_priv: Any = cf.privacy_compliance;
        cf_fin: Any = cf.financial_foundation;
        cf_desk: Any = cf.deal_desk_process;
        regulations_out: list[dict[str, Any]] = [];
        for r in cf_priv.applicable_regulations {
            reg: Any = r;
            regulations_out.append(
                {
                    "regulation_name": reg.regulation_name,
                    "applicability_reason": reg.applicability_reason,
                    "required_actions": reg.required_actions
                }
            );
        }

        output.append(
            {
                "software_name": bundle.software_name,
                "agent_6_business_intelligence": {
                    "market_size": {
                        "tam": br_ms.tam,
                        "sam": br_ms.sam,
                        "som": br_ms.som,
                        "sizing_rationale": br_ms.sizing_rationale
                    },
                    "competitors": competitors_out,
                    "tailwinds": br.tailwinds,
                    "headwinds": br.headwinds,
                    "current_buyer_alternatives": br.current_buyer_alternatives,
                    "pricing_intelligence": br.pricing_intelligence,
                    "positioning_recommendation": br.positioning_recommendation
                },

                "agent_7_customer_model": {
                    "icp": {
                        "industry_vertical": cm_icp.industry_vertical,
                        "company_size_revenue": cm_icp.company_size_revenue,
                        "company_size_headcount": cm_icp.company_size_headcount,
                        "geography": cm_icp.geography,
                        "tech_stack_signals": cm_icp.tech_stack_signals,
                        "business_model": cm_icp.business_model,
                        "disqualifying_criteria": cm_icp.disqualifying_criteria,
                        "buying_triggers": cm_icp.buying_triggers
                    },
                    "buyer_personas": personas_out,
                    "lead_scoring_rules": scoring_out,
                    "qualified_lead_threshold": cm.qualified_lead_threshold
                },

                "agent_8_value_proposition": {
                    "statement": vp.value_proposition_statement,
                    "positioning": vp.positioning_statement,
                    "category_strategy": vp.category_strategy,
                    "category_rationale": vp.category_rationale,
                    "persona_messages": vp.persona_messages,
                    "roi_model": {
                        "headline_outcome": vp_roi.headline_outcome,
                        "line_items": roi_lines_out,
                        "total_annual_value": vp_roi.total_annual_value,
                        "payback_period": vp_roi.payback_period,
                        "key_assumptions": vp_roi.key_assumptions
                    },
                    "proof_points": vp.proof_points
                },

                "agent_9_sales_infrastructure": {
                    "crm_setup": {
                        "recommended_crm": sp_crm.recommended_crm,
                        "crm_rationale": sp_crm.crm_rationale,
                        "deal_stages": sp_crm.deal_stages,
                        "required_fields_per_stage": sp_crm.required_fields_per_stage,
                        "key_dashboard_metrics": sp_crm.key_dashboard_metrics
                    },
                    "pipeline_stages": stages_out,
                    "outreach_stack": {
                        "email_sequencer": sp_stack.email_sequencer,
                        "linkedin_tool": sp_stack.linkedin_tool,
                        "call_recorder": sp_stack.call_recorder,
                        "scheduling_tool": sp_stack.scheduling_tool,
                        "data_enrichment": sp_stack.data_enrichment,
                        "integration_notes": sp_stack.integration_notes
                    },
                    "prospect_list_strategy": sp.prospect_list_strategy,
                    "email_sequence": sequence_out,
                    "demo_flow": {
                        "opening_recap": sp_demo.opening_recap,
                        "aha_moment": sp_demo.aha_moment,
                        "core_walkthrough_steps": sp_demo.core_walkthrough_steps,
                        "persona_variations": sp_demo.persona_variations,
                        "sandbox_suggestion": sp_demo.sandbox_suggestion
                    },
                    "commercial_documents": docs_out
                },

                "agent_10_partnerships": {
                    "partner_landscape": landscape_out,
                    "top_integration_partnerships": integrations_out,
                    "value_exchanges": exchanges_out,
                    "co_selling_tests": cosell_out,
                    "partnership_sequencing": ps.partnership_sequencing
                },

                "agent_11_compliance": {
                    "incorporation_plan": {
                        "recommended_entity_type": cf_inc.recommended_entity_type,
                        "jurisdiction": cf_inc.jurisdiction,
                        "rationale": cf_inc.rationale,
                        "required_registrations": cf_inc.required_registrations,
                        "equity_setup_notes": cf_inc.equity_setup_notes,
                        "recommended_legal_resources": cf_inc.recommended_legal_resources
                    },
                    "ip_protection": {
                        "trademark_targets": cf_ip.trademark_targets,
                        "trademark_timeline": cf_ip.trademark_timeline,
                        "patent_recommendation": cf_ip.patent_recommendation,
                        "required_employee_agreements": cf_ip.required_employee_agreements,
                        "trade_secret_measures": cf_ip.trade_secret_measures
                    },
                    "privacy_compliance": {
                        "applicable_regulations": regulations_out,
                        "minimum_implementations": cf_priv.minimum_implementations,
                        "architecture_recommendations": cf_priv.architecture_recommendations,
                        "breach_notification_procedure": cf_priv.breach_notification_procedure
                    },
                    "financial_foundation": {
                        "recommended_accounting_software": cf_fin.recommended_accounting_software,
                        "revenue_recognition_policy": cf_fin.revenue_recognition_policy,
                        "unit_economics_to_track": cf_fin.unit_economics_to_track,
                        "financial_model_scenarios": cf_fin.financial_model_scenarios,
                        "burn_and_runway_dashboard_items": cf_fin.burn_and_runway_dashboard_items,
                        "outsourcing_recommendation": cf_fin.outsourcing_recommendation
                    },
                    "deal_desk_process": {
                        "review_triggers": cf_desk.review_triggers,
                        "approval_workflow": cf_desk.approval_workflow,
                        "turnaround_target": cf_desk.turnaround_target,
                        "tracking_fields": cf_desk.tracking_fields,
                        "insights_to_monitor": cf_desk.insights_to_monitor
                    },
                    "implementation_sequence": cf.implementation_sequence
                }
            }
        );
    }

    return output;
}

