#!/usr/bin/env bash

set -e

read -p "Enter project name: " PROJECT_NAME

# Convert project name to lowercase and snake_case for venv
VENV_NAME="venv_$(echo "$PROJECT_NAME" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/_/g')"

# Create project outside the script folder
PROJECT_ROOT="$(dirname "$PWD")/$PROJECT_NAME"

echo "Should the SQLAlchemy setup be async? (y/n): "
read ASYNC_CHOICE

echo "Include authentication? (y/n): "
read AUTH_CHOICE

echo "Include authorization? (y/n): "
read AUTHZ_CHOICE

echo "Include ratelimiting? (y/n): "
read RATELIMIT_CHOICE

echo "Include caching? (y/n): "
read CACHE_CHOICE

echo "Add pre-commit hooks for code quality? (y/n): "
read PRECOMMIT_CHOICE

echo "Add CI/CD pipeline (GitHub Actions)? (y/n): "
read CICD_CHOICE

echo "Add Makefile for common tasks? (y/n): "
read MAKEFILE_CHOICE

echo "Add Docker healthcheck? (y/n): "
read HEALTHCHECK_CHOICE

echo "Choose license (MIT/Apache-2.0/None): "
read LICENSE_CHOICE

# Create base structure
mkdir -p "$PROJECT_ROOT"/app/api/v1/dependencies
mkdir -p "$PROJECT_ROOT"/app/api/v1/routes
mkdir -p "$PROJECT_ROOT"/app/core
mkdir -p "$PROJECT_ROOT"/app/domain/entities
mkdir -p "$PROJECT_ROOT"/app/domain/repositories
mkdir -p "$PROJECT_ROOT"/app/infrastructure/database/schemas
mkdir -p "$PROJECT_ROOT"/app/infrastructure/database/models
mkdir -p "$PROJECT_ROOT"/app/infrastructure/database/repositories
mkdir -p "$PROJECT_ROOT"/app/services
mkdir -p "$PROJECT_ROOT"/tests

cd "$PROJECT_ROOT"

# Set local Python version with pyenv
echo "3.11.0" > .python-version
pyenv local 3.11.0

# Create virtual environment using pyenv's python
pyenv exec python -m venv "$VENV_NAME"
source "$VENV_NAME/bin/activate"

# Requirements (async or sync)
if [[ "$ASYNC_CHOICE" =~ ^[Yy]$ ]]; then
    SQLALCHEMY_DEPS="sqlalchemy
asyncpg"
    DB_URL="postgresql+asyncpg://\${POSTGRES_USER}:\${POSTGRES_PASSWORD}@\${POSTGRES_HOST}:\${POSTGRES_PORT}/\${POSTGRES_DB}"
    SESSION_IMPORT="from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine, async_sessionmaker"
    SESSION_CODE="
DATABASE_URL = os.getenv('DATABASE_URL')

engine = create_async_engine(DATABASE_URL, echo=True)
async_session = async_sessionmaker(engine, expire_on_commit=False)

async def get_db():
    async with async_session() as session:
        yield session
"
    CREATE_TABLES_CODE="
import asyncio
from app.infrastructure.database.models.example import Example
async def create_tables():
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
if __name__ == '__main__':
    asyncio.run(create_tables())
"
else
    SQLALCHEMY_DEPS="sqlalchemy
psycopg2-binary"
    DB_URL="postgresql://\${POSTGRES_USER}:\${POSTGRES_PASSWORD}@\${POSTGRES_HOST}:\${POSTGRES_PORT}/\${POSTGRES_DB}"
    SESSION_IMPORT="from sqlalchemy.orm import sessionmaker"
    SESSION_CODE="
DATABASE_URL = os.getenv('DATABASE_URL')

engine = create_engine(DATABASE_URL, echo=True)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
"
    CREATE_TABLES_CODE="
from app.infrastructure.database.models.example import Example
def create_tables():
    Base.metadata.create_all(bind=engine)
if __name__ == '__main__':
    create_tables()
"
fi

cat > requirements.txt <<EOF
fastapi
uvicorn[standard]
$SQLALCHEMY_DEPS
python-dotenv
alembic
pytest
EOF

# .env and .env-example
cat > .env <<EOF
POSTGRES_USER=
POSTGRES_PASSWORD=
POSTGRES_DB=
POSTGRES_HOST=
POSTGRES_PORT=5432
DATABASE_URL=
EOF

cat > .env-example <<EOF
POSTGRES_USER=your_db_user
POSTGRES_PASSWORD=your_db_password
POSTGRES_DB=your_db_name
POSTGRES_HOST=your_db_host
POSTGRES_PORT=5432
DATABASE_URL=your_database_url
EOF

# .gitignore (comprehensive)
cat > .gitignore <<EOF
.env
$VENV_NAME/
__pycache__/
.python-version
*.pyc
*.pyo
*.pyd
.Python
venv/
env/
ENV/
.venv/
.env.local
.env.*.local

# Environment Variables
.env
.env.development
.env.production
.env.test

# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
wheels/
pip-wheel-metadata/
share/python-wheels/
*.egg-info/
.installed.cfg
*.egg
MANIFEST

# pytest
.pytest_cache/
.coverage
.coverage.*
coverage.xml
htmlcov/
.tox/
.hypothesis/

# IDE & Editor Settings
.vscode/
.idea/
*.swp
*.swo
*~
.DS_Store
.env.local
.python-version
*.sublime-project
*.sublime-workspace

# Database
*.db
*.sqlite
*.sqlite3
data/
*.pgdump

# Logs
*.log
logs/
*.out

# OS
.DS_Store
Thumbs.db
.AppleDouble
.LSOverride
*.swp

# Docker
.dockerignore
docker-compose.override.yml

# Storage & Temporary Files
temp/
tmp/
*.jpg
*.jpeg
*.png
test-output.*

# Build & Distribution
dist/
build/
*.egg-info/

# Project Specific
migrations/
alembic/

# Mac
.AppleDouble
.LSOverride
._*

# Windows
Thumbs.db
ehthumbs.db
Desktop.ini

# IDE Specific
.vscode/settings.json
.vscode/launch.json
.idea/
*.iml
*.iws
*.ipr
.classpath
.project
.c9/
*.launch
.settings/

# Package Manager Lock Files (optional - uncomment if needed)
# poetry.lock
# Pipfile.lock

# Node (if using frontend tools)
node_modules/
npm-debug.log
yarn-error.log

# Keep but exclude sensitive files
!.env-example
!.env.sample

# Temporary files
*.tmp
*.temp
~$*

# IDE backup files
*.bak
*.backup
*.orig

# Misc
.cache/
.mypy_cache/
.pylint.d/
.ruff_cache/

# Docker volumes (if not in docker-compose)
postgres_data/
mongo_data/
redis_data/

# Testing artifacts
.test_results/
test_results/
test-results.xml

# Development
.vscode/extensions.json
.eslintcache
.stylelintcache
EOF

# README.md (comprehensive)
cat > README.md <<EOF
# $PROJECT_NAME

This project was scaffolded using fastapi_scaffold_script.sh.

## Features

- Async or sync SQLAlchemy support
- Authentication, authorization, ratelimiting, and caching folders (if selected)
- Pre-commit hooks for code quality (if selected)
- CI/CD pipeline with GitHub Actions (if selected)
- Makefile for common tasks (if selected)
- Docker and Docker Compose support
- Alembic migrations
- Environment variable management with .env and .env-example
- Example FastAPI app, models, schemas, and repositories
- Comprehensive .gitignore

## Prerequisites

- Python 3.11
- [pyenv](https://github.com/pyenv/pyenv) (recommended)
- Docker & Docker Compose (optional, for containerization)
- Git

## Installation & Setup

### 1. Clone the repository

\`\`\`bash
git clone <your-repo-url>
cd $PROJECT_NAME
\`\`\`

### 2. Set up virtual environment

#### Linux/Mac

\`\`\`bash
python3 -m venv $VENV_NAME
source $VENV_NAME/bin/activate
\`\`\`

#### Windows

\`\`\`powershell
python -m venv $VENV_NAME
$VENV_NAME\\Scripts\\activate
\`\`\`

#### Using pyenv

\`\`\`bash
pyenv install 3.11.0
pyenv local 3.11.0
pyenv exec python -m venv $VENV_NAME
source $VENV_NAME/bin/activate
\`\`\`

### 3. Install dependencies

\`\`\`bash
pip install -r requirements.txt
\`\`\`

### 4. Set up environment variables

- Copy .env-example to .env and fill in your values.

\`\`\`bash
cp .env-example .env
\`\`\`

### 5. Run locally

\`\`\`bash
uvicorn app.main:app --reload
\`\`\`

### 6. Run with Docker

\`\`\`bash
docker-compose up --build
\`\`\`

## Accessing the Application

- Local: [http://localhost:8000](http://localhost:8000)
- Swagger UI: [http://localhost:8000/docs](http://localhost:8000/docs)
- Redoc: [http://localhost:8000/redoc](http://localhost:8000/redoc)

### Example Requests

#### Curl

\`\`\`bash
curl http://localhost:8000/api/v1/health
\`\`\`

#### Postman

- Import the endpoint GET /api/v1/health in Postman.

#### Browser

- Visit [http://localhost:8000/api/v1/health](http://localhost:8000/api/v1/health)

## Project Structure

\`\`\`
.
├── app/
│   ├── api/
│   │   └── v1/
│   │       ├── dependencies/
│   │       ├── routes/
│   │       │   └── endpoints.py
│   │       └── routes.py
│   ├── authentication/
│   ├── authorization/
│   ├── caching/
│   ├── core/
│   │   ├── constants.py
│   │   ├── database.py
│   │   ├── logging.py
│   │   ├── settings.py
│   │   └── __init__.py
│   ├── domain/
│   │   ├── entities/
│   │   │   └── __init__.py
│   │   └── repositories/
│   │       ├── __init__.py
│   │       └── base.py
│   ├── infrastructure/
│   │   └── database/
│   │       ├── __init__.py
│   │       ├── create_tables.py
│   │       ├── models/
│   │       │   ├── __init__.py
│   │       │   └── example.py
│   │       ├── repositories/
│   │       │   ├── __init__.py
│   │       │   └── example_repository.py
│   │       ├── schemas/
│   │       │   ├── __init__.py
│   │       │   └── example.py
│   │       └── session.py
│   ├── ratelimiting/
│   ├── services/
│   │   └── __init__.py
│   └── main.py
├── tests/
│   └── test_health.py
├── .env
├── .env-example
├── .gitignore
├── .python-version
├── Dockerfile
├── docker-compose.yml
├── requirements.txt
├── README.md
\`\`\`

## Testing Endpoints

\`\`\`bash
pytest
\`\`\`

## Pushing to GitHub

\`\`\`bash
git init
git add .
git commit -m "Initial commit"
git remote add origin <your-repo-url>
git push -u origin main
\`\`\`

---

Happy coding!
EOF

# Docker Compose
cat > docker-compose.yml <<EOF
version: "3.9"
services:
  db:
    image: postgres:15
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: ${PROJECT_NAME}_db
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
  web:
    build: .
    command: uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
    volumes:
      - ./app:/app/app
    ports:
      - "8000:8000"
    depends_on:
      - db
    env_file:
      - .env
volumes:
  postgres_data:
EOF

# Ensure Dockerfile exists for Docker Compose
if [[ ! -f Dockerfile ]]; then
    cat > Dockerfile <<EOF
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY ./app ./app

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
EOF
fi

# Alembic init
alembic init alembic
sed -i "s|^sqlalchemy.url =.*|sqlalchemy.url = $DB_URL|" alembic.ini

# Example FastAPI app, models, schemas, repositories, and test
cat > app/core/constants.py <<EOF
PROJECT_NAME = "$PROJECT_NAME"
API_PREFIX = "/api/v1"
EOF

cat > app/core/database.py <<EOF
import os
from dotenv import load_dotenv
load_dotenv()
from app.core.settings import settings

DATABASE_URL = settings.DATABASE_URL
EOF

cat > app/core/logging.py <<EOF
import logging
import sys

def setup_logging():
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
        handlers=[
            logging.StreamHandler(sys.stdout)
        ]
    )
EOF

cat > app/core/settings.py <<EOF
from pydantic import BaseSettings

class Settings(BaseSettings):
    POSTGRES_USER: str
    POSTGRES_PASSWORD: str
    POSTGRES_DB: str
    POSTGRES_HOST: str
    POSTGRES_PORT: int
    DATABASE_URL: str

    class Config:
        env_file = ".env"

settings = Settings()
EOF

touch app/core/__init__.py

cat > app/main.py <<EOF
from fastapi import FastAPI
from app.api.v1.routes import router as api_router
from app.core.logging import setup_logging
import logging

setup_logging()
logger = logging.getLogger(__name__)

app = FastAPI(title="$PROJECT_NAME")

@app.on_event("startup")
async def startup_event():
    logger.info("Application startup")

@app.on_event("shutdown")
async def shutdown_event():
    logger.info("Application shutdown")

app.include_router(api_router, prefix="/api/v1")
EOF

cat > app/api/v1/routes.py <<EOF
from fastapi import APIRouter

router = APIRouter()

@router.get("/health")
def health_check():
    return {"status": "ok"}
EOF

touch app/api/v1/routes/endpoints.py
touch app/api/v1/dependencies/__init__.py
touch app/api/v1/dependencies/dependencies.py

cat > app/infrastructure/database/schemas/example.py <<EOF
from pydantic import BaseModel

class ExampleSchema(BaseModel):
    id: int
    name: str

    class Config:
        orm_mode = True
EOF

touch app/infrastructure/database/schemas/__init__.py

cat > app/infrastructure/database/models/example.py <<EOF
from sqlalchemy import Column, Integer, String
from app.domain.repositories.base import Base

class Example(Base):
    __tablename__ = "examples"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, index=True)
EOF

touch app/infrastructure/database/models/__init__.py

cat > app/infrastructure/database/repositories/example_repository.py <<EOF
# Example repository implementation for Example model
EOF

touch app/infrastructure/database/repositories/__init__.py
cat > app/domain/repositories/base.py <<EOF
from sqlalchemy.orm import declarative_base

Base = declarative_base()
EOF

touch app/domain/repositories/__init__.py
touch app/domain/entities/__init__.py
touch app/services/__init__.py

cat > app/infrastructure/database/session.py <<EOF
import os
from dotenv import load_dotenv
load_dotenv()
$SESSION_IMPORT
from sqlalchemy import create_engine
from app.domain.repositories.base import Base
$SESSION_CODE
EOF

cat > app/infrastructure/database/create_tables.py <<EOF
from app.infrastructure.database.session import engine, Base
$CREATE_TABLES_CODE
EOF

touch app/infrastructure/database/__init__.py

cat > tests/test_health.py <<EOF
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_health_check():
    response = client.get("/api/v1/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}
EOF

# --- Improvements: Only create folders if selected ---
if [[ "$AUTH_CHOICE" =~ ^[Yy]$ ]]; then
    mkdir -p app/authentication
    echo "# Authentication module" > app/authentication/__init__.py
fi

if [[ "$AUTHZ_CHOICE" =~ ^[Yy]$ ]]; then
    mkdir -p app/authorization
    echo "# Authorization module" > app/authorization/__init__.py
fi

if [[ "$RATELIMIT_CHOICE" =~ ^[Yy]$ ]]; then
    mkdir -p app/ratelimiting
    echo "# Ratelimiting module" > app/ratelimiting/__init__.py
fi

if [[ "$CACHE_CHOICE" =~ ^[Yy]$ ]]; then
    mkdir -p app/caching
    echo "# Caching module" > app/caching/__init__.py
fi

if [[ "$PRECOMMIT_CHOICE" =~ ^[Yy]$ ]]; then
    pip install pre-commit
    cat > .pre-commit-config.yaml <<EOF
repos:
  - repo: https://github.com/psf/black
    rev: 23.3.0
    hooks:
      - id: black
  - repo: https://github.com/PyCQA/flake8
    rev: 6.0.0
    hooks:
      - id: flake8
EOF
    if [ ! -d .git ]; then
        git init
    fi
    pre-commit install
fi

if [[ "$CICD_CHOICE" =~ ^[Yy]$ ]]; then
    mkdir -p .github/workflows
    cat > .github/workflows/python-app.yml <<EOF
name: Python application

on: [push]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.11'
      - name: Install dependencies
        run: pip install -r requirements.txt
      - name: Run tests
        run: pytest
EOF
fi

if [[ "$MAKEFILE_CHOICE" =~ ^[Yy]$ ]]; then
    cat > Makefile <<EOF
install:
\tpip install -r requirements.txt

run:
\tuvicorn app.main:app --reload

test:
\tpytest

migrate:
\talembic upgrade head
EOF
fi

if [[ "$HEALTHCHECK_CHOICE" =~ ^[Yy]$ ]]; then
    if [[ ! -f Dockerfile ]]; then
        cat > Dockerfile <<EOF
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY ./app ./app

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
EOF
    fi
    sed -i '/^CMD \[.*uvicorn.*\]/i HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 CMD curl --fail http://localhost:8000/api/v1/health || exit 1' Dockerfile
fi

if [[ "$LICENSE_CHOICE" == "MIT" ]]; then
    cat > LICENSE <<EOF
MIT License

Copyright (c) $(date +%Y)

Permission is hereby granted, free of charge, to any person obtaining a copy...
EOF
elif [[ "$LICENSE_CHOICE" == "Apache-2.0" ]]; then
    cat > LICENSE <<EOF
Apache License
Version 2.0, January 2004
http://www.apache.org/licenses/
...
EOF
fi

pip install -r requirements.txt

echo -e "\nFastAPI project scaffold created. \n"
echo -e "Project $PROJECT_NAME scaffolded successfully.\n"
echo -e "cd into  $PROJECT_NAME to get started.\n"
echo -e "Activate your venv with: source $VENV_NAME/bin/activate\n"
echo -e "Remember to fill in your .env file with the correct values.\n"
echo -e "run pip upgrade with:  pip install --upgrade pip\n"
echo -e "Install dependencies with: pip install -r requirements.txt\n"
echo -e "Run the app locally with: uvicorn app.main:app --reload\n"
echo -e "Run the app with Docker: docker-compose up --build\n"
echo -e "Run Alembic migrations with: alembic upgrade head\n"
echo -e "Access the app at: http://localhost:8000\n"
echo -e "Access the endpoint at: http://localhost:8000/api/v1/health\n"
echo -e "API docs at: http://localhost:8000/docs\n"
echo -e "Redoc docs at: http://localhost:8000/redoc\n"
echo -e "Run tests with: pytest\n"
echo -e "Happy coding!\n"
echo -e "to deactivate the venv, use: deactivate\n"