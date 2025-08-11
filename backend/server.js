const express = require('express');
const cors = require('cors');
const { Pool } = require('pg');
const fs = require('fs');
const path = require('path');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 5000;

// Logger configuration
const logDir = '/var/log';
const logFile = path.join(logDir, 'usermanagement.txt');

// Ensure log directory exists
if (!fs.existsSync(logDir)) {
    fs.mkdirSync(logDir, { recursive: true });
}

// Logger function
const logger = {
    info: (message, data = null) => {
        const timestamp = new Date().toISOString();
        const logEntry = `[${timestamp}] [INFO] ${message}${data ? ' | ' + JSON.stringify(data) : ''}\n`;

        // Console log
        console.log(logEntry.trim());

        // File log
        fs.appendFileSync(logFile, logEntry);
    },

    error: (message, error = null) => {
        const timestamp = new Date().toISOString();
        const errorDetails = error ? (error.stack || error.message || JSON.stringify(error)) : '';
        const logEntry = `[${timestamp}] [ERROR] ${message}${errorDetails ? ' | ' + errorDetails : ''}\n`;

        // Console log
        console.error(logEntry.trim());

        // File log
        fs.appendFileSync(logFile, logEntry);
    },

    warn: (message, data = null) => {
        const timestamp = new Date().toISOString();
        const logEntry = `[${timestamp}] [WARN] ${message}${data ? ' | ' + JSON.stringify(data) : ''}\n`;

        // Console log
        console.warn(logEntry.trim());

        // File log
        fs.appendFileSync(logFile, logEntry);
    },

    debug: (message, data = null) => {
        const timestamp = new Date().toISOString();
        const logEntry = `[${timestamp}] [DEBUG] ${message}${data ? ' | ' + JSON.stringify(data) : ''}\n`;

        // Console log
        console.log(logEntry.trim());

        // File log
        fs.appendFileSync(logFile, logEntry);
    }
};

// Middleware
app.use(cors());
app.use(express.json());

// Request logging middleware
app.use((req, res, next) => {
    const start = Date.now();

    res.on('finish', () => {
        const duration = Date.now() - start;
        logger.info(`${req.method} ${req.originalUrl} - ${res.statusCode} - ${duration}ms`, {
            method: req.method,
            url: req.originalUrl,
            statusCode: res.statusCode,
            duration: `${duration}ms`,
            userAgent: req.get('User-Agent'),
            ip: req.ip
        });
    });

    next();
});

// PostgreSQL connection
const pool = new Pool({
    user: process.env.DB_USER || 'postgres',
    host: process.env.DB_HOST || 'localhost',
    database: process.env.DB_NAME || 'userdb',
    password: process.env.DB_PASSWORD || 'password',
    port: process.env.DB_PORT || 5432,
});

// Test database connection
pool.query('SELECT NOW()', (err, res) => {
    if (err) {
        logger.error('Database connection error:', err);
    } else {
        logger.info('Connected to PostgreSQL database');
    }
});

// Create users table if it doesn't exist
const createTableQuery = `
  CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL
  );
`;

pool.query(createTableQuery, (err, res) => {
    if (err) {
        logger.error('Error creating table:', err);
    } else {
        logger.info('Users table ready');
    }
});

// Routes

// Get all users
app.get('/api/users', async (req, res) => {
    try {
        logger.debug('Fetching all users');
        const result = await pool.query('SELECT * FROM users ORDER BY id');
        logger.info(`Successfully fetched ${result.rows.length} users`);
        res.json(result.rows);
    } catch (err) {
        logger.error('Error fetching users:', err);
        res.status(500).json({ error: 'Server error' });
    }
});

// Get user by ID
app.get('/api/users/:id', async (req, res) => {
    try {
        const { id } = req.params;
        logger.debug(`Fetching user with ID: ${id}`);

        const result = await pool.query('SELECT * FROM users WHERE id = $1', [id]);

        if (result.rows.length === 0) {
            logger.warn(`User not found with ID: ${id}`);
            return res.status(404).json({ error: 'User not found' });
        }

        logger.info(`Successfully fetched user with ID: ${id}`);
        res.json(result.rows[0]);
    } catch (err) {
        logger.error(`Error fetching user with ID ${req.params.id}:`, err);
        res.status(500).json({ error: 'Server error' });
    }
});

// Create new user
app.post('/api/users', async (req, res) => {
    try {
        const { name, phone, email } = req.body;
        logger.debug('Creating new user', { name, phone, email });

        if (!name || !phone || !email) {
            logger.warn('Missing required fields for user creation', { name, phone, email });
            return res.status(400).json({ error: 'Name, phone, and email are required' });
        }

        const result = await pool.query(
            'INSERT INTO users (name, phone, email) VALUES ($1, $2, $3) RETURNING *',
            [name, phone, email]
        );

        logger.info('User created successfully', { userId: result.rows[0].id, email });
        res.status(201).json(result.rows[0]);
    } catch (err) {
        logger.error('Error creating user:', err);
        if (err.code === '23505') { // Unique constraint violation
            logger.warn('Email already exists', { email: req.body.email });
            res.status(400).json({ error: 'Email already exists' });
        } else {
            res.status(500).json({ error: 'Server error' });
        }
    }
});

// Update user
app.put('/api/users/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const { name, phone, email } = req.body;
        logger.debug(`Updating user with ID: ${id}`, { name, phone, email });

        if (!name || !phone || !email) {
            logger.warn(`Missing required fields for user update ID: ${id}`, { name, phone, email });
            return res.status(400).json({ error: 'Name, phone, and email are required' });
        }

        const result = await pool.query(
            'UPDATE users SET name = $1, phone = $2, email = $3 WHERE id = $4 RETURNING *',
            [name, phone, email, id]
        );

        if (result.rows.length === 0) {
            logger.warn(`User not found for update with ID: ${id}`);
            return res.status(404).json({ error: 'User not found' });
        }

        logger.info(`User updated successfully with ID: ${id}`);
        res.json(result.rows[0]);
    } catch (err) {
        logger.error(`Error updating user with ID ${req.params.id}:`, err);
        res.status(500).json({ error: 'Server error' });
    }
});

// Delete user
app.delete('/api/users/:id', async (req, res) => {
    try {
        const { id } = req.params;
        logger.debug(`Deleting user with ID: ${id}`);

        const result = await pool.query('DELETE FROM users WHERE id = $1 RETURNING *', [id]);

        if (result.rows.length === 0) {
            logger.warn(`User not found for deletion with ID: ${id}`);
            return res.status(404).json({ error: 'User not found' });
        }

        logger.info(`User deleted successfully with ID: ${id}`, { deletedUser: result.rows[0] });
        res.json({ message: 'User deleted successfully' });
    } catch (err) {
        logger.error(`Error deleting user with ID ${req.params.id}:`, err);
        res.status(500).json({ error: 'Server error' });
    }
});

// Health check
app.get('/health', (req, res) => {
    logger.debug('Health check requested');
    res.json({ status: 'OK', timestamp: new Date().toISOString() });
});

app.listen(PORT, () => {
    logger.info(`Server running on port ${PORT}`);
});