import from typing { Any }
import json;
import from market_agent1 {
    MarketingBrief,
    run_marketing_brief
}

walker TestMarketAgent1 {
    can run with Root entry {
        mock_input: str = """
        {
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
            "tam": {
              "value": 5000000000,
              "method": "blended",
              "notes": "Estimated from outbound sales software market"
            },
            "sam": {
              "value": 300000000,
              "notes": "Mid-market B2B SaaS slice"
            },
            "som": {
              "value": 10000000,
              "time_horizon": "2-3 years",
              "notes": "Initial obtainable share"
            },
            "market_growth_rate": "18% YoY",
            "competitor_summary": ["Apollo", "Outreach", "Salesloft"]
          },
          "pricing_packaging": {
            "pricing_model": "per seat",
            "price_point": "$99/user/month",
            "average_acv": 12000,
            "tiers": [
              {
                "name": "Starter",
                "description": "Small outbound teams",
                "price": "$99/user/month",
                "included_features": ["sequence automation", "basic analytics"]
              },
              {
                "name": "Growth",
                "description": "Scaling sales teams",
                "price": "$149/user/month",
                "included_features": ["advanced analytics", "team workflows"]
              }
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
          "financial_model": {
            "revenue_model_formula": "reps × meetings × conversion × ACV",
            "base_case": {
              "annual_revenue_target": 1000000,
              "quarterly_targets": [200000, 250000, 275000, 275000],
              "monthly_targets": [80000, 80000, 80000]
            },
            "optimistic_case": {},
            "conservative_case": {},
            "runway_months": 18,
            "pipeline_coverage_target": "3-4x"
          },
          "sales_funnel": {
            "stage_benchmarks": {
              "outreach_to_reply": "3%",
              "reply_to_meeting": "40%",
              "meeting_to_qualified_opportunity": "50%",
              "opportunity_to_proposal": "60%",
              "proposal_to_closed_won": "30%"
            },
            "average_sales_cycle_days": 45,
            "pipeline_velocity_formula": "(opps × deal size × win rate) / sales cycle",
            "activity_to_outcome_ratios": ["200 emails -> 6 meetings", "4 meetings -> 1 opportunity"],
            "leading_indicators": ["meetings booked", "pipeline created"],
            "lagging_indicators": ["closed revenue", "bookings"]
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
            "churn_targets": {
              "logo_churn": "<10%",
              "revenue_churn": "<8%"
            },
            "churn_reasons": ["budget cuts", "poor onboarding"],
            "retention_notes": "Expansion expected through additional seats"
          },
          "dashboards_reporting": {
            "weekly_sales_dashboard_metrics": ["pipeline by stage", "meetings booked"],
            "monthly_exec_dashboard_metrics": ["ARR growth", "CAC by channel"],
            "deal_tracking_fields": ["stage", "close date", "deal value"],
            "review_cadence": {
              "pipeline_reviews": "weekly",
              "unit_economics_reviews": "monthly"
            }
          },
          "key_assumptions": ["Primary buyer is sales leadership"],
          "key_risks": ["Crowded market", "Needs clearer differentiation"],
          "missing_inputs": []
        }
        """;

        mock_input_dict: dict[str, Any] = json.loads(mock_input);
        brief: MarketingBrief = run_marketing_brief(mock_input_dict);
        report brief;
    }
}

with entry {
    result: Any = root() spawn TestMarketAgent1();
    brief: Any = result.reports[0];

    output: dict[str, Any] = {
        "startup_summary": {
            "product_name": brief.startup_summary.product_name,
            "one_liner": brief.startup_summary.one_liner,
            "category": brief.startup_summary.category
        },
        "priority_icp": {
            "segment_name": brief.priority_icp.segment_name,
            "economic_buyer": brief.priority_icp.economic_buyer_title,
            "main_user": brief.priority_icp.primary_user_title,
            "company_size": brief.priority_icp.company_size,
            "industries": brief.priority_icp.target_industries
        },
        "problem_statement": brief.icp_problem_statement,
        "value_narrative": {
            "before_state": brief.value_narrative.pain_before_product,
            "after_state": brief.value_narrative.outcome_after_product,
            "core_value_props": brief.value_narrative.core_value_props
        },
        "pricing_summary": {
            "pricing_model": brief.pricing_snapshot.pricing_model,
            "starting_price": brief.pricing_snapshot.starting_price,
            "average_acv": brief.pricing_snapshot.average_acv
        },
        "roi_summary": {
            "cost_of_inaction": brief.roi_proof.cost_of_inaction,
            "expected_roi": brief.roi_proof.expected_roi_summary,
            "payback_window": brief.roi_proof.payback_window
        },
        "proof_points": brief.proof_points,
        "competitive_context": brief.competitive_context,
        "message_priorities": brief.message_priorities,
        "brand_angle": brief.brand_positioning_angle,
        "risks_or_constraints": brief.marketing_risks_and_constraints,
        "missing_inputs": brief.missing_inputs
    };

    print("\\n=== test_market_agent1 output ===");
    print(json.dumps(output, indent=2));
}