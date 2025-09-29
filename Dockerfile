# Dockerfile for DumbKV - A simple key-value server
# Uses Ubuntu 24.04 as base image with uv for Python package management

# Start with Ubuntu 24.04 LTS for stability and security updates (latest supported by GHA)
FROM ubuntu:24.04

# Copy uv package manager from official image for efficient Python dependency management
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

# Set working directory for the application
WORKDIR /app

# Install system dependencies and clean up in single layer to reduce image size
# - build-essential: Required for compiling Python packages with C extensions
# - git: Required by some Python packages during installation
RUN apt-get update && apt-get upgrade -y && apt-get install -y --no-install-recommends build-essential git && rm -rf /var/lib/apt/lists/*

# Install Python 3.12 as required by the project
RUN uv python install 3.12

# Copy dependency files first for better Docker layer caching
# Changes to source code won't invalidate the dependency installation layer
COPY pyproject.toml uv.lock ./

# Install Python dependencies using frozen lockfile for reproducible builds
# --frozen ensures exact versions from uv.lock are used
RUN uv sync --frozen

# Copy application source code after dependencies for optimal caching
# This layer only rebuilds when source code changes
COPY main.py dumbkv.py logging.yaml ./
COPY ui/ ./ui/

# Set up default environment variables for SQLite backend
# Can be overridden at runtime for different database configurations
ENV DATABASE_LOCATION=dumbkv.db
ENV DATABASE_TYPE=sqlite

# Expose port 8000 for the FastAPI/uvicorn server
EXPOSE 8000

# Run the DumbKV application using uvicorn ASGI server
# - Binds to all interfaces (0.0.0.0) for container accessibility
# - Uses logging configuration from logging.yaml
CMD ["uv", "run", "uvicorn", "main:api", "--host", "0.0.0.0", "--port", "8000", "--log-config", "logging.yaml"]
