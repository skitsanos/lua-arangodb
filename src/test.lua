local arangodb = require("arangodb")
local json = require('cjson')

local client = arangodb.new({
    endpoint = "http://127.0.0.1:8529",
    username = "root",
    password = "openSesame",
    database = "debug"
})

print('You are running on ArangoDB v.' .. client:version())

print(json.encode(client.db.list()))

print(json.encode(client.db.create('demo')))
print(json.encode(client.db.drop('demo')))

local users = {}
users[1] = { username = "user1", passwd = "password1", active = true }

client.db.create(
        "my_database",
        {
            sharding = "single",
            replicationFactor = 2,
            writeConcern = 2
        },
        users
)

print(json.encode(client.db.drop('my_database')))

-- query

local success, results = pcall(function()
    return client.db.query("FOR i IN 1..10 RETURN i")
end)

if success then
    -- print the results
    for _, v in ipairs(results) do
        print(v)
    end
else
    -- print the error message
    print('ERR: ' .. results)
end


-- page size
local page_size = 25

-- starting page number
local page_num = 1

-- loop until all pages are retrieved
while true do
    -- execute a query
    local successPaginated, resultsPaginated = pcall(function()
        return client.db.query("FOR doc IN users LIMIT " .. (page_num - 1) * page_size .. ", " .. page_size .. " RETURN doc")
    end)

    if not successPaginated then
        print('ERR: ' .. resultsPaginated)
        break
    else
        -- print the results
        print('Getting results, page #' .. page_num .. ', size: ' .. #resultsPaginated)
        for _, v in ipairs(resultsPaginated) do
            print(json.encode(v))
        end

        -- if the number of returned documents is less than page size, we have reached the end
        if #resultsPaginated < page_size then
            break
        end

        -- increment page number
        page_num = page_num + 1
    end
end