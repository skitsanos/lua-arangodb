--[[
    OpenAI-compatible Embeddings Module
    Generate vector embeddings via OpenAI API or compatible endpoints (Ollama, vLLM, LocalAI, etc.)
]]

local http = require("resty.http")
local json = require("cjson")

local Embeddings = {}
Embeddings.__index = Embeddings

-- Default configuration
local DEFAULT_CONFIG = {
    base_url = "https://api.openai.com/v1",
    model = "text-embedding-3-small",
    timeout = 30000,  -- 30 seconds
    dimensions = nil, -- Use model default
    ssl_verify = false -- Disable SSL verification by default (container environments)
}

--[[
    Create a new Embeddings client

    @param options (table): Configuration options
        - api_key (string, required): API key for authentication
        - base_url (string, optional): API base URL (default: "https://api.openai.com/v1")
        - model (string, optional): Embedding model (default: "text-embedding-3-small")
        - timeout (number, optional): Request timeout in ms (default: 30000)
        - dimensions (number, optional): Output dimensions (for models that support it)
    @return Embeddings client instance
]]
function Embeddings.new(options)
    options = options or {}

    -- Get API key from options or environment
    local api_key = options.api_key
    if not api_key or api_key == "" then
        api_key = os.getenv("OPENAI_API_KEY")
    end

    if not api_key or api_key == "" then
        error("Embeddings: api_key is required (provide in options or set OPENAI_API_KEY env var)")
    end

    local self = setmetatable({}, Embeddings)

    self._config = {
        api_key = api_key,
        base_url = (options.base_url or DEFAULT_CONFIG.base_url):gsub("/$", ""),
        model = options.model or DEFAULT_CONFIG.model,
        timeout = options.timeout or DEFAULT_CONFIG.timeout,
        dimensions = options.dimensions or DEFAULT_CONFIG.dimensions,
        ssl_verify = options.ssl_verify ~= nil and options.ssl_verify or DEFAULT_CONFIG.ssl_verify
    }

    return self
end

--[[
    Create HTTP client with configured settings
    @return HTTP client instance
]]
function Embeddings:_createHttpClient()
    local httpc = http.new()
    httpc:set_timeout(self._config.timeout)
    return httpc
end

--[[
    Generate embedding for a single text

    @param text (string): Input text to embed
    @param options (table, optional): Request options
        - model (string): Override default model
        - dimensions (number): Output dimensions (for supported models)
        - encoding_format (string): "float" or "base64" (default: "float")
    @return table: Embedding vector (array of numbers)
]]
function Embeddings:create(text, options)
    if not text or text == "" then
        error("Embeddings: text is required")
    end

    options = options or {}

    local body = {
        input = text,
        model = options.model or self._config.model
    }

    -- Add optional parameters
    local dimensions = options.dimensions or self._config.dimensions
    if dimensions then
        body.dimensions = dimensions
    end

    if options.encoding_format then
        body.encoding_format = options.encoding_format
    end

    local httpc = self:_createHttpClient()
    local res, err = httpc:request_uri(self._config.base_url .. "/embeddings", {
        method = "POST",
        headers = {
            ["Content-Type"] = "application/json",
            ["Authorization"] = "Bearer " .. self._config.api_key
        },
        body = json.encode(body),
        ssl_verify = self._config.ssl_verify
    })

    if not res then
        error("Embeddings request failed: " .. (err or "unknown error"))
    end

    local data = json.decode(res.body)

    if data.error then
        error("Embeddings API error: " .. (data.error.message or json.encode(data.error)))
    end

    return data.data[1].embedding
end

--[[
    Generate embeddings for multiple texts (batch)

    @param texts (table): Array of input texts to embed
    @param options (table, optional): Request options
        - model (string): Override default model
        - dimensions (number): Output dimensions (for supported models)
        - encoding_format (string): "float" or "base64" (default: "float")
    @return table: Array of embedding vectors
]]
function Embeddings:createBatch(texts, options)
    if not texts or #texts == 0 then
        error("Embeddings: texts array is required")
    end

    options = options or {}

    local body = {
        input = texts,
        model = options.model or self._config.model
    }

    -- Add optional parameters
    local dimensions = options.dimensions or self._config.dimensions
    if dimensions then
        body.dimensions = dimensions
    end

    if options.encoding_format then
        body.encoding_format = options.encoding_format
    end

    local httpc = self:_createHttpClient()
    local res, err = httpc:request_uri(self._config.base_url .. "/embeddings", {
        method = "POST",
        headers = {
            ["Content-Type"] = "application/json",
            ["Authorization"] = "Bearer " .. self._config.api_key
        },
        body = json.encode(body),
        ssl_verify = self._config.ssl_verify
    })

    if not res then
        error("Embeddings request failed: " .. (err or "unknown error"))
    end

    local data = json.decode(res.body)

    if data.error then
        error("Embeddings API error: " .. (data.error.message or json.encode(data.error)))
    end

    -- Sort by index and extract embeddings
    local embeddings = {}
    for _, item in ipairs(data.data) do
        embeddings[item.index + 1] = item.embedding
    end

    return embeddings
end

--[[
    Generate embedding and return full response with metadata

    @param text (string|table): Input text or array of texts
    @param options (table, optional): Request options
    @return table: Full API response including usage stats
]]
function Embeddings:createWithMetadata(text, options)
    if not text then
        error("Embeddings: text is required")
    end

    options = options or {}

    local body = {
        input = text,
        model = options.model or self._config.model
    }

    local dimensions = options.dimensions or self._config.dimensions
    if dimensions then
        body.dimensions = dimensions
    end

    if options.encoding_format then
        body.encoding_format = options.encoding_format
    end

    local httpc = self:_createHttpClient()
    local res, err = httpc:request_uri(self._config.base_url .. "/embeddings", {
        method = "POST",
        headers = {
            ["Content-Type"] = "application/json",
            ["Authorization"] = "Bearer " .. self._config.api_key
        },
        body = json.encode(body),
        ssl_verify = self._config.ssl_verify
    })

    if not res then
        error("Embeddings request failed: " .. (err or "unknown error"))
    end

    local data = json.decode(res.body)

    if data.error then
        error("Embeddings API error: " .. (data.error.message or json.encode(data.error)))
    end

    return {
        embeddings = data.data,
        model = data.model,
        usage = data.usage
    }
end

--[[
    Get the dimension of embeddings for the current model
    (Makes a test request with minimal input)

    @return number: Embedding dimension
]]
function Embeddings:getDimension()
    local embedding = self:create("test")
    return #embedding
end

--[[
    List available models (OpenAI only)

    @return table: Array of model objects
]]
function Embeddings:listModels()
    local httpc = self:_createHttpClient()
    local res, err = httpc:request_uri(self._config.base_url .. "/models", {
        method = "GET",
        headers = {
            ["Authorization"] = "Bearer " .. self._config.api_key
        },
        ssl_verify = self._config.ssl_verify
    })

    if not res then
        error("List models request failed: " .. (err or "unknown error"))
    end

    local data = json.decode(res.body)

    if data.error then
        error("API error: " .. (data.error.message or json.encode(data.error)))
    end

    -- Filter for embedding models
    local embedding_models = {}
    for _, model in ipairs(data.data or {}) do
        if model.id:match("embed") then
            table.insert(embedding_models, model)
        end
    end

    return embedding_models
end

return Embeddings
