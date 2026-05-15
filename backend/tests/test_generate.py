import pytest
from httpx import ASGITransport, AsyncClient

from app.main import create_app


@pytest.fixture
def app():
    return create_app()


async def test_generate_cards_returns_drafts(app):
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        response = await ac.post(
            "/generate/cards",
            json={
                "text": "Mitochondria is the powerhouse of the cell. ATP is energy currency. Glycolysis breaks down glucose.",
                "count": 6,
                "card_types": ["qa", "cloze", "mcq"],
            },
        )
    assert response.status_code == 200
    body = response.json()
    assert len(body["cards"]) <= 6
    assert len(body["cards"]) >= 1
    assert body["model"] == "fake-v1"
    assert body["source_chars"] > 0
    # each card has a discriminator-respecting shape
    for card in body["cards"]:
        assert card["type"] in {"qa", "cloze", "mcq"}


async def test_generate_cards_rejects_blank_text(app):
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        response = await ac.post(
            "/generate/cards",
            json={"text": "          ", "count": 5},
        )
    # Either 422 from pydantic validator (min_length) or 422 from explicit check.
    assert response.status_code == 422


async def test_generate_cards_respects_count(app):
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        response = await ac.post(
            "/generate/cards",
            json={"text": "Sentence one. Sentence two. Sentence three.", "count": 2, "card_types": ["qa"]},
        )
    assert response.status_code == 200
    assert len(response.json()["cards"]) <= 2
