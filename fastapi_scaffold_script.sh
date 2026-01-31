#!/usr/bin/env bash

set -e

read -p "Enter project name: " PROJECT_NAME

# Create project outside the script folder
PROJECT_ROOT="$(dirname "$PWD")/$PROJECT_NAME"

echo "Should the SQLAlchemy setup be async? (y/n): "
read ASYNC_CHOICE

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
    logger.info('Creating async DB session')
    async with async_session() as session:
        yield session
"
    CREATE_TABLES_CODE="
import asyncio
from app.infrastructure.database.models.example import Example
async def create_tables():
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    logger.info('Async tables created')
if __name__ == '__main__':
    asyncio.run(create_tables())
"
    ALEMBIC_URL="sqlalchemy.url = $DB_URL"
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
    logger.info('Creating sync DB session')
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
    logger.info('Sync tables created')
if __name__ == '__main__':
    create_tables()
"
    ALEMBIC_URL="sqlalchemy.url = $DB_URL"
fi

# Create project structure
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

# Scalability/reliability folders
mkdir -p "$PROJECT_ROOT"/app/authentication
mkdir -p "$PROJECT_ROOT"/app/authorization
mkdir -p "$PROJECT_ROOT"/app/ratelimiting
mkdir -p "$PROJECT_ROOT"/app/caching

cd "$PROJECT_ROOT"

# Set local Python version with pyenv
echo "3.11.0" > .python-version
pyenv local 3.11.0

# Create virtual environment using pyenv's python
VENV_NAME="venv_$(echo "$PROJECT_NAME" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/_/g')"
pyenv exec python -m venv "$VENV_NAME"
source "$VENV_NAME/bin/activate"

# .gitignore
cat > .gitignore <<EOF
.env
$VENV_NAME/
__pycache__/
.python-version
*.pyc
*.pyo
*.pyd
.Python
# Virtual Environments
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
!.env.example
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

# Requirements
cat > requirements.txt <<EOF
fastapi
uvicorn[standard]
$SQLALCHEMY_DEPS
python-dotenv
alembic
pytest
EOF

# .env (for local use, not committed)
cat > .env <<EOF
POSTGRES_USER=
POSTGRES_PASSWORD=
POSTGRES_DB=
POSTGRES_HOST=
POSTGRES_PORT=5432
DATABASE_URL=
EOF

# .env-example (placeholders, safe to commit)
cat > .env-example <<EOF
POSTGRES_USER=your_db_user
POSTGRES_PASSWORD=your_db_password
POSTGRES_DB=your_db_name
POSTGRES_HOST=your_db_host
POSTGRES_PORT=5432
DATABASE_URL=your_database_url
EOF

# Core files
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

cat > app/core/constants.py <<EOF
# Application-wide constants
PROJECT_NAME = "$PROJECT_NAME"
API_PREFIX = "/api/v1"
EOF

touch app/core/__init__.py

# Minimal FastAPI app with logging
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

# Minimal API router
cat > app/api/v1/routes.py <<EOF
from fastapi import APIRouter

router = APIRouter()

@router.get("/health")
def health_check():
    return {"status": "ok"}
EOF

touch app/api/v1/__init__.py
touch app/api/v1/dependencies/__init__.py
touch app/api/v1/dependencies/dependencies.py
touch app/api/v1/routes/endpoints.py

# Example Pydantic schema
cat > app/infrastructure/database/schemas/example.py <<EOF
from pydantic import BaseModel

class ExampleSchema(BaseModel):
    id: int
    name: str

    class Config:
        orm_mode = True
EOF

touch app/infrastructure/database/schemas/__init__.py

# Example DB model
cat > app/infrastructure/database/models/example.py <<EOF
from sqlalchemy import Column, Integer, String
from app.domain.repositories.base import Base

class Example(Base):
    __tablename__ = "examples"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, index=True)
EOF

touch app/infrastructure/database/models/__init__.py

# Example repository
cat > app/infrastructure/database/repositories/example_repository.py <<EOF
# Example repository implementation for Example model
EOF

touch app/infrastructure/database/repositories/__init__.py

# Repository base in domain
cat > app/domain/repositories/base.py <<EOF
from sqlalchemy.orm import declarative_base

Base = declarative_base()
EOF

touch app/domain/repositories/__init__.py
touch app/domain/entities/__init__.py
touch app/services/__init__.py

# Database session with logging
cat > app/infrastructure/database/session.py <<EOF
import os
from dotenv import load_dotenv
load_dotenv()
import logging
logger = logging.getLogger(__name__)
$SESSION_IMPORT
from sqlalchemy import create_engine
from app.domain.repositories.base import Base
$SESSION_CODE
EOF

# Table creation script with logging
cat > app/infrastructure/database/create_tables.py <<EOF
from app.infrastructure.database.session import engine, Base
import logging
logger = logging.getLogger(__name__)
$CREATE_TABLES_CODE
EOF

touch app/infrastructure/database/__init__.py

# Dockerfile
cat > Dockerfile <<EOF
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY ./app ./app

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
EOF

# docker-compose.yml
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

# .python-version for pyenv
echo "3.11.0" > .python-version

# README
cat > README.md <<EOF
# $PROJECT_NAME

## Prerequisites

- Python 3.11
- [pyenv](https://github.com/pyenv/pyenv) (recommended)
- Docker & Docker Compose (for containerized setup)
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
python3 -m venv venv_${PROJECT_NAME,,}
source venv_${PROJECT_NAME,,}/bin/activate
\`\`\`

#### Windows

\`\`\`powershell
python -m venv venv_${PROJECT_NAME,,}
venv_${PROJECT_NAME,,}\\Scripts\\activate
\`\`\`

#### Using pyenv

\`\`\`bash
pyenv install 3.11.0
pyenv local 3.11.0
pyenv exec python -m venv venv_${PROJECT_NAME,,}
source venv_${PROJECT_NAME,,}/bin/activate
\`\`\`

### 3. Install dependencies

\`\`\`bash
pip install -r requirements.txt
\`\`\`

### 4. Set up environment variables

- Copy \`.env-example\` to \`.env\` and fill in your values.

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

- Import the endpoint \`GET /api/v1/health\` in Postman.

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
│   ├── domain/
│   │   └── repositories/
│   │       └── base.py
│   ├── infrastructure/
│   │   └── database/
│   │       ├── create_tables.py
│   │       ├── models/
│   │       │   └── example.py
│   │       ├── repositories/
│   │       │   └── example_repository.py
│   │       ├── schemas/
│   │       │   └── example.py
│   │       └── session.py
│   ├── ratelimiting/
│   ├── services/
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

### Folder & File Explanations

- \`api/v1/routes\`: Contains endpoint files for API version 1.
- \`api/v1/routes.py\`: Main router for API v1.
- \`core\`: Core settings, logging, constants, and DB engine setup.
- \`domain/repositories\`: Repository base for domain logic.
- \`infrastructure/database/models\`: SQLAlchemy DB models.
- \`infrastructure/database/schemas\`: Pydantic schemas.
- \`infrastructure/database/repositories\`: DB repository implementations.
- \`services\`: Business logic/services.
- \`authentication, authorization, ratelimiting, caching\`: For future scalability/reliability.
- \`tests\`: Automated tests.
- \`Dockerfile\`, \`docker-compose.yml\`: Containerization files.
- \`.env\`, \`.env-example\`: Environment variable files.
- \`requirements.txt\`: Python dependencies.
- \`.gitignore\`: Git ignore rules.
- \`.python-version\`: Pyenv version file.
- \`README.md\`: Project documentation.

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

## Accessing from GitHub

- Visit your repository URL: \`https://github.com/<your-username>/$PROJECT_NAME\`

---

Happy coding!
EOF

# Alembic init
alembic init alembic
sed -i "s|^sqlalchemy.url =.*|$ALEMBIC_URL|" alembic.ini
cat > alembic/env.py <<EOF
import sys
import os
from logging.config import fileConfig

from sqlalchemy import engine_from_config
from sqlalchemy import pool

from alembic import context

sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
from app.domain.repositories.base import Base

# this is the Alembic Config object, which provides
# access to the values within the .ini file in use.
config = context.config

# Interpret the config file for Python logging.
# This line sets up loggers basically.
fileConfig(config.config_file_name)

target_metadata = Base.metadata

def run_migrations_offline():
    url = config.get_main_option("sqlalchemy.url")
    context.configure(
        url=url, target_metadata=target_metadata, literal_binds=True, compare_type=True
    )

    with context.begin_transaction():
        context.run_migrations()

def run_migrations_online():
    connectable = engine_from_config(
        config.get_section(config.config_ini_section),
        prefix="sqlalchemy.",
        poolclass=pool.NullPool,
    )

    with connectable.connect() as connection:
        context.configure(
            connection=connection, target_metadata=target_metadata, compare_type=True
        )

        with context.begin_transaction():
            context.run_migrations()

if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
EOF

# Tests folder with example test
cat > tests/test_health.py <<EOF
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_health_check():
    response = client.get("/api/v1/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}
EOF
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