"""Agent 1: Lookout Agent - Fetches and identifies current market trends from news."""

import from byllm.lib { Model }
import from typing { Any }
import requests;
import json;
import from env_loader { OPENAI_API_KEY, NEWS_API_KEY, DEFAULT_MODEL_NAME }

glob llm = Model(model_name=DEFAULT_MODEL_NAME, api_key=OPENAI_API_KEY);

"""Represents a single article/trend with title and description."""
obj Trend {
    has title: str = "";
    has description: str = "";
}

"""Fallback trends used when live news is unavailable."""
glob FALLBACK_TRENDS: list[Trend] = [
    Trend(
        title="AI copilots expand into regulated enterprise workflows",
        description="Businesses are adopting AI assistants for finance, healthcare, and legal operations while struggling with auditability and human review."
    ),
    Trend(
        title="Utilities modernize grids to handle EVs and distributed energy",
        description="Power operators need better software to forecast load, manage outages, and coordinate solar, batteries, and electric vehicles."
    ),
    Trend(
        title="Cyberattacks increasingly target midsize businesses",
        description="Smaller organizations face rising ransomware and phishing risk but lack dedicated security teams and affordable tooling."
    ),
    Trend(
        title="Hospitals push operational automation to offset staffing shortages",
        description="Healthcare providers are looking for workflow tools that reduce admin burden, speed scheduling, and improve patient communication."
    ),
    Trend(
        title="Supply chains shift toward real-time visibility tools",
        description="Manufacturers and distributors want earlier warning signals for delays, inventory risk, and supplier disruptions."
    ),
    Trend(
        title="Climate reporting rules drive demand for emissions tracking",
        description="Companies need practical systems to collect sustainability data, validate it, and produce stakeholder-ready reports."
    )
];

"""Fetch JSON from the News API, returning null if the request fails."""
def fetch_news_json(url: str, params: dict[str, str]) -> Any {
    try {
        resp: Any = requests.get(url, params=params, timeout=10);
        resp.raise_for_status();
        return resp.json();
    } except Exception as e {
        print(f"LookoutAgent: News request failed for {url}: {e}");
        return None;
    }
}

"""Fetch top headlines from News API for a given category."""
def fetch_top_headlines(
    category: str = "technology", country: str = "us", page_size: int = 20
) -> list[dict[str, str]] {
    url: str = "https://newsapi.org/v2/top-headlines";
    params: dict[str, str] = {
        "apiKey": NEWS_API_KEY,
        "category": category,
        "country": country,
        "pageSize": str(page_size)
    };
    data: Any = fetch_news_json(url, params);
    articles: list[dict[str, str]] = [];
    if data != None && data.get("status") == "ok" {
        for article in data.get("articles", []) {
            articles.append(
                {
                    "title": article.get("title", ""),
                    "description": article.get("description", ""),
                    "source": article.get("source", {}).get("name", ""),
                    "publishedAt": article.get("publishedAt", ""),
                    "url": article.get("url", "")
                }
            );
        }
    }
    print(f"Fetched articles from {category}");
    return articles;
}

"""Search for news articles about a specific topic or keyword."""
def search_news(query: str, page_size: int = 20) -> list[dict[str, str]] {
    url: str = "https://newsapi.org/v2/everything";
    params: dict[str, str] = {
        "apiKey": NEWS_API_KEY,
        "q": query,
        "pageSize": str(page_size),
        "sortBy": "publishedAt",
        "language": "en"
    };
    data: Any = fetch_news_json(url, params);
    articles: list[dict[str, str]] = [];
    if data != None && data.get("status") == "ok" {
        for article in data.get("articles", []) {
            articles.append(
                {
                    "title": article.get("title", ""),
                    "description": article.get("description", ""),
                    "source": article.get("source", {}).get("name", ""),
                    "publishedAt": article.get("publishedAt", ""),
                    "url": article.get("url", "")
                }
            );
        }
    }
    return articles;
}

"""Extract top 10 articles from multiple categories."""
def get_top_trends() -> list[Trend] {
    trends: list[Trend] = [];
    categories: list[str] = ["technology", "business", "science"];

    for category in categories {
        articles: list[dict[str, str]] = fetch_top_headlines(
            category=category, page_size=5
        );
        for article in articles {
            if len(trends) < 10 {
                trends.append(
                    Trend(
                        title=article.get("title", ""),
                        description=article.get("description", "")
                    )
                );
            }
        }
    }
    if len(trends) == 0 {
        print("LookoutAgent: Using built-in fallback trends because no live news was fetched.");
        return FALLBACK_TRENDS;
    }
    return trends;
}
