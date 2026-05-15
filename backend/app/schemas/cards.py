from enum import Enum
from typing import Annotated, Literal, Union

from pydantic import BaseModel, Field


class CardType(str, Enum):
    qa = "qa"
    cloze = "cloze"
    mcq = "mcq"


class QaDraft(BaseModel):
    type: Literal["qa"] = "qa"
    front: str = Field(min_length=1, max_length=500)
    back: str = Field(min_length=1, max_length=2000)


class ClozeDraft(BaseModel):
    type: Literal["cloze"] = "cloze"
    text: str = Field(min_length=10, max_length=2000)


class McqDraft(BaseModel):
    type: Literal["mcq"] = "mcq"
    question: str = Field(min_length=1, max_length=500)
    options: list[str] = Field(min_length=2, max_length=6)
    correct_index: int = Field(ge=0, le=5)


CardDraft = Annotated[Union[QaDraft, ClozeDraft, McqDraft], Field(discriminator="type")]


class GenerateCardsRequest(BaseModel):
    """Input text the LLM should turn into flashcards."""

    text: str = Field(min_length=10, max_length=50000)
    count: int = Field(default=10, ge=1, le=30)
    card_types: list[CardType] = Field(default_factory=lambda: list(CardType))
    language: Literal["vi", "en", "auto"] = "auto"


class GenerateCardsResponse(BaseModel):
    cards: list[CardDraft]
    source_chars: int
    model: str  # e.g. "fake-v1" or "gemini-2.0-flash"
