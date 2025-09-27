FROM ubuntu:24.04

COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

WORKDIR /app

RUN apt-get update && apt-get upgrade -y && apt-get install -y --no-install-recommends build-essential git && rm -rf /var/lib/apt/lists/*

RUN uv python install 3.12

# Copy dependency files first for better caching
COPY pyproject.toml uv.lock ./

# Install dependencies
RUN uv sync --frozen

# Copy application source code
COPY main.py dumbkv.py logging.yaml ./

# Set up default environment variables
ENV DATABASE_LOCATION=dumbkv.db
ENV DATABASE_TYPE=sqlite

# Expose port 8000
EXPOSE 8000

# Run the application
CMD ["uv", "run", "uvicorn", "main:api", "--host", "0.0.0.0", "--port", "8000", "--log-config", "logging.yaml"]
