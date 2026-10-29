from pydantic import BaseModel, ConfigDict, Field


class AnalyzeRequest(BaseModel):
    model_config = ConfigDict(str_strip_whitespace=True)

    job_offer: str = Field(
        min_length=50,
        max_length=20_000,
        description="Texte complet de l'offre d'alternance.",
    )
    cv: str = Field(
        min_length=50,
        max_length=20_000,
        description="Texte complet du CV du candidat.",
    )


class AnalyzeResponse(BaseModel):
    score: int = Field(ge=0, le=100, description="Score de correspondance de 0 à 100.")
    matched_skills: list[str] = Field(description="Compétences de l'offre présentes dans le CV.")
    missing_skills: list[str] = Field(description="Compétences de l'offre absentes du CV.")
    summary: str = Field(description="Court résumé de l'analyse.")
    advice: list[str] = Field(description="Conseils pour améliorer la candidature.")