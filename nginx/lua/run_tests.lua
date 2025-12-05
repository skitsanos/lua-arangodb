--[[
    Test Runner for lua-arangodb
    Runs all module tests and reports results
]]

local json = require("cjson")
local arangodb = require("arangodb")

-- Test configuration
local config = {
    endpoint = os.getenv("ARANGO_ENDPOINT") or "http://arangodb:8529",
    username = os.getenv("ARANGO_USERNAME") or "root",
    password = os.getenv("ARANGO_PASSWORD") or "openSesame",
    database = os.getenv("ARANGO_DATABASE") or "_system"
}

-- Test results
local results = {
    total = 0,
    passed = 0,
    failed = 0,
    errors = {},
    tests = {}
}

-- Helper function to run a test
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

-- Helper function to assert
local function assert_equal(expected, actual, message)
    if expected ~= actual then
        error(string.format("%s: expected %s, got %s",
            message or "Assertion failed",
            tostring(expected),
            tostring(actual)))
    end
end

local function assert_true(value, message)
    if not value then
        error(message or "Expected true but got false")
    end
end

local function assert_not_nil(value, message)
    if value == nil then
        error(message or "Expected non-nil value")
    end
end

local function assert_type(expected_type, value, message)
    if type(value) ~= expected_type then
        error(string.format("%s: expected type %s, got %s",
            message or "Type assertion failed",
            expected_type,
            type(value)))
    end
end

-- Start tests
ngx.say("=" .. string.rep("=", 60))
ngx.say("lua-arangodb Test Suite")
ngx.say("=" .. string.rep("=", 60))
ngx.say("")
ngx.say("Configuration:")
ngx.say("  Endpoint: " .. config.endpoint)
ngx.say("  Username: " .. config.username)
ngx.say("  Database: " .. config.database)
ngx.say("")
ngx.flush()

-- Create client
local client
runTest("Client Creation", function()
    client = arangodb.new({
        endpoint = config.endpoint,
        username = config.username,
        password = config.password,
        database = config.database
    })
    assert_not_nil(client, "Client should be created")
end)

if not client then
    ngx.say("\nFATAL: Could not create client. Aborting tests.")
    ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
    return
end

-- ============================================================================
-- Server Tests
-- ============================================================================
ngx.say("\n--- Server Tests ---")
ngx.flush()

runTest("Get Server Version", function()
    local version = client:version()
    assert_not_nil(version, "Version should not be nil")
    assert_not_nil(version.version, "Version string should exist")
    ngx.say("    Server version: " .. version.version)
end)

runTest("Get Engine Info", function()
    local engine = client:engine()
    assert_not_nil(engine, "Engine info should not be nil")
    assert_not_nil(engine.name, "Engine name should exist")
    ngx.say("    Engine: " .. engine.name)
end)

runTest("Server Availability", function()
    local available = client:isAvailable()
    assert_true(available, "Server should be available")
end)

-- ============================================================================
-- Database Tests
-- ============================================================================
ngx.say("\n--- Database Tests ---")
ngx.flush()

local test_db_name = "lua_arangodb_test_" .. ngx.now()

runTest("List Databases", function()
    local databases = client.db:list()
    assert_type("table", databases, "Databases should be a table")
    assert_true(#databases > 0, "Should have at least one database")
end)

runTest("Get Current Database", function()
    local current = client.db:current()
    assert_not_nil(current, "Current database info should exist")
    assert_not_nil(current.name, "Database name should exist")
end)

runTest("Create Database", function()
    local result = client.db:create(test_db_name)
    assert_not_nil(result, "Create result should not be nil")
end)

runTest("Database Exists", function()
    local exists = client.db:exists(test_db_name)
    assert_true(exists, "Test database should exist")
end)

runTest("Drop Database", function()
    local result = client.db:drop(test_db_name)
    assert_not_nil(result, "Drop result should not be nil")
end)

-- ============================================================================
-- Collection Tests
-- ============================================================================
ngx.say("\n--- Collection Tests ---")
ngx.flush()

local test_collection = "test_collection_" .. ngx.now()

runTest("Create Collection", function()
    local result = client.collection:create(test_collection)
    assert_not_nil(result, "Create result should not be nil")
    assert_equal(test_collection, result.name, "Collection name should match")
end)

runTest("Collection Exists", function()
    local exists = client.collection:exists(test_collection)
    assert_true(exists, "Test collection should exist")
end)

runTest("List Collections", function()
    local collections = client.collection:list(true)
    assert_type("table", collections, "Collections should be a table")
end)

runTest("Get Collection Properties", function()
    local props = client.collection:properties(test_collection)
    assert_not_nil(props, "Properties should not be nil")
    assert_equal(test_collection, props.name, "Collection name should match")
end)

runTest("Get Collection Count", function()
    local count = client.collection:count(test_collection)
    assert_equal(0, count, "New collection should have 0 documents")
end)

-- ============================================================================
-- Document Tests
-- ============================================================================
ngx.say("\n--- Document Tests ---")
ngx.flush()

local test_doc_key

runTest("Create Document", function()
    local doc = client.document:create(test_collection, {
        name = "Test Document",
        value = 42,
        tags = {"test", "lua"}
    }, { returnNew = true })
    assert_not_nil(doc, "Document should be created")
    assert_not_nil(doc._key, "Document should have _key")
    test_doc_key = doc._key
end)

runTest("Get Document", function()
    local doc = client.document:get(test_collection, test_doc_key)
    assert_not_nil(doc, "Document should be retrieved")
    assert_equal("Test Document", doc.name, "Document name should match")
    assert_equal(42, doc.value, "Document value should match")
end)

runTest("Document Exists", function()
    local exists = client.document:exists(test_collection, test_doc_key)
    assert_true(exists, "Document should exist")
end)

runTest("Update Document", function()
    local doc = client.document:update(test_collection, test_doc_key, {
        value = 100,
        updated = true
    }, { returnNew = true })
    assert_not_nil(doc, "Update result should not be nil")
end)

runTest("Create Multiple Documents", function()
    local docs = client.document:createMany(test_collection, {
        { name = "Doc 1", value = 1 },
        { name = "Doc 2", value = 2 },
        { name = "Doc 3", value = 3 }
    })
    assert_type("table", docs, "Result should be a table")
    assert_equal(3, #docs, "Should create 3 documents")
end)

-- ============================================================================
-- Query Tests
-- ============================================================================
ngx.say("\n--- Query Tests ---")
ngx.flush()

runTest("Execute AQL Query", function()
    local results = client.query:execute(
        "FOR doc IN @@collection LIMIT 10 RETURN doc",
        { ["@collection"] = test_collection }
    )
    assert_type("table", results, "Results should be a table")
    assert_true(#results >= 1, "Should have at least 1 result")
end)

runTest("Execute Query with Bind Vars", function()
    local results = client.query:execute(
        "FOR doc IN @@collection FILTER doc.value >= @minValue RETURN doc",
        { ["@collection"] = test_collection, minValue = 2 }
    )
    assert_type("table", results, "Results should be a table")
end)

runTest("Query All (auto-pagination)", function()
    local results = client.query:all(
        "FOR i IN 1..100 RETURN i",
        nil,
        { batchSize = 10 }
    )
    assert_equal(100, #results, "Should return all 100 results")
end)

runTest("Parse Query", function()
    local result = client.query:parse("FOR doc IN test RETURN doc")
    assert_not_nil(result, "Parse result should not be nil")
end)

runTest("Explain Query", function()
    local result = client.query:explain(
        "FOR doc IN @@collection RETURN doc",
        { ["@collection"] = test_collection }
    )
    assert_not_nil(result, "Explain result should not be nil")
    assert_not_nil(result.plan, "Should have execution plan")
end)

-- ============================================================================
-- Index Tests
-- ============================================================================
ngx.say("\n--- Index Tests ---")
ngx.flush()

runTest("List Indexes", function()
    local indexes = client.index:list(test_collection)
    assert_type("table", indexes, "Indexes should be a table")
    assert_true(#indexes >= 1, "Should have at least primary index")
end)

runTest("Create Persistent Index", function()
    local idx = client.index:createPersistent(test_collection, {"value"}, {
        name = "idx_value",
        sparse = false
    })
    assert_not_nil(idx, "Index should be created")
    assert_equal("persistent", idx.type, "Index type should be persistent")
end)

runTest("Create TTL Index", function()
    local idx = client.index:createTTL(test_collection, {"expireAt"}, 3600, {
        name = "idx_ttl"
    })
    assert_not_nil(idx, "TTL index should be created")
    assert_equal("ttl", idx.type, "Index type should be ttl")
end)

runTest("Get Index By Name", function()
    local idx = client.index:getByName(test_collection, "idx_value")
    assert_not_nil(idx, "Index should be found")
    assert_equal("idx_value", idx.name, "Index name should match")
end)

-- ============================================================================
-- Transaction Tests
-- ============================================================================
ngx.say("\n--- Transaction Tests ---")
ngx.flush()

runTest("Execute JavaScript Transaction", function()
    local result = client.transaction:execute({
        collections = {
            read = { test_collection }
        },
        action = [[
            function() {
                var db = require('@arangodb').db;
                return db._query('RETURN 1').toArray()[0];
            }
        ]]
    })
    assert_equal(1, result, "Transaction should return 1")
end)

runTest("Stream Transaction", function()
    local tx = client.transaction:begin({
        write = { test_collection }
    })
    assert_not_nil(tx, "Transaction should begin")
    assert_not_nil(tx.id, "Transaction should have ID")

    local status = client.transaction:status(tx.id)
    assert_equal("running", status.status, "Transaction should be running")

    client.transaction:abort(tx.id)
end)

-- ============================================================================
-- Cleanup
-- ============================================================================
ngx.say("\n--- Cleanup ---")
ngx.flush()

runTest("Delete Document", function()
    local result = client.document:delete(test_collection, test_doc_key)
    assert_not_nil(result, "Delete result should not be nil")
end)

runTest("Truncate Collection", function()
    local result = client.collection:truncate(test_collection)
    assert_not_nil(result, "Truncate result should not be nil")
end)

runTest("Drop Collection", function()
    local result = client.collection:drop(test_collection)
    assert_not_nil(result, "Drop result should not be nil")
end)

-- ============================================================================
-- Summary
-- ============================================================================
ngx.say("\n" .. string.rep("=", 61))
ngx.say(string.format("Test Results: %d passed, %d failed, %d total",
    results.passed, results.failed, results.total))
ngx.say(string.rep("=", 61))

if results.failed > 0 then
    ngx.say("\nFailed Tests:")
    for _, err in ipairs(results.errors) do
        ngx.say("  - " .. err.test .. ": " .. err.error)
    end
end

ngx.say("\nDone.")
