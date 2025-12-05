FROM openresty/openresty:alpine

# Install dependencies
RUN apk add --no-cache curl perl

# Install lua-resty-http via opm
RUN opm get ledgetech/lua-resty-http

# Copy our base64 library
COPY src/lib/base64.lua /usr/local/openresty/lualib/base64.lua

# Working directory
WORKDIR /app
