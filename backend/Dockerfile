FROM python:3.12-slim AS base

ENV PYTHONUNBUFFERED=1 PIP_NO_CACHE_DIR=1
WORKDIR /app

# uv-style install: copy lock + pyproject, install deps
COPY pyproject.toml uv.lock* ./
RUN pip install --upgrade pip && pip install uv && uv sync --frozen --no-dev || uv sync --no-dev

COPY app ./app

EXPOSE 8080
ENV PORT=8080
CMD ["sh", "-c", "uv run uvicorn app.main:app --host 0.0.0.0 --port $PORT"]
