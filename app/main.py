from fastapi import FastAPI
from app.schemas import AnalyzeRequest, AnalyzeResponse

app = FastAPI(
    title="Alternance Matcher API",
    description="Compare un CV à une offre d'alternance grâce à un LLM.",
    version="0.1.0",
)


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}

@app.post("/analyze", response_model=AnalyzeResponse)
def analyze(request: AnalyzeRequest) -> AnalyzeResponse:
    # Réponse provisoire : sera remplacée par l'appel au LLM à l'étape 4
    return AnalyzeResponse(
        score=50,
        matched_skills=["Python"],
        missing_skills=["Docker"],
        summary="Réponse de test.",
        advice=["Ajouter un projet Docker au CV."],
    )