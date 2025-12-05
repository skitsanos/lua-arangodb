--[[
    ArangoDB Database Operations Module
    Handles database management operations
]]

local Database = {}
Database.__index = Database

function Database.new(client)
    local self = setmetatable({}, Database)
    self._client = client
    return self
end

--[[
    List all accessible databases
    @return table: Array of database names
]]
function Database:list()
    local data = self._client:get("/_api/database")
    return data.result
end

--[[
    List databases the current user can access
    @return table: Array of database names
]]
function Database:listUser()
    local data = self._client:get("/_api/database/user")
    return data.result
end

--[[
    Get information about the current database
    @return table: Database information
]]
function Database:current()
    local data = self._client:get("/_api/database/current")
    return data.result
end

--[[
    Check if a database exists
    @param name (string): Database name
    @return boolean: true if exists
]]
function Database:exists(name)
    local databases = self:list()
    for _, db in ipairs(databases) do
        if db == name then
            return true
        end
    end
    return false
end

--[[
    Create a new database

    @param name (string, required): Database name
    @param options (table, optional): Database options
        - sharding (string): Sharding method ("flexible" or "single") - cluster only
        - replicationFactor (number): Replication factor - cluster only
        - writeConcern (number): Write concern - cluster only
    @param users (table, optional): Array of user objects
        - username (string, required): User login name
        - passwd (string, optional): User password
        - active (boolean, optional): Whether user is active (default: true)
        - extra (table, optional): Additional user data

    @return table: Operation result
]]
function Database:create(name, options, users)
    if not name or name == "" then
        error("Database: name is required")
    end

    local payload = { name = name }

    if options then
        payload.options = options
    end

    if users then
        payload.users = users
    end

    return self._client:post("/_api/database", payload)
end

--[[
    Drop a database

    @param name (string, required): Database name to drop
    @return table: Operation result
]]
function Database:drop(name)
    if not name or name == "" then
        error("Database: name is required")
    end

    return self._client:delete("/_api/database/" .. name)
end

--[[
    Execute an AQL query (shorthand for query module)

    @param aql (string): AQL query string
    @param bindVars (table, optional): Bind parameters
    @param options (table, optional): Query options
    @return table: Query results
]]
function Database:query(aql, bindVars, options)
    return self._client.query:execute(aql, bindVars, options)
end

return Database
