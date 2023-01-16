local json = require("cjson")
local http = require("resty.http")
local base64 = require("base64")

local arangodb_db_list = {}

function arangodb_db_list.list(self)
    local httpc = http.new()
    httpc:set_timeout(3000)
    local headers = { ["Content-Type"] = "application/json" }
    if self.token then
        headers["Authorization"] = "bearer ".. self.token
    elseif self.username and self.password then
        headers["Authorization"] = "Basic " .. base64.encode(self.username .. ":" .. self.password)
    end
    local res, err = httpc:request_uri(string.format("%s/_api/database", self.endpoint), {
        method = "GET",
        headers = headers
    })
    if not res then
        error("Failed to list databases: " .. err)
    end
    local data = json.decode(res.body)
    if data.error then
        error("Failed to list databases: " .. data.errorMessage)
    end
    return data.result
end

return arangodb_db_list
