# Image de base : Python 3.11 en version allégée (même version qu'en local et en CI)
FROM python:3.11-slim

# Pas de fichiers .pyc, et logs affichés immédiatement
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

# On copie d'abord requirements.txt seul : tant qu'il ne change pas,
# Docker réutilise cette couche en cache et ne réinstalle pas tout
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Puis le code de l'application
COPY app/ ./app/

# Sécurité : l'application ne tourne pas en root
RUN useradd --create-home appuser
USER appuser

EXPOSE 8000

# Docker vérifie régulièrement que l'API répond sur /health
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')" || exit 1

# 0.0.0.0 : écoute sur toutes les interfaces, sinon l'API est injoignable depuis l'extérieur du conteneur
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
