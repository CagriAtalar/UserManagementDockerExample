// Frontend Logger Utility
// This logger provides both console and file logging capabilities

class Logger {
    constructor() {
        this.logLevel = process.env.NODE_ENV === 'production' ? 'info' : 'debug';
        this.logLevels = {
            error: 0,
            warn: 1,
            info: 2,
            debug: 3
        };
    }

    formatMessage(level, message, data = null) {
        const timestamp = new Date().toISOString();
        const dataString = data ? ' | ' + JSON.stringify(data, null, 2) : '';
        return `[${timestamp}] [${level.toUpperCase()}] ${message}${dataString}\n`;
    }

    shouldLog(level) {
        return this.logLevels[level] <= this.logLevels[this.logLevel];
    }

    log(level, message, data = null) {
        if (!this.shouldLog(level)) return;

        const logEntry = this.formatMessage(level, message, data);

        // Console logging
        switch (level) {
            case 'error':
                console.error(logEntry.trim());
                break;
            case 'warn':
                console.warn(logEntry.trim());
                break;
            case 'info':
                console.info(logEntry.trim());
                break;
            case 'debug':
                console.log(logEntry.trim());
                break;
        }

        // File logging (localStorage for browser compatibility)
        this.writeToFile(logEntry);
    }

    writeToFile(logEntry) {
        try {
            const existingLogs = localStorage.getItem('usermanagement_logs') || '';
            const newLogs = existingLogs + logEntry;

            // Keep only last 1000 log entries to prevent localStorage overflow
            const logLines = newLogs.split('\n');
            if (logLines.length > 1000) {
                const trimmedLogs = logLines.slice(-1000).join('\n');
                localStorage.setItem('usermanagement_logs', trimmedLogs);
            } else {
                localStorage.setItem('usermanagement_logs', newLogs);
            }
        } catch (error) {
            console.warn('Could not save log to localStorage:', error);
        }
    }

    // Export logs for download
    exportLogs() {
        try {
            const logs = localStorage.getItem('usermanagement_logs') || '';
            if (logs) {
                const blob = new Blob([logs], { type: 'text/plain' });
                const url = URL.createObjectURL(blob);
                const a = document.createElement('a');
                a.href = url;
                a.download = `usermanagement_logs_${new Date().toISOString().split('T')[0]}.txt`;
                document.body.appendChild(a);
                a.click();
                document.body.removeChild(a);
                URL.revokeObjectURL(url);
            }
        } catch (error) {
            console.error('Error exporting logs:', error);
        }
    }

    // Clear logs
    clearLogs() {
        try {
            localStorage.removeItem('usermanagement_logs');
        } catch (error) {
            console.error('Error clearing logs:', error);
        }
    }

    // Public methods
    error(message, data = null) {
        this.log('error', message, data);
    }

    warn(message, data = null) {
        this.log('warn', message, data);
    }

    info(message, data = null) {
        this.log('info', message, data);
    }

    debug(message, data = null) {
        this.log('debug', message, data);
    }
}

// Create and export singleton instance
const logger = new Logger();
export default logger;
