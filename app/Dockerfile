FROM python:3.12-slim

WORKDIR /app

# Pick up fixed Debian packages (Trivy HIGH/CRITICAL OS gate).
RUN apt-get update \
  && apt-get upgrade -y \
  && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir "--only-binary=:all:" -r requirements.txt

# Explicit file copies only (avoid recursive COPY .).
COPY config.py auth.py db.py schema.py main.py telemetry.py logging_setup.py audit.py bootstrap_auth.py seed.py ./

RUN useradd --create-home --uid 10001 appuser \
  && chown -R appuser:appuser /app
USER appuser

EXPOSE 8000
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
