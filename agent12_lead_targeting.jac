"""Agent 12: Lead Targeting Pipeline

Full end-to-end pipeline:
  Step 1 — LLM (Claude) extracts industries, job titles, and search terms
  Step 2 — Google Places API finds businesses + phone numbers
  Step 3 — VAPI AI initiates outbound calls

Pipeline position: Agent 5 (software ideas) → Agent 12 (find + call leads)

Keys required in .env:
  ANTHROPIC_API_KEY      (Claude — required for extraction)
  GOOGLE_PLACES_API_KEY  (required for Places queries)
  VAPI_API_KEY           (optional — skip calls if absent)
  VAPI_PHONE_NUMBER_ID   (required if making calls)
  VAPI_ASSISTANT_ID      (required if making calls)
"""

import from byllm.lib { Model }
import from typing { Any }
import json;
import os;
import requests;
import from env_loader {
    ANTHROPIC_API_KEY,
    GOOGLE_PLACES_API_KEY,
    VAPI_API_KEY,
    VAPI_PHONE_NUMBER_ID,
    VAPI_ASSISTANT_ID
}
import from agent4_problem_creator { run_problem_creation, ProblemStatement }
import from agent5_software_prompt { SoftwarePrompt, generate_software_prompts, serialize_problems }

# Create properly-typed local copies of API keys
glob _anthropic_key: Any = ANTHROPIC_API_KEY;
glob _google_places_key: Any = GOOGLE_PLACES_API_KEY;
glob _vapi_key: Any = VAPI_API_KEY;
glob _vapi_phone: Any = VAPI_PHONE_NUMBER_ID;
glob _vapi_assistant: Any = VAPI_ASSISTANT_ID;

glob llm = Model(model_name="anthropic/claude-sonnet-4-6", api_key=_anthropic_key);

glob AGENT5_CACHE_FILENAME: str = "agent5-result.json";
glob MAX_RESULTS_PER_TERM: int = 5;

# ---------------------------------------------------------------------------
# Object types
# ---------------------------------------------------------------------------

"""One ideal customer profile segment."""
obj IdealCustomerProfile {
    has segment_name: str = "";
    has description: str = "";
    has company_size: str = "";
    has revenue_range: str = "";
}

"""LLM-extracted lead-targeting intelligence for one product."""
obj LeadTargetingResult {
    has product_summary: str = "";
    has business_model_guess: str = "";
    has target_industries: list[str] = [];
    has ideal_customer_profiles: list[IdealCustomerProfile] = [];
    has target_job_titles: list[str] = [];
    has keywords: list[str] = [];
    has pain_point_keywords: list[str] = [];
    has google_places_search_terms: list[str] = [];
    has location_needed: bool = False;
    has missing_inputs: list[str] = [];
    has notes: str = "";
}

"""A discovered business prospect from Google Places."""
obj Business {
    has name: str = "";
    has address: str = "";
    has phone: str = "";
    has website: str = "";
    has source: str = "";
    has place_id: str = "";
    has rating: float = 0.0;
    has search_term: str = "";
}

"""Record of one VAPI outbound call attempt."""
obj CallRecord {
    has business_name: str = "";
    has phone: str = "";
    has vapi_call_id: str = "";
    has status: str = "";
    has error: str = "";
}

"""Full pipeline output for one software product."""
obj PipelineResult {
    has software_name: str = "";
    has product_description: str = "";
    has search_location: str = "";
    has extraction: LeadTargetingResult = LeadTargetingResult();
    has businesses: list[Business] = [];
    has call_records: list[CallRecord] = [];
    has total_businesses_found: int = 0;
    has total_calls_initiated: int = 0;
}

# ---------------------------------------------------------------------------
# Step 1 — LLM extraction
# ---------------------------------------------------------------------------

"""Extract structured lead-targeting data from a product description."""
def extract_lead_targeting(product_description: str) -> LeadTargetingResult by llm;

sem extract_lead_targeting = """
You are a senior go-to-market strategist and sales intelligence analyst.
Read the software product description provided and extract precise, structured
lead-targeting data for a sales team that will use it to find real business
prospects via the Google Places API. The input product_description contains the software details to analyze.

Be conservative and practical. Never invent data.

=== OUTPUT FIELDS ===

product_summary
  Single sentence (max 20 words): "Helps X do Y."

business_model_guess
  Exactly one of: B2B | B2C | B2B2C | Unknown
  Default to B2B for business-facing products.

target_industries
  3-6 specific verticals. E.g. "Dental practices", "Home services contractors".
  Never use vague labels like "healthcare" or "tech".

ideal_customer_profiles
  2-4 ICP segments, each with:
    segment_name   — short label (e.g. "Independent dental practice")
    description    — one sentence on why they're a strong fit
    company_size   — employee range (e.g. "5-30 employees")
    revenue_range  — annual revenue estimate (e.g. "$500K-$3M")

target_job_titles
  4-8 realistic buyer or decision-maker titles.
  E.g. "Practice Manager", "Office Administrator", "Clinic Owner".

keywords
  6-12 short product-capability keywords (1-3 words each).
  E.g. "missed call recovery", "appointment automation", "AI receptionist".

pain_point_keywords
  4-8 phrases the prospect would say, not marketing copy.
  E.g. "missed appointments", "staff overwhelmed", "lost bookings".

google_places_search_terms
  4-10 SHORT terms (1-4 words) that work as Google Places API queries.
  GOOD: "dental clinic", "orthodontist", "med spa", "roofing contractor"
  BAD:  "businesses that need call automation" — too long, won't work.

location_needed
  true if physical location matters, false otherwise.

missing_inputs
  List absent info that would sharpen targeting. Empty list if sufficient.

notes
  One short paragraph: assumptions made, confidence level, any caveats.

=== RULES ===
- Be specific. Vague = useless downstream.
- Google Places terms must be short real establishment types.
- Never invent facts not in the description.
""";

# ---------------------------------------------------------------------------
# Step 2 — Google Places
# ---------------------------------------------------------------------------

glob PLACES_TEXTSEARCH_URL: str = "https://maps.googleapis.com/maps/api/place/textsearch/json";
glob PLACES_DETAILS_URL: str = "https://maps.googleapis.com/maps/api/place/details/json";

"""Fetch phone number and website for one place_id via Places Details API."""
def get_place_details(place_id: str, api_key: str) -> dict[str, str] {
    params: dict[str, str] = {
        "place_id": place_id,
        "fields": "formatted_phone_number,website",
        "key": api_key
    };
    response: Any = requests.get(PLACES_DETAILS_URL, params=params, timeout=10);
    data: Any = response.json();
    res: Any = data.get("result", {});
    return {
        "phone": res.get("formatted_phone_number", ""),
        "website": res.get("website", "")
    };
}

"""Query Google Places Text Search for one term, return up to MAX_RESULTS_PER_TERM businesses."""
def search_google_places(
    search_term: str,
    location: str,
    api_key: str
) -> list[Business] {
    businesses: list[Business] = [];
    if len(api_key) == 0 {
        return businesses;
    }
    query: str = search_term;
    if len(location) > 0 {
        query = search_term + " in " + location;
    }
    params: dict[str, str] = {
        "query": query,
        "key": api_key
    };
    response: Any = requests.get(PLACES_TEXTSEARCH_URL, params=params, timeout=15);
    data: Any = response.json();
    status: str = data.get("status", "");
    if status != "OK" {
        print(f"    [Places] Status '{status}' for: {query}");
        return businesses;
    }
    count: int = 0;
    for place in data.get("results", []) {
        if count >= MAX_RESULTS_PER_TERM {
            break;
        }
        place_id: str = place.get("place_id", "");
        details: dict[str, str] = get_place_details(place_id, api_key);
        businesses.append(
            Business(
                name=place.get("name", ""),
                address=place.get("formatted_address", ""),
                phone=details["phone"],
                website=details["website"],
                source="google",
                place_id=place_id,
                rating=place.get("rating", 0.0),
                search_term=search_term
            )
        );
        count += 1;
    }
    return businesses;
}

# ---------------------------------------------------------------------------
# Step 3 — VAPI outbound calls
# ---------------------------------------------------------------------------

glob VAPI_CALL_URL: str = "https://api.vapi.ai/call/phone";

"""Format a phone number to E.164 format (+1XXXXXXXXXX for US numbers)."""
def format_phone_e164(phone: str) -> str {
    if len(phone) == 0 {
        return "";
    }
    
    # Remove all non-digit characters
    digits: str = "";
    for c in phone {
        if c >= "0" and c <= "9" {
            digits += c;
        }
    }
    
    # If it starts with 1, assume it's already US with country code
    if len(digits) == 11 and digits[0] == "1" {
        return "+" + digits;
    }
    
    # If it's 10 digits, add US country code
    if len(digits) == 10 {
        return "+1" + digits;
    }
    
    # If it's 7 digits, assume local number, but we can't format without area code
    if len(digits) == 7 {
        return "";  # Invalid for E.164
    }
    
    # For any other format, return empty (invalid)
    return "";
}

"""Initiate one VAPI outbound call. Returns a CallRecord with status."""
def make_vapi_call(
    phone: str,
    business_name: str,
    vapi_key: str,
    phone_number_id: str,
    assistant_id: str
) -> CallRecord {
    record: CallRecord = CallRecord(
        business_name=business_name,
        phone=phone,
        vapi_call_id="",
        status="skipped",
        error=""
    );
    r: Any = record;
    
    # Format phone to E.164
    formatted_phone: str = format_phone_e164(phone);
    if len(formatted_phone) == 0 {
        r.error = "Invalid phone number format";
        return record;
    }
    
    headers: dict[str, str] = {
        "Authorization": "Bearer " + vapi_key,
        "Content-Type": "application/json"
    };
    payload: dict[str, Any] = {
        "phoneNumberId": phone_number_id,
        "assistantId": assistant_id,
        "customer": {
            "number": formatted_phone,
            "name": business_name
        }
    };
    response: Any = requests.post(VAPI_CALL_URL, headers=headers, json=payload, timeout=15);
    data: Any = response.json();
    status_code: int = response.status_code;
    if status_code == 200 or status_code == 201 {
        r.vapi_call_id = data.get("id", "");
        r.status = "initiated";
    } else {
        r.status = "failed";
        r.error = data.get("message", str(status_code));
    }
    return record;
}

# ---------------------------------------------------------------------------
# Deduplication
# ---------------------------------------------------------------------------

"""Remove duplicate businesses by phone number and exact name."""
def deduplicate_businesses(businesses: list[Business]) -> list[Business] {
    seen_phones: list[str] = [];
    seen_names: list[str] = [];
    unique: list[Business] = [];
    for biz in businesses {
        b: Any = biz;
        raw_phone: str = b.phone;
        phone_key: str = (
            raw_phone.strip()
                     .replace(" ", "")
                     .replace("-", "")
                     .replace("(", "")
                     .replace(")", "")
        );
        name_key: str = b.name.strip().lower();
        phone_seen: bool = len(phone_key) > 0 and phone_key in seen_phones;
        name_seen: bool = name_key in seen_names;
        if phone_seen or name_seen {
            continue;
        }
        if len(phone_key) > 0 {
            seen_phones.append(phone_key);
        }
        seen_names.append(name_key);
        unique.append(biz);
    }
    return unique;
}

# ---------------------------------------------------------------------------
# Serialization
# ---------------------------------------------------------------------------

"""Serialize a LeadTargetingResult to a dict."""
def serialize_extraction(r: LeadTargetingResult) -> dict[str, Any] {
    item: Any = r;
    icp_list: list[dict[str, Any]] = [];
    for icp in item.ideal_customer_profiles {
        p: Any = icp;
        icp_list.append({
            "segment_name": p.segment_name,
            "description": p.description,
            "company_size": p.company_size,
            "revenue_range": p.revenue_range
        });
    }
    return {
        "product_summary": item.product_summary,
        "business_model_guess": item.business_model_guess,
        "target_industries": item.target_industries,
        "ideal_customer_profiles": icp_list,
        "target_job_titles": item.target_job_titles,
        "keywords": item.keywords,
        "pain_point_keywords": item.pain_point_keywords,
        "google_places_search_terms": item.google_places_search_terms,
        "location_needed": item.location_needed,
        "missing_inputs": item.missing_inputs,
        "notes": item.notes
    };
}

"""Serialize a Business to a dict."""
def serialize_business(b: Business) -> dict[str, Any] {
    item: Any = b;
    return {
        "name": item.name,
        "address": item.address,
        "phone": item.phone,
        "website": item.website,
        "source": item.source,
        "rating": item.rating,
        "search_term": item.search_term
    };
}

"""Serialize a CallRecord to a dict."""
def serialize_call_record(c: CallRecord) -> dict[str, Any] {
    item: Any = c;
    return {
        "business_name": item.business_name,
        "phone": item.phone,
        "vapi_call_id": item.vapi_call_id,
        "status": item.status,
        "error": item.error
    };
}

# ---------------------------------------------------------------------------
# Agent 5 cache helpers
# ---------------------------------------------------------------------------

"""Build a product description string from a SoftwarePrompt for LLM input."""
def build_product_description(sp: SoftwarePrompt) -> str {
    item: Any = sp;
    features: str = json.dumps(item.core_features);
    return (
        f"Software name: {item.software_name}\n"
        f"Problem it solves: {item.problem}\n"
        f"Description: {item.description}\n"
        f"Core features: {features}"
    );
}

"""Find agent5-result.json in CWD or JackHacksproject subdirectory."""
def find_agent5_cache() -> str {
    candidates: list[str] = [
        AGENT5_CACHE_FILENAME,
        os.path.join("JackHacksproject", AGENT5_CACHE_FILENAME)
    ];
    for p in candidates {
        if os.path.exists(p) {
            return p;
        }
    }
    return "";
}

"""Load SoftwarePrompt list from agent5-result.json cache."""
def load_software_prompts_from_cache(cache_path: str) -> list[SoftwarePrompt] {
    f: Any = open(cache_path, "r");
    content: str = f.read();
    f.close();
    data: Any = json.loads(content);
    prompts: list[SoftwarePrompt] = [];
    for entry in data {
        prompts.append(
            SoftwarePrompt(
                category_name=entry.get("category_name", ""),
                problem=entry.get("problem", ""),
                score=entry.get("score", 0),
                software_name=entry.get("software_name", ""),
                description=entry.get("description", ""),
                core_features=entry.get("core_features", []),
                tech_stack=entry.get("tech_stack", ""),
                prompt=entry.get("prompt", "")
            )
        );
    }
    return prompts;
}

# ---------------------------------------------------------------------------
# Main orchestration
# ---------------------------------------------------------------------------

"""Run the full 4-step pipeline for one SoftwarePrompt + location.
   Returns a PipelineResult with extraction, businesses, and call records."""
def run_pipeline_for_product(sp: SoftwarePrompt, search_location: str) -> PipelineResult {
    item: Any = sp;
    product_description: str = build_product_description(sp);

    pipeline: PipelineResult = PipelineResult(
        software_name=item.software_name,
        product_description=product_description,
        search_location=search_location
    );
    p: Any = pipeline;

    # Step 1: LLM extraction
    print(f"  [1/3] LLM extraction for '{item.software_name}'...");
    extraction: LeadTargetingResult = extract_lead_targeting(product_description);
    p.extraction = extraction;
    ex: Any = extraction;
    print(f"        {len(ex.google_places_search_terms)} search terms extracted.");

    # Step 2: Google Places
    all_businesses: list[Business] = [];
    if len(_google_places_key) == 0 {
        print("  [2/3] GOOGLE_PLACES_API_KEY not set — skipping Places.");
    } else {
        print(f"  [2/3] Google Places ({len(ex.google_places_search_terms)} terms)...");
        for term in ex.google_places_search_terms {
            found: list[Business] = search_google_places(term, search_location, _google_places_key);
            print(f"        '{term}' → {len(found)} results");
            for b in found {
                all_businesses.append(b);
            }
        }
    }

    unique: list[Business] = deduplicate_businesses(all_businesses);
    p.businesses = unique;
    p.total_businesses_found = len(unique);
    print(f"        Deduplicated → {len(unique)} unique businesses.");

    # Step 3: VAPI calls
    call_records: list[CallRecord] = [];
    if len(_vapi_key) == 0 or len(_vapi_phone) == 0 or len(_vapi_assistant) == 0 {
        print("  [3/3] VAPI credentials not set — skipping calls.");
    } else {
        print(f"  [3/3] VAPI — initiating calls for {len(unique)} businesses...");
        for biz in unique {
            b: Any = biz;
            if len(b.phone) == 0 {
                continue;
            }
            print(f"        Calling {b.name} at {b.phone}...");
            record: CallRecord = make_vapi_call(
                b.phone, b.name,
                _vapi_key, _vapi_phone, _vapi_assistant
            );
            call_records.append(record);
        }
    }
    p.call_records = call_records;
    p.total_calls_initiated = len(call_records);

    return pipeline;
}

"""Load SoftwarePrompts from Agent 5 cache or run full pipeline, then run lead targeting for each."""
def run_lead_targeting_pipeline(search_location: str) -> list[PipelineResult] {
    prompts: list[SoftwarePrompt] = [];

    cache_path: str = find_agent5_cache();
    if cache_path != "" {
        print(f"Agent12: Found Agent 5 cache at '{cache_path}'.");
        prompts = load_software_prompts_from_cache(cache_path);
        print(f"Agent12: Loaded {len(prompts)} software prompts.");
    }
    if len(prompts) == 0 {
        print("Agent12: No Agent 5 cache — running Agents 1-5...");
        problems: list[ProblemStatement] = run_problem_creation();
        problems_json: str = serialize_problems(problems);
        prompts = generate_software_prompts(problems_json);
        print(f"Agent12: Generated {len(prompts)} software prompts.");
    }

    results: list[PipelineResult] = [];
    for sp in prompts {
        sp_item: Any = sp;
        print(f"\nAgent12: Processing '{sp_item.software_name}'...");
        result: PipelineResult = run_pipeline_for_product(sp, search_location);
        results.append(result);
    }
    return results;
}

# ---------------------------------------------------------------------------
# Walker
# ---------------------------------------------------------------------------

walker LeadTargetingAgent {
    has search_location: str = "Atlanta, GA";

    can run with Root entry {
        print("\n========================================");
        print("Agent 12: Lead Targeting Pipeline");
        print("  Step 1: Claude LLM extraction");
        print("  Step 2: Google Places API");
        print("  Step 3: VAPI outbound calls");
        print("========================================\n");

        results: list[PipelineResult] = run_lead_targeting_pipeline(self.search_location);
        report results;

        total_biz: int = 0;
        total_calls: int = 0;
        for r in results {
            ri: Any = r;
            total_biz += ri.total_businesses_found;
            total_calls += ri.total_calls_initiated;
        }
        print(f"\nAgent12 Done: {len(results)} products | {total_biz} businesses | {total_calls} calls.");
    }
}

# ---------------------------------------------------------------------------
# Entry / test block
# ---------------------------------------------------------------------------

with entry {
    result: Any = root() spawn LeadTargetingAgent();
    pipelines: list[PipelineResult] = result.reports[0];

    output: list[dict[str, Any]] = [];
    for pipeline in pipelines {
        p: Any = pipeline;

        biz_list: list[dict[str, Any]] = [];
        for biz in p.businesses {
            biz_list.append(serialize_business(biz));
        }

        call_list: list[dict[str, Any]] = [];
        for c in p.call_records {
            call_list.append(serialize_call_record(c));
        }

        output.append({
            "software_name": p.software_name,
            "search_location": p.search_location,
            "extraction": serialize_extraction(p.extraction),
            "businesses_found": biz_list,
            "calls_initiated": call_list,
            "summary": {
                "total_businesses": p.total_businesses_found,
                "total_calls": p.total_calls_initiated
            }
        });
    }

    print("\n=== Agent 12 Output: Lead Targeting Pipeline ===");
    print(json.dumps(output, indent=2));
}
