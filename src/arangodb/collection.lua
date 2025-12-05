--[[
    ArangoDB Collection Operations Module
    Handles collection management operations
]]

local Collection = {}
Collection.__index = Collection

-- Collection types
Collection.TYPE_DOCUMENT = 2
Collection.TYPE_EDGE = 3

function Collection.new(client)
    local self = setmetatable({}, Collection)
    self._client = client
    return self
end

--[[
    List all collections in the current database

    @param excludeSystem (boolean, optional): Exclude system collections (default: false)
    @return table: Array of collection objects
]]
function Collection:list(excludeSystem)
    local query = nil
    if excludeSystem then
        query = { excludeSystem = true }
    end
    local data = self._client:get("/_api/collection", { query = query })
    return data.result
end

--[[
    Get collection information

    @param name (string): Collection name
    @return table: Collection information
]]
function Collection:get(name)
    if not name or name == "" then
        error("Collection: name is required")
    end
    return self._client:get("/_api/collection/" .. name)
end

--[[
    Get collection properties

    @param name (string): Collection name
    @return table: Collection properties
]]
function Collection:properties(name)
    if not name or name == "" then
        error("Collection: name is required")
    end
    return self._client:get("/_api/collection/" .. name .. "/properties")
end

--[[
    Check if a collection exists

    @param name (string): Collection name
    @return boolean: true if exists
]]
function Collection:exists(name)
    local ok, _ = pcall(function()
        return self:get(name)
    end)
    return ok
end

--[[
    Get collection count (number of documents)

    @param name (string): Collection name
    @return number: Document count
]]
function Collection:count(name)
    if not name or name == "" then
        error("Collection: name is required")
    end
    local data = self._client:get("/_api/collection/" .. name .. "/count")
    return data.count
end

--[[
    Get collection statistics

    @param name (string): Collection name
    @return table: Collection statistics
]]
function Collection:figures(name)
    if not name or name == "" then
        error("Collection: name is required")
    end
    local data = self._client:get("/_api/collection/" .. name .. "/figures")
    return data.figures
end

--[[
    Get collection revision ID

    @param name (string): Collection name
    @return string: Revision ID
]]
function Collection:revision(name)
    if not name or name == "" then
        error("Collection: name is required")
    end
    local data = self._client:get("/_api/collection/" .. name .. "/revision")
    return data.revision
end

--[[
    Get collection checksum

    @param name (string): Collection name
    @param options (table, optional): Options
        - withRevisions (boolean): Include revisions in checksum
        - withData (boolean): Include data in checksum
    @return table: Checksum information
]]
function Collection:checksum(name, options)
    if not name or name == "" then
        error("Collection: name is required")
    end
    return self._client:get("/_api/collection/" .. name .. "/checksum", { query = options })
end

--[[
    Create a new collection

    @param name (string, required): Collection name
    @param options (table, optional): Collection options
        - type (number): Collection type (2 = document, 3 = edge)
        - waitForSync (boolean): Wait for sync on write operations
        - keyOptions (table): Key generation options
            - type (string): "traditional", "autoincrement", "uuid", "padded"
            - allowUserKeys (boolean): Allow user-defined keys
            - increment (number): Auto-increment value
            - offset (number): Auto-increment offset
        - schema (table): JSON Schema for validation
        - computedValues (table): Computed values configuration
        - cacheEnabled (boolean): Enable in-memory cache
        - numberOfShards (number): Number of shards (cluster)
        - shardKeys (table): Shard key attributes (cluster)
        - replicationFactor (number): Replication factor (cluster)
        - writeConcern (number): Write concern (cluster)
        - shardingStrategy (string): Sharding strategy (cluster)
        - distributeShardsLike (string): Distribute shards like collection (cluster)
        - isSmart (boolean): Smart collection (Enterprise)
        - isSystem (boolean): System collection
        - syncByRevision (boolean): Use revision-based sync

    @return table: Created collection info
]]
function Collection:create(name, options)
    if not name or name == "" then
        error("Collection: name is required")
    end

    local payload = options or {}
    payload.name = name

    return self._client:post("/_api/collection", payload)
end

--[[
    Create a document collection

    @param name (string): Collection name
    @param options (table, optional): Additional options
    @return table: Created collection info
]]
function Collection:createDocument(name, options)
    options = options or {}
    options.type = Collection.TYPE_DOCUMENT
    return self:create(name, options)
end

--[[
    Create an edge collection

    @param name (string): Collection name
    @param options (table, optional): Additional options
    @return table: Created collection info
]]
function Collection:createEdge(name, options)
    options = options or {}
    options.type = Collection.TYPE_EDGE
    return self:create(name, options)
end

--[[
    Drop a collection

    @param name (string): Collection name
    @param isSystem (boolean, optional): Drop system collection
    @return table: Operation result
]]
function Collection:drop(name, isSystem)
    if not name or name == "" then
        error("Collection: name is required")
    end

    local query = nil
    if isSystem then
        query = { isSystem = true }
    end

    return self._client:delete("/_api/collection/" .. name, { query = query })
end

--[[
    Truncate a collection (remove all documents)

    @param name (string): Collection name
    @return table: Operation result
]]
function Collection:truncate(name)
    if not name or name == "" then
        error("Collection: name is required")
    end
    return self._client:put("/_api/collection/" .. name .. "/truncate", {})
end

--[[
    Rename a collection

    @param name (string): Current collection name
    @param newName (string): New collection name
    @return table: Renamed collection info
]]
function Collection:rename(name, newName)
    if not name or name == "" then
        error("Collection: name is required")
    end
    if not newName or newName == "" then
        error("Collection: newName is required")
    end
    return self._client:put("/_api/collection/" .. name .. "/rename", { name = newName })
end

--[[
    Modify collection properties

    @param name (string): Collection name
    @param properties (table): Properties to modify
        - waitForSync (boolean)
        - schema (table)
        - computedValues (table)
        - replicationFactor (number) - cluster
        - writeConcern (number) - cluster
        - cacheEnabled (boolean)
    @return table: Updated collection info
]]
function Collection:setProperties(name, properties)
    if not name or name == "" then
        error("Collection: name is required")
    end
    return self._client:put("/_api/collection/" .. name .. "/properties", properties)
end

--[[
    Load a collection into memory

    @param name (string): Collection name
    @return table: Collection info
]]
function Collection:load(name)
    if not name or name == "" then
        error("Collection: name is required")
    end
    return self._client:put("/_api/collection/" .. name .. "/load", {})
end

--[[
    Unload a collection from memory

    @param name (string): Collection name
    @return table: Collection info
]]
function Collection:unload(name)
    if not name or name == "" then
        error("Collection: name is required")
    end
    return self._client:put("/_api/collection/" .. name .. "/unload", {})
end

--[[
    Load collection indexes into memory

    @param name (string): Collection name
    @return table: Operation result
]]
function Collection:loadIndexes(name)
    if not name or name == "" then
        error("Collection: name is required")
    end
    return self._client:put("/_api/collection/" .. name .. "/loadIndexesIntoMemory", {})
end

--[[
    Recalculate collection count

    @param name (string): Collection name
    @return table: Updated count info
]]
function Collection:recalculateCount(name)
    if not name or name == "" then
        error("Collection: name is required")
    end
    return self._client:put("/_api/collection/" .. name .. "/recalculateCount", {})
end

--[[
    Compact collection data

    @param name (string): Collection name
    @return table: Operation result
]]
function Collection:compact(name)
    if not name or name == "" then
        error("Collection: name is required")
    end
    return self._client:put("/_api/collection/" .. name .. "/compact", {})
end

--[[
    Get responsible shard for a document (cluster only)

    @param name (string): Collection name
    @param document (table): Document with shard key attributes
    @return table: Shard information
]]
function Collection:responsibleShard(name, document)
    if not name or name == "" then
        error("Collection: name is required")
    end
    return self._client:put("/_api/collection/" .. name .. "/responsibleShard", document)
end

--[[
    Get collection shards (cluster only)

    @param name (string): Collection name
    @param details (boolean, optional): Include shard details
    @return table: Shards information
]]
function Collection:shards(name, details)
    if not name or name == "" then
        error("Collection: name is required")
    end
    local query = nil
    if details then
        query = { details = true }
    end
    return self._client:get("/_api/collection/" .. name .. "/shards", { query = query })
end

return Collection
