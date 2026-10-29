class LLMError(Exception):
    """Erreur de base liée au LLM. Chaque sous-classe porte son code HTTP."""

    status_code = 502
    message = "Erreur lors de l'appel au LLM."

    def __init__(self, message: str | None = None) -> None:
        super().__init__(message or self.message)
        self.message = message or self.message


class LLMConfigError(LLMError):
    """La clé API est absente : le serveur est mal configuré."""

    status_code = 503
    message = "Le service d'analyse n'est pas configuré (clé API absente)."


class LLMUnavailableError(LLMError):
    """L'API Claude est saturée ou limite nos requêtes : réessayer plus tard."""

    status_code = 503
    message = "Le service d'analyse est temporairement indisponible. Réessayez plus tard."


class LLMTimeoutError(LLMError):
    """L'API Claude n'a pas répondu à temps."""

    status_code = 504
    message = "Le service d'analyse n'a pas répondu à temps."


class LLMUpstreamError(LLMError):
    """L'API Claude a renvoyé une erreur (clé invalide, crédits épuisés, etc.)."""

    status_code = 502
    message = "Le service d'analyse a renvoyé une erreur."


class LLMInvalidResponseError(LLMError):
    """Le LLM a répondu, mais pas dans le format attendu."""

    status_code = 502
    message = "Le service d'analyse a renvoyé une réponse invalide."
