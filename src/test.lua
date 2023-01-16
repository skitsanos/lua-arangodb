local arangodb = require("arangodb")

local db = arangodb.new({
    endpoint = "http://127.0.0.1:8529",
    username = "root",
    password = "openSesame",
    db = "debug"
})

print('You are running on ArangoDB v.' .. db:version())

-- query

local success, results = pcall(function()
    return db:query("FOR i IN 1..10 RETURN i")
end)

if success then
    -- print the results
    for _, v in ipairs(results) do
        print(v)
    end
else
    -- print the error message
    print(results)
end

