local json = require("cjson")
local http = require("resty.http")
local base64 = require("base64")

local arangodb_db_query = {}

function arangodb_db_query.query(self, aql)
    local httpc = http.new()
    httpc:set_timeout(3000)
    local headers = { ["Content-Type"] = "application/json" }

    if self.token then
        headers["Authorization"] = "bearer " .. self.token
    elseif self.username and self.password then
        headers["Authorization"] = "Basic " .. base64.encode(self.username .. ":" .. self.password)
    end

    local res, err = httpc:request_uri(string.format("%s/_db/%s/_api/cursor", self.endpoint, self.database), {
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

return arangodb_db_query