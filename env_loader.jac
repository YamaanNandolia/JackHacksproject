import os;
import from typing { Any }

"""Load .env entries into the OS environment at runtime."""
def load_dotenv(path: str = ".env") -> bool {
    if not os.path.exists(path) {
        return False;
    }

    f: Any = open(path, "r");
    content: str = f.read();
    f.close();

    for line in content.split("\n") {
        trimmed: str = line.strip();
        if trimmed == "" || trimmed.startswith("#") {
            continue;
        }

        parts: list[str] = trimmed.split("=", 1);
        if len(parts) != 2 {
            continue;
        }

        key: str = parts[0].strip();
        value: str = parts[1].strip();
        if len(key) > 0 {
            os.environ[key] = value;
        }
    }

    return True;
}

"""Normalize model ids so LiteLLM routes Gemini models to the Gemini API, not Vertex."""
def resolve_default_model_name() -> str {
    model_name: str = os.getenv("DEFAULT_MODEL_NAME", "gemini/gemini-2.5-flash");
    if model_name.startswith("gemini") && not model_name.startswith("gemini/") {
        return "gemini/" + model_name;
    }
    return model_name;
}

glob DOTENV_LOADED: bool = load_dotenv();

glob OPENAI_API_KEY: str = os.getenv("OPENAI_API_KEY", "");
glob NEWS_API_KEY: str = os.getenv("NEWS_API_KEY", "");
glob DEFAULT_MODEL_NAME: str = resolve_default_model_name();
