import pytest

from app.schemas.cards import GenerateCardsRequest
from app.services.llm import FakeLlmProvider


@pytest.fixture
def provider():
    return FakeLlmProvider()


async def test_fake_provider_produces_requested_count(provider):
    request = GenerateCardsRequest(text="A. B. C. D. E.", count=3)
    response = await provider.generate_cards(request)
    assert len(response.cards) == 3


async def test_fake_provider_is_deterministic(provider):
    request = GenerateCardsRequest(text="Photosynthesis converts light into chemical energy.", count=3)
    r1 = await provider.generate_cards(request)
    r2 = await provider.generate_cards(request)
    assert [c.model_dump() for c in r1.cards] == [c.model_dump() for c in r2.cards]
