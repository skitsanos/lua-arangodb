--[[
    ArangoDB Query/Cursor Operations Module
    Handles AQL query execution and cursor management
]]

local Query = {}
Query.__index = Query

function Query.new(client)
    local self = setmetatable({}, Query)
    self._client = client
    return self
end

--[[
    Execute an AQL query

    @param aql (string): AQL query string
    @param bindVars (table, optional): Bind parameters
    @param options (table, optional): Query options
        - count (boolean): Return total count
        - batchSize (number): Batch size for cursor
        - ttl (number): Cursor TTL in seconds
        - cache (boolean): Use query cache
        - memoryLimit (number): Memory limit in bytes
        - fullCount (boolean): Return full count (with LIMIT)
        - fillBlockCache (boolean): Fill block cache
        - stream (boolean): Stream results
        - allowDirtyReads (boolean): Allow dirty reads (cluster)
        - maxRuntime (number): Max runtime in seconds
        - maxWarningCount (number): Max warnings to return
        - maxNodesPerCallstack (number): Max nodes per callstack
        - satelliteSyncWait (number): Satellite sync wait (Enterprise)
        - allowRetry (boolean): Allow retry on failure
        - profile (number): Profile level (0, 1, 2)
        - optimizer (table): Optimizer rules
            - rules (table): Array of rules
        - shardIds (table): Shard IDs to query (cluster)
        - transaction (table): Transaction options
            - collections (table): Read/write collections
    @return table: Query results (array)
    @return table: Cursor metadata (id, hasMore, count, etc.)
]]
function Query:execute(aql, bindVars, options)
    if not aql or aql == "" then
        error("Query: aql is required")
    end

    local body = {
        query = aql
    }

    if bindVars then
        body.bindVars = bindVars
    end

    if options then
        -- Copy allowed options to body
        local allowed = {
            "count", "batchSize", "ttl", "cache", "memoryLimit",
            "fullCount", "fillBlockCache", "stream", "allowDirtyReads",
            "maxRuntime", "maxWarningCount", "maxNodesPerCallstack",
            "satelliteSyncWait", "allowRetry", "profile"
        }
        for _, opt in ipairs(allowed) do
            if options[opt] ~= nil then
                body[opt] = options[opt]
            end
        end

        -- Handle nested options
        if options.optimizer then
            body.options = body.options or {}
            body.options.optimizer = options.optimizer
        end
        if options.shardIds then
            body.options = body.options or {}
            body.options.shardIds = options.shardIds
        end
        if options.transaction then
            body.options = body.options or {}
            body.options.transaction = options.transaction
        end
    end

    local data = self._client:post("/_api/cursor", body)

    -- Return results and cursor metadata
    local cursor = {
        id = data.id,
        hasMore = data.hasMore,
        count = data.count,
        cached = data.cached,
        extra = data.extra,
        warnings = data.warnings
    }

    return data.result, cursor
end

--[[
    Execute a query and return all results (handles pagination automatically)

    @param aql (string): AQL query string
    @param bindVars (table, optional): Bind parameters
    @param options (table, optional): Query options
    @return table: All query results
]]
function Query:all(aql, bindVars, options)
    local results, cursor = self:execute(aql, bindVars, options)

    -- Fetch remaining batches if any
    while cursor.hasMore and cursor.id do
        local more = self:next(cursor.id)
        for _, item in ipairs(more.result) do
            table.insert(results, item)
        end
        cursor.hasMore = more.hasMore
        if not more.hasMore then
            cursor.id = nil
        end
    end

    return results
end

--[[
    Get next batch from cursor

    @param cursorId (string): Cursor ID
    @return table: Cursor data with results
]]
function Query:next(cursorId)
    if not cursorId or cursorId == "" then
        error("Query: cursorId is required")
    end
    return self._client:post("/_api/cursor/" .. cursorId, {})
end

--[[
    Delete a cursor

    @param cursorId (string): Cursor ID
    @return table: Operation result
]]
function Query:deleteCursor(cursorId)
    if not cursorId or cursorId == "" then
        error("Query: cursorId is required")
    end
    return self._client:delete("/_api/cursor/" .. cursorId)
end

--[[
    Create a cursor iterator

    @param aql (string): AQL query string
    @param bindVars (table, optional): Bind parameters
    @param options (table, optional): Query options
    @return function: Iterator function
]]
function Query:iterate(aql, bindVars, options)
    local results, cursor = self:execute(aql, bindVars, options)
    local index = 0
    local client = self._client

    return function()
        index = index + 1

        -- Return from current batch
        if index <= #results then
            return results[index]
        end

        -- Fetch next batch if available
        if cursor.hasMore and cursor.id then
            local more = client:post("/_api/cursor/" .. cursor.id, {})
            results = more.result
            cursor.hasMore = more.hasMore
            if not more.hasMore then
                cursor.id = nil
            end
            index = 1
            if #results > 0 then
                return results[index]
            end
        end

        return nil
    end
end

--[[
    Parse an AQL query (validate without executing)

    @param aql (string): AQL query string
    @param options (table, optional): Parse options
        - bindVars (table): Bind variables for validation
    @return table: Parse result with AST
]]
function Query:parse(aql, options)
    if not aql or aql == "" then
        error("Query: aql is required")
    end

    local body = { query = aql }
    if options and options.bindVars then
        body.bindVars = options.bindVars
    end

    return self._client:post("/_api/query", body)
end

--[[
    Explain an AQL query

    @param aql (string): AQL query string
    @param bindVars (table, optional): Bind parameters
    @param options (table, optional): Explain options
        - allPlans (boolean): Return all plans
        - maxNumberOfPlans (number): Max plans to return
        - optimizer (table): Optimizer rules
    @return table: Execution plan(s)
]]
function Query:explain(aql, bindVars, options)
    if not aql or aql == "" then
        error("Query: aql is required")
    end

    local body = { query = aql }
    if bindVars then
        body.bindVars = bindVars
    end

    if options then
        body.options = options
    end

    return self._client:post("/_api/explain", body)
end

--[[
    Kill a running query

    @param queryId (string): Query ID
    @return table: Operation result
]]
function Query:kill(queryId)
    if not queryId or queryId == "" then
        error("Query: queryId is required")
    end
    return self._client:delete("/_api/query/" .. queryId)
end

--[[
    List currently running queries

    @param all (boolean, optional): List queries from all databases
    @return table: Array of running queries
]]
function Query:listRunning(all)
    local query = nil
    if all then
        query = { all = true }
    end
    return self._client:get("/_api/query/current", { query = query })
end

--[[
    List slow queries

    @param all (boolean, optional): List queries from all databases
    @return table: Array of slow queries
]]
function Query:listSlow(all)
    local query = nil
    if all then
        query = { all = true }
    end
    return self._client:get("/_api/query/slow", { query = query })
end

--[[
    Clear slow query log

    @param all (boolean, optional): Clear for all databases
    @return table: Operation result
]]
function Query:clearSlow(all)
    local query = nil
    if all then
        query = { all = true }
    end
    return self._client:delete("/_api/query/slow", { query = query })
end

--[[
    Get query tracking properties

    @return table: Query tracking configuration
]]
function Query:getTracking()
    return self._client:get("/_api/query/properties")
end

--[[
    Set query tracking properties

    @param properties (table): Properties to set
        - enabled (boolean): Enable tracking
        - trackSlowQueries (boolean): Track slow queries
        - trackBindVars (boolean): Track bind variables
        - maxSlowQueries (number): Max slow queries to keep
        - slowQueryThreshold (number): Threshold in seconds
        - slowStreamingQueryThreshold (number): Threshold for streaming
        - maxQueryStringLength (number): Max query string length
    @return table: Updated configuration
]]
function Query:setTracking(properties)
    return self._client:put("/_api/query/properties", properties)
end

--[[
    Get query cache properties

    @return table: Cache configuration
]]
function Query:getCacheProperties()
    return self._client:get("/_api/query-cache/properties")
end

--[[
    Set query cache properties

    @param properties (table): Properties to set
        - mode (string): "off", "on", "demand"
        - maxResults (number): Max cached results
        - maxResultsSize (number): Max size per result
        - maxEntrySize (number): Max entry size
        - includeSystem (boolean): Include system collections
    @return table: Updated configuration
]]
function Query:setCacheProperties(properties)
    return self._client:put("/_api/query-cache/properties", properties)
end

--[[
    Get query cache entries

    @return table: Cache entries
]]
function Query:getCacheEntries()
    return self._client:get("/_api/query-cache/entries")
end

--[[
    Clear query cache

    @return table: Operation result
]]
function Query:clearCache()
    return self._client:delete("/_api/query-cache")
end

--[[
    Get available AQL functions

    @param namespace (string, optional): Filter by namespace
    @return table: Array of AQL functions
]]
function Query:functions(namespace)
    local query = nil
    if namespace then
        query = { namespace = namespace }
    end
    return self._client:get("/_api/aqlfunction", { query = query })
end

--[[
    Register a user-defined AQL function

    @param name (string): Function name (namespace::name)
    @param code (string): JavaScript function code
    @param isDeterministic (boolean, optional): Function is deterministic
    @return table: Operation result
]]
function Query:createFunction(name, code, isDeterministic)
    if not name or name == "" then
        error("Query: name is required")
    end
    if not code or code == "" then
        error("Query: code is required")
    end

    return self._client:post("/_api/aqlfunction", {
        name = name,
        code = code,
        isDeterministic = isDeterministic or false
    })
end

--[[
    Remove a user-defined AQL function

    @param name (string): Function name or namespace
    @param group (boolean, optional): Remove entire namespace
    @return table: Operation result
]]
function Query:deleteFunction(name, group)
    if not name or name == "" then
        error("Query: name is required")
    end

    local query = nil
    if group then
        query = { group = true }
    end

    return self._client:delete("/_api/aqlfunction/" .. name, { query = query })
end

--[[
    List available query rules

    @return table: Array of optimizer rules
]]
function Query:rules()
    return self._client:get("/_api/query/rules")
end

return Query
