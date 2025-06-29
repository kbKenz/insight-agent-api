#!/bin/bash

# Test Script for Insight Agent API Setup
# This script verifies that all services are running correctly

set -e

# Color codes for output
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🧪 Testing Insight Agent API Setup${NC}"
echo "Verifying all services are running correctly..."
echo ""

# Function to check if a service is responding
check_service() {
    local name=$1
    local url=$2
    local expected_status=${3:-"200\|302\|307"}
    
    echo -n "Testing $name... "
    
    if curl -s -o /dev/null -w "%{http_code}" "$url" | grep -q "$expected_status"; then
        echo -e "${GREEN}✅ OK${NC}"
        return 0
    else
        echo -e "${RED}❌ Failed${NC}"
        return 1
    fi
}

# Function to check if a port is listening
check_port() {
    local name=$1
    local port=$2
    
    echo -n "Checking $name port $port... "
    
    if nc -z localhost "$port" 2>/dev/null; then
        echo -e "${GREEN}✅ OK${NC}"
        return 0
    else
        echo -e "${RED}❌ Failed${NC}"
        return 1
    fi
}

# Check if Docker containers are running
echo -e "${YELLOW}📋 Checking Docker containers...${NC}"
if ! docker-compose ps | grep -q "Up"; then
    echo -e "${RED}❌ No running containers found. Please run 'docker-compose up -d' first.${NC}"
    exit 1
fi

# List running containers
docker-compose ps

echo ""
echo -e "${YELLOW}🔍 Testing service endpoints...${NC}"

# Test services
failed_tests=0

# Test PostgreSQL
if ! check_port "PostgreSQL" 5432; then
    failed_tests=$((failed_tests + 1))
fi

# Test FastAPI application
if ! check_service "FastAPI Health" "http://localhost:8000/health"; then
    failed_tests=$((failed_tests + 1))
fi

if ! check_service "FastAPI Root" "http://localhost:8000/"; then
    failed_tests=$((failed_tests + 1))
fi

if ! check_service "FastAPI Docs" "http://localhost:8000/docs"; then
    failed_tests=$((failed_tests + 1))
fi

# Test Prometheus
if ! check_service "Prometheus" "http://localhost:9090/"; then
    failed_tests=$((failed_tests + 1))
fi

# Test Grafana
if ! check_service "Grafana" "http://localhost:3000/"; then
    failed_tests=$((failed_tests + 1))
fi

# Test cAdvisor
if ! check_service "cAdvisor" "http://localhost:8080/"; then
    failed_tests=$((failed_tests + 1))
fi

# Test pgAdmin (optional, only if running)
if docker-compose ps | grep -q "pgadmin.*Up"; then
    if ! check_service "pgAdmin" "http://localhost:5050/"; then
        echo -e "${YELLOW}⚠️  pgAdmin is running but not responding (this is normal during startup)${NC}"
    fi
fi

echo ""
echo -e "${YELLOW}🗄️  Testing database connection...${NC}"

# Test database connection
if docker exec insight_agent_postgres pg_isready -U postgres -d insight_agent > /dev/null 2>&1; then
    echo -e "${GREEN}✅ PostgreSQL connection OK${NC}"
    
    # Test database query
    if docker exec insight_agent_postgres psql -U postgres -d insight_agent -c "SELECT 1;" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Database query OK${NC}"
    else
        echo -e "${RED}❌ Database query failed${NC}"
        failed_tests=$((failed_tests + 1))
    fi
else
    echo -e "${RED}❌ PostgreSQL connection failed${NC}"
    failed_tests=$((failed_tests + 1))
fi

# Test application database connection
echo -n "Testing application database connection... "
response=$(curl -s http://localhost:8000/health 2>/dev/null || echo "failed")

if echo "$response" | grep -q '"database":"healthy"'; then
    echo -e "${GREEN}✅ OK${NC}"
elif echo "$response" | grep -q '"database":"unhealthy"'; then
    echo -e "${RED}❌ Database connection failed${NC}"
    failed_tests=$((failed_tests + 1))
else
    echo -e "${RED}❌ Health endpoint not responding${NC}"
    failed_tests=$((failed_tests + 1))
fi

echo ""
echo -e "${YELLOW}📊 Service Summary:${NC}"

# Show environment info
if [ -f ".env.development" ]; then
    source .env.development
    echo -e "${BLUE}Environment:${NC} ${APP_ENV:-development}"
    echo -e "${BLUE}Database:${NC} ${POSTGRES_DB:-insight_agent}"
    echo -e "${BLUE}Database User:${NC} ${POSTGRES_USER:-postgres}"
fi

echo ""
echo -e "${BLUE}🌐 Available URLs:${NC}"
echo "• FastAPI Application: http://localhost:8000"
echo "• API Documentation: http://localhost:8000/docs"
echo "• API Redoc: http://localhost:8000/redoc"
echo "• Health Check: http://localhost:8000/health"
echo "• Prometheus: http://localhost:9090"
echo "• Grafana: http://localhost:3000"
echo "• cAdvisor: http://localhost:8080"

if docker-compose ps | grep -q "pgadmin.*Up"; then
    echo "• pgAdmin: http://localhost:5050"
fi

echo ""
if [ $failed_tests -eq 0 ]; then
    echo -e "${GREEN}🎉 All tests passed! Your setup is working correctly.${NC}"
    echo ""
    echo -e "${BLUE}💡 Next steps:${NC}"
    echo "• Try the API: curl http://localhost:8000/health"
    echo "• View API docs: open http://localhost:8000/docs"
    echo "• Monitor metrics: open http://localhost:3000"
    exit 0
else
    echo -e "${RED}❌ $failed_tests test(s) failed. Please check the logs and configuration.${NC}"
    echo ""
    echo -e "${YELLOW}🔧 Troubleshooting:${NC}"
    echo "• Check logs: docker-compose logs"
    echo "• Restart services: docker-compose restart"
    echo "• Full reset: docker-compose down -v && docker-compose up -d"
    exit 1
fi 