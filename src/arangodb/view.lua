--[[
    ArangoDB View Operations Module
    Handles ArangoSearch views and search-alias views
]]

local View = {}
View.__index = View

-- View types
View.TYPE_ARANGOSEARCH = "arangosearch"
View.TYPE_SEARCH_ALIAS = "search-alias"

function View.new(client)
    local self = setmetatable({}, View)
    self._client = client
    return self
end

--[[
    List all views

    @return table: Array of view objects
]]
function View:list()
    local data = self._client:get("/_api/view")
    return data.result
end

--[[
    Get a view by name

    @param name (string): View name
    @return table: View information
]]
function View:get(name)
    if not name or name == "" then
        error("View: name is required")
    end
    return self._client:get("/_api/view/" .. name)
end

--[[
    Get view properties

    @param name (string): View name
    @return table: View properties
]]
function View:properties(name)
    if not name or name == "" then
        error("View: name is required")
    end
    return self._client:get("/_api/view/" .. name .. "/properties")
end

--[[
    Check if a view exists

    @param name (string): View name
    @return boolean: true if exists
]]
function View:exists(name)
    local ok, _ = pcall(function()
        return self:get(name)
    end)
    return ok
end

--[[
    Create an ArangoSearch view

    @param name (string): View name
    @param options (table, optional): View options
        - links (table): Collection links
        - primarySort (table): Primary sort definition
        - primarySortCompression (string): "lz4" or "none"
        - storedValues (table): Stored values configuration
        - cleanupIntervalStep (number): Cleanup interval
        - commitIntervalMsec (number): Commit interval
        - consolidationIntervalMsec (number): Consolidation interval
        - consolidationPolicy (table): Consolidation policy
        - writebufferIdle (number): Write buffer idle
        - writebufferActive (number): Write buffer active
        - writebufferSizeMax (number): Max write buffer size
    @return table: Created view info
]]
function View:createArangoSearch(name, options)
    if not name or name == "" then
        error("View: name is required")
    end

    local body = {
        name = name,
        type = View.TYPE_ARANGOSEARCH
    }

    if options then
        for k, v in pairs(options) do
            body[k] = v
        end
    end

    return self._client:post("/_api/view", body)
end

--[[
    Create a search-alias view

    @param name (string): View name
    @param indexes (table, optional): Array of index references
        Each: { collection = "name", index = "indexName" }
    @return table: Created view info
]]
function View:createSearchAlias(name, indexes)
    if not name or name == "" then
        error("View: name is required")
    end

    local body = {
        name = name,
        type = View.TYPE_SEARCH_ALIAS
    }

    if indexes then
        body.indexes = indexes
    end

    return self._client:post("/_api/view", body)
end

--[[
    Create a view (generic)

    @param name (string): View name
    @param type (string): View type
    @param properties (table, optional): View properties
    @return table: Created view info
]]
function View:create(name, type, properties)
    if not name or name == "" then
        error("View: name is required")
    end
    if not type then
        error("View: type is required")
    end

    local body = properties or {}
    body.name = name
    body.type = type

    return self._client:post("/_api/view", body)
end

--[[
    Drop a view

    @param name (string): View name
    @return table: Operation result
]]
function View:drop(name)
    if not name or name == "" then
        error("View: name is required")
    end
    return self._client:delete("/_api/view/" .. name)
end

--[[
    Rename a view

    @param name (string): Current view name
    @param newName (string): New view name
    @return table: Renamed view info
]]
function View:rename(name, newName)
    if not name or name == "" then
        error("View: name is required")
    end
    if not newName or newName == "" then
        error("View: newName is required")
    end
    return self._client:put("/_api/view/" .. name .. "/rename", { name = newName })
end

--[[
    Update view properties (partial update)

    @param name (string): View name
    @param properties (table): Properties to update
    @return table: Updated view properties
]]
function View:updateProperties(name, properties)
    if not name or name == "" then
        error("View: name is required")
    end
    return self._client:patch("/_api/view/" .. name .. "/properties", properties)
end

--[[
    Replace view properties (full update)

    @param name (string): View name
    @param properties (table): New properties
    @return table: Updated view properties
]]
function View:replaceProperties(name, properties)
    if not name or name == "" then
        error("View: name is required")
    end
    return self._client:put("/_api/view/" .. name .. "/properties", properties)
end

-- ============================================================================
-- ArangoSearch Link Management
-- ============================================================================

--[[
    Add a link to an ArangoSearch view

    @param viewName (string): View name
    @param collection (string): Collection to link
    @param linkOptions (table, optional): Link options
        - analyzers (table): Array of analyzer names
        - fields (table): Field definitions
        - includeAllFields (boolean): Include all fields
        - trackListPositions (boolean): Track list positions
        - storeValues (string): "none" or "id"
        - inBackground (boolean): Create in background
        - cache (boolean): Enable cache
        - nested (table): Nested field definitions
    @return table: Updated view properties
]]
function View:addLink(viewName, collection, linkOptions)
    if not viewName or viewName == "" then
        error("View: viewName is required")
    end
    if not collection or collection == "" then
        error("View: collection is required")
    end

    local links = {}
    links[collection] = linkOptions or {}

    return self:updateProperties(viewName, { links = links })
end

--[[
    Remove a link from an ArangoSearch view

    @param viewName (string): View name
    @param collection (string): Collection to unlink
    @return table: Updated view properties
]]
function View:removeLink(viewName, collection)
    if not viewName or viewName == "" then
        error("View: viewName is required")
    end
    if not collection or collection == "" then
        error("View: collection is required")
    end

    local links = {}
    links[collection] = nil -- null removes the link

    return self:updateProperties(viewName, { links = links })
end

--[[
    Update a link in an ArangoSearch view

    @param viewName (string): View name
    @param collection (string): Collection name
    @param linkOptions (table): New link options
    @return table: Updated view properties
]]
function View:updateLink(viewName, collection, linkOptions)
    return self:addLink(viewName, collection, linkOptions)
end

-- ============================================================================
-- Search-Alias Index Management
-- ============================================================================

--[[
    Add an index to a search-alias view

    @param viewName (string): View name
    @param collection (string): Collection name
    @param indexName (string): Inverted index name
    @return table: Updated view properties
]]
function View:addIndex(viewName, collection, indexName)
    if not viewName or viewName == "" then
        error("View: viewName is required")
    end
    if not collection or collection == "" then
        error("View: collection is required")
    end
    if not indexName or indexName == "" then
        error("View: indexName is required")
    end

    return self:updateProperties(viewName, {
        indexes = {
            { collection = collection, index = indexName }
        }
    })
end

--[[
    Remove an index from a search-alias view

    @param viewName (string): View name
    @param collection (string): Collection name
    @param indexName (string): Inverted index name
    @return table: Updated view properties
]]
function View:removeIndex(viewName, collection, indexName)
    if not viewName or viewName == "" then
        error("View: viewName is required")
    end

    -- Get current indexes
    local props = self:properties(viewName)
    local newIndexes = {}

    if props.indexes then
        for _, idx in ipairs(props.indexes) do
            if not (idx.collection == collection and idx.index == indexName) then
                table.insert(newIndexes, idx)
            end
        end
    end

    return self:replaceProperties(viewName, { indexes = newIndexes })
end

-- ============================================================================
-- Convenience Methods
-- ============================================================================

--[[
    Create a simple ArangoSearch view with a single collection link

    @param name (string): View name
    @param collection (string): Collection to link
    @param options (table, optional): Options
        - analyzers (table): Analyzers to use
        - fields (table): Field definitions
        - includeAllFields (boolean): Include all fields (default: true)
    @return table: Created view info
]]
function View:createSimple(name, collection, options)
    options = options or {}

    local linkOptions = {
        includeAllFields = options.includeAllFields ~= false,
        analyzers = options.analyzers,
        fields = options.fields
    }

    local links = {}
    links[collection] = linkOptions

    return self:createArangoSearch(name, { links = links })
end

--[[
    Get view by name and type

    @param name (string): View name
    @return table|nil: View info or nil
    @return string|nil: View type or nil
]]
function View:getWithType(name)
    local ok, view = pcall(function()
        return self:get(name)
    end)
    if ok then
        return view, view.type
    end
    return nil, nil
end

return View
