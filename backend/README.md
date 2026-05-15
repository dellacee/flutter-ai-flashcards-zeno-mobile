# Zeno Backend

FastAPI service for the AI generate-cards pipeline. Pluggable LLM provider — defaults to a deterministic fake that produces plausible-looking cards from any input. Drop in `GeminiLlmProvider` (TODO) by setting `GEMINI_API_KEY` and uncommenting the wiring in `app/services/llm.py:get_llm_provider`.

## Run locally

```bash
cd backend
uv sync
uv run uvicorn app.main:app --reload --port 8000
```

Visit http://localhost:8000/docs for the OpenAPI explorer.

## Test

```bash
uv run pytest
```

## Deploy to Cloud Run

```bash
gcloud run deploy zeno-backend \
  --source . \
  --region asia-southeast1 \
  --allow-unauthenticated  # tighten with Firebase Auth ID-token verification later
```

Set `GEMINI_API_KEY` via Cloud Run env or Secret Manager.

## Endpoints

- `GET /healthz` → `{"status": "ok"}`
- `POST /generate/cards` → produces flashcards from text. See `app/schemas/cards.py`.
