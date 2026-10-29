from fastapi import Depends, FastAPI

from app.llm import LLMAnalyzer, get_analyzer
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
def analyze(
    request: AnalyzeRequest,
    analyzer: LLMAnalyzer = Depends(get_analyzer),
) -> AnalyzeResponse:
    return analyzer.analyze(request)
