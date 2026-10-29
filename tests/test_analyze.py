import anthropic
import httpx
import pytest
from types import SimpleNamespace

from tests.conftest import VALID_ANALYSIS, VALID_REQUEST, tool_use_response

# Fausse requête HTTP, nécessaire pour construire les exceptions du SDK anthropic
FAKE_REQUEST = httpx.Request("POST", "https://api.anthropic.com/v1/messages")


def status_error(error_class, status_code: int) -> Exception:
    """Construit une erreur HTTP du SDK anthropic (401, 429...)."""
    response = httpx.Response(status_code, request=FAKE_REQUEST)
    return error_class("Erreur simulée", response=response, body=None)


# --- Cas nominal ---


def test_analyze_returns_llm_analysis(client, use_fake_llm):
    use_fake_llm(response=tool_use_response(VALID_ANALYSIS))

    response = client.post("/analyze", json=VALID_REQUEST)

    assert response.status_code == 200
    assert response.json() == VALID_ANALYSIS


def test_analyze_forces_tool_use_and_sends_both_texts(client, use_fake_llm):
    fake_client = use_fake_llm(response=tool_use_response(VALID_ANALYSIS))

    client.post("/analyze", json=VALID_REQUEST)

    call = fake_client.messages.calls[0]
    assert call["tool_choice"] == {"type": "tool", "name": "submit_analysis"}
    user_content = call["messages"][0]["content"]
    assert VALID_REQUEST["job_offer"] in user_content
    assert VALID_REQUEST["cv"] in user_content


# --- Validation de la requête (422) ---


@pytest.mark.parametrize(
    "payload",
    [
        {"job_offer": "Trop court", "cv": VALID_REQUEST["cv"]},
        {"job_offer": VALID_REQUEST["job_offer"], "cv": "Trop court"},
        {"job_offer": " " * 100, "cv": VALID_REQUEST["cv"]},
        {"job_offer": VALID_REQUEST["job_offer"]},
        {},
    ],
    ids=["offre-courte", "cv-court", "offre-espaces", "cv-manquant", "corps-vide"],
)
def test_analyze_rejects_invalid_request(client, use_fake_llm, payload):
    fake_client = use_fake_llm(response=tool_use_response(VALID_ANALYSIS))

    response = client.post("/analyze", json=payload)

    assert response.status_code == 422
    assert fake_client.messages.calls == []  # le LLM n'a jamais été appelé : pas de coût


# --- Réponses invalides du LLM (502) ---


def test_analyze_rejects_score_out_of_range(client, use_fake_llm):
    use_fake_llm(response=tool_use_response({**VALID_ANALYSIS, "score": 150}))

    response = client.post("/analyze", json=VALID_REQUEST)

    assert response.status_code == 502


def test_analyze_rejects_missing_field(client, use_fake_llm):
    incomplete = {key: value for key, value in VALID_ANALYSIS.items() if key != "summary"}
    use_fake_llm(response=tool_use_response(incomplete))

    response = client.post("/analyze", json=VALID_REQUEST)

    assert response.status_code == 502


def test_analyze_rejects_response_without_tool_call(client, use_fake_llm):
    text_only = SimpleNamespace(content=[SimpleNamespace(type="text", text="Bonjour !")])
    use_fake_llm(response=text_only)

    response = client.post("/analyze", json=VALID_REQUEST)

    assert response.status_code == 502


# --- Erreurs de l'API Claude ---


@pytest.mark.parametrize(
    "error, expected_status",
    [
        (anthropic.APITimeoutError(request=FAKE_REQUEST), 504),
        (anthropic.APIConnectionError(request=FAKE_REQUEST), 503),
        (status_error(anthropic.RateLimitError, 429), 503),
        (status_error(anthropic.InternalServerError, 500), 503),
        (status_error(anthropic.AuthenticationError, 401), 502),
        (status_error(anthropic.BadRequestError, 400), 502),
    ],
    ids=["timeout", "connexion", "rate-limit", "erreur-serveur", "cle-invalide", "credits-epuises"],
)
def test_analyze_maps_claude_errors_to_http_codes(client, use_fake_llm, error, expected_status):
    use_fake_llm(error=error)

    response = client.post("/analyze", json=VALID_REQUEST)

    assert response.status_code == expected_status
    assert "detail" in response.json()


# --- Clé API absente (503) ---


def test_analyze_returns_503_when_api_key_is_missing(client, monkeypatch):
    # Pas de faux LLM ici : on teste le vrai get_analyzer, sans clé
    monkeypatch.delenv("ANTHROPIC_API_KEY", raising=False)

    response = client.post("/analyze", json=VALID_REQUEST)

    assert response.status_code == 503
    assert "clé API" in response.json()["detail"]
