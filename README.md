# FastAPI Scaffold Script

This repository contains two scripts for scaffolding FastAPI projects:

- **fastapi_scaffold_script.sh**
- **fastapi_scaffold_improvements_script.sh**

---

## Scripts Overview

### 1. `fastapi_scaffold_script.sh`

- **Purpose:**  
  Quickly scaffolds a standard FastAPI project with a recommended structure, including SQLAlchemy, Alembic, Docker, and basic folders for authentication, authorization, ratelimiting, and caching.
- **Features:**  
  - Sync/async SQLAlchemy support  
  - Docker and Docker Compose files  
  - Alembic migrations  
  - Example health endpoint  
  - Pre-filled `.env` and `.env-example`  
  - Comprehensive `.gitignore`  
  - Basic README  
- **When to use:**  
  Use this script if you want a **quick, standard FastAPI project scaffold** with all the essentials and a clean, extensible structure.

---

### 2. `fastapi_scaffold_improvements_script.sh`

- **Purpose:**  
  An improved and more interactive version of the scaffold script. It allows you to **customize** your project scaffold with more options and better automation.
- **Improvements over the basic script:**  
  - Interactive prompts for enabling/disabling features (auth, ratelimiting, caching, pre-commit, CI/CD, Makefile, Docker healthcheck, license)
  - Only creates folders and files for features you select
  - Optionally adds pre-commit hooks and GitHub Actions workflow
  - Optionally adds a Makefile for common tasks
  - Optionally adds a Docker healthcheck
  - Optionally adds a license file (MIT/Apache-2.0)
  - More detailed README and documentation
- **When to use:**  
  Use this script if you want a **customizable FastAPI scaffold** and want to include/exclude features based on your project needs.

---

## How to Use

### 1. Clone this repository

```bash
git clone <your-repo-url>
cd fastapi-scaffold-script
```

### 2. Run a script

**Make the script executable:**
   ```bash
   chmod +x fastapi_scaffold_script.sh
   ```
#### For a standard scaffold:

```bash
bash fastapi_scaffold_script.sh
```

#### For an improved, customizable scaffold:

```bash
bash fastapi_scaffold_improvements_script.sh
```

- Both scripts will prompt you for a project name.
- The project folder will be created **outside** the `fastapi-scaffold-script` directory (as a sibling folder).
- Follow the prompts and instructions in the terminal.

---

## Which Script Should I Use?

| Script                                 | Use When...                                                                                   |
|-----------------------------------------|----------------------------------------------------------------------------------------------|
| `fastapi_scaffold_script.sh`            | You want a quick, standard FastAPI scaffold with all common features included by default.     |
| `fastapi_scaffold_improvements_script.sh` | You want to **customize** your scaffold, enabling/disabling features as needed for your project. |

---

## Example

Suppose your folder structure is:

```
/home/user/dev/fastapi-scaffold-script/
```

If you run either script from inside `fastapi-scaffold-script`,  
your new project will be created as a sibling:

```
/home/user/dev/fastapi-scaffold-script/
/home/user/dev/my-fastapi-project/
```

 ##  After scaffolding:
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

 ## Run your FastAPI app locally:
   ```bash
   uvicorn app.main:app --reload
   ```

 ## Run with Docker:
   ```bash
   docker-compose up --build
   ```

---



## Summary

- Use **`fastapi_scaffold_script.sh`** for a quick, all-in-one scaffold.
- Use **`fastapi_scaffold_improvements_script.sh`** for a tailored, feature-selectable scaffold.

Both scripts help you start new FastAPI projects with best practices and modern tooling.