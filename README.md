# Insight Agent API

A FastAPI backend application built with the [Aeternalis-Ingenium FastAPI Backend Template](https://github.com/Aeternalis-Ingenium/FastAPI-Backend-Template).

## Tech Stack

- 🐍 **FastAPI** - High-performance async Python web framework
- 🐘 **PostgreSQL** - Asynchronous database with SQLAlchemy 2.0
- 🐳 **Docker** - Containerized development and deployment
- 🔄 **Alembic** - Database migrations
- 🧪 **pytest** - Testing framework
- 🔒 **JWT Authentication** - Secure user authentication

## Quick Start

1. **Environment Setup**

   ```bash
   cp .env.example .env
   # Edit .env with your configuration
   ```

2. **Docker Development**

   ```bash
   chmod +x backend/entrypoint.sh
   docker-compose build
   docker-compose up
   ```

3. **Local Development**
   ```bash
   cd backend
   pip install -r requirements.txt
   uvicorn src.main:backend_app --reload
   ```

## URLs

- **API Documentation**: http://localhost:8001/docs (Docker) or http://localhost:8000/docs (Local)
- **Database Admin**: http://localhost:8081 (Docker only)

## Project Structure

```
├── backend/           # FastAPI application
│   ├── src/          # Source code
│   ├── tests/        # Test suites
│   └── requirements.txt
├── .github/          # CI/CD workflows
├── docker-compose.yaml
└── .env.example      # Environment variables template
```

For detailed setup instructions, see the [backend README](backend/README.md).
