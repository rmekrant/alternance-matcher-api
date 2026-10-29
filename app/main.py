import logging

from fastapi import Depends, FastAPI, Request
from fastapi.responses import JSONResponse

from app.errors import LLMError
from app.llm import LLMAnalyzer, get_analyzer
from app.schemas import AnalyzeRequest, AnalyzeResponse

logging.basicConfig(level=logging.INFO)

app = FastAPI(
    title="Alternance Matcher API",
    description="Compare un CV à une offre d'alternance grâce à un LLM.",
    version="0.1.0",
)


@app.exception_handler(LLMError)
def handle_llm_error(request: Request, exc: LLMError) -> JSONResponse:
    # Transforme toutes nos erreurs LLM en réponse JSON avec le bon code HTTP.
    # Le détail technique reste dans les logs du serveur, pas dans la réponse.
    return JSONResponse(status_code=exc.status_code, content={"detail": exc.message})


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}


@app.post(
    "/analyze",
    response_model=AnalyzeResponse,
    responses={
        502: {"description": "Erreur ou réponse invalide du LLM"},
        503: {"description": "Service non configuré ou temporairement indisponible"},
        504: {"description": "Le LLM n'a pas répondu à temps"},
    },
)
def analyze(
    request: AnalyzeRequest,
    analyzer: LLMAnalyzer = Depends(get_analyzer),
) -> AnalyzeResponse:
    return analyzer.analyze(request)
