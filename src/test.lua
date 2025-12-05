--[[
    Test script for lua-arangodb client
    Run with: resty -I /path/to/src src/test.lua
]]

local arangodb = require("arangodb")
local json = require("cjson")

-- Create client
local client = arangodb.new({
    endpoint = "http://127.0.0.1:8529",
    username = "root",
    password = "openSesame",
    database = "_system"
})

print("=== ArangoDB Client Test ===\n")

-- Server info
local version = client:version()
print("Server version: " .. version.version)
print("Server: " .. version.server)
print("License: " .. version.license)

local engine = client:engine()
print("Storage engine: " .. engine.name)

-- Database operations
print("\n--- Database Operations ---")
local databases = client.db:list()
print("Databases: " .. json.encode(databases))

-- Create test database
local test_db = "lua_test_" .. os.time()
print("Creating database: " .. test_db)
client.db:create(test_db)

-- Switch to test database
client:useDatabase(test_db)
print("Switched to database: " .. client:getDatabase())

-- Collection operations
print("\n--- Collection Operations ---")
local col_name = "test_collection"
print("Creating collection: " .. col_name)
client.collection:create(col_name)

local collections = client.collection:list(true)
print("Collections: " .. json.encode(collections))

-- Document operations
print("\n--- Document Operations ---")

-- Create single document
local doc = client.document:create(col_name, {
    name = "Alice",
    age = 30,
    email = "alice@example.com"
}, { returnNew = true })
print("Created document: " .. doc._key)

-- Create multiple documents
local docs = client.document:createMany(col_name, {
    { name = "Bob", age = 25 },
    { name = "Charlie", age = 35 },
    { name = "Diana", age = 28 }
})
print("Created " .. #docs .. " documents")

-- Get document
local retrieved = client.document:get(col_name, doc._key)
print("Retrieved: " .. json.encode(retrieved))

-- Update document
client.document:update(col_name, doc._key, {
    age = 31,
    updated = true
})
print("Updated document")

-- Query operations
print("\n--- Query Operations ---")

-- Simple query
local results = client.query:execute(
    "FOR doc IN @@collection RETURN doc",
    { ["@collection"] = col_name }
)
print("Query returned " .. #results .. " documents")

-- Query with filter
local filtered = client.query:execute(
    "FOR doc IN @@collection FILTER doc.age >= @minAge RETURN doc",
    { ["@collection"] = col_name, minAge = 30 }
)
print("Filtered query returned " .. #filtered .. " documents")

-- Query with pagination (all results)
local all_results = client.query:all(
    "FOR i IN 1..100 RETURN i",
    nil,
    { batchSize = 25 }
)
print("Paginated query returned " .. #all_results .. " results")

-- Index operations
print("\n--- Index Operations ---")

local indexes = client.index:list(col_name)
print("Indexes: " .. #indexes)

-- Create persistent index
local idx = client.index:createPersistent(col_name, {"name"}, {
    name = "idx_name",
    unique = false
})
print("Created index: " .. idx.name .. " (type: " .. idx.type .. ")")

-- Transaction operations
print("\n--- Transaction Operations ---")

-- JavaScript transaction
local tx_result = client.transaction:execute({
    collections = { read = { col_name } },
    action = [[
        function() {
            var db = require('@arangodb').db;
            return db._query('FOR doc IN ]] .. col_name .. [[ RETURN 1').toArray().length;
        }
    ]]
})
print("Transaction result: " .. tostring(tx_result))

-- Stream transaction
local tx = client.transaction:begin({ write = { col_name } })
print("Started stream transaction: " .. tx.id)

local status = client.transaction:status(tx.id)
print("Transaction status: " .. status.status)

client.transaction:abort(tx.id)
print("Aborted transaction")

-- Cleanup
print("\n--- Cleanup ---")

-- Delete document
client.document:delete(col_name, doc._key)
print("Deleted document")

-- Drop collection
client.collection:drop(col_name)
print("Dropped collection")

-- Switch back to _system and drop test database
client:useDatabase("_system")
client.db:drop(test_db)
print("Dropped database: " .. test_db)

print("\n=== All tests completed successfully! ===")
