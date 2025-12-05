--[[
    ArangoDB Graph Operations Module
    Handles named graph management and traversals
]]

local Graph = {}
Graph.__index = Graph

function Graph.new(client)
    local self = setmetatable({}, Graph)
    self._client = client
    return self
end

-- ============================================================================
-- Graph Management
-- ============================================================================

--[[
    List all graphs

    @return table: Array of graph objects
]]
function Graph:list()
    local data = self._client:get("/_api/gharial")
    return data.graphs
end

--[[
    Get a graph by name

    @param name (string): Graph name
    @return table: Graph information
]]
function Graph:get(name)
    if not name or name == "" then
        error("Graph: name is required")
    end
    local data = self._client:get("/_api/gharial/" .. name)
    return data.graph
end

--[[
    Check if a graph exists

    @param name (string): Graph name
    @return boolean: true if exists
]]
function Graph:exists(name)
    local ok, _ = pcall(function()
        return self:get(name)
    end)
    return ok
end

--[[
    Create a new graph

    @param name (string): Graph name
    @param edgeDefinitions (table): Array of edge definitions
        Each definition: { collection, from = {}, to = {} }
    @param options (table, optional): Graph options
        - orphanCollections (table): Orphan vertex collections
        - isSmart (boolean): Smart graph (Enterprise)
        - isDisjoint (boolean): Disjoint smart graph (Enterprise)
        - smartGraphAttribute (string): Smart attribute (Enterprise)
        - numberOfShards (number): Number of shards (cluster)
        - replicationFactor (number): Replication factor (cluster)
        - writeConcern (number): Write concern (cluster)
        - satellites (table): Satellite collections (Enterprise)
        - waitForSync (boolean): Wait for sync
    @return table: Created graph info
]]
function Graph:create(name, edgeDefinitions, options)
    if not name or name == "" then
        error("Graph: name is required")
    end

    local body = {
        name = name,
        edgeDefinitions = edgeDefinitions or {}
    }

    if options then
        if options.orphanCollections then
            body.orphanCollections = options.orphanCollections
        end
        -- Graph-specific options
        local graphOptions = {}
        local optionKeys = {
            "isSmart", "isDisjoint", "smartGraphAttribute",
            "numberOfShards", "replicationFactor", "writeConcern", "satellites"
        }
        for _, key in ipairs(optionKeys) do
            if options[key] ~= nil then
                graphOptions[key] = options[key]
            end
        end
        if next(graphOptions) then
            body.options = graphOptions
        end
    end

    local query = nil
    if options and options.waitForSync then
        query = { waitForSync = true }
    end

    local data = self._client:post("/_api/gharial", body, { query = query })
    return data.graph
end

--[[
    Drop a graph

    @param name (string): Graph name
    @param dropCollections (boolean, optional): Drop associated collections
    @return table: Operation result
]]
function Graph:drop(name, dropCollections)
    if not name or name == "" then
        error("Graph: name is required")
    end

    local query = nil
    if dropCollections then
        query = { dropCollections = true }
    end

    return self._client:delete("/_api/gharial/" .. name, { query = query })
end

-- ============================================================================
-- Vertex Collections
-- ============================================================================

--[[
    List vertex collections

    @param graphName (string): Graph name
    @return table: Array of vertex collection names
]]
function Graph:listVertexCollections(graphName)
    if not graphName or graphName == "" then
        error("Graph: graphName is required")
    end
    local data = self._client:get("/_api/gharial/" .. graphName .. "/vertex")
    return data.collections
end

--[[
    Add a vertex collection

    @param graphName (string): Graph name
    @param collection (string): Collection name
    @param options (table, optional): Options
        - satellites (table): Satellite collections (Enterprise)
    @return table: Updated graph info
]]
function Graph:addVertexCollection(graphName, collection, options)
    if not graphName or graphName == "" then
        error("Graph: graphName is required")
    end
    if not collection or collection == "" then
        error("Graph: collection is required")
    end

    local body = { collection = collection }
    if options and options.satellites then
        body.options = { satellites = options.satellites }
    end

    local data = self._client:post(
        "/_api/gharial/" .. graphName .. "/vertex",
        body
    )
    return data.graph
end

--[[
    Remove a vertex collection

    @param graphName (string): Graph name
    @param collection (string): Collection name
    @param dropCollection (boolean, optional): Drop the collection itself
    @return table: Updated graph info
]]
function Graph:removeVertexCollection(graphName, collection, dropCollection)
    if not graphName or graphName == "" then
        error("Graph: graphName is required")
    end
    if not collection or collection == "" then
        error("Graph: collection is required")
    end

    local query = nil
    if dropCollection then
        query = { dropCollection = true }
    end

    local data = self._client:delete(
        "/_api/gharial/" .. graphName .. "/vertex/" .. collection,
        { query = query }
    )
    return data.graph
end

-- ============================================================================
-- Edge Definitions
-- ============================================================================

--[[
    List edge definitions

    @param graphName (string): Graph name
    @return table: Array of edge definitions
]]
function Graph:listEdgeDefinitions(graphName)
    if not graphName or graphName == "" then
        error("Graph: graphName is required")
    end
    local graph = self:get(graphName)
    return graph.edgeDefinitions
end

--[[
    Add an edge definition

    @param graphName (string): Graph name
    @param definition (table): Edge definition
        - collection (string): Edge collection name
        - from (table): Array of source vertex collections
        - to (table): Array of target vertex collections
    @param options (table, optional): Options
        - satellites (table): Satellite collections (Enterprise)
    @return table: Updated graph info
]]
function Graph:addEdgeDefinition(graphName, definition, options)
    if not graphName or graphName == "" then
        error("Graph: graphName is required")
    end
    if not definition or not definition.collection then
        error("Graph: definition with collection is required")
    end

    local body = definition
    if options and options.satellites then
        body.options = { satellites = options.satellites }
    end

    local data = self._client:post(
        "/_api/gharial/" .. graphName .. "/edge",
        body
    )
    return data.graph
end

--[[
    Replace an edge definition

    @param graphName (string): Graph name
    @param edgeCollection (string): Edge collection name
    @param definition (table): New edge definition
    @param options (table, optional): Options
        - waitForSync (boolean): Wait for sync
        - dropCollections (boolean): Drop orphaned collections
    @return table: Updated graph info
]]
function Graph:replaceEdgeDefinition(graphName, edgeCollection, definition, options)
    if not graphName or graphName == "" then
        error("Graph: graphName is required")
    end
    if not edgeCollection or edgeCollection == "" then
        error("Graph: edgeCollection is required")
    end

    local query = {}
    if options then
        if options.waitForSync then query.waitForSync = true end
        if options.dropCollections then query.dropCollections = true end
    end

    local data = self._client:put(
        "/_api/gharial/" .. graphName .. "/edge/" .. edgeCollection,
        definition,
        { query = next(query) and query or nil }
    )
    return data.graph
end

--[[
    Remove an edge definition

    @param graphName (string): Graph name
    @param edgeCollection (string): Edge collection name
    @param options (table, optional): Options
        - waitForSync (boolean): Wait for sync
        - dropCollections (boolean): Drop orphaned collections
    @return table: Updated graph info
]]
function Graph:removeEdgeDefinition(graphName, edgeCollection, options)
    if not graphName or graphName == "" then
        error("Graph: graphName is required")
    end
    if not edgeCollection or edgeCollection == "" then
        error("Graph: edgeCollection is required")
    end

    local query = {}
    if options then
        if options.waitForSync then query.waitForSync = true end
        if options.dropCollections then query.dropCollections = true end
    end

    local data = self._client:delete(
        "/_api/gharial/" .. graphName .. "/edge/" .. edgeCollection,
        { query = next(query) and query or nil }
    )
    return data.graph
end

-- ============================================================================
-- Vertex Operations
-- ============================================================================

--[[
    Get a vertex

    @param graphName (string): Graph name
    @param collection (string): Vertex collection
    @param key (string): Vertex key
    @param options (table, optional): Options
        - rev (string): Revision to match
    @return table: Vertex document
]]
function Graph:getVertex(graphName, collection, key, options)
    if not graphName or graphName == "" then
        error("Graph: graphName is required")
    end
    if not collection or collection == "" then
        error("Graph: collection is required")
    end
    if not key or key == "" then
        error("Graph: key is required")
    end

    local headers = {}
    if options and options.rev then
        headers["If-Match"] = '"' .. options.rev .. '"'
    end

    local data = self._client:get(
        "/_api/gharial/" .. graphName .. "/vertex/" .. collection .. "/" .. key,
        { headers = headers }
    )
    return data.vertex
end

--[[
    Create a vertex

    @param graphName (string): Graph name
    @param collection (string): Vertex collection
    @param vertex (table): Vertex document
    @param options (table, optional): Options
        - waitForSync (boolean): Wait for sync
        - returnNew (boolean): Return new document
    @return table: Created vertex info
]]
function Graph:createVertex(graphName, collection, vertex, options)
    if not graphName or graphName == "" then
        error("Graph: graphName is required")
    end
    if not collection or collection == "" then
        error("Graph: collection is required")
    end

    local query = {}
    if options then
        if options.waitForSync then query.waitForSync = true end
        if options.returnNew then query.returnNew = true end
    end

    local data = self._client:post(
        "/_api/gharial/" .. graphName .. "/vertex/" .. collection,
        vertex,
        { query = next(query) and query or nil }
    )
    return data.vertex
end

--[[
    Update a vertex (partial)

    @param graphName (string): Graph name
    @param collection (string): Vertex collection
    @param key (string): Vertex key
    @param vertex (table): Partial vertex data
    @param options (table, optional): Options
        - waitForSync (boolean): Wait for sync
        - returnNew (boolean): Return new document
        - returnOld (boolean): Return old document
        - keepNull (boolean): Keep null values
        - ifMatch (string): Revision to match
    @return table: Updated vertex info
]]
function Graph:updateVertex(graphName, collection, key, vertex, options)
    if not graphName or graphName == "" then
        error("Graph: graphName is required")
    end
    if not collection or collection == "" then
        error("Graph: collection is required")
    end
    if not key or key == "" then
        error("Graph: key is required")
    end

    local query = {}
    local headers = {}
    if options then
        if options.waitForSync then query.waitForSync = true end
        if options.returnNew then query.returnNew = true end
        if options.returnOld then query.returnOld = true end
        if options.keepNull ~= nil then query.keepNull = options.keepNull end
        if options.ifMatch then
            headers["If-Match"] = '"' .. options.ifMatch .. '"'
        end
    end

    local data = self._client:patch(
        "/_api/gharial/" .. graphName .. "/vertex/" .. collection .. "/" .. key,
        vertex,
        { query = next(query) and query or nil, headers = headers }
    )
    return data.vertex
end

--[[
    Replace a vertex (full)

    @param graphName (string): Graph name
    @param collection (string): Vertex collection
    @param key (string): Vertex key
    @param vertex (table): New vertex data
    @param options (table, optional): Same as updateVertex
    @return table: Replaced vertex info
]]
function Graph:replaceVertex(graphName, collection, key, vertex, options)
    if not graphName or graphName == "" then
        error("Graph: graphName is required")
    end
    if not collection or collection == "" then
        error("Graph: collection is required")
    end
    if not key or key == "" then
        error("Graph: key is required")
    end

    local query = {}
    local headers = {}
    if options then
        if options.waitForSync then query.waitForSync = true end
        if options.returnNew then query.returnNew = true end
        if options.returnOld then query.returnOld = true end
        if options.keepNull ~= nil then query.keepNull = options.keepNull end
        if options.ifMatch then
            headers["If-Match"] = '"' .. options.ifMatch .. '"'
        end
    end

    local data = self._client:put(
        "/_api/gharial/" .. graphName .. "/vertex/" .. collection .. "/" .. key,
        vertex,
        { query = next(query) and query or nil, headers = headers }
    )
    return data.vertex
end

--[[
    Delete a vertex

    @param graphName (string): Graph name
    @param collection (string): Vertex collection
    @param key (string): Vertex key
    @param options (table, optional): Options
        - waitForSync (boolean): Wait for sync
        - returnOld (boolean): Return deleted document
        - ifMatch (string): Revision to match
    @return table: Operation result
]]
function Graph:deleteVertex(graphName, collection, key, options)
    if not graphName or graphName == "" then
        error("Graph: graphName is required")
    end
    if not collection or collection == "" then
        error("Graph: collection is required")
    end
    if not key or key == "" then
        error("Graph: key is required")
    end

    local query = {}
    local headers = {}
    if options then
        if options.waitForSync then query.waitForSync = true end
        if options.returnOld then query.returnOld = true end
        if options.ifMatch then
            headers["If-Match"] = '"' .. options.ifMatch .. '"'
        end
    end

    return self._client:delete(
        "/_api/gharial/" .. graphName .. "/vertex/" .. collection .. "/" .. key,
        { query = next(query) and query or nil, headers = headers }
    )
end

-- ============================================================================
-- Edge Operations
-- ============================================================================

--[[
    Get an edge

    @param graphName (string): Graph name
    @param collection (string): Edge collection
    @param key (string): Edge key
    @param options (table, optional): Options
        - rev (string): Revision to match
    @return table: Edge document
]]
function Graph:getEdge(graphName, collection, key, options)
    if not graphName or graphName == "" then
        error("Graph: graphName is required")
    end
    if not collection or collection == "" then
        error("Graph: collection is required")
    end
    if not key or key == "" then
        error("Graph: key is required")
    end

    local headers = {}
    if options and options.rev then
        headers["If-Match"] = '"' .. options.rev .. '"'
    end

    local data = self._client:get(
        "/_api/gharial/" .. graphName .. "/edge/" .. collection .. "/" .. key,
        { headers = headers }
    )
    return data.edge
end

--[[
    Create an edge

    @param graphName (string): Graph name
    @param collection (string): Edge collection
    @param edge (table): Edge document (must have _from and _to)
    @param options (table, optional): Options
        - waitForSync (boolean): Wait for sync
        - returnNew (boolean): Return new document
    @return table: Created edge info
]]
function Graph:createEdge(graphName, collection, edge, options)
    if not graphName or graphName == "" then
        error("Graph: graphName is required")
    end
    if not collection or collection == "" then
        error("Graph: collection is required")
    end
    if not edge or not edge._from or not edge._to then
        error("Graph: edge with _from and _to is required")
    end

    local query = {}
    if options then
        if options.waitForSync then query.waitForSync = true end
        if options.returnNew then query.returnNew = true end
    end

    local data = self._client:post(
        "/_api/gharial/" .. graphName .. "/edge/" .. collection,
        edge,
        { query = next(query) and query or nil }
    )
    return data.edge
end

--[[
    Update an edge (partial)

    @param graphName (string): Graph name
    @param collection (string): Edge collection
    @param key (string): Edge key
    @param edge (table): Partial edge data
    @param options (table, optional): Same as updateVertex
    @return table: Updated edge info
]]
function Graph:updateEdge(graphName, collection, key, edge, options)
    if not graphName or graphName == "" then
        error("Graph: graphName is required")
    end
    if not collection or collection == "" then
        error("Graph: collection is required")
    end
    if not key or key == "" then
        error("Graph: key is required")
    end

    local query = {}
    local headers = {}
    if options then
        if options.waitForSync then query.waitForSync = true end
        if options.returnNew then query.returnNew = true end
        if options.returnOld then query.returnOld = true end
        if options.keepNull ~= nil then query.keepNull = options.keepNull end
        if options.ifMatch then
            headers["If-Match"] = '"' .. options.ifMatch .. '"'
        end
    end

    local data = self._client:patch(
        "/_api/gharial/" .. graphName .. "/edge/" .. collection .. "/" .. key,
        edge,
        { query = next(query) and query or nil, headers = headers }
    )
    return data.edge
end

--[[
    Replace an edge (full)

    @param graphName (string): Graph name
    @param collection (string): Edge collection
    @param key (string): Edge key
    @param edge (table): New edge data (must have _from and _to)
    @param options (table, optional): Same as updateVertex
    @return table: Replaced edge info
]]
function Graph:replaceEdge(graphName, collection, key, edge, options)
    if not graphName or graphName == "" then
        error("Graph: graphName is required")
    end
    if not collection or collection == "" then
        error("Graph: collection is required")
    end
    if not key or key == "" then
        error("Graph: key is required")
    end
    if not edge or not edge._from or not edge._to then
        error("Graph: edge with _from and _to is required")
    end

    local query = {}
    local headers = {}
    if options then
        if options.waitForSync then query.waitForSync = true end
        if options.returnNew then query.returnNew = true end
        if options.returnOld then query.returnOld = true end
        if options.keepNull ~= nil then query.keepNull = options.keepNull end
        if options.ifMatch then
            headers["If-Match"] = '"' .. options.ifMatch .. '"'
        end
    end

    local data = self._client:put(
        "/_api/gharial/" .. graphName .. "/edge/" .. collection .. "/" .. key,
        edge,
        { query = next(query) and query or nil, headers = headers }
    )
    return data.edge
end

--[[
    Delete an edge

    @param graphName (string): Graph name
    @param collection (string): Edge collection
    @param key (string): Edge key
    @param options (table, optional): Same as deleteVertex
    @return table: Operation result
]]
function Graph:deleteEdge(graphName, collection, key, options)
    if not graphName or graphName == "" then
        error("Graph: graphName is required")
    end
    if not collection or collection == "" then
        error("Graph: collection is required")
    end
    if not key or key == "" then
        error("Graph: key is required")
    end

    local query = {}
    local headers = {}
    if options then
        if options.waitForSync then query.waitForSync = true end
        if options.returnOld then query.returnOld = true end
        if options.ifMatch then
            headers["If-Match"] = '"' .. options.ifMatch .. '"'
        end
    end

    return self._client:delete(
        "/_api/gharial/" .. graphName .. "/edge/" .. collection .. "/" .. key,
        { query = next(query) and query or nil, headers = headers }
    )
end

-- ============================================================================
-- Traversal
-- ============================================================================

--[[
    Perform a graph traversal

    @param startVertex (string): Starting vertex ID
    @param options (table): Traversal options
        - direction (string): "outbound", "inbound", "any"
        - graphName (string): Named graph to traverse
        - edgeCollection (string): Edge collection (for anonymous graphs)
        - minDepth (number): Minimum depth
        - maxDepth (number): Maximum depth
        - uniqueness (table): Uniqueness options
            - vertices (string): "global", "path", "none"
            - edges (string): "global", "path", "none"
        - order (string): "preorder", "postorder", "preorder-expander"
        - itemOrder (string): "forward", "backward"
        - strategy (string): "depthfirst", "breadthfirst"
        - filter (string): Filter expression
        - visitor (string): Visitor expression
        - init (string): Init expression
        - expander (string): Expander expression
        - sort (string): Sort expression
        - maxIterations (number): Max iterations
    @return table: Traversal results with vertices and paths
]]
function Graph:traverse(startVertex, options)
    if not startVertex or startVertex == "" then
        error("Graph: startVertex is required")
    end

    options = options or {}

    local body = {
        startVertex = startVertex
    }

    -- Copy options
    local allowed = {
        "direction", "graphName", "edgeCollection", "minDepth", "maxDepth",
        "uniqueness", "order", "itemOrder", "strategy", "filter", "visitor",
        "init", "expander", "sort", "maxIterations"
    }
    for _, opt in ipairs(allowed) do
        if options[opt] ~= nil then
            body[opt] = options[opt]
        end
    end

    return self._client:post("/_api/traversal", body)
end

return Graph
