from fastapi import FastAPI

app = FastAPI(
    title="Alternance Matcher API",
    description="Compare un CV à une offre d'alternance grâce à un LLM.",
    version="0.1.0",
)


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}