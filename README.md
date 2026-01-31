# FastAPI Scaffold Script

This repository contains a Bash script (`fastapi_scaffold_script.sh`) that automatically scaffolds a production-ready FastAPI project using hexagonal architecture.

## What the Script Does

- Prompts for your project name and whether to use async or sync SQLAlchemy.
- Sets up a Python virtual environment using pyenv.
- Creates a scalable folder structure with core, domain, infrastructure, services, API, and tests.
- Adds support for Alembic migrations, Docker, and environment variable management.
- Generates example files for models, schemas, repositories, and endpoints.
- Includes a comprehensive `.gitignore` and README template.
- Prepares folders for authentication, authorization, ratelimiting, and caching.

## How to Run

1. **Install prerequisites:**
   - [pyenv](https://github.com/pyenv/pyenv)
   - Python 3.11
   - Docker (optional, for containerization)

2. **Clone this repository:**
   ```bash
   git clone https://github.com/tossie79/fastapi-scaffold-script.git
   cd fastapi-scaffold-script
   ```

3. **Make the script executable:**
   ```bash
   chmod +x fastapi_scaffold_script.sh
   ```

4. **Run the script:**
   ```bash
   bash fastapi_scaffold_script.sh
   ```

5. **Follow the prompts to scaffold your FastAPI project.**

6. **After scaffolding:**
   - Change into your new project folder.
   - Activate the virtual environment:
     ```bash
     source venv_<your_project_name>/bin/activate
     ```
   - Install dependencies:
     ```bash
     pip install -r requirements.txt
     ```
   - Copy `.env-example` to `.env` and fill in your environment variables.

7. **Run your FastAPI app locally:**
   ```bash
   uvicorn app.main:app --reload
   ```

8. **Or run with Docker:**
   ```bash
   docker-compose up --build
   ```

---

## Possible Future Improvements

- Interactive options for extra features (authentication, authorization, ratelimiting, caching).
- Automatic GitHub repo creation using GitHub CLI.
- Pre-configured CI/CD pipelines (e.g., GitHub Actions).
- Pre-commit hooks for code quality.
- Custom license selection.
- API documentation starter templates.
- Docker healthcheck.
- Makefile or task runner for common commands.
- Optional frontend scaffold for full-stack projects.
- Enhanced error handling and validation in the script.
- Template-based file generation for maintainability.
- Support for multiple database backends.
- Automatic dependency installation after scaffolding.
- Customizable project metadata (author, description, version).

---

**For more details, see the generated README in your scaffolded project.**