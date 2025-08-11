# User Management Docker Example

A full-stack user management application built with React, Node.js, and PostgreSQL, featuring real-time backup functionality.

## 🚀 Features

- **Frontend**: React.js with modern UI
- **Backend**: Node.js/Express.js REST API
- **Database**: PostgreSQL with real-time backup
- **Containerization**: Docker & Docker Compose
- **Real-time Backup**: Automated PostgreSQL replication

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Frontend      │    │    Backend      │    │   PostgreSQL    │
│   (Port 3000)   │◄──►│   (Port 5000)   │◄──►│   (Port 5434)   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                                       │
                                                       ▼
                                              ┌─────────────────┐
                                              │  Backup System  │
                                              │  (Port 5433)    │
                                              └─────────────────┘
```

## 📋 Prerequisites

- Docker
- Docker Compose
- Git

## 🚀 Quick Start

### 1. Clone the repository
```bash
git clone <repository-url>
cd UserManagementDockerExample
```

### 2. Start the main application
```bash
docker-compose up -d
```

### 3. Start the backup system (optional)
```bash
docker-compose -f docker-compose-backup.yml up -d
```

### 4. Access the application
- **Frontend**: http://localhost:3000
- **Backend API**: http://localhost:5000
- **Main Database**: localhost:5434
- **Backup Database**: localhost:5433

## 🔧 Services

### Main Application
- **Frontend**: React.js application
- **Backend**: Node.js/Express.js API
- **Database**: PostgreSQL (userdb)

### Backup System
- **Master PostgreSQL**: Primary database for backup system
- **Backup PostgreSQL**: Replicated database
- **Backup Manager**: Automated synchronization service

## 📊 API Endpoints

### Users
- `GET /api/users` - Get all users
- `GET /api/users/:id` - Get user by ID
- `POST /api/users` - Create new user
- `PUT /api/users/:id` - Update user
- `DELETE /api/users/:id` - Delete user

### Health Check
- `GET /health` - Service health status

## 🗄️ Database Schema

```sql
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL
);
```

## 🔒 Environment Variables

```bash
# Database
DB_HOST=postgres
DB_USER=postgres
DB_NAME=userdb
DB_PASSWORD=password
DB_PORT=5432

# Server
PORT=5000
```

## 🐳 Docker Commands

### Start services
```bash
docker-compose up -d
```

### Stop services
```bash
docker-compose down
```

### View logs
```bash
docker-compose logs -f
```

### Rebuild services
```bash
docker-compose up -d --build
```

## 📁 Project Structure

```
UserManagementDockerExample/
├── frontend/                 # React frontend
│   ├── src/
│   ├── public/
│   └── Dockerfile
├── backend/                  # Node.js backend
│   ├── server.js
│   ├── package.json
│   └── Dockerfile
├── docker-compose.yml        # Main application
├── docker-compose-backup.yml # Backup system
├── backup-script.sh         # Backup automation
├── start.sh                 # Startup script
└── README.md
```

## 🔄 Backup System

The backup system provides real-time data replication:

- **Automatic synchronization** every 5 minutes
- **Incremental backups** for efficiency
- **Separate PostgreSQL instances** for safety
- **Automated failover** capabilities

## 🧪 Testing

1. Open http://localhost:3000
2. Add a new user
3. Edit existing users
4. Delete users
5. Check backup database after 5 minutes

## 🚨 Troubleshooting

### Port conflicts
If you encounter port conflicts, modify the ports in `docker-compose.yml`

### Database connection issues
Check if PostgreSQL container is running:
```bash
docker ps | grep postgres
```

### Backup system issues
Check backup manager logs:
```bash
docker logs backup-manager
```

## 📝 License

This project is for educational purposes.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## 📞 Support

For questions or issues, please open an issue on GitHub.
