from fastapi import APIRouter, Depends, HTTPException

from app.schemas.cards import GenerateCardsRequest, GenerateCardsResponse
from app.services.llm import LlmProvider, get_llm_provider

router = APIRouter(prefix="/generate")


@router.post("/cards", response_model=GenerateCardsResponse)
async def generate_cards(
    request: GenerateCardsRequest,
    provider: LlmProvider = Depends(get_llm_provider),
) -> GenerateCardsResponse:
    if not request.text.strip():
        raise HTTPException(status_code=422, detail="text must not be blank")
    return await provider.generate_cards(request)
