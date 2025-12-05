# ArangoDB Client for OpenResty/Lua

A comprehensive, modular ArangoDB client library for OpenResty/Lua with full HTTP API support.

## Features

- Full ArangoDB HTTP API coverage
- Modular architecture with separate modules for each API area
- Connection pooling and keepalive support
- Both Basic and JWT authentication
- AQL query execution with cursor pagination
- Stream transactions support
- Graph operations (Gharial API)
- ArangoSearch views and analyzers
- Foxx microservices management
- User and permission management
- Cluster operations support

## Installation

### Dependencies

```shell
luarocks install lua-cjson
luarocks install lbase64
luarocks install lua-resty-http
```

### Manual Installation

Copy the `src/arangodb` folder to your Lua package path.

## Quick Start

```lua
local arangodb = require("arangodb")

-- Create client
local client = arangodb.new({
    endpoint = "http://127.0.0.1:8529",
    username = "root",
    password = "password",
    database = "_system"
})

-- Get server version
local version = client:version()
print("ArangoDB " .. version.version)

-- Execute AQL query
local results = client.query:execute(
    "FOR doc IN users FILTER doc.age >= @minAge RETURN doc",
    { minAge = 21 }
)

-- Create a document
local doc = client.document:create("users", {
    name = "Alice",
    age = 30
})
```

## Configuration

```lua
local client = arangodb.new({
    -- Required
    endpoint = "http://127.0.0.1:8529",  -- ArangoDB server URL

    -- Authentication (one of these is required)
    username = "root",                    -- Basic auth username
    password = "password",                -- Basic auth password
    -- OR
    token = "jwt-token",                  -- JWT bearer token

    -- Optional
    database = "_system",                 -- Default database (default: "_system")
    timeout = 30000,                      -- Request timeout in ms (default: 30000)
    keepalive = 60000,                    -- Keepalive timeout in ms (default: 60000)
    pool_size = 100,                      -- Connection pool size (default: 100)
    ssl_verify = false                    -- Verify SSL certificates (default: false)
})
```

## API Reference

### Client Methods

```lua
-- Get server version
client:version(details)              -- details: include detailed info

-- Get storage engine info
client:engine()

-- Check server availability
client:isAvailable()

-- Switch database
client:useDatabase(name)
client:getDatabase()

-- Raw HTTP methods
client:get(path, options)
client:post(path, body, options)
client:put(path, body, options)
client:patch(path, body, options)
client:delete(path, options)
```

### Database Operations (`client.db`)

```lua
-- List databases
client.db:list()                     -- All databases
client.db:listUser()                 -- User-accessible databases
client.db:current()                  -- Current database info
client.db:exists(name)               -- Check if database exists

-- Create database
client.db:create(name, options, users)

-- Drop database
client.db:drop(name)

-- Shorthand query (uses client.query:execute)
client.db:query(aql, bindVars, options)
```

### Collection Operations (`client.collection`)

```lua
-- List collections
client.collection:list(excludeSystem)

-- Get collection info
client.collection:get(name)
client.collection:properties(name)
client.collection:exists(name)
client.collection:count(name)
client.collection:figures(name)
client.collection:revision(name)

-- Create collections
client.collection:create(name, options)
client.collection:createDocument(name, options)  -- type = 2
client.collection:createEdge(name, options)      -- type = 3

-- Modify collections
client.collection:rename(name, newName)
client.collection:setProperties(name, properties)
client.collection:truncate(name)
client.collection:drop(name, isSystem)

-- Memory management
client.collection:load(name)
client.collection:unload(name)
client.collection:loadIndexes(name)
client.collection:compact(name)
```

### Document Operations (`client.document`)

```lua
-- Read documents
client.document:get(collection, key, options)
client.document:exists(collection, key)
client.document:head(collection, key)
client.document:getMany(collection, keys, options)

-- Create documents
client.document:create(collection, document, options)
client.document:createMany(collection, documents, options)

-- Update documents
client.document:update(collection, key, document, options)
client.document:updateMany(collection, documents, options)

-- Replace documents
client.document:replace(collection, key, document, options)
client.document:replaceMany(collection, documents, options)

-- Delete documents
client.document:delete(collection, key, options)
client.document:deleteMany(collection, keys, options)

-- Import/Export
client.document:import(collection, documents, options)
client.document:export(collection, options)
```

#### Document Options

```lua
{
    waitForSync = true,      -- Wait for sync to disk
    returnNew = true,        -- Return new document
    returnOld = true,        -- Return old document
    silent = false,          -- Don't return metadata
    overwrite = false,       -- Overwrite existing
    overwriteMode = "update", -- "ignore", "update", "replace", "conflict"
    keepNull = true,         -- Keep null values in updates
    mergeObjects = true,     -- Merge nested objects
    ifMatch = "rev",         -- Conditional by revision
}
```

### Query Operations (`client.query`)

```lua
-- Execute queries
local results, cursor = client.query:execute(aql, bindVars, options)
local all_results = client.query:all(aql, bindVars, options)  -- Auto-pagination

-- Cursor operations
client.query:next(cursorId)
client.query:deleteCursor(cursorId)

-- Iterator for large result sets
for doc in client.query:iterate(aql, bindVars, options) do
    print(doc.name)
end

-- Query analysis
client.query:parse(aql, options)
client.query:explain(aql, bindVars, options)

-- Running queries
client.query:listRunning(all)
client.query:kill(queryId)

-- Slow query log
client.query:listSlow(all)
client.query:clearSlow(all)

-- Query tracking
client.query:getTracking()
client.query:setTracking(properties)

-- Query cache
client.query:getCacheProperties()
client.query:setCacheProperties(properties)
client.query:getCacheEntries()
client.query:clearCache()

-- AQL functions
client.query:functions(namespace)
client.query:createFunction(name, code, isDeterministic)
client.query:deleteFunction(name, group)

-- Optimizer rules
client.query:rules()
```

#### Query Options

```lua
{
    count = true,            -- Return total count
    batchSize = 1000,        -- Batch size for cursor
    ttl = 30,                -- Cursor TTL in seconds
    cache = true,            -- Use query cache
    memoryLimit = 0,         -- Memory limit in bytes
    fullCount = true,        -- Return full count (with LIMIT)
    stream = true,           -- Stream results
    profile = 2,             -- Profile level (0, 1, 2)
    maxRuntime = 60,         -- Max runtime in seconds
}
```

### Index Operations (`client.index`)

```lua
-- List indexes
client.index:list(collection, withStats, withHidden)
client.index:get(indexId)
client.index:getByName(collection, indexName)
client.index:exists(indexId)

-- Create indexes
client.index:create(collection, definition)
client.index:createPersistent(collection, fields, options)
client.index:createGeo(collection, fields, options)
client.index:createFulltext(collection, fields, options)  -- Deprecated
client.index:createTTL(collection, fields, expireAfter, options)
client.index:createZKD(collection, fields, options)
client.index:createMDI(collection, fields, options)
client.index:createInverted(collection, fields, options)

-- Drop index
client.index:drop(indexId)

-- Ensure index exists
local idx, created = client.index:ensure(collection, definition)
```

### Graph Operations (`client.graph`)

```lua
-- Graph management
client.graph:list()
client.graph:get(name)
client.graph:exists(name)
client.graph:create(name, edgeDefinitions, options)
client.graph:drop(name, dropCollections)

-- Vertex collections
client.graph:listVertexCollections(graphName)
client.graph:addVertexCollection(graphName, collection, options)
client.graph:removeVertexCollection(graphName, collection, dropCollection)

-- Edge definitions
client.graph:listEdgeDefinitions(graphName)
client.graph:addEdgeDefinition(graphName, definition, options)
client.graph:replaceEdgeDefinition(graphName, edgeCollection, definition, options)
client.graph:removeEdgeDefinition(graphName, edgeCollection, options)

-- Vertex CRUD
client.graph:getVertex(graphName, collection, key, options)
client.graph:createVertex(graphName, collection, vertex, options)
client.graph:updateVertex(graphName, collection, key, vertex, options)
client.graph:replaceVertex(graphName, collection, key, vertex, options)
client.graph:deleteVertex(graphName, collection, key, options)

-- Edge CRUD
client.graph:getEdge(graphName, collection, key, options)
client.graph:createEdge(graphName, collection, edge, options)
client.graph:updateEdge(graphName, collection, key, edge, options)
client.graph:replaceEdge(graphName, collection, key, edge, options)
client.graph:deleteEdge(graphName, collection, key, options)

-- Traversal
client.graph:traverse(startVertex, options)
```

### Transaction Operations (`client.transaction`)

```lua
-- JavaScript transaction (single request)
local result = client.transaction:execute({
    collections = { read = {"col1"}, write = {"col2"} },
    params = { userId = "123", amount = 50 },
    action = [[
        function(params) {
            var db = require('@arangodb').db;
            var user = db.col1.document(params.userId);
            db.col2.insert({ debit: params.amount, user: user._key });
            return "success";
        }
    ]]
})

-- Stream transactions (multi-request)
local tx = client.transaction:begin(collections, options)
local status = client.transaction:status(tx.id)
client.transaction:commit(tx.id)
client.transaction:abort(tx.id)
client.transaction:list()

-- Transaction helper (auto commit/abort)
client.transaction:run(collections, function(txId)
    -- Operations here
    return result
end, options)

-- Transaction-aware operations
client.transaction:query(txId, aql, bindVars, options)
client.transaction:createDocument(txId, collection, document, options)
client.transaction:updateDocument(txId, collection, key, document, options)
client.transaction:deleteDocument(txId, collection, key, options)
```

### User Operations (`client.user`)

```lua
-- User management
client.user:list()
client.user:get(username)
client.user:exists(username)
client.user:create(username, password, options)
client.user:update(username, options)
client.user:replace(username, password, options)
client.user:delete(username)

-- Database permissions
client.user:getDatabasePermission(username, database)
client.user:setDatabasePermission(username, database, permission)
client.user:clearDatabasePermission(username, database)
client.user:listDatabasePermissions(username, full)

-- Collection permissions
client.user:getCollectionPermission(username, database, collection)
client.user:setCollectionPermission(username, database, collection, permission)
client.user:clearCollectionPermission(username, database, collection)

-- Convenience methods
client.user:grantDatabase(username, database)           -- rw
client.user:grantDatabaseReadOnly(username, database)   -- ro
client.user:revokeDatabase(username, database)          -- none
client.user:grantCollection(username, database, collection)
client.user:grantCollectionReadOnly(username, database, collection)
client.user:revokeCollection(username, database, collection)
```

### Admin Operations (`client.admin`)

```lua
-- Server info
client.admin:version(details)
client.admin:engine()
client.admin:serverId()
client.admin:serverRole()
client.admin:serverAvailability()
client.admin:serverMode()
client.admin:setServerMode(mode)

-- Statistics
client.admin:statistics()
client.admin:statisticsDescription()
client.admin:metrics(serverId)

-- Logs
client.admin:logs(options)
client.admin:logLevel(serverId)
client.admin:setLogLevel(levels, serverId)

-- Cluster operations
client.admin:clusterHealth()
client.admin:clusterEndpoints()
client.admin:clusterStatistics(dbserver)
client.admin:maintenance(serverId, mode, options)
client.admin:cleanOutServer(serverId)
client.admin:moveShard(options)
client.admin:rebalanceShards(options)

-- Async jobs
client.admin:jobs(status, count)
client.admin:jobResult(jobId)
client.admin:cancelJob(jobId)
client.admin:deleteJobs(jobType, stamp)

-- Tasks
client.admin:tasks()
client.admin:task(taskId)
client.admin:createTask(options)
client.admin:deleteTask(taskId)

-- Misc
client.admin:time()
client.admin:shutdown(soft)
client.admin:compact(options)
```

### Analyzer Operations (`client.analyzer`)

```lua
-- Analyzer management
client.analyzer:list()
client.analyzer:get(name)
client.analyzer:exists(name)
client.analyzer:create(name, type, properties, features)
client.analyzer:delete(name, force)

-- Type-specific creators
client.analyzer:createIdentity(name, features)
client.analyzer:createDelimiter(name, delimiter, features)
client.analyzer:createStem(name, locale, features)
client.analyzer:createNorm(name, locale, options, features)
client.analyzer:createNgram(name, options, features)
client.analyzer:createText(name, locale, options, features)
client.analyzer:createAQL(name, queryString, options, features)
client.analyzer:createPipeline(name, pipeline, features)
client.analyzer:createStopwords(name, stopwords, options, features)
client.analyzer:createCollation(name, locale, features)
client.analyzer:createGeoJSON(name, options, features)
client.analyzer:createGeoPoint(name, options, features)
```

### View Operations (`client.view`)

```lua
-- View management
client.view:list()
client.view:get(name)
client.view:properties(name)
client.view:exists(name)
client.view:drop(name)
client.view:rename(name, newName)

-- Create views
client.view:create(name, type, properties)
client.view:createArangoSearch(name, options)
client.view:createSearchAlias(name, indexes)
client.view:createSimple(name, collection, options)

-- Modify views
client.view:updateProperties(name, properties)
client.view:replaceProperties(name, properties)

-- Link management (ArangoSearch)
client.view:addLink(viewName, collection, linkOptions)
client.view:removeLink(viewName, collection)
client.view:updateLink(viewName, collection, linkOptions)

-- Index management (search-alias)
client.view:addIndex(viewName, collection, indexName)
client.view:removeIndex(viewName, collection, indexName)
```

### Foxx Operations (`client.foxx`)

```lua
-- Service management
client.foxx:list(excludeSystem)
client.foxx:get(mount)
client.foxx:exists(mount)
client.foxx:installFromUrl(mount, source, options)
client.foxx:installFromPath(mount, path, options)
client.foxx:installFromZip(mount, zipData, options)
client.foxx:replace(mount, source, options)
client.foxx:upgrade(mount, source, options)
client.foxx:uninstall(mount, options)

-- Configuration
client.foxx:getConfiguration(mount)
client.foxx:updateConfiguration(mount, configuration)
client.foxx:replaceConfiguration(mount, configuration)

-- Dependencies
client.foxx:getDependencies(mount)
client.foxx:updateDependencies(mount, dependencies)
client.foxx:replaceDependencies(mount, dependencies)

-- Development mode
client.foxx:enableDevelopment(mount)
client.foxx:disableDevelopment(mount)

-- Scripts
client.foxx:listScripts(mount)
client.foxx:runScript(mount, scriptName, args)

-- Other
client.foxx:readme(mount)
client.foxx:swagger(mount)
client.foxx:download(mount)
client.foxx:runTests(mount, options)
```

## Testing with Docker/Podman

The project includes a docker-compose setup for testing:

```shell
# Start ArangoDB and OpenResty
podman-compose up -d
# or
docker-compose up -d

# Run tests via HTTP
curl http://localhost:8080/test

# Test specific module
curl http://localhost:8080/test/database
curl http://localhost:8080/test/collection
curl http://localhost:8080/test/document
curl http://localhost:8080/test/query
curl http://localhost:8080/test/graph

# Interactive AQL query
curl -X POST http://localhost:8080/query \
  -H "Content-Type: application/json" \
  -d '{"query": "FOR i IN 1..10 RETURN i"}'
```

### Hurl Tests

The project includes comprehensive Hurl tests in `tests/hurl/`:

```shell
# Run all Hurl tests
hurl --test tests/hurl/*.hurl

# Run specific test
hurl --test tests/hurl/01-database.hurl
```

### DNS Resolver Note

The nginx configuration uses a DNS resolver for container networking. If switching between Docker and Podman, you may need to update `nginx/conf/nginx.conf`:

- **Docker**: `resolver 127.0.0.11 ipv6=off;`
- **Podman**: `resolver 10.89.0.1 ipv6=off;` (check with `podman exec <container> cat /etc/resolv.conf`)

## Testing with resty

```shell
# Run the test script
resty -I src src/test.lua
```

## License

MIT License
