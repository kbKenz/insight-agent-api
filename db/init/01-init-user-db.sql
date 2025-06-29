-- Database initialization script for insight-agent-api
-- This script runs automatically when the PostgreSQL container starts for the first time

-- Create application database if it doesn't exist
-- (The main database is already created via POSTGRES_DB environment variable)

-- Create application user if it doesn't exist
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'insight_agent_user') THEN
        CREATE ROLE insight_agent_user WITH 
            LOGIN 
            PASSWORD 'insight_agent_password'
            CREATEDB
            NOSUPERUSER
            NOCREATEROLE
            INHERIT
            NOREPLICATION
            CONNECTION LIMIT -1;
    END IF;
END $$;

-- Grant privileges to the application user
GRANT CONNECT ON DATABASE insight_agent TO insight_agent_user;
GRANT CREATE ON DATABASE insight_agent TO insight_agent_user;

-- Switch to the application database
\c insight_agent;

-- Grant schema privileges
GRANT USAGE ON SCHEMA public TO insight_agent_user;
GRANT CREATE ON SCHEMA public TO insight_agent_user;

-- Grant default privileges for future objects
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO insight_agent_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT USAGE, SELECT ON SEQUENCES TO insight_agent_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT EXECUTE ON FUNCTIONS TO insight_agent_user;

-- Create additional schemas if needed
CREATE SCHEMA IF NOT EXISTS app AUTHORIZATION insight_agent_user;
CREATE SCHEMA IF NOT EXISTS logs AUTHORIZATION insight_agent_user;

-- Grant privileges on additional schemas
GRANT ALL PRIVILEGES ON SCHEMA app TO insight_agent_user;
GRANT ALL PRIVILEGES ON SCHEMA logs TO insight_agent_user;

-- Set default privileges for the new schemas
ALTER DEFAULT PRIVILEGES IN SCHEMA app GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO insight_agent_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA app GRANT USAGE, SELECT ON SEQUENCES TO insight_agent_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA app GRANT EXECUTE ON FUNCTIONS TO insight_agent_user;

ALTER DEFAULT PRIVILEGES IN SCHEMA logs GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO insight_agent_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA logs GRANT USAGE, SELECT ON SEQUENCES TO insight_agent_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA logs GRANT EXECUTE ON FUNCTIONS TO insight_agent_user;

-- Create essential extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";
CREATE EXTENSION IF NOT EXISTS "btree_gin";
CREATE EXTENSION IF NOT EXISTS "btree_gist";

-- Log the initialization
INSERT INTO pg_catalog.pg_stat_statements_info (dealloc, stats_reset) 
    VALUES (0, NOW()) 
    ON CONFLICT DO NOTHING;

-- Output completion message
SELECT 'Database initialization completed successfully!' AS message; 