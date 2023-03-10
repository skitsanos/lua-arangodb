local json = require("cjson")
local http = require("resty.http")
local base64 = require("base64")

local arangodb_db_create = {}

function arangodb_db_create.create(self, name, options, users)
    local httpc = http.new()
    httpc:set_timeout(3000)
    local headers = { ["Content-Type"] = "application/json" }
    if self.token then
        headers["Authorization"] = "bearer ".. self.token
    elseif self.username and self.password then
        headers["Authorization"] = "Basic " .. base64.encode(self.username .. ":" .. self.password)
    end
    local payload = { name = name }
    if options then
        payload.options = options
    end
    if users then
        payload.users = users
    end
    local res, err = httpc:request_uri(string.format("%s/_api/database", self.endpoint), {
        method = "POST",
        headers = headers,
        body = json.encode(payload)
    })
    if not res then
        error("Failed to create database: " .. err)
    end
    local data = json.decode(res.body)
    if data.error then
        error("Failed to create database: " .. data.errorMessage)
    end
    return data
end

return arangodb_db_create
