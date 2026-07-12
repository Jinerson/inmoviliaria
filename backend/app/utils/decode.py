import unicodedata


def normalize_text(text: str) -> str:
    text = unicodedata.normalize("NFKD",  text if text else "")
    text = text.encode("ascii", "ignore").decode("ascii")
    return text.lower()