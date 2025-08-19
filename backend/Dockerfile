FROM node:18-alpine

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production

# Copy source code
COPY . .

# Create logs directory
RUN mkdir -p /var/log

# Create non-root user for security
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

# Change ownership of app directory
RUN chown -R nodejs:nodejs /app /var/log

# Switch to non-root user
USER nodejs

# Expose port
EXPOSE 5000

# Health check (Kubernetes will handle this via readiness/liveness probes)
# HEALTHCHECK removed for Kubernetes

# Start the application
CMD ["npm", "start"]
