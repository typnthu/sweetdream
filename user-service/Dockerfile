# ===== Stage 1: Builder =====
FROM node:20-alpine AS builder

WORKDIR /app

# Copy package files first (to leverage Docker caching)
COPY package*.json ./
COPY prisma ./prisma/

# Install ALL dependencies (including devDependencies)
RUN npm install

# Copy rest of the source code
COPY . .

# Generate Prisma client (before build)
RUN npx prisma generate

# Build TypeScript
RUN npm run build


# ===== Stage 2: Production =====
FROM node:20-alpine AS production

# Install dumb-init and openssl for Prisma
RUN apk add --no-cache dumb-init openssl

# Create app user
RUN addgroup -g 1001 -S nodejs
RUN adduser -S nextjs -u 1001

WORKDIR /app

# Copy only necessary files from builder
COPY --from=builder --chown=nextjs:nodejs /app/dist ./dist
COPY --from=builder --chown=nextjs:nodejs /app/node_modules ./node_modules
COPY --from=builder --chown=nextjs:nodejs /app/package*.json ./
COPY --from=builder --chown=nextjs:nodejs /app/prisma ./prisma
COPY --from=builder --chown=nextjs:nodejs /app/src ./src
COPY --from=builder --chown=nextjs:nodejs /app/tsconfig.json ./tsconfig.json
COPY --chown=nextjs:nodejs startup.sh ./startup.sh

RUN chmod +x startup.sh

USER nextjs

EXPOSE 3003

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3003/health', (res) => { process.exit(res.statusCode === 200 ? 0 : 1) })"

ENTRYPOINT ["dumb-init", "--"]
CMD ["./startup.sh"]
