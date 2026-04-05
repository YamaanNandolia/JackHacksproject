import os
import csv
import time
import json
import requests
from dotenv import load_dotenv

load_dotenv()

VAPI_API_KEY = os.getenv("VAPI_API_KEY")
VAPI_PHONE_NUMBER_ID = os.getenv("VAPI_PHONE_NUMBER_ID")
VAPI_ASSISTANT_ID = os.getenv("VAPI_ASSISTANT_ID")

BASE_URL = "https://api.vapi.ai"

HEADERS = {
    "Authorization": f"Bearer {VAPI_API_KEY}",
    "Content-Type": "application/json"
}


def load_numbers_from_txt(filepath: str) -> list[dict]:
    """Load phone numbers from a plain text file (one number per line)."""
    numbers = []
    with open(filepath, "r") as f:
        for line in f:
            number = line.strip()
            if number and not number.startswith("#"):
                numbers.append({"phone": number, "name": number})
    return numbers


def load_numbers_from_csv(filepath: str) -> list[dict]:
    """Load phone numbers from a CSV file with 'name' and 'phone' columns, or just phone numbers."""
    numbers = []
    with open(filepath, "r") as f:
        # Read first line to check if it looks like a header
        first_line = f.readline().strip()
        
        # If first line contains only digits and +, it's probably just phone numbers
        if first_line and all(c.isdigit() or c in '+-() ' for c in first_line):
            # No headers, treat as phone numbers only
            numbers.append({
                "phone": first_line,
                "name": first_line
            })
            # Read rest of lines
            for line in f:
                number = line.strip()
                if number:
                    numbers.append({
                        "phone": number,
                        "name": number
                    })
        else:
            # Has headers, use CSV reader
            f.seek(0)  # Go back to beginning
            reader = csv.DictReader(f)
            for row in reader:
                numbers.append({
                    "phone": row.get("phone", "").strip(),
                    "name": row.get("name", "Unknown").strip()
                })
    return numbers


def load_numbers(filepath: str) -> list[dict]:
    """Auto-detect file type and load numbers."""
    if filepath.endswith(".csv"):
        return load_numbers_from_csv(filepath)
    elif filepath.endswith(".txt"):
        return load_numbers_from_txt(filepath)
    else:
        raise ValueError(f"Unsupported file type: {filepath}. Use .txt or .csv")


def make_call(contact: dict, assistant_overrides: dict = None) -> dict:
    """
    Make a single outbound call via Vapi.
    
    contact: dict with 'phone' and optionally 'name'
    assistant_overrides: optional dict to override assistant variables per call
    """
    payload = {
        "phoneNumberId": VAPI_PHONE_NUMBER_ID,
        "assistantId": VAPI_ASSISTANT_ID,
        "customer": {
            "number": contact["phone"],
            "name": contact.get("name", "")
        }
    }

    # Optional: pass dynamic variables to the assistant (e.g., customer name)
    if assistant_overrides:
        payload["assistantOverrides"] = assistant_overrides

    response = requests.post(
        f"{BASE_URL}/call/phone",
        headers=HEADERS,
        json=payload
    )

    if response.status_code in (200, 201):
        data = response.json()
        print(f"[OK]  Called {contact['phone']} ({contact.get('name', '')}) — Call ID: {data.get('id')}")
        return {"status": "success", "call_id": data.get("id"), "contact": contact}
    else:
        print(f"[ERR] Failed to call {contact['phone']} — {response.status_code}: {response.text}")
        return {"status": "failed", "error": response.text, "contact": contact}


def get_call_status(call_id: str) -> dict:
    """Fetch the status of a specific call."""
    response = requests.get(
        f"{BASE_URL}/call/{call_id}",
        headers=HEADERS
    )
    return response.json()


def run_campaign(filepath: str, delay_between_calls: float = 2.0):
    """
    Load contacts from file and call them all.
    
    filepath: path to .txt or .csv file
    delay_between_calls: seconds to wait between calls (avoid rate limits)
    """
    contacts = load_numbers(filepath)
    print(f"Loaded {len(contacts)} contacts from {filepath}\n")

    results = []

    for i, contact in enumerate(contacts):
        print(f"[{i+1}/{len(contacts)}] Calling {contact['phone']}...")

        # Pass the contact name as a variable to the assistant
        overrides = {
            "variableValues": {
                "customerName": contact.get("name", "there")
            }
        }

        result = make_call(contact, assistant_overrides=overrides)
        results.append(result)

        # Delay between calls to avoid hitting rate limits
        if i < len(contacts) - 1:
            time.sleep(delay_between_calls)

    # Save results to JSON
    output_file = "call_results.json"
    with open(output_file, "w") as f:
        json.dump(results, f, indent=2)

    # Print summary
    success = sum(1 for r in results if r["status"] == "success")
    failed = len(results) - success
    print(f"\n--- Campaign Complete ---")
    print(f"Total:   {len(results)}")
    print(f"Success: {success}")
    print(f"Failed:  {failed}")
    print(f"Results saved to {output_file}")

    return results


def check_all_call_statuses(results_file: str = "call_results.json"):
    """Check the final status of all calls from a previous campaign."""
    with open(results_file, "r") as f:
        results = json.load(f)

    for result in results:
        if result["status"] == "success":
            call_id = result["call_id"]
            status = get_call_status(call_id)
            print(f"{result['contact']['phone']} — status: {status.get('status')} | duration: {status.get('duration')}s")


# ─── Entry Point ──────────────────────────────────────────────────────────────

if __name__ == "__main__":
    # Run the calling campaign
    run_campaign("phone_numbers.csv", delay_between_calls=3.0)

    # Optional: wait and then check statuses
    # print("\nChecking call statuses...")
    # time.sleep(60)
    # check_all_call_statuses()
