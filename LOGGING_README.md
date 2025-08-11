# Logging System Documentation

## Overview
This document describes the comprehensive logging system implemented for the User Management System, covering both backend (Node.js) and frontend (React) applications.

## Features

### Backend Logging
- **File-based logging** to `/var/log/usermanagement.txt`
- **Console logging** for development and debugging
- **Structured logging** with timestamps and log levels
- **Request logging middleware** for all HTTP requests
- **Database operation logging** for all CRUD operations
- **Error logging** with stack traces and context

### Frontend Logging
- **Browser-based logging** using localStorage
- **Console logging** for development
- **Log export functionality** for downloading logs
- **Log management** (clear, export)
- **User action logging** for all CRUD operations

### Host System Integration
- **Volume mounts** for persistent log storage
- **Log rotation** and backup management
- **Host-based log management** scripts

## Log Levels

### Backend
- **ERROR**: Critical errors, exceptions, and failures
- **WARN**: Warning conditions and potential issues
- **INFO**: General information and successful operations
- **DEBUG**: Detailed debugging information

### Frontend
- **ERROR**: JavaScript errors and API failures
- **WARN**: Warning conditions and validation issues
- **INFO**: General information and successful operations
- **DEBUG**: Detailed debugging information

## Log Format

All logs follow this consistent format:
```
[2024-01-15T10:30:45.123Z] [INFO] User created successfully | {"userId": 123, "email": "user@example.com"}
```

## Configuration

### Backend Logging
The backend logger is configured in `backend/server.js`:

```javascript
const logDir = '/var/log';
const logFile = path.join(logDir, 'usermanagement.txt');
```

### Frontend Logging
The frontend logger is configured in `frontend/src/utils/logger.js`:

```javascript
const logger = new Logger();
logger.logLevel = process.env.NODE_ENV === 'production' ? 'info' : 'debug';
```

### Docker Configuration
Log volumes are mounted in `docker-compose.yml`:

```yaml
volumes:
  - /var/log:/var/log:rw
  - ./logs:/var/log/container-logs:rw
```

## Usage

### Backend Logging
```javascript
const logger = require('./logger');

logger.info('User operation completed', { userId: 123 });
logger.error('Database connection failed', error);
logger.warn('Missing required field', { field: 'email' });
logger.debug('Processing request', { method: 'POST', url: '/api/users' });
```

### Frontend Logging
```javascript
import logger from './utils/logger';

logger.info('User logged in', { userId: 123 });
logger.error('API request failed', error);
logger.warn('Form validation failed', { field: 'email' });
logger.debug('Component rendered', { props: componentProps });
```

### Host Log Management
Use the `log-manager.sh` script for host-based log management:

```bash
# Show log statistics
sudo ./log-manager.sh status

# Rotate logs if necessary
sudo ./log-manager.sh rotate

# Tail logs in real-time
./log-manager.sh tail

# Search logs
./log-manager.sh search "error"

# Clean up old backups
sudo ./log-manager.sh cleanup
```

## Log File Locations

### Container Logs
- **Backend**: `/var/log/usermanagement.txt`
- **Frontend**: Browser localStorage (exported as text files)

### Host Logs
- **Primary**: `/var/log/usermanagement.txt`
- **Backups**: `/var/log/backups/usermanagement_YYYYMMDD_HHMMSS.txt`
- **Container logs**: `./logs/` (project directory)

## Log Rotation

Logs are automatically rotated when they exceed 100MB:
- Old logs are moved to `/var/log/backups/`
- Maximum 10 backup files are kept
- New log file is created automatically

## Security Considerations

- Log files are created with appropriate permissions (644)
- Log directories have restricted access (755)
- Sensitive data is not logged (passwords, tokens)
- Log files are stored in secure locations

## Monitoring and Maintenance

### Regular Tasks
1. **Daily**: Check log file size and health
2. **Weekly**: Review error patterns and warnings
3. **Monthly**: Clean up old backup files
4. **As needed**: Export logs for analysis

### Log Analysis
Use the log manager script to analyze logs:
```bash
# Find all errors
./log-manager.sh search "ERROR"

# Monitor real-time activity
./log-manager.sh tail

# Check log health
./log-manager.sh status
```

## Troubleshooting

### Common Issues

1. **Permission Denied**
   ```bash
   sudo chmod 755 /var/log
   sudo chown root:root /var/log/usermanagement.txt
   ```

2. **Disk Space Issues**
   ```bash
   sudo ./log-manager.sh rotate
   sudo ./log-manager.sh cleanup
   ```

3. **Log File Not Found**
   - Check if the application is running
   - Verify volume mounts in Docker
   - Check file permissions

### Debug Mode
Enable debug logging by setting environment variables:
```bash
# Backend
NODE_ENV=development

# Frontend
REACT_APP_LOG_LEVEL=debug
```

## Performance Impact

- **File I/O**: Minimal impact with async operations
- **Storage**: Logs are automatically rotated and cleaned
- **Memory**: Frontend logs limited to 1000 entries
- **Network**: No additional network overhead

## Best Practices

1. **Log Levels**: Use appropriate log levels for different types of information
2. **Structured Data**: Include relevant context in log messages
3. **Error Handling**: Always log errors with full context
4. **Performance**: Avoid logging in tight loops or critical paths
5. **Security**: Never log sensitive information
6. **Maintenance**: Regularly review and clean up old logs

## Integration with External Tools

The logging system can be integrated with:
- **ELK Stack** (Elasticsearch, Logstash, Kibana)
- **Splunk** for log analysis
- **Prometheus** for metrics collection
- **Grafana** for visualization
- **Custom monitoring scripts**

## Support

For issues with the logging system:
1. Check the log manager script output
2. Verify Docker volume mounts
3. Check file permissions and ownership
4. Review application logs for errors
5. Consult this documentation
