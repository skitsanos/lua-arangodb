local json = require("cjson")
local http = require("resty.http")

local arangodb = {}

function arangodb:new(options)
    -- Verify that all fields are set
    if not options.host or not options.port or not options.username or not options.password or not options.db then
        error("Missing required field in options")
    end

    -- Create a new object and set options as its properties
    local obj = { host = options.host, port = options.port, username = options.username, password = options.password, db = options.db, secure = options.secure }

    if options.token then
        obj.token = options.token
    end

    setmetatable(obj, self)
    self.__index = self
    return obj
end

function arangodb:connect()
    -- Connection code goes here
    -- Use self.host, self.port, self.username, self.password and self.db for connection
    -- Use self.token if it exists
end

function arangodb:query(aql)
    -- Execute the given AQL query on the connected ArangoDB server
    -- Use self.host, self.port, self.username, self.password and self.db for connection
    -- Use self.token if it exists
    -- Return the result of the query
end

function arangodb:version()
    local httpc = http.new()
    httpc:set_timeout(3000)
    local protocol = self.secure and "https" or "http"
    local res, err = httpc:request_uri(string.format("%s://%s:%s/_api/version", protocol, self.host, self.port),{
        headers = {
            ["Authorization"] = self.token and "bearer ".. self.token or "Basic " .. mime.b64(self.username .. ":" .. self.password)
        }
    })
    if not res then
        error("Failed to get version from server: " .. err)
    end
    local data = json.decode(res.body)
    return data.version
end


return arangodb