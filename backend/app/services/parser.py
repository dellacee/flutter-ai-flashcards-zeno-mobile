def chunk_text(text: str, max_chars: int = 4000) -> list[str]:
    """Split text into chunks no larger than max_chars on paragraph boundaries."""
    paragraphs = [p.strip() for p in text.split("\n\n") if p.strip()]
    chunks: list[str] = []
    current = ""
    for p in paragraphs:
        if not current:
            current = p
        elif len(current) + 2 + len(p) <= max_chars:
            current = f"{current}\n\n{p}"
        else:
            chunks.append(current)
            current = p
    if current:
        chunks.append(current)
    return chunks
