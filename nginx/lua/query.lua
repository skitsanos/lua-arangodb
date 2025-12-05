--[[
    Interactive AQL Query Endpoint
    Execute AQL queries via HTTP POST
]]

local json = require("cjson")
local arangodb = require("arangodb")

-- Configuration
local config = {
    endpoint = os.getenv("ARANGO_ENDPOINT") or "http://arangodb:8529",
    username = os.getenv("ARANGO_USERNAME") or "root",
    password = os.getenv("ARANGO_PASSWORD") or "openSesame",
    database = os.getenv("ARANGO_DATABASE") or "_system"
}

-- Handle GET requests - show form
if ngx.req.get_method() == "GET" then
    ngx.header["Content-Type"] = "text/html"
    ngx.say([[
<!DOCTYPE html>
<html>
<head>
    <title>AQL Query</title>
    <style>
        body { font-family: monospace; max-width: 800px; margin: 40px auto; padding: 0 20px; }
        textarea { width: 100%; height: 200px; font-family: monospace; }
        button { padding: 10px 20px; margin-top: 10px; }
        pre { background: #f4f4f4; padding: 15px; overflow-x: auto; }
        .error { color: red; }
    </style>
</head>
<body>
    <h1>AQL Query</h1>
    <form method="POST">
        <label>Database:</label>
        <input type="text" name="database" value="_system" style="width: 200px;"><br><br>
        <label>Query:</label><br>
        <textarea name="query" placeholder="FOR doc IN collection RETURN doc"></textarea><br>
        <label>Bind Variables (JSON):</label><br>
        <textarea name="bindVars" style="height: 80px;" placeholder='{"@collection": "users"}'></textarea><br>
        <button type="submit">Execute</button>
    </form>
</body>
</html>
    ]])
    return
end

-- Handle POST requests - execute query
ngx.req.read_body()
local body = ngx.req.get_body_data()
local args = ngx.req.get_post_args()

-- Parse JSON body if present
local query, bindVars, database

if body and body:sub(1,1) == "{" then
    local ok, parsed = pcall(json.decode, body)
    if ok then
        query = parsed.query
        bindVars = parsed.bindVars
        database = parsed.database
    end
else
    query = args.query
    database = args.database
    if args.bindVars and args.bindVars ~= "" then
        local ok, parsed = pcall(json.decode, args.bindVars)
        if ok then
            bindVars = parsed
        end
    end
end

-- Validate
if not query or query == "" then
    ngx.status = ngx.HTTP_BAD_REQUEST
    ngx.header["Content-Type"] = "application/json"
    ngx.say(json.encode({ error = true, message = "Query is required" }))
    return
end

-- Create client
local client = arangodb.new({
    endpoint = config.endpoint,
    username = config.username,
    password = config.password,
    database = database or config.database
})

-- Execute query
local ok, result, cursor = pcall(function()
    return client.query:execute(query, bindVars, { count = true })
end)

ngx.header["Content-Type"] = "application/json"

if ok then
    ngx.say(json.encode({
        error = false,
        result = result,
        count = cursor and cursor.count,
        hasMore = cursor and cursor.hasMore,
        cached = cursor and cursor.cached
    }))
else
    ngx.status = ngx.HTTP_BAD_REQUEST
    ngx.say(json.encode({
        error = true,
        message = tostring(result)
    }))
end
