# Containerized PostgreSQL Database

This directory contains the containerized PostgreSQL setup for the insight-agent-api project using **PostgreSQL 17** (latest stable version as of June 2025).

## 🏗️ Architecture

The setup includes:

- **PostgreSQL 17**: Latest stable version with optimized configuration
- **pgAdmin 4**: Web-based PostgreSQL administration tool
- **Custom initialization scripts**: Automated database and user setup
- **Volume persistence**: Data persists between container restarts
- **Health checks**: Automatic container health monitoring

## 📁 Directory Structure

```
db/
├── docker-compose.yml      # Main container orchestration file
├── postgresql.conf         # PostgreSQL server configuration
├── pg_hba.conf            # Host-based authentication configuration
├── env.template           # Environment variables template
├── init/                  # Database initialization scripts
│   ├── 01-init-user-db.sql   # User and database setup
│   └── 02-create-tables.sql  # Application table creation
└── README.md              # This file
```

## 🚀 Quick Start

### Prerequisites

- Docker and Docker Compose installed
- Available ports: 5432 (PostgreSQL) and 5050 (pgAdmin)

### 1. Environment Setup

```bash
# Copy the environment template
cp env.template .env

# Edit the .env file with your desired credentials
nano .env
```

**Important**: Change all default passwords in the `.env` file before running in production!

### 2. Start the Database

```bash
# Start PostgreSQL and pgAdmin
docker-compose up -d

# Check service status
docker-compose ps

# View logs
docker-compose logs -f postgres
```

### 3. Verify Installation

```bash
# Test PostgreSQL connection
docker exec -it postgres_db psql -U postgres -d insight_agent -c "SELECT version();"

# Or connect from host machine
psql -h localhost -p 5432 -U postgres -d insight_agent
```

## 🔧 Configuration

### PostgreSQL Configuration

The `postgresql.conf` file is optimized for:

- **Performance**: Tuned for modern hardware with SSDs
- **Security**: SCRAM-SHA-256 authentication, restricted connections
- **Monitoring**: Enhanced logging and statistics collection
- **Development**: Suitable for both development and production

Key settings:

- `shared_buffers = 256MB`
- `max_connections = 200`
- `wal_level = replica` (ready for replication)
- `log_connections = on`
- `track_io_timing = on`

### Authentication (pg_hba.conf)

Security configuration includes:

- Local connections use trust for postgres user
- Network connections require SCRAM-SHA-256 authentication
- Restricted to private network ranges
- Replication support configured

## 📊 Management Tools

### pgAdmin Access

1. Open your browser to `http://localhost:5050`
2. Login with credentials from your `.env` file
3. Add server connection:
   - **Host**: `postgres` (container name)
   - **Port**: `5432`
   - **Database**: `insight_agent`
   - **Username/Password**: From your `.env` file

### Command Line Access

```bash
# Connect to PostgreSQL container
docker exec -it postgres_db bash

# Connect directly to database
docker exec -it postgres_db psql -U postgres -d insight_agent

# Run SQL file
docker exec -i postgres_db psql -U postgres -d insight_agent < your_script.sql
```

## 🗄️ Database Schema

The initialization scripts create:

### Schemas

- `public`: Default PostgreSQL schema
- `app`: Application-specific tables
- `logs`: Logging and audit tables

### Tables

- `users`: User accounts and authentication
- `sessions`: User session management
- `threads`: Conversation threads
- `messages`: Chat messages and interactions

### Extensions

- `uuid-ossp`: UUID generation
- `pg_trgm`: Text similarity and fuzzy matching
- `btree_gin`, `btree_gist`: Advanced indexing

## 🔄 Data Management

### Backup

```bash
# Create backup
docker exec postgres_db pg_dump -U postgres insight_agent > backup_$(date +%Y%m%d_%H%M%S).sql

# Backup with compression
docker exec postgres_db pg_dump -U postgres -Fc insight_agent > backup_$(date +%Y%m%d_%H%M%S).dump
```

### Restore

```bash
# Restore from SQL file
docker exec -i postgres_db psql -U postgres -d insight_agent < backup.sql

# Restore from dump file
docker exec -i postgres_db pg_restore -U postgres -d insight_agent backup.dump
```

### Reset Database

```bash
# Stop containers and remove volumes
docker-compose down -v

# Restart fresh
docker-compose up -d
```

## 🔧 Maintenance

### Log Management

```bash
# View PostgreSQL logs
docker-compose logs postgres

# Follow logs in real-time
docker-compose logs -f postgres

# View specific log files inside container
docker exec postgres_db ls -la /var/lib/postgresql/data/log/
```

### Performance Monitoring

```bash
# Check active connections
docker exec postgres_db psql -U postgres -c "SELECT * FROM pg_stat_activity;"

# Monitor database statistics
docker exec postgres_db psql -U postgres -c "SELECT * FROM pg_stat_database;"

# Check table sizes
docker exec postgres_db psql -U postgres -d insight_agent -c "
SELECT schemaname, tablename, pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables WHERE schemaname NOT IN ('information_schema', 'pg_catalog')
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;"
```

## 🔐 Security

### Production Considerations

1. **Change default passwords** in the `.env` file
2. **Restrict network access** in `pg_hba.conf`
3. **Enable SSL/TLS** for encrypted connections
4. **Set up regular backups**
5. **Monitor logs** for suspicious activity
6. **Keep PostgreSQL updated**

### SSL Configuration (Production)

```bash
# Generate SSL certificates (example)
openssl req -new -x509 -days 365 -nodes -text -out server.crt -keyout server.key

# Update postgresql.conf
ssl = on
ssl_cert_file = '/etc/ssl/certs/server.crt'
ssl_key_file = '/etc/ssl/private/server.key'
```

## 🚨 Troubleshooting

### Common Issues

1. **Container won't start**

   ```bash
   # Check logs
   docker-compose logs postgres

   # Verify port availability
   netstat -tulpn | grep :5432
   ```

2. **Connection refused**

   ```bash
   # Check if container is running
   docker-compose ps

   # Verify network connectivity
   docker exec postgres_db pg_isready -U postgres
   ```

3. **Permission denied**

   ```bash
   # Check file permissions
   ls -la postgresql.conf pg_hba.conf

   # Fix permissions if needed
   chmod 644 postgresql.conf pg_hba.conf
   ```

4. **Out of disk space**

   ```bash
   # Check Docker volumes
   docker system df

   # Clean up if needed
   docker system prune -v
   ```

### Reset and Troubleshooting Commands

```bash
# Complete reset
docker-compose down -v --remove-orphans
docker-compose up -d

# Rebuild containers
docker-compose build --no-cache
docker-compose up -d

# Check resource usage
docker stats postgres_db
```

## 📋 Environment Variables

| Variable            | Description          | Default         |
| ------------------- | -------------------- | --------------- |
| `POSTGRES_DB`       | Database name        | `insight_agent` |
| `POSTGRES_USER`     | PostgreSQL superuser | `postgres`      |
| `POSTGRES_PASSWORD` | PostgreSQL password  | Required        |
| `POSTGRES_PORT`     | PostgreSQL port      | `5432`          |
| `PGADMIN_EMAIL`     | pgAdmin login email  | Required        |
| `PGADMIN_PASSWORD`  | pgAdmin password     | Required        |
| `PGADMIN_PORT`      | pgAdmin web port     | `5050`          |

## 🆙 Upgrades

### PostgreSQL Version Upgrades

When upgrading PostgreSQL versions:

1. **Backup your data** first
2. **Check compatibility** of extensions and configuration
3. **Test in development** environment first
4. **Use pg_upgrade** for major version changes

```bash
# Example upgrade process
docker-compose down
cp -r postgres_data postgres_data_backup
# Update docker-compose.yml with new version
docker-compose up -d
```

## 📚 Additional Resources

- [PostgreSQL 17 Documentation](https://www.postgresql.org/docs/17/)
- [Docker PostgreSQL Official Image](https://hub.docker.com/_/postgres)
- [pgAdmin 4 Documentation](https://www.pgadmin.org/docs/)
- [PostgreSQL Performance Tuning](https://wiki.postgresql.org/wiki/Performance_Optimization)

## 🤝 Contributing

When adding new database features:

1. **Update initialization scripts** in the `init/` directory
2. **Document schema changes** in this README
3. **Test with fresh database** setup
4. **Consider migration scripts** for existing databases
