#!/bin/bash

# PostgreSQL Database Setup Script
# This script helps set up the containerized PostgreSQL database for the insight-agent-api

set -e

# Color codes for output
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🐘 PostgreSQL Database Setup${NC}"
echo "Setting up containerized PostgreSQL for insight-agent-api"
echo ""

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}❌ Docker is not running. Please start Docker first.${NC}"
    exit 1
fi

# Check if docker-compose is available
if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}❌ docker-compose not found. Please install Docker Compose.${NC}"
    exit 1
fi

# Set environment (default to development)
ENV=${1:-development}

echo -e "${GREEN}📝 Environment: ${ENV}${NC}"

# Check if .env file exists for the environment
ENV_FILE=".env.${ENV}"
if [ ! -f "$ENV_FILE" ]; then
    echo -e "${YELLOW}⚠️  Environment file $ENV_FILE not found.${NC}"
    echo -e "${YELLOW}📋 Creating from .env.example...${NC}"
    
    if [ ! -f ".env.example" ]; then
        echo -e "${RED}❌ .env.example not found. Please create it first.${NC}"
        exit 1
    fi
    
    cp .env.example "$ENV_FILE"
    echo -e "${GREEN}✅ Created $ENV_FILE${NC}"
    echo -e "${YELLOW}🔧 Please update the database passwords in $ENV_FILE before continuing.${NC}"
    echo ""
    echo "Press Enter to continue after updating the passwords, or Ctrl+C to exit..."
    read -r
fi

# Source the environment file
set -a
source "$ENV_FILE"
set +a

echo -e "${GREEN}🚀 Starting PostgreSQL database...${NC}"

# Start only the database services first
docker-compose up -d postgres

# Wait for PostgreSQL to be ready
echo -e "${YELLOW}⏳ Waiting for PostgreSQL to start...${NC}"
timeout=60
counter=0

while ! docker exec insight_agent_postgres pg_isready -U "${POSTGRES_USER:-postgres}" -d "${POSTGRES_DB:-insight_agent}" > /dev/null 2>&1; do
    if [ $counter -eq $timeout ]; then
        echo -e "${RED}❌ PostgreSQL failed to start within $timeout seconds${NC}"
        docker-compose logs postgres
        exit 1
    fi
    
    echo -n "."
    sleep 1
    counter=$((counter + 1))
done

echo ""
echo -e "${GREEN}✅ PostgreSQL is ready!${NC}"

# Test database connection
echo -e "${GREEN}🔍 Testing database connection...${NC}"
if docker exec insight_agent_postgres psql -U "${POSTGRES_USER:-postgres}" -d "${POSTGRES_DB:-insight_agent}" -c "SELECT version();" > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Database connection successful!${NC}"
else
    echo -e "${RED}❌ Database connection failed${NC}"
    exit 1
fi

# Show database info
echo ""
echo -e "${BLUE}📊 Database Information:${NC}"
echo -e "${GREEN}Database Name:${NC} ${POSTGRES_DB:-insight_agent}"
echo -e "${GREEN}Database User:${NC} ${POSTGRES_USER:-postgres}"
echo -e "${GREEN}Database Host:${NC} localhost"
echo -e "${GREEN}Database Port:${NC} ${POSTGRES_PORT:-5432}"

# Check if user wants to start pgAdmin
echo ""
echo -e "${YELLOW}🔧 Would you like to start pgAdmin for database management? (y/N)${NC}"
read -r start_pgadmin

if [[ $start_pgadmin =~ ^[Yy]$ ]]; then
    echo -e "${GREEN}🚀 Starting pgAdmin...${NC}"
    docker-compose --profile tools up -d pgadmin
    
    echo -e "${GREEN}✅ pgAdmin started!${NC}"
    echo -e "${BLUE}🌐 pgAdmin URL:${NC} http://localhost:${PGADMIN_PORT:-5050}"
    echo -e "${BLUE}📧 Email:${NC} ${PGADMIN_EMAIL:-admin@example.com}"
    echo -e "${BLUE}🔑 Password:${NC} ${PGADMIN_PASSWORD:-admin}"
    echo ""
    echo -e "${YELLOW}📝 To add server in pgAdmin:${NC}"
    echo "   Host: postgres"
    echo "   Port: 5432"
    echo "   Database: ${POSTGRES_DB:-insight_agent}"
    echo "   Username: ${POSTGRES_USER:-postgres}"
    echo "   Password: ${POSTGRES_PASSWORD}"
fi

echo ""
echo -e "${GREEN}🎉 Database setup complete!${NC}"
echo ""
echo -e "${BLUE}📝 Next steps:${NC}"
echo "1. Start the full application: docker-compose up -d"
echo "2. Check logs: docker-compose logs -f"
echo "3. Stop services: docker-compose down"
echo ""
echo -e "${YELLOW}💡 Useful commands:${NC}"
echo "• Connect to database: docker exec -it insight_agent_postgres psql -U ${POSTGRES_USER:-postgres} -d ${POSTGRES_DB:-insight_agent}"
echo "• View database logs: docker-compose logs postgres"
echo "• Reset database: docker-compose down -v && docker-compose up -d postgres"
echo ""
echo -e "${GREEN}✨ Happy coding!${NC}" 