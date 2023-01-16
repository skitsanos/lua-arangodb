local json = require("cjson")
local http = require("resty.http")
local base64 = require("base64")

local arangodb_db_query = require("arangodb-db-query")
local arangodb_db_create = require("arangodb-db-create")

local arangodb = {}
arangodb.__index = arangodb

function arangodb.new(options)
    options = options or {}
    local self = setmetatable({}, arangodb)
    self.db = {}

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
    if not options.database or options.database == "" then
        error("database name is not provided or empty")
    end

    self.username = options.username
    self.password = options.password
    self.token = options.token
    self.database = options.database
    self.endpoint = options.endpoint

    --self.db.query = function(aql)
    --    return arangodb_db_query.query(self, aql)
    --end

    self.db.query = function(aql)
        return arangodb_db_query.query(self, aql)
    end

    self.db.create = function(name)
        return arangodb_db_create.create(self, name)
    end

    return self
end

function arangodb:version()
    local httpc = http.new()
    httpc:set_timeout(3000)
    local headers = {}
    if self.token then
        headers["Authorization"] = "bearer " .. self.token
    elseif self.username and self.password then
        headers["Authorization"] = "Basic " .. base64.encode(self.username .. ":" .. self.password)
    end
    local res, err = httpc:request_uri(string.format("%s/_api/version", self.endpoint), {
        headers = headers
    })
    if not res then
        error("Failed to get version from server: " .. err)
    end
    local data = json.decode(res.body)
    return data.version
end

return arangodb