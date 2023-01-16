local arangodb = require("arangodb")
local json = require('cjson')

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
        return db:query("FOR doc IN users LIMIT " .. (page_num - 1) * page_size .. ", " .. page_size .. " RETURN doc")
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