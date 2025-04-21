FROM node:slim

WORKDIR /app

# Copy package files first for better caching
COPY package*.json ./
COPY yarn*.lock* ./

# Install dependencies with retry logic
RUN if [ -f "yarn.lock" ]; then \
      for i in 1 2 3; do \
        echo "Attempt $i: Installing packages with yarn..." && \
        yarn config set network-timeout 300000 && \
        yarn install && break || \
        sleep 10; \
      done; \
    else \
      for i in 1 2 3; do \
        echo "Attempt $i: Installing packages with npm..." && \
        npm config set registry https://registry.npmjs.org/ && \
        npm ci && break || \
        sleep 10; \
      done; \
    fi

# Copy the rest of the project
COPY . .

# Add next export to package.json if it doesn't exist
RUN if ! grep -q "\"export\":" package.json; then \
      sed -i 's/\"scripts\": {/\"scripts\": {\n    \"export\": \"next export\",/g' package.json; \
    fi

# Build and export the app
RUN if [ -f "yarn.lock" ]; then \
      yarn build && yarn export || (npm run build && npm run export); \
    else \
      npm run build && npm run export; \
    fi

# The output will be in /app/out