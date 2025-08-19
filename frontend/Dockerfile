FROM node:18-alpine

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci

# Copy source code
COPY . .

# Build the app
ARG REACT_APP_API_URL=http://backend-service:5000
ENV REACT_APP_API_URL=$REACT_APP_API_URL
RUN echo "Building with REACT_APP_API_URL=$REACT_APP_API_URL" && npm run build

# Install serve globally
RUN npm install -g serve

# Create non-root user for security
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

# Change ownership of app directory (only necessary files)
RUN chown -R nodejs:nodejs /app/build /app/package*.json

# Switch to non-root user
USER nodejs

# Expose port
EXPOSE 3000

# Start the application
CMD ["serve", "-s", "build", "-l", "3000"]
