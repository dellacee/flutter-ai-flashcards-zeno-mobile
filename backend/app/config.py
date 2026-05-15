from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Environment-driven config. Reads .env at project root if present."""

    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    app_name: str = "Zeno Backend"
    debug: bool = False
    cors_origins: list[str] = ["*"]  # tighten in Cloud Run prod

    # LLM
    gemini_api_key: str | None = None  # if None, use FakeLlmProvider


settings = Settings()
