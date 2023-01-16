local json = require("cjson")
local http = require("resty.http")
local base64 = require ("base64")

local arangodb = {}
arangodb.__index = arangodb

function arangodb.new(options)
    options = options or {}
    local self = setmetatable({}, arangodb)

    if not options.endpoint or options.endpoint == "" then
        error("Endpoint is not provided or empty")
    end
    if not options.username or options.username == "" then
        if not options.token or options.token == "" then
            error("Username and Token both are not provided or empty")
        end
    end
    if not options.password or options.password == "" then
        if not options.token or options.token == "" then
            error("Password and Token both are not provided or empty")
        end
    end
    if not options.db or options.db == "" then
        error("DB name is not provided or empty")
    end

    self.username = options.username
    self.password = options.password
    self.token = options.token
    self.db = options.db
    self.endpoint = options.endpoint
    return self
end

function arangodb:version()
    local httpc = http.new()
    httpc:set_timeout(3000)
    local headers = {}
    if self.token then
        headers["Authorization"] = "bearer ".. self.token
    elseif self.username and self.password then
        headers["Authorization"] = "Basic " .. base64.encode(self.username .. ":" .. self.password)
    end
    local res, err = httpc:request_uri(string.format("%s/_api/version", self.endpoint),{
        headers = headers
    })
    if not res then
        error("Failed to get version from server: " .. err)
    end
    local data = json.decode(res.body)
    return data.version
end

function arangodb:query(aql)
    local httpc = http.new()
    httpc:set_timeout(3000)
    local headers = { ["Content-Type"] = "application/json" }
    if self.token then
        headers["Authorization"] = "bearer ".. self.token
    elseif self.username and self.password then
        headers["Authorization"] = "Basic " .. base64.encode(self.username .. ":" .. self.password)
    end
    local res, err = httpc:request_uri(string.format("%s/_db/%s/_api/cursor", self.endpoint, self.db), {
        method = "POST",
        headers = headers,
        body = json.encode({ query = aql })
    })
    if not res then
        error("Failed to execute query: " .. err)
    end
    local data = json.decode(res.body)
    if data.error then
        error("Failed to execute query: " .. data.errorMessage)
    end
    return data.result
end


return arangodb