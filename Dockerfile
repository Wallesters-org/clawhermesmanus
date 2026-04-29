# syntax=docker/dockerfile:1.7
FROM python:3.11-slim AS base

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

RUN apt-get update && apt-get install -y --no-install-recommends \
    git curl ripgrep ffmpeg ca-certificates build-essential \
  && rm -rf /var/lib/apt/lists/*

# Install UV (Hermes pattern)
RUN curl -LsSf https://astral.sh/uv/install.sh | sh && \
    mv /root/.local/bin/uv /usr/local/bin/uv

WORKDIR /app
COPY pyproject.toml ./
RUN uv venv /opt/venv --python 3.11
ENV PATH="/opt/venv/bin:$PATH"

FROM base AS runtime
COPY . /app
RUN uv pip install -e ".[all]" || true

EXPOSE 7860
HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
  CMD curl -fsS http://localhost:7860/health || exit 1

ENTRYPOINT ["chm"]
CMD ["serve", "--host", "0.0.0.0", "--port", "7860"]
