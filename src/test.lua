local arangodb = require("arangodb")

local db = arangodb.new({
    endpoint = "http://127.0.0.1:8529",
    username = "root",
    password = "openSesame",
    db = "debug"
})

local version = db:version()
print('You are running on ArangoDB v.' .. version)

-- query

local results = db:query("FOR i IN 1..10 RETURN i")

-- print the results
for _, v in ipairs(results) do
    print(v)
end