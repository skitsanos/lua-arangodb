--[[
    ArangoDB Client for OpenResty/Lua
    A comprehensive client library for ArangoDB HTTP API

    Dependencies:
    - lua-cjson
    - lbase64
    - lua-resty-http
]]

local json = require("cjson")
local http = require("resty.http")

-- Try to load base64 from various sources
local base64
local ok, mod = pcall(require, "lib.base64")
if ok then
    base64 = mod
else
    ok, mod = pcall(require, "base64")
    if ok then
        base64 = mod
    else
        -- Fallback to ngx.encode_base64 if available
        if ngx and ngx.encode_base64 then
            base64 = {
                encode = ngx.encode_base64,
                decode = ngx.decode_base64
            }
        else
            error("No base64 library available")
        end
    end
end

-- Import sub-modules
local Database = require("arangodb.database")
local Collection = require("arangodb.collection")
local Document = require("arangodb.document")
local Index = require("arangodb.index")
local Query = require("arangodb.query")
local Graph = require("arangodb.graph")
local Transaction = require("arangodb.transaction")
local User = require("arangodb.user")
local Admin = require("arangodb.admin")
local Analyzer = require("arangodb.analyzer")
local View = require("arangodb.view")
local Foxx = require("arangodb.foxx")

local ArangoDB = {}
ArangoDB.__index = ArangoDB

-- Percent-encode a query component (fallback when ngx.escape_uri is unavailable)
local function encode_uri_component(value)
    if ngx and ngx.escape_uri then
        return ngx.escape_uri(value)
    end
    return tostring(value):gsub("([^%w%-%._~])", function(c)
        return string.format("%%%02X", string.byte(c))
    end)
end

-- Build a query string with proper encoding and support for array values
local function build_query_string(params)
    if not params then
        return nil
    end

    local parts = {}

    local function append(key, val)
        if val == nil then
            return
        end

        if type(val) == "boolean" then
            val = val and "true" or "false"
        end

        if type(val) == "table" then
            for _, item in ipairs(val) do
                append(key, item)
            end
            return
        end

        table.insert(parts, encode_uri_component(key) .. "=" .. encode_uri_component(val))
    end

    for k, v in pairs(params) do
        append(k, v)
    end

    if #parts == 0 then
        return nil
    end

    return "?" .. table.concat(parts, "&")
end

-- Default configuration
local DEFAULT_CONFIG = {
    timeout = 30000,        -- 30 seconds
    keepalive = 60000,      -- 60 seconds
    pool_size = 100,
    ssl_verify = false
}

--[[
    Create a new ArangoDB client instance

    @param options (table): Configuration options
        - endpoint (string, required): The URL of the ArangoDB server (e.g., "http://127.0.0.1:8529")
        - username (string, optional): Username for Basic authentication
        - password (string, optional): Password for Basic authentication
        - token (string, optional): JWT token for Bearer authentication
        - database (string, optional): Default database name (defaults to "_system")
        - timeout (number, optional): Request timeout in milliseconds (default: 30000)
        - keepalive (number, optional): Connection keepalive timeout in milliseconds (default: 60000)
        - pool_size (number, optional): Connection pool size (default: 100)
        - ssl_verify (boolean, optional): Verify SSL certificates (default: false)

    @return ArangoDB client instance
]]
function ArangoDB.new(options)
    options = options or {}

    -- Validate required options
    if not options.endpoint or options.endpoint == "" then
        error("ArangoDB: endpoint is required")
    end

    -- Validate authentication (either username/password or token required)
    local has_basic_auth = options.username and options.username ~= ""
    local has_token_auth = options.token and options.token ~= ""

    if not has_basic_auth and not has_token_auth then
        error("ArangoDB: authentication required (provide username/password or token)")
    end

    local self = setmetatable({}, ArangoDB)

    -- Store configuration
    self._config = {
        endpoint = options.endpoint:gsub("/$", ""), -- Remove trailing slash
        username = options.username,
        password = options.password or "",
        token = options.token,
        database = options.database or "_system",
        timeout = options.timeout or DEFAULT_CONFIG.timeout,
        keepalive = options.keepalive or DEFAULT_CONFIG.keepalive,
        pool_size = options.pool_size or DEFAULT_CONFIG.pool_size,
        ssl_verify = options.ssl_verify or DEFAULT_CONFIG.ssl_verify
    }

    -- Initialize sub-modules
    self.db = Database.new(self)
    self.collection = Collection.new(self)
    self.document = Document.new(self)
    self.index = Index.new(self)
    self.query = Query.new(self)
    self.graph = Graph.new(self)
    self.transaction = Transaction.new(self)
    self.user = User.new(self)
    self.admin = Admin.new(self)
    self.analyzer = Analyzer.new(self)
    self.view = View.new(self)
    self.foxx = Foxx.new(self)

    return self
end

--[[
    Get the current database name
    @return string
]]
function ArangoDB:getDatabase()
    return self._config.database
end

--[[
    Set/switch the current database
    @param name (string): Database name
]]
function ArangoDB:useDatabase(name)
    if not name or name == "" then
        error("ArangoDB: database name is required")
    end
    self._config.database = name
end

--[[
    Build authorization headers
    @return table: Headers with authorization
]]
function ArangoDB:_buildAuthHeaders()
    local headers = {
        ["Content-Type"] = "application/json",
        ["Accept"] = "application/json"
    }

    if self._config.token then
        headers["Authorization"] = "bearer " .. self._config.token
    elseif self._config.username then
        headers["Authorization"] = "Basic " .. base64.encode(
            self._config.username .. ":" .. self._config.password
        )
    end

    return headers
end

--[[
    Create a new HTTP client with configured settings
    @return HTTP client instance
]]
function ArangoDB:_createHttpClient()
    local httpc = http.new()
    httpc:set_timeout(self._config.timeout)
    return httpc
end

--[[
    Make an HTTP request to the ArangoDB server

    @param method (string): HTTP method (GET, POST, PUT, PATCH, DELETE)
    @param path (string): API path (e.g., "/_api/version")
    @param options (table, optional): Request options
        - body (table): Request body (will be JSON encoded)
        - query (table): Query parameters
        - headers (table): Additional headers
        - database (string): Override database for this request
        - raw_body (string): Raw body string (bypasses JSON encoding)

    @return table: Response data
    @return table: Full response object (headers, status, etc.)
]]
function ArangoDB:request(method, path, options)
    options = options or {}

    local httpc = self:_createHttpClient()
    local headers = self:_buildAuthHeaders()

    -- Merge additional headers
    if options.headers then
        for k, v in pairs(options.headers) do
            headers[k] = v
        end
    end

    -- Build URL
    local url = self._config.endpoint

    -- Add database prefix if path starts with /_db/ or if it's a database-specific endpoint
    if not path:match("^/_db/") and not path:match("^/_api/database") and
       not path:match("^/_api/version") and not path:match("^/_api/engine") and
       not path:match("^/_admin/") and not path:match("^/_api/user") then
        local db = options.database or self._config.database
        url = url .. "/_db/" .. db
    end

    url = url .. path

    -- Add query parameters
    local query_string = build_query_string(options.query)
    if query_string then
        url = url .. query_string
    end

    -- Prepare request body
    local body = nil
    if options.raw_body then
        body = options.raw_body
    elseif options.body then
        body = json.encode(options.body)
    end

    -- Make request
    local res, err = httpc:request_uri(url, {
        method = method,
        headers = headers,
        body = body,
        ssl_verify = self._config.ssl_verify
    })

    -- Set keepalive
    httpc:set_keepalive(self._config.keepalive, self._config.pool_size)

    if not res then
        error("ArangoDB request failed: " .. (err or "unknown error"))
    end

    -- Parse response
    local data = nil
    if res.body and res.body ~= "" then
        local ok, decoded = pcall(json.decode, res.body)
        if ok then
            data = decoded
        else
            data = { body = res.body }
        end
    end

    -- Check for ArangoDB errors
    if data and data.error then
        error(string.format("ArangoDB error %d: %s",
            data.errorNum or 0,
            data.errorMessage or "Unknown error"))
    end

    -- Check HTTP status
    if res.status >= 400 then
        local msg = data and data.errorMessage or res.body or "Request failed"
        error(string.format("ArangoDB HTTP %d: %s", res.status, msg))
    end

    return data, {
        status = res.status,
        headers = res.headers,
        body = res.body
    }
end

--[[
    GET request helper
]]
function ArangoDB:get(path, options)
    return self:request("GET", path, options)
end

--[[
    POST request helper
]]
function ArangoDB:post(path, body, options)
    options = options or {}
    options.body = body
    return self:request("POST", path, options)
end

--[[
    PUT request helper
]]
function ArangoDB:put(path, body, options)
    options = options or {}
    options.body = body
    return self:request("PUT", path, options)
end

--[[
    PATCH request helper
]]
function ArangoDB:patch(path, body, options)
    options = options or {}
    options.body = body
    return self:request("PATCH", path, options)
end

--[[
    DELETE request helper
]]
function ArangoDB:delete(path, options)
    return self:request("DELETE", path, options)
end

--[[
    Get server version information
    @param details (boolean, optional): Include detailed version info
    @return table: Version information
]]
function ArangoDB:version(details)
    local query = nil
    if details then
        query = { details = true }
    end
    return self:get("/_api/version", { query = query })
end

--[[
    Get server engine information
    @return table: Engine information
]]
function ArangoDB:engine()
    return self:get("/_api/engine")
end

--[[
    Check server availability (health check)
    @return boolean: true if server is available
]]
function ArangoDB:isAvailable()
    local ok, _ = pcall(function()
        return self:version()
    end)
    return ok
end

return ArangoDB
