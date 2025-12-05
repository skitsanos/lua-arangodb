--[[
    Module-specific test runner for lua-arangodb
    Runs tests for a specific module based on URL parameter
]]

local json = require("cjson")
local arangodb = require("arangodb")

-- Get the module to test from URL
local test_module = ngx.var.test_module

-- Test configuration
local config = {
    endpoint = os.getenv("ARANGO_ENDPOINT") or "http://arangodb:8529",
    username = os.getenv("ARANGO_USERNAME") or "root",
    password = os.getenv("ARANGO_PASSWORD") or "openSesame",
    database = os.getenv("ARANGO_DATABASE") or "_system"
}

-- Test results
local results = {
    module = test_module,
    total = 0,
    passed = 0,
    failed = 0,
    errors = {},
    tests = {}
}

-- Helper functions
local function runTest(name, testFn)
    results.total = results.total + 1
    local ok, err = pcall(testFn)
    if ok then
        results.passed = results.passed + 1
        results.tests[name] = { status = "passed" }
        ngx.say("✓ " .. name)
    else
        results.failed = results.failed + 1
        results.tests[name] = { status = "failed", error = tostring(err) }
        table.insert(results.errors, { test = name, error = tostring(err) })
        ngx.say("✗ " .. name .. ": " .. tostring(err))
    end
    ngx.flush()
end

local function assert_equal(expected, actual, message)
    if expected ~= actual then
        error(string.format("%s: expected %s, got %s",
            message or "Assertion failed", tostring(expected), tostring(actual)))
    end
end

local function assert_true(value, message)
    if not value then error(message or "Expected true") end
end

local function assert_not_nil(value, message)
    if value == nil then error(message or "Expected non-nil") end
end

local function assert_type(expected_type, value, message)
    if type(value) ~= expected_type then
        error(string.format("%s: expected %s, got %s",
            message or "Type assertion failed", expected_type, type(value)))
    end
end

-- Header
ngx.say("=" .. string.rep("=", 60))
ngx.say("Testing Module: " .. test_module)
ngx.say("=" .. string.rep("=", 60))
ngx.say("")
ngx.flush()

-- Create client
local client = arangodb.new({
    endpoint = config.endpoint,
    username = config.username,
    password = config.password,
    database = config.database
})

-- Module-specific tests
local test_collection = "test_" .. test_module .. "_" .. ngx.now()

-- ============================================================================
-- Database Module Tests
-- ============================================================================
if test_module == "database" then
    local test_db = "test_db_" .. ngx.now()

    runTest("List Databases", function()
        local dbs = client.db:list()
        assert_type("table", dbs)
    end)

    runTest("List User Databases", function()
        local dbs = client.db:listUser()
        assert_type("table", dbs)
    end)

    runTest("Get Current Database", function()
        local current = client.db:current()
        assert_not_nil(current)
        assert_not_nil(current.name)
    end)

    runTest("Create Database", function()
        local result = client.db:create(test_db)
        assert_not_nil(result)
    end)

    runTest("Database Exists", function()
        local exists = client.db:exists(test_db)
        assert_true(exists)
    end)

    runTest("Drop Database", function()
        local result = client.db:drop(test_db)
        assert_not_nil(result)
    end)

    runTest("Database Not Exists After Drop", function()
        local exists = client.db:exists(test_db)
        assert_true(not exists)
    end)

-- ============================================================================
-- Collection Module Tests
-- ============================================================================
elseif test_module == "collection" then
    runTest("Create Document Collection", function()
        local result = client.collection:createDocument(test_collection)
        assert_not_nil(result)
        assert_equal(2, result.type)
    end)

    runTest("List Collections", function()
        local cols = client.collection:list(true)
        assert_type("table", cols)
    end)

    runTest("Get Collection", function()
        local col = client.collection:get(test_collection)
        assert_equal(test_collection, col.name)
    end)

    runTest("Collection Properties", function()
        local props = client.collection:properties(test_collection)
        assert_not_nil(props)
    end)

    runTest("Collection Count", function()
        local count = client.collection:count(test_collection)
        assert_equal(0, count)
    end)

    runTest("Collection Figures", function()
        local figures = client.collection:figures(test_collection)
        assert_not_nil(figures)
    end)

    runTest("Collection Revision", function()
        local rev = client.collection:revision(test_collection)
        assert_not_nil(rev)
    end)

    runTest("Truncate Collection", function()
        local result = client.collection:truncate(test_collection)
        assert_not_nil(result)
    end)

    local edge_collection = test_collection .. "_edges"
    runTest("Create Edge Collection", function()
        local result = client.collection:createEdge(edge_collection)
        assert_not_nil(result)
        assert_equal(3, result.type)
    end)

    runTest("Drop Collections", function()
        client.collection:drop(test_collection)
        client.collection:drop(edge_collection)
    end)

-- ============================================================================
-- Document Module Tests
-- ============================================================================
elseif test_module == "document" then
    -- Setup
    client.collection:create(test_collection)

    local doc_key

    runTest("Create Document", function()
        local doc = client.document:create(test_collection, {
            name = "Test",
            value = 42
        }, { returnNew = true })
        assert_not_nil(doc._key)
        doc_key = doc._key
    end)

    runTest("Get Document", function()
        local doc = client.document:get(test_collection, doc_key)
        assert_equal("Test", doc.name)
    end)

    runTest("Document Exists", function()
        local exists = client.document:exists(test_collection, doc_key)
        assert_true(exists)
    end)

    runTest("Update Document", function()
        local doc = client.document:update(test_collection, doc_key, {
            value = 100
        }, { returnNew = true })
        assert_not_nil(doc)
    end)

    runTest("Replace Document", function()
        local doc = client.document:replace(test_collection, doc_key, {
            name = "Replaced",
            newField = true
        }, { returnNew = true })
        assert_not_nil(doc)
    end)

    runTest("Create Many Documents", function()
        local docs = client.document:createMany(test_collection, {
            { name = "A", value = 1 },
            { name = "B", value = 2 },
            { name = "C", value = 3 }
        })
        assert_equal(3, #docs)
    end)

    runTest("Delete Document", function()
        local result = client.document:delete(test_collection, doc_key)
        assert_not_nil(result)
    end)

    -- Cleanup
    client.collection:drop(test_collection)

-- ============================================================================
-- Index Module Tests
-- ============================================================================
elseif test_module == "index" then
    -- Setup
    client.collection:create(test_collection)

    runTest("List Indexes", function()
        local indexes = client.index:list(test_collection)
        assert_true(#indexes >= 1) -- Primary index
    end)

    runTest("Create Persistent Index", function()
        local idx = client.index:createPersistent(test_collection, {"field1"}, {
            name = "idx_persistent"
        })
        assert_equal("persistent", idx.type)
    end)

    runTest("Create Unique Index", function()
        local idx = client.index:createPersistent(test_collection, {"uniqueField"}, {
            name = "idx_unique",
            unique = true
        })
        assert_true(idx.unique)
    end)

    runTest("Create TTL Index", function()
        local idx = client.index:createTTL(test_collection, {"expireAt"}, 3600, {
            name = "idx_ttl"
        })
        assert_equal("ttl", idx.type)
    end)

    runTest("Create Geo Index", function()
        local idx = client.index:createGeo(test_collection, {"location"}, {
            name = "idx_geo",
            geoJson = true
        })
        assert_equal("geo", idx.type)
    end)

    runTest("Get Index", function()
        local idx = client.index:getByName(test_collection, "idx_persistent")
        assert_not_nil(idx)
    end)

    runTest("Drop Index", function()
        local idx = client.index:getByName(test_collection, "idx_persistent")
        local result = client.index:drop(idx.id)
        assert_not_nil(result)
    end)

    -- Cleanup
    client.collection:drop(test_collection)

-- ============================================================================
-- Query Module Tests
-- ============================================================================
elseif test_module == "query" then
    -- Setup
    client.collection:create(test_collection)
    for i = 1, 50 do
        client.document:create(test_collection, { num = i })
    end

    runTest("Execute Query", function()
        local results = client.query:execute("FOR i IN 1..5 RETURN i")
        assert_equal(5, #results)
    end)

    runTest("Query with Bind Vars", function()
        local results = client.query:execute(
            "FOR doc IN @@col FILTER doc.num <= @max RETURN doc",
            { ["@col"] = test_collection, max = 10 }
        )
        assert_equal(10, #results)
    end)

    runTest("Query All (pagination)", function()
        local results = client.query:all(
            "FOR doc IN @@col RETURN doc",
            { ["@col"] = test_collection },
            { batchSize = 10 }
        )
        assert_equal(50, #results)
    end)

    runTest("Query Iterator", function()
        local count = 0
        for doc in client.query:iterate("FOR i IN 1..10 RETURN i") do
            count = count + 1
        end
        assert_equal(10, count)
    end)

    runTest("Parse Query", function()
        local result = client.query:parse("FOR doc IN test RETURN doc")
        assert_not_nil(result)
    end)

    runTest("Explain Query", function()
        local result = client.query:explain(
            "FOR doc IN @@col RETURN doc",
            { ["@col"] = test_collection }
        )
        assert_not_nil(result.plan)
    end)

    runTest("Get Tracking Properties", function()
        local props = client.query:getTracking()
        assert_not_nil(props)
    end)

    -- Cleanup
    client.collection:drop(test_collection)

-- ============================================================================
-- Graph Module Tests
-- ============================================================================
elseif test_module == "graph" then
    local graph_name = "test_graph_" .. ngx.now()
    local vertex_col = "vertices_" .. ngx.now()
    local edge_col = "edges_" .. ngx.now()

    runTest("Create Graph", function()
        local graph = client.graph:create(graph_name, {
            {
                collection = edge_col,
                from = { vertex_col },
                to = { vertex_col }
            }
        })
        assert_not_nil(graph)
    end)

    runTest("List Graphs", function()
        local graphs = client.graph:list()
        assert_type("table", graphs)
    end)

    runTest("Get Graph", function()
        local graph = client.graph:get(graph_name)
        assert_equal(graph_name, graph._key)
    end)

    runTest("List Vertex Collections", function()
        local cols = client.graph:listVertexCollections(graph_name)
        assert_type("table", cols)
    end)

    local vertex1_key
    runTest("Create Vertex", function()
        local v = client.graph:createVertex(graph_name, vertex_col, {
            name = "Alice"
        })
        assert_not_nil(v._key)
        vertex1_key = v._key
    end)

    runTest("Create Edge", function()
        -- Create second vertex first
        local v2 = client.graph:createVertex(graph_name, vertex_col, {
            name = "Bob"
        })
        -- Create edge using actual document keys
        local e = client.graph:createEdge(graph_name, edge_col, {
            _from = vertex_col .. "/" .. vertex1_key,
            _to = vertex_col .. "/" .. v2._key,
            relation = "knows"
        })
        assert_not_nil(e)
    end)

    runTest("Drop Graph", function()
        local result = client.graph:drop(graph_name, true)
        assert_not_nil(result)
    end)

-- ============================================================================
-- Transaction Module Tests
-- ============================================================================
elseif test_module == "transaction" then
    -- Setup
    client.collection:create(test_collection)

    runTest("JavaScript Transaction", function()
        local result = client.transaction:execute({
            collections = { write = { test_collection } },
            params = { colName = test_collection },
            action = [[
                function(params) {
                    var db = require('@arangodb').db;
                    db._collection(params.colName).insert({ test: true });
                    return "success";
                }
            ]]
        })
        assert_equal("success", result)
    end)

    runTest("Begin Stream Transaction", function()
        local tx = client.transaction:begin({
            write = { test_collection }
        })
        assert_not_nil(tx.id)
        client.transaction:abort(tx.id)
    end)

    runTest("List Transactions", function()
        local txs = client.transaction:list()
        assert_type("table", txs)
    end)

    runTest("Transaction Run Helper", function()
        local result = client.transaction:run(
            { write = { test_collection } },
            function(txId)
                return "executed with " .. txId
            end
        )
        assert_true(result:find("executed with") ~= nil)
    end)

    -- Cleanup
    client.collection:drop(test_collection)

-- ============================================================================
-- User Module Tests
-- ============================================================================
elseif test_module == "user" then
    local test_user = "test_user_" .. ngx.now()

    runTest("List Users", function()
        local users = client.user:list()
        assert_type("table", users)
    end)

    runTest("Create User", function()
        local user = client.user:create(test_user, "testpass123", {
            active = true,
            extra = { role = "tester" }
        })
        assert_not_nil(user)
    end)

    runTest("Get User", function()
        local user = client.user:get(test_user)
        assert_equal(test_user, user.user)
    end)

    runTest("User Exists", function()
        local exists = client.user:exists(test_user)
        assert_true(exists)
    end)

    runTest("Update User", function()
        local user = client.user:update(test_user, {
            extra = { role = "updated" }
        })
        assert_not_nil(user)
    end)

    runTest("Set Database Permission", function()
        local result = client.user:setDatabasePermission(test_user, "_system", "ro")
        assert_not_nil(result)
    end)

    runTest("Get Database Permission", function()
        local perm = client.user:getDatabasePermission(test_user, "_system")
        assert_equal("ro", perm)
    end)

    runTest("Delete User", function()
        local result = client.user:delete(test_user)
        assert_not_nil(result)
    end)

-- ============================================================================
-- Admin Module Tests
-- ============================================================================
elseif test_module == "admin" then
    runTest("Get Version", function()
        local version = client.admin:version(true)
        assert_not_nil(version.version)
    end)

    runTest("Get Engine", function()
        local engine = client.admin:engine()
        assert_not_nil(engine.name)
    end)

    runTest("Get Statistics", function()
        local stats = client.admin:statistics()
        assert_not_nil(stats)
    end)

    runTest("Get Server Role", function()
        local role = client.admin:serverRole()
        assert_not_nil(role)
    end)

    runTest("Get Server Time", function()
        local time = client.admin:time()
        assert_not_nil(time.time)
    end)

    runTest("Get Log Level", function()
        local levels = client.admin:logLevel()
        assert_not_nil(levels)
    end)

    runTest("List Tasks", function()
        local tasks = client.admin:tasks()
        assert_type("table", tasks)
    end)

-- ============================================================================
-- Analyzer Module Tests
-- ============================================================================
elseif test_module == "analyzer" then
    local analyzer_name = "test_analyzer_" .. ngx.now()

    runTest("List Analyzers", function()
        local analyzers = client.analyzer:list()
        assert_type("table", analyzers)
    end)

    runTest("Create Text Analyzer", function()
        local a = client.analyzer:createText(analyzer_name, "en", {
            case = "lower",
            stemming = true
        }, {"frequency", "position"})
        assert_not_nil(a)
    end)

    runTest("Get Analyzer", function()
        local a = client.analyzer:get(analyzer_name)
        assert_equal("text", a.type)
    end)

    runTest("Delete Analyzer", function()
        local result = client.analyzer:delete(analyzer_name)
        assert_not_nil(result)
    end)

-- ============================================================================
-- View Module Tests
-- ============================================================================
elseif test_module == "view" then
    local view_name = "test_view_" .. math.floor(ngx.now() * 1000) .. "_" .. math.random(10000, 99999)

    -- Create a collection for the view
    client.collection:create(test_collection)

    runTest("List Views", function()
        local views = client.view:list()
        assert_type("table", views)
    end)

    runTest("Create ArangoSearch View", function()
        local v = client.view:createArangoSearch(view_name, {
            links = {
                [test_collection] = { includeAllFields = true }
            }
        })
        assert_not_nil(v)
    end)

    runTest("Get View", function()
        local v = client.view:get(view_name)
        assert_equal(view_name, v.name)
    end)

    runTest("View Properties", function()
        local props = client.view:properties(view_name)
        assert_not_nil(props)
    end)

    runTest("Drop View", function()
        local result = client.view:drop(view_name)
        assert_not_nil(result)
    end)

    -- Cleanup
    client.collection:drop(test_collection)

-- ============================================================================
-- Embeddings Module Tests
-- ============================================================================
elseif test_module == "embeddings" then
    local api_key = os.getenv("OPENAI_API_KEY")

    if not api_key or api_key == "" then
        ngx.say("Skipping embeddings tests: OPENAI_API_KEY not set")
    else
        local embeddings = arangodb.Embeddings.new({
            api_key = api_key
        })

        runTest("Create Single Embedding", function()
            local vector = embeddings:create("Hello world")
            assert_type("table", vector)
            assert_true(#vector > 0, "Embedding vector should not be empty")
        end)

        runTest("Create Batch Embeddings", function()
            local vectors = embeddings:createBatch({"Hello", "World"})
            assert_type("table", vectors)
            assert_equal(2, #vectors)
            assert_type("table", vectors[1])
            assert_type("table", vectors[2])
        end)

        runTest("Create With Metadata", function()
            local result = embeddings:createWithMetadata("Test text")
            assert_not_nil(result.embeddings)
            assert_not_nil(result.model)
            assert_not_nil(result.usage)
        end)

        runTest("Get Dimension", function()
            local dim = embeddings:getDimension()
            assert_type("number", dim)
            assert_true(dim > 0, "Dimension should be positive")
        end)
    end

else
    ngx.say("Unknown module: " .. test_module)
    ngx.say("Available modules: database, collection, document, index, query, graph, transaction, user, admin, analyzer, view, embeddings")
end

-- ============================================================================
-- Summary
-- ============================================================================
ngx.say("\n" .. string.rep("=", 61))
ngx.say(string.format("Results: %d passed, %d failed, %d total",
    results.passed, results.failed, results.total))
ngx.say(string.rep("=", 61))

if results.failed > 0 then
    ngx.say("\nFailed Tests:")
    for _, err in ipairs(results.errors) do
        ngx.say("  - " .. err.test .. ": " .. err.error)
    end
end
