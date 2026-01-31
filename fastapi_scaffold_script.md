Here is a Bash script that scaffolds a FastAPI hexagonal architecture project as you described.
It will:

 - Prompt for the project name.
 - Set up pyenv with Python 3.11 and a virtual environment.
 - Scaffold the directory structure with the specified folders and files.
 - Add a minimal FastAPI app using SQLAlchemy and PostgreSQL.
 - Create requirements.txt, Dockerfile, and docker-compose.yml.
 - Save this as scaffold_hex_fastapi.sh and run with 
 ```
 bash scaffold_hex_fastapi.sh.
 ```


 IMPROVEMENTS

 - Prompts for project name and sync/async SQLAlchemy setup.
 - Sets up pyenv, venv, and directory structure.
 - Adds a .env and .env-example with DB variables.
 - Creates a minimal database session and table creation logic (sync or async).
 - Adds Alembic for migrations and configures it.
 - Updates requirements.txt for sync/async and Alembic.
 - Save as scaffold_hex_fastapi.sh and run with 
 ```
 bash scaffold_hex_fastapi.sh
 ```