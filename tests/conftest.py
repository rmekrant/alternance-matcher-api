from types import SimpleNamespace

import pytest
from fastapi.testclient import TestClient

from app.llm import LLMAnalyzer, get_analyzer
from app.main import app

VALID_REQUEST = {
    "job_offer": "Alternance développeur backend Python. Compétences : Python, FastAPI, SQL, Docker, Git.",
    "cv": "Étudiant ingénieur à l'EFREI. Projets en Python et SQL, utilisation de Git au quotidien.",
}

VALID_ANALYSIS = {
    "score": 65,
    "matched_skills": ["Python", "SQL", "Git"],
    "missing_skills": ["FastAPI", "Docker"],
    "summary": "Bon socle Python et SQL, mais pas d'expérience FastAPI ni Docker.",
    "advice": ["Ajouter un projet FastAPI au CV.", "Conteneuriser un projet avec Docker."],
}


class FakeMessages:
    """Imite client.messages du SDK anthropic, sans aucun appel réseau."""

    def __init__(self, response=None, error: Exception | None = None) -> None:
        self.response = response
        self.error = error
        self.calls: list[dict] = []  # garde les arguments reçus pour pouvoir les vérifier

    def create(self, **kwargs):
        self.calls.append(kwargs)
        if self.error is not None:
            raise self.error
        return self.response


def tool_use_response(data: dict) -> SimpleNamespace:
    """Construit une fausse réponse Claude contenant un appel à l'outil."""
    block = SimpleNamespace(type="tool_use", name="submit_analysis", input=data)
    return SimpleNamespace(content=[block])


def make_fake_client(response=None, error: Exception | None = None) -> SimpleNamespace:
    return SimpleNamespace(messages=FakeMessages(response=response, error=error))


@pytest.fixture
def client():
    """Client de test de l'API. Nettoie les remplacements de dépendances après chaque test."""
    yield TestClient(app)
    app.dependency_overrides.clear()


@pytest.fixture
def use_fake_llm():
    """Remplace le vrai LLM par un faux grâce à dependency_overrides."""

    def _use(response=None, error: Exception | None = None) -> SimpleNamespace:
        fake_client = make_fake_client(response=response, error=error)
        app.dependency_overrides[get_analyzer] = lambda: LLMAnalyzer(fake_client)
        return fake_client

    return _use
