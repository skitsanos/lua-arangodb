--[[
    ArangoDB Transaction Operations Module
    Handles both JavaScript transactions and Stream Transactions
]]

local Transaction = {}
Transaction.__index = Transaction

function Transaction.new(client)
    local self = setmetatable({}, Transaction)
    self._client = client
    return self
end

-- ============================================================================
-- JavaScript Transactions (single-request)
-- ============================================================================

--[[
    Execute a JavaScript transaction

    @param options (table): Transaction options
        - collections (table, required): Collection access declaration
            - read (table): Collections for read access
            - write (table): Collections for write access
            - exclusive (table): Collections for exclusive access
        - action (string, required): JavaScript function code
        - params (table, optional): Parameters to pass to the function
        - waitForSync (boolean, optional): Wait for sync
        - lockTimeout (number, optional): Lock timeout in seconds
        - maxTransactionSize (number, optional): Max transaction size
    @return any: Transaction result
]]
function Transaction:execute(options)
    if not options or not options.collections then
        error("Transaction: collections is required")
    end
    if not options.action then
        error("Transaction: action is required")
    end

    local data = self._client:post("/_api/transaction", options)
    return data.result
end

-- ============================================================================
-- Stream Transactions (multi-request)
-- ============================================================================

--[[
    Begin a stream transaction

    @param collections (table): Collection access declaration
        - read (table): Collections for read access
        - write (table): Collections for write access
        - exclusive (table): Collections for exclusive access
    @param options (table, optional): Transaction options
        - waitForSync (boolean): Wait for sync
        - allowImplicit (boolean): Allow implicit collections
        - lockTimeout (number): Lock timeout in seconds
        - maxTransactionSize (number): Max transaction size
        - skipFastLockRound (boolean): Skip fast lock acquisition
    @return table: Transaction info with ID
]]
function Transaction:begin(collections, options)
    if not collections then
        error("Transaction: collections is required")
    end

    local body = {
        collections = collections
    }

    if options then
        local allowed = {
            "waitForSync", "allowImplicit", "lockTimeout",
            "maxTransactionSize", "skipFastLockRound"
        }
        for _, opt in ipairs(allowed) do
            if options[opt] ~= nil then
                body[opt] = options[opt]
            end
        end
    end

    local data = self._client:post("/_api/transaction/begin", body)
    return data.result
end

--[[
    Get stream transaction status

    @param transactionId (string): Transaction ID
    @return table: Transaction status
]]
function Transaction:status(transactionId)
    if not transactionId or transactionId == "" then
        error("Transaction: transactionId is required")
    end
    local data = self._client:get("/_api/transaction/" .. transactionId)
    return data.result
end

--[[
    Commit a stream transaction

    @param transactionId (string): Transaction ID
    @return table: Commit result
]]
function Transaction:commit(transactionId)
    if not transactionId or transactionId == "" then
        error("Transaction: transactionId is required")
    end
    local data = self._client:put("/_api/transaction/" .. transactionId, {})
    return data.result
end

--[[
    Abort a stream transaction

    @param transactionId (string): Transaction ID
    @return table: Abort result
]]
function Transaction:abort(transactionId)
    if not transactionId or transactionId == "" then
        error("Transaction: transactionId is required")
    end
    local data = self._client:delete("/_api/transaction/" .. transactionId)
    return data.result
end

--[[
    List all running stream transactions

    @return table: Array of transaction objects
]]
function Transaction:list()
    local data = self._client:get("/_api/transaction")
    return data.transactions
end

--[[
    Execute operations within a stream transaction context

    This is a helper that manages the transaction lifecycle:
    - Begins the transaction
    - Executes the callback with transaction ID
    - Commits on success or aborts on error

    @param collections (table): Collection access declaration
    @param callback (function): Function to execute (receives transactionId)
    @param options (table, optional): Transaction options
    @return any: Callback result
]]
function Transaction:run(collections, callback, options)
    local tx = self:begin(collections, options)
    local txId = tx.id

    local ok, result = pcall(function()
        return callback(txId)
    end)

    if ok then
        self:commit(txId)
        return result
    else
        pcall(function()
            self:abort(txId)
        end)
        error(result)
    end
end

-- ============================================================================
-- Transaction-aware operations
-- ============================================================================

--[[
    Helper to add transaction header to requests

    @param transactionId (string): Transaction ID
    @return table: Headers with transaction ID
]]
function Transaction:headers(transactionId)
    return {
        ["x-arango-trx-id"] = transactionId
    }
end

--[[
    Execute an AQL query within a transaction

    @param transactionId (string): Transaction ID
    @param aql (string): AQL query
    @param bindVars (table, optional): Bind parameters
    @param options (table, optional): Query options
    @return table: Query results
]]
function Transaction:query(transactionId, aql, bindVars, options)
    if not transactionId or transactionId == "" then
        error("Transaction: transactionId is required")
    end

    options = options or {}
    options.headers = self:headers(transactionId)

    return self._client.query:execute(aql, bindVars, options)
end

--[[
    Create a document within a transaction

    @param transactionId (string): Transaction ID
    @param collection (string): Collection name
    @param document (table): Document data
    @param options (table, optional): Document options
    @return table: Created document info
]]
function Transaction:createDocument(transactionId, collection, document, options)
    if not transactionId or transactionId == "" then
        error("Transaction: transactionId is required")
    end

    options = options or {}
    options.headers = self:headers(transactionId)

    return self._client.document:create(collection, document, options)
end

--[[
    Update a document within a transaction

    @param transactionId (string): Transaction ID
    @param collection (string): Collection name
    @param key (string): Document key
    @param document (table): Partial document data
    @param options (table, optional): Document options
    @return table: Updated document info
]]
function Transaction:updateDocument(transactionId, collection, key, document, options)
    if not transactionId or transactionId == "" then
        error("Transaction: transactionId is required")
    end

    options = options or {}
    options.headers = self:headers(transactionId)

    return self._client.document:update(collection, key, document, options)
end

--[[
    Delete a document within a transaction

    @param transactionId (string): Transaction ID
    @param collection (string): Collection name
    @param key (string): Document key
    @param options (table, optional): Document options
    @return table: Deleted document info
]]
function Transaction:deleteDocument(transactionId, collection, key, options)
    if not transactionId or transactionId == "" then
        error("Transaction: transactionId is required")
    end

    options = options or {}
    options.headers = self:headers(transactionId)

    return self._client.document:delete(collection, key, options)
end

return Transaction
