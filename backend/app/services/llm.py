import random
from abc import ABC, abstractmethod

from app.schemas.cards import (
    CardDraft,
    CardType,
    ClozeDraft,
    GenerateCardsRequest,
    GenerateCardsResponse,
    McqDraft,
    QaDraft,
)


class LlmProvider(ABC):
    """Interface every LLM backend must implement. Lets us swap real-Gemini in later."""

    name: str

    @abstractmethod
    async def generate_cards(self, request: GenerateCardsRequest) -> GenerateCardsResponse: ...


class FakeLlmProvider(LlmProvider):
    """Deterministic-but-varied fake. Generates plausible cards from input text by
    splitting into sentences and templating per type. Used until a real key is
    plugged in."""

    name = "fake-v1"

    async def generate_cards(self, request: GenerateCardsRequest) -> GenerateCardsResponse:
        sentences = [s.strip() for s in request.text.replace("\n", " ").split(".") if len(s.strip()) > 5]
        if not sentences:
            sentences = ["Sample sentence about a topic", "Another illustrative fact"]

        rng = random.Random(hash(request.text) & 0xFFFFFFFF)
        types = request.card_types or list(CardType)

        cards: list[CardDraft] = []
        for i in range(min(request.count, len(sentences) * 3)):
            sentence = sentences[i % len(sentences)]
            t = types[i % len(types)]
            if t == CardType.qa:
                cards.append(QaDraft(
                    front=f"Q: {sentence[:80]}?",
                    back=f"A: {sentence}",
                ))
            elif t == CardType.cloze:
                words = sentence.split()
                if len(words) >= 3:
                    target_idx = rng.randrange(len(words))
                    target = words[target_idx]
                    words[target_idx] = "{{c1::" + target + "}}"
                    cards.append(ClozeDraft(text=" ".join(words)))
                else:
                    cards.append(ClozeDraft(text=f"{sentence} {{{{c1::sample}}}}"))
            elif t == CardType.mcq:
                cards.append(McqDraft(
                    question=f"Which best describes: {sentence[:80]}?",
                    options=[
                        f"Option A about {sentence[:40]}",
                        "Option B (distractor)",
                        "Option C (distractor)",
                        "Option D (distractor)",
                    ],
                    correct_index=0,
                ))
        return GenerateCardsResponse(
            cards=cards[: request.count],
            source_chars=len(request.text),
            model=self.name,
        )


def get_llm_provider() -> LlmProvider:
    """Factory. Real Gemini provider plugged in here when GEMINI_API_KEY is set."""
    from app.config import settings  # noqa: PLC0415  (deferred import avoids circular deps)

    # if settings.gemini_api_key:
    #     return GeminiLlmProvider(api_key=settings.gemini_api_key)
    _ = settings  # referenced to keep the import (will be used once real provider exists)
    return FakeLlmProvider()
