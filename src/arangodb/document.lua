--[[
    ArangoDB Document Operations Module
    Handles CRUD operations on documents
]]

local json = require("cjson")

local Document = {}
Document.__index = Document

function Document.new(client)
    local self = setmetatable({}, Document)
    self._client = client
    return self
end

--[[
    Build query parameters for document operations
]]
local function buildDocumentQuery(options)
    if not options then return nil end

    local query = {}
    local valid_params = {
        "waitForSync", "returnNew", "returnOld", "silent",
        "overwrite", "overwriteMode", "keepNull", "mergeObjects",
        "refillIndexCaches", "versionAttribute", "ignoreRevs"
    }

    for _, param in ipairs(valid_params) do
        if options[param] ~= nil then
            query[param] = options[param]
        end
    end

    return next(query) and query or nil
end

--[[
    Get a document by its handle or key

    @param collection (string): Collection name
    @param key (string): Document key or full handle (_id)
    @param options (table, optional): Options
        - ifNoneMatch (string): ETag for conditional request
        - ifMatch (string): ETag for conditional request
    @return table: Document
]]
function Document:get(collection, key, options)
    if not collection or collection == "" then
        error("Document: collection is required")
    end
    if not key or key == "" then
        error("Document: key is required")
    end

    local headers = {}
    if options then
        if options.ifNoneMatch then
            headers["If-None-Match"] = '"' .. options.ifNoneMatch .. '"'
        end
        if options.ifMatch then
            headers["If-Match"] = '"' .. options.ifMatch .. '"'
        end
    end

    local handle = key:find("/") and key or (collection .. "/" .. key)
    return self._client:get("/_api/document/" .. handle, { headers = headers })
end

--[[
    Check if a document exists

    @param collection (string): Collection name
    @param key (string): Document key
    @return boolean: true if exists
]]
function Document:exists(collection, key)
    local ok, _ = pcall(function()
        return self:get(collection, key)
    end)
    return ok
end

--[[
    Get document header (revision) only

    @param collection (string): Collection name
    @param key (string): Document key
    @return table: Headers with _rev
]]
function Document:head(collection, key)
    if not collection or collection == "" then
        error("Document: collection is required")
    end
    if not key or key == "" then
        error("Document: key is required")
    end

    local handle = key:find("/") and key or (collection .. "/" .. key)
    local _, response = self._client:request("HEAD", "/_api/document/" .. handle)
    return {
        _rev = response.headers["etag"] and response.headers["etag"]:gsub('"', '') or nil
    }
end

--[[
    Create a new document

    @param collection (string): Collection name
    @param document (table): Document data
    @param options (table, optional): Options
        - waitForSync (boolean): Wait for sync to disk
        - returnNew (boolean): Return the new document
        - returnOld (boolean): Return the old document (for overwrite)
        - silent (boolean): Don't return metadata
        - overwrite (boolean): Overwrite existing document
        - overwriteMode (string): "ignore", "update", "replace", "conflict"
        - keepNull (boolean): Keep null values (for update mode)
        - mergeObjects (boolean): Merge objects (for update mode)
        - refillIndexCaches (boolean): Refill index caches
        - versionAttribute (string): Attribute for versioning
    @return table: Created document metadata
]]
function Document:create(collection, document, options)
    if not collection or collection == "" then
        error("Document: collection is required")
    end
    if not document then
        error("Document: document is required")
    end

    return self._client:post(
        "/_api/document/" .. collection,
        document,
        { query = buildDocumentQuery(options) }
    )
end

--[[
    Create multiple documents

    @param collection (string): Collection name
    @param documents (table): Array of documents
    @param options (table, optional): Same as create()
    @return table: Array of created document metadata
]]
function Document:createMany(collection, documents, options)
    if not collection or collection == "" then
        error("Document: collection is required")
    end
    if not documents or #documents == 0 then
        error("Document: documents array is required")
    end

    return self._client:post(
        "/_api/document/" .. collection,
        documents,
        { query = buildDocumentQuery(options) }
    )
end

--[[
    Replace a document (full update)

    @param collection (string): Collection name
    @param key (string): Document key
    @param document (table): New document data
    @param options (table, optional): Options
        - waitForSync (boolean): Wait for sync
        - returnNew (boolean): Return new document
        - returnOld (boolean): Return old document
        - silent (boolean): Don't return metadata
        - ignoreRevs (boolean): Ignore revision conflicts
        - ifMatch (string): Conditional update by revision
        - refillIndexCaches (boolean): Refill index caches
        - versionAttribute (string): Version attribute
    @return table: Replaced document metadata
]]
function Document:replace(collection, key, document, options)
    if not collection or collection == "" then
        error("Document: collection is required")
    end
    if not key or key == "" then
        error("Document: key is required")
    end
    if not document then
        error("Document: document is required")
    end

    local headers = {}
    if options and options.ifMatch then
        headers["If-Match"] = '"' .. options.ifMatch .. '"'
    end

    local handle = key:find("/") and key or (collection .. "/" .. key)
    return self._client:put(
        "/_api/document/" .. handle,
        document,
        { query = buildDocumentQuery(options), headers = headers }
    )
end

--[[
    Replace multiple documents

    @param collection (string): Collection name
    @param documents (table): Array of documents (must include _key)
    @param options (table, optional): Same as replace()
    @return table: Array of replaced document metadata
]]
function Document:replaceMany(collection, documents, options)
    if not collection or collection == "" then
        error("Document: collection is required")
    end
    if not documents or #documents == 0 then
        error("Document: documents array is required")
    end

    return self._client:put(
        "/_api/document/" .. collection,
        documents,
        { query = buildDocumentQuery(options) }
    )
end

--[[
    Update a document (partial update)

    @param collection (string): Collection name
    @param key (string): Document key
    @param document (table): Partial document data
    @param options (table, optional): Options
        - waitForSync (boolean): Wait for sync
        - returnNew (boolean): Return new document
        - returnOld (boolean): Return old document
        - silent (boolean): Don't return metadata
        - ignoreRevs (boolean): Ignore revision conflicts
        - ifMatch (string): Conditional update by revision
        - keepNull (boolean): Keep null values (default: true)
        - mergeObjects (boolean): Merge nested objects (default: true)
        - refillIndexCaches (boolean): Refill index caches
        - versionAttribute (string): Version attribute
    @return table: Updated document metadata
]]
function Document:update(collection, key, document, options)
    if not collection or collection == "" then
        error("Document: collection is required")
    end
    if not key or key == "" then
        error("Document: key is required")
    end
    if not document then
        error("Document: document is required")
    end

    local headers = {}
    if options and options.ifMatch then
        headers["If-Match"] = '"' .. options.ifMatch .. '"'
    end

    local handle = key:find("/") and key or (collection .. "/" .. key)
    return self._client:patch(
        "/_api/document/" .. handle,
        document,
        { query = buildDocumentQuery(options), headers = headers }
    )
end

--[[
    Update multiple documents

    @param collection (string): Collection name
    @param documents (table): Array of partial documents (must include _key)
    @param options (table, optional): Same as update()
    @return table: Array of updated document metadata
]]
function Document:updateMany(collection, documents, options)
    if not collection or collection == "" then
        error("Document: collection is required")
    end
    if not documents or #documents == 0 then
        error("Document: documents array is required")
    end

    return self._client:patch(
        "/_api/document/" .. collection,
        documents,
        { query = buildDocumentQuery(options) }
    )
end

--[[
    Delete a document

    @param collection (string): Collection name
    @param key (string): Document key
    @param options (table, optional): Options
        - waitForSync (boolean): Wait for sync
        - returnOld (boolean): Return deleted document
        - silent (boolean): Don't return metadata
        - ifMatch (string): Conditional delete by revision
        - refillIndexCaches (boolean): Refill index caches
    @return table: Deleted document metadata
]]
function Document:delete(collection, key, options)
    if not collection or collection == "" then
        error("Document: collection is required")
    end
    if not key or key == "" then
        error("Document: key is required")
    end

    local headers = {}
    if options and options.ifMatch then
        headers["If-Match"] = '"' .. options.ifMatch .. '"'
    end

    local handle = key:find("/") and key or (collection .. "/" .. key)
    return self._client:delete(
        "/_api/document/" .. handle,
        { query = buildDocumentQuery(options), headers = headers }
    )
end

--[[
    Delete multiple documents

    @param collection (string): Collection name
    @param keys (table): Array of document keys or selectors
    @param options (table, optional): Same as delete()
    @return table: Array of deleted document metadata
]]
function Document:deleteMany(collection, keys, options)
    if not collection or collection == "" then
        error("Document: collection is required")
    end
    if not keys or #keys == 0 then
        error("Document: keys array is required")
    end

    return self._client:request(
        "DELETE",
        "/_api/document/" .. collection,
        { body = keys, query = buildDocumentQuery(options) }
    )
end

--[[
    Get multiple documents by keys

    @param collection (string): Collection name
    @param keys (table): Array of document keys
    @param options (table, optional): Options
        - onlyget (boolean): Only return found documents (no errors)
        - ignoreRevs (boolean): Ignore revision in selectors
    @return table: Array of documents
]]
function Document:getMany(collection, keys, options)
    if not collection or collection == "" then
        error("Document: collection is required")
    end
    if not keys or #keys == 0 then
        error("Document: keys array is required")
    end

    local query = {}
    if options then
        if options.onlyget then query.onlyget = true end
        if options.ignoreRevs then query.ignoreRevs = true end
    end

    local data = self._client:put(
        "/_api/document/" .. collection,
        keys,
        { query = next(query) and query or nil }
    )

    return data
end

--[[
    Import documents from JSON array

    @param collection (string): Collection name
    @param documents (table): Array of documents
    @param options (table, optional): Import options
        - type (string): "documents", "list", "auto"
        - fromPrefix (string): Prefix for _from
        - toPrefix (string): Prefix for _to
        - overwrite (boolean): Overwrite collection
        - waitForSync (boolean): Wait for sync
        - onDuplicate (string): "error", "update", "replace", "ignore"
        - complete (boolean): Fail on any error
        - details (boolean): Return detailed results
    @return table: Import results
]]
function Document:import(collection, documents, options)
    if not collection or collection == "" then
        error("Document: collection is required")
    end
    if not documents then
        error("Document: documents is required")
    end

    options = options or {}
    local query = { collection = collection }

    local valid_params = {
        "type", "fromPrefix", "toPrefix", "overwrite",
        "waitForSync", "onDuplicate", "complete", "details"
    }
    for _, param in ipairs(valid_params) do
        if options[param] ~= nil then
            query[param] = options[param]
        end
    end

    -- Build JSONL format for import
    local lines = {}
    for _, doc in ipairs(documents) do
        table.insert(lines, json.encode(doc))
    end
    local body = table.concat(lines, "\n")

    return self._client:request("POST", "/_api/import", {
        query = query,
        raw_body = body,
        headers = { ["Content-Type"] = "application/x-ndjson" }
    })
end

--[[
    Export documents from a collection

    @param collection (string): Collection name
    @param options (table, optional): Export options
        - flush (boolean): Flush WAL before export
        - flushWait (number): Wait time for flush
        - count (number): Maximum documents to export
        - batchSize (number): Batch size
        - restrict (table): Attribute restrictions
            - type (string): "include" or "exclude"
            - fields (table): Array of field names
        - ttl (number): Cursor TTL
    @return table: Export cursor
]]
function Document:export(collection, options)
    if not collection or collection == "" then
        error("Document: collection is required")
    end

    local body = options or {}
    body.collection = collection

    return self._client:post("/_api/export", body)
end

return Document
