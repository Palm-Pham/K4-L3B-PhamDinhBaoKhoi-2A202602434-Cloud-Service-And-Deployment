# Build dependencies in a separate stage so the runtime image stays small.
FROM python:3.11-slim AS builder

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

FROM python:3.11-slim

WORKDIR /app
COPY --from=builder /install /usr/local
COPY app ./app
COPY utils ./utils

RUN useradd --create-home --uid 10001 appuser
USER appuser

ENV PORT=8000
EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
    CMD python -c "import os, urllib.request; urllib.request.urlopen('http://127.0.0.1:' + os.environ.get('PORT', '8000') + '/health', timeout=3).read()" || exit 1

CMD ["sh", "-c", "exec uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8000}"]
