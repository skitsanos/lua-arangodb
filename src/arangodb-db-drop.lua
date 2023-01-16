local json = require("cjson")
local http = require("resty.http")
local base64 = require("base64")

local arangodb_db_drop = {}

function arangodb_db_drop.drop(self, name)
    local httpc = http.new()
    httpc:set_timeout(3000)
    local headers = { ["Content-Type"] = "application/json" }
    if self.token then
        headers["Authorization"] = "bearer ".. self.token
    elseif self.username and self.password then
        headers["Authorization"] = "Basic " .. base64.encode(self.username .. ":" .. self.password)
    end
    local res, err = httpc:request_uri(string.format("%s/_api/database/%s", self.endpoint, name), {
        method = "DELETE",
        headers = headers
    })
    if not res then
        error("Failed to drop database: " .. err)
    end
    local data = json.decode(res.body)
    if data.error then
        error("Failed to drop database: " .. data.errorMessage)
    end
    return data
end

return arangodb_db_drop
