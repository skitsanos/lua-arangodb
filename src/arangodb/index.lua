--[[
    ArangoDB Index Operations Module
    Handles index management operations
]]

local Index = {}
Index.__index = Index

-- Index types
Index.TYPE_PRIMARY = "primary"
Index.TYPE_HASH = "hash"
Index.TYPE_SKIPLIST = "skiplist"
Index.TYPE_PERSISTENT = "persistent"
Index.TYPE_GEO = "geo"
Index.TYPE_FULLTEXT = "fulltext"
Index.TYPE_TTL = "ttl"
Index.TYPE_ZKD = "zkd"
Index.TYPE_MDI = "mdi"
Index.TYPE_MDI_PREFIXED = "mdi-prefixed"
Index.TYPE_INVERTED = "inverted"
Index.TYPE_VECTOR = "vector"

-- Vector index metrics
Index.METRIC_COSINE = "cosine"
Index.METRIC_L2 = "l2"
Index.METRIC_INNER_PRODUCT = "innerProduct"

function Index.new(client)
    local self = setmetatable({}, Index)
    self._client = client
    return self
end

--[[
    List all indexes for a collection

    @param collection (string): Collection name
    @param withStats (boolean, optional): Include index statistics
    @param withHidden (boolean, optional): Include hidden indexes
    @return table: Array of index objects
]]
function Index:list(collection, withStats, withHidden)
    if not collection or collection == "" then
        error("Index: collection is required")
    end

    local query = { collection = collection }
    if withStats then query.withStats = true end
    if withHidden then query.withHidden = true end

    local data = self._client:get("/_api/index", { query = query })
    return data.indexes
end

--[[
    Get index by ID

    @param indexId (string): Index ID (format: "collection/id")
    @return table: Index information
]]
function Index:get(indexId)
    if not indexId or indexId == "" then
        error("Index: indexId is required")
    end
    return self._client:get("/_api/index/" .. indexId)
end

--[[
    Create a generic index

    @param collection (string): Collection name
    @param definition (table): Index definition
        - type (string, required): Index type
        - fields (table): Array of field names
        - name (string, optional): Index name
        - unique (boolean, optional): Unique constraint
        - sparse (boolean, optional): Sparse index
        - deduplicate (boolean, optional): Deduplicate array values
        - estimates (boolean, optional): Maintain selectivity estimates
        - cacheEnabled (boolean, optional): Enable in-memory cache
        - inBackground (boolean, optional): Create in background
        - ... (type-specific options)
    @return table: Created index info
]]
function Index:create(collection, definition)
    if not collection or collection == "" then
        error("Index: collection is required")
    end
    if not definition or not definition.type then
        error("Index: definition with type is required")
    end

    return self._client:post("/_api/index", definition, {
        query = { collection = collection }
    })
end

--[[
    Create a persistent index (B-tree)

    @param collection (string): Collection name
    @param fields (table): Array of field names
    @param options (table, optional): Index options
        - name (string): Index name
        - unique (boolean): Unique constraint
        - sparse (boolean): Sparse index
        - deduplicate (boolean): Deduplicate array values
        - estimates (boolean): Maintain selectivity estimates
        - cacheEnabled (boolean): Enable cache
        - inBackground (boolean): Create in background
        - storedValues (table): Additional stored values
    @return table: Created index info
]]
function Index:createPersistent(collection, fields, options)
    options = options or {}
    options.type = Index.TYPE_PERSISTENT
    options.fields = fields
    return self:create(collection, options)
end

--[[
    Create a hash index (deprecated, use persistent)

    @param collection (string): Collection name
    @param fields (table): Array of field names
    @param options (table, optional): Index options
    @return table: Created index info
]]
function Index:createHash(collection, fields, options)
    options = options or {}
    options.type = Index.TYPE_HASH
    options.fields = fields
    return self:create(collection, options)
end

--[[
    Create a skiplist index (deprecated, use persistent)

    @param collection (string): Collection name
    @param fields (table): Array of field names
    @param options (table, optional): Index options
    @return table: Created index info
]]
function Index:createSkiplist(collection, fields, options)
    options = options or {}
    options.type = Index.TYPE_SKIPLIST
    options.fields = fields
    return self:create(collection, options)
end

--[[
    Create a geo index

    @param collection (string): Collection name
    @param fields (table): Array of field names (1 or 2 fields)
    @param options (table, optional): Index options
        - name (string): Index name
        - geoJson (boolean): Interpret as GeoJSON
        - legacyPolygons (boolean): Use legacy polygon format
        - inBackground (boolean): Create in background
    @return table: Created index info
]]
function Index:createGeo(collection, fields, options)
    options = options or {}
    options.type = Index.TYPE_GEO
    options.fields = fields
    return self:create(collection, options)
end

--[[
    Create a fulltext index (deprecated, use ArangoSearch)

    @param collection (string): Collection name
    @param fields (table): Array with single field name
    @param options (table, optional): Index options
        - name (string): Index name
        - minLength (number): Minimum word length
        - inBackground (boolean): Create in background
    @return table: Created index info
]]
function Index:createFulltext(collection, fields, options)
    options = options or {}
    options.type = Index.TYPE_FULLTEXT
    options.fields = fields
    return self:create(collection, options)
end

--[[
    Create a TTL index (time-to-live)

    @param collection (string): Collection name
    @param fields (table): Array with single field name (timestamp field)
    @param expireAfter (number): Expiration time in seconds
    @param options (table, optional): Index options
        - name (string): Index name
        - inBackground (boolean): Create in background
    @return table: Created index info
]]
function Index:createTTL(collection, fields, expireAfter, options)
    options = options or {}
    options.type = Index.TYPE_TTL
    options.fields = fields
    options.expireAfter = expireAfter
    return self:create(collection, options)
end

--[[
    Create a ZKD index (multi-dimensional)

    @param collection (string): Collection name
    @param fields (table): Array of field names
    @param options (table, optional): Index options
        - name (string): Index name
        - unique (boolean): Unique constraint
        - fieldValueTypes (string): "double" for all numeric
        - inBackground (boolean): Create in background
    @return table: Created index info
]]
function Index:createZKD(collection, fields, options)
    options = options or {}
    options.type = Index.TYPE_ZKD
    options.fields = fields
    return self:create(collection, options)
end

--[[
    Create an MDI index (multi-dimensional)

    @param collection (string): Collection name
    @param fields (table): Array of field names
    @param options (table, optional): Index options
        - name (string): Index name
        - unique (boolean): Unique constraint
        - fieldValueTypes (string): "double" for all numeric
        - prefixFields (table): Prefix fields (for mdi-prefixed)
        - storedValues (table): Additional stored values
        - inBackground (boolean): Create in background
    @return table: Created index info
]]
function Index:createMDI(collection, fields, options)
    options = options or {}
    options.type = Index.TYPE_MDI
    options.fields = fields
    return self:create(collection, options)
end

--[[
    Create an MDI-prefixed index

    @param collection (string): Collection name
    @param fields (table): Array of field names
    @param prefixFields (table): Array of prefix field names
    @param options (table, optional): Index options
    @return table: Created index info
]]
function Index:createMDIPrefixed(collection, fields, prefixFields, options)
    options = options or {}
    options.type = Index.TYPE_MDI_PREFIXED
    options.fields = fields
    options.prefixFields = prefixFields
    return self:create(collection, options)
end

--[[
    Create an inverted index (for ArangoSearch)

    @param collection (string): Collection name
    @param fields (table): Array of field definitions
    @param options (table, optional): Index options
        - name (string): Index name
        - searchField (boolean): Index as searchField
        - storedValues (table): Stored values
        - primarySort (table): Primary sort definition
        - primaryKeyCache (boolean): Enable primary key cache
        - analyzer (string): Default analyzer
        - features (table): Analyzer features
        - includeAllFields (boolean): Include all fields
        - trackListPositions (boolean): Track list positions
        - parallelism (number): Parallelism for indexing
        - cleanupIntervalStep (number): Cleanup interval
        - commitIntervalMsec (number): Commit interval
        - consolidationIntervalMsec (number): Consolidation interval
        - consolidationPolicy (table): Consolidation policy
        - writebufferIdle (number): Write buffer idle
        - writebufferActive (number): Write buffer active
        - writebufferSizeMax (number): Max write buffer size
        - inBackground (boolean): Create in background
    @return table: Created index info
]]
function Index:createInverted(collection, fields, options)
    options = options or {}
    options.type = Index.TYPE_INVERTED
    options.fields = fields
    return self:create(collection, options)
end

--[[
    Create a vector index for semantic similarity search (v3.12.4+)

    Vector indexes use the Faiss library to index vector embeddings.
    NOTE: Requires --vector-index startup option enabled on server.
    NOTE: Documents with vector data must exist BEFORE creating the index.

    @param collection (string): Collection name
    @param field (string): Attribute path containing the vector embedding array
    @param params (table): Vector index parameters
        - metric (string, required): Similarity metric - "cosine", "l2", or "innerProduct"
        - dimension (number, required): Vector dimension (array length)
        - nLists (number, required): Number of Voronoi cells (~N/15 where N=doc count)
        - defaultNProbe (number, optional): Neighboring centroids to search (default: 1)
        - trainingIterations (number, optional): Training iterations (default: 25)
        - factory (string, optional): Faiss factory string for advanced config
    @param options (table, optional): Additional index options
        - name (string): Index name
        - sparse (boolean): Exclude docs with null/missing vectors (default: false)
        - parallelism (number): Threads for indexing (default: 2)
        - inBackground (boolean): Create in background (default: false)
    @return table: Created index info

    @example
        -- Create a cosine similarity index for 384-dimensional embeddings
        client.index:createVector("documents", "embedding", {
            metric = "cosine",
            dimension = 384,
            nLists = 100,
            defaultNProbe = 10
        })

        -- Query with AQL:
        -- FOR doc IN documents
        --   SORT APPROX_NEAR_COSINE(doc.embedding, @queryVector) DESC
        --   LIMIT 10
        --   RETURN doc
]]
function Index:createVector(collection, field, params, options)
    if not collection or collection == "" then
        error("Index: collection is required")
    end
    if not field or field == "" then
        error("Index: field is required")
    end
    if not params then
        error("Index: params is required")
    end
    if not params.metric then
        error("Index: params.metric is required (cosine, l2, or innerProduct)")
    end
    if not params.dimension then
        error("Index: params.dimension is required")
    end
    if not params.nLists then
        error("Index: params.nLists is required")
    end

    options = options or {}
    options.type = Index.TYPE_VECTOR
    options.fields = { field }
    options.params = {
        metric = params.metric,
        dimension = params.dimension,
        nLists = params.nLists
    }

    -- Optional params
    if params.defaultNProbe then
        options.params.defaultNProbe = params.defaultNProbe
    end
    if params.trainingIterations then
        options.params.trainingIterations = params.trainingIterations
    end
    if params.factory then
        options.params.factory = params.factory
    end

    return self:create(collection, options)
end

--[[
    Drop an index

    @param indexId (string): Index ID (format: "collection/id")
    @return table: Operation result
]]
function Index:drop(indexId)
    if not indexId or indexId == "" then
        error("Index: indexId is required")
    end
    return self._client:delete("/_api/index/" .. indexId)
end

--[[
    Check if index exists

    @param indexId (string): Index ID
    @return boolean: true if exists
]]
function Index:exists(indexId)
    local ok, _ = pcall(function()
        return self:get(indexId)
    end)
    return ok
end

--[[
    Get all indexes for a collection by name

    @param collection (string): Collection name
    @param indexName (string): Index name to find
    @return table|nil: Index info or nil if not found
]]
function Index:getByName(collection, indexName)
    local indexes = self:list(collection)
    for _, idx in ipairs(indexes) do
        if idx.name == indexName then
            return idx
        end
    end
    return nil
end

--[[
    Ensure an index exists (create if not exists)

    @param collection (string): Collection name
    @param definition (table): Index definition
    @return table: Index info
    @return boolean: true if created, false if already existed
]]
function Index:ensure(collection, definition)
    if definition.name then
        local existing = self:getByName(collection, definition.name)
        if existing then
            return existing, false
        end
    end
    return self:create(collection, definition), true
end

return Index
