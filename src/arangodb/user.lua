--[[
    ArangoDB User Management Module
    Handles user and permission operations
]]

local User = {}
User.__index = User

-- Permission levels
User.PERMISSION_NONE = "none"
User.PERMISSION_RO = "ro"
User.PERMISSION_RW = "rw"

function User.new(client)
    local self = setmetatable({}, User)
    self._client = client
    return self
end

-- ============================================================================
-- User Management
-- ============================================================================

--[[
    List all users

    @return table: Array of user objects
]]
function User:list()
    local data = self._client:get("/_api/user")
    return data.result
end

--[[
    Get a user by name

    @param username (string): Username
    @return table: User information
]]
function User:get(username)
    if not username or username == "" then
        error("User: username is required")
    end
    local data = self._client:get("/_api/user/" .. username)
    return data
end

--[[
    Check if a user exists

    @param username (string): Username
    @return boolean: true if exists
]]
function User:exists(username)
    local ok, _ = pcall(function()
        return self:get(username)
    end)
    return ok
end

--[[
    Create a new user

    @param username (string, required): Username
    @param password (string, optional): Password
    @param options (table, optional): User options
        - active (boolean): Whether user is active (default: true)
        - extra (table): Additional user data
    @return table: Created user info
]]
function User:create(username, password, options)
    if not username or username == "" then
        error("User: username is required")
    end

    local body = {
        user = username,
        passwd = password or ""
    }

    if options then
        if options.active ~= nil then
            body.active = options.active
        end
        if options.extra then
            body.extra = options.extra
        end
    end

    return self._client:post("/_api/user", body)
end

--[[
    Replace a user (full update)

    @param username (string): Username
    @param password (string, optional): New password
    @param options (table, optional): User options
        - active (boolean): Whether user is active
        - extra (table): Additional user data
    @return table: Updated user info
]]
function User:replace(username, password, options)
    if not username or username == "" then
        error("User: username is required")
    end

    local body = {
        passwd = password or ""
    }

    if options then
        if options.active ~= nil then
            body.active = options.active
        end
        if options.extra then
            body.extra = options.extra
        end
    end

    return self._client:put("/_api/user/" .. username, body)
end

--[[
    Update a user (partial update)

    @param username (string): Username
    @param options (table): Fields to update
        - passwd (string): New password
        - active (boolean): Whether user is active
        - extra (table): Additional user data
    @return table: Updated user info
]]
function User:update(username, options)
    if not username or username == "" then
        error("User: username is required")
    end

    return self._client:patch("/_api/user/" .. username, options or {})
end

--[[
    Delete a user

    @param username (string): Username
    @return table: Operation result
]]
function User:delete(username)
    if not username or username == "" then
        error("User: username is required")
    end
    return self._client:delete("/_api/user/" .. username)
end

-- ============================================================================
-- Database Permissions
-- ============================================================================

--[[
    Get user's database permission

    @param username (string): Username
    @param database (string): Database name
    @return string: Permission level ("none", "ro", "rw")
]]
function User:getDatabasePermission(username, database)
    if not username or username == "" then
        error("User: username is required")
    end
    if not database or database == "" then
        error("User: database is required")
    end

    local data = self._client:get(
        "/_api/user/" .. username .. "/database/" .. database
    )
    return data.result
end

--[[
    Set user's database permission

    @param username (string): Username
    @param database (string): Database name
    @param permission (string): Permission level ("none", "ro", "rw")
    @return table: Operation result
]]
function User:setDatabasePermission(username, database, permission)
    if not username or username == "" then
        error("User: username is required")
    end
    if not database or database == "" then
        error("User: database is required")
    end
    if not permission then
        error("User: permission is required")
    end

    return self._client:put(
        "/_api/user/" .. username .. "/database/" .. database,
        { grant = permission }
    )
end

--[[
    Clear user's database permission

    @param username (string): Username
    @param database (string): Database name
    @return table: Operation result
]]
function User:clearDatabasePermission(username, database)
    if not username or username == "" then
        error("User: username is required")
    end
    if not database or database == "" then
        error("User: database is required")
    end

    return self._client:delete(
        "/_api/user/" .. username .. "/database/" .. database
    )
end

--[[
    List user's database permissions

    @param username (string): Username
    @param full (boolean, optional): Include collection permissions
    @return table: Database permissions
]]
function User:listDatabasePermissions(username, full)
    if not username or username == "" then
        error("User: username is required")
    end

    local query = nil
    if full then
        query = { full = true }
    end

    local data = self._client:get(
        "/_api/user/" .. username .. "/database",
        { query = query }
    )
    return data.result
end

-- ============================================================================
-- Collection Permissions
-- ============================================================================

--[[
    Get user's collection permission

    @param username (string): Username
    @param database (string): Database name
    @param collection (string): Collection name
    @return string: Permission level ("none", "ro", "rw")
]]
function User:getCollectionPermission(username, database, collection)
    if not username or username == "" then
        error("User: username is required")
    end
    if not database or database == "" then
        error("User: database is required")
    end
    if not collection or collection == "" then
        error("User: collection is required")
    end

    local data = self._client:get(
        "/_api/user/" .. username .. "/database/" .. database .. "/" .. collection
    )
    return data.result
end

--[[
    Set user's collection permission

    @param username (string): Username
    @param database (string): Database name
    @param collection (string): Collection name
    @param permission (string): Permission level ("none", "ro", "rw")
    @return table: Operation result
]]
function User:setCollectionPermission(username, database, collection, permission)
    if not username or username == "" then
        error("User: username is required")
    end
    if not database or database == "" then
        error("User: database is required")
    end
    if not collection or collection == "" then
        error("User: collection is required")
    end
    if not permission then
        error("User: permission is required")
    end

    return self._client:put(
        "/_api/user/" .. username .. "/database/" .. database .. "/" .. collection,
        { grant = permission }
    )
end

--[[
    Clear user's collection permission

    @param username (string): Username
    @param database (string): Database name
    @param collection (string): Collection name
    @return table: Operation result
]]
function User:clearCollectionPermission(username, database, collection)
    if not username or username == "" then
        error("User: username is required")
    end
    if not database or database == "" then
        error("User: database is required")
    end
    if not collection or collection == "" then
        error("User: collection is required")
    end

    return self._client:delete(
        "/_api/user/" .. username .. "/database/" .. database .. "/" .. collection
    )
end

-- ============================================================================
-- Convenience Methods
-- ============================================================================

--[[
    Grant read-write access to a database

    @param username (string): Username
    @param database (string): Database name
    @return table: Operation result
]]
function User:grantDatabase(username, database)
    return self:setDatabasePermission(username, database, User.PERMISSION_RW)
end

--[[
    Grant read-only access to a database

    @param username (string): Username
    @param database (string): Database name
    @return table: Operation result
]]
function User:grantDatabaseReadOnly(username, database)
    return self:setDatabasePermission(username, database, User.PERMISSION_RO)
end

--[[
    Revoke all access to a database

    @param username (string): Username
    @param database (string): Database name
    @return table: Operation result
]]
function User:revokeDatabase(username, database)
    return self:setDatabasePermission(username, database, User.PERMISSION_NONE)
end

--[[
    Grant read-write access to a collection

    @param username (string): Username
    @param database (string): Database name
    @param collection (string): Collection name
    @return table: Operation result
]]
function User:grantCollection(username, database, collection)
    return self:setCollectionPermission(username, database, collection, User.PERMISSION_RW)
end

--[[
    Grant read-only access to a collection

    @param username (string): Username
    @param database (string): Database name
    @param collection (string): Collection name
    @return table: Operation result
]]
function User:grantCollectionReadOnly(username, database, collection)
    return self:setCollectionPermission(username, database, collection, User.PERMISSION_RO)
end

--[[
    Revoke all access to a collection

    @param username (string): Username
    @param database (string): Database name
    @param collection (string): Collection name
    @return table: Operation result
]]
function User:revokeCollection(username, database, collection)
    return self:setCollectionPermission(username, database, collection, User.PERMISSION_NONE)
end

return User
