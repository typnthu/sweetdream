# Development Dockerfile
FROM node:20-alpine

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies (use npm install for development)
RUN npm install

# Copy prisma schema
COPY prisma ./prisma

# Copy tsconfig
COPY tsconfig.json ./

# Copy source code
COPY src ./src

# Expose port
EXPOSE 3001

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3001/health', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})" || exit 1

# Start application (will be overridden by docker-compose command)
CMD ["npm", "run", "dev"]
