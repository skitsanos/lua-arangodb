--[[
    ArangoDB Foxx Service Operations Module
    Handles Foxx microservice management
]]

local Foxx = {}
Foxx.__index = Foxx

function Foxx.new(client)
    local self = setmetatable({}, Foxx)
    self._client = client
    return self
end

--[[
    List all installed Foxx services

    @param excludeSystem (boolean, optional): Exclude system services
    @return table: Array of service objects
]]
function Foxx:list(excludeSystem)
    local query = nil
    if excludeSystem then
        query = { excludeSystem = true }
    end
    return self._client:get("/_api/foxx", { query = query })
end

--[[
    Get service information

    @param mount (string): Service mount path
    @return table: Service information
]]
function Foxx:get(mount)
    if not mount or mount == "" then
        error("Foxx: mount is required")
    end
    return self._client:get("/_api/foxx/service", {
        query = { mount = mount }
    })
end

--[[
    Check if a service exists

    @param mount (string): Service mount path
    @return boolean: true if exists
]]
function Foxx:exists(mount)
    local ok, _ = pcall(function()
        return self:get(mount)
    end)
    return ok
end

--[[
    Install a Foxx service from a URL

    @param mount (string): Mount path for the service
    @param source (string): URL to service source (zip/tar.gz)
    @param options (table, optional): Installation options
        - development (boolean): Enable development mode
        - setup (boolean): Run setup script
        - legacy (boolean): Install in legacy mode
        - configuration (table): Service configuration
        - dependencies (table): Service dependencies
    @return table: Installed service info
]]
function Foxx:installFromUrl(mount, source, options)
    if not mount or mount == "" then
        error("Foxx: mount is required")
    end
    if not source or source == "" then
        error("Foxx: source is required")
    end

    local query = { mount = mount }
    if options then
        if options.development then query.development = true end
        if options.setup ~= nil then query.setup = options.setup end
        if options.legacy then query.legacy = true end
    end

    local body = {
        source = source
    }
    if options then
        if options.configuration then body.configuration = options.configuration end
        if options.dependencies then body.dependencies = options.dependencies end
    end

    return self._client:post("/_api/foxx", body, { query = query })
end

--[[
    Install a Foxx service from a local path (server-side)

    @param mount (string): Mount path for the service
    @param path (string): Server-side path to service source
    @param options (table, optional): Installation options
    @return table: Installed service info
]]
function Foxx:installFromPath(mount, path, options)
    if not mount or mount == "" then
        error("Foxx: mount is required")
    end
    if not path or path == "" then
        error("Foxx: path is required")
    end

    local query = { mount = mount }
    if options then
        if options.development then query.development = true end
        if options.setup ~= nil then query.setup = options.setup end
        if options.legacy then query.legacy = true end
    end

    local body = {
        source = path
    }
    if options then
        if options.configuration then body.configuration = options.configuration end
        if options.dependencies then body.dependencies = options.dependencies end
    end

    return self._client:post("/_api/foxx", body, { query = query })
end

--[[
    Install a Foxx service from uploaded zip data

    @param mount (string): Mount path for the service
    @param zipData (string): Raw zip file data
    @param options (table, optional): Installation options
    @return table: Installed service info
]]
function Foxx:installFromZip(mount, zipData, options)
    if not mount or mount == "" then
        error("Foxx: mount is required")
    end
    if not zipData then
        error("Foxx: zipData is required")
    end

    local query = { mount = mount }
    if options then
        if options.development then query.development = true end
        if options.setup ~= nil then query.setup = options.setup end
        if options.legacy then query.legacy = true end
    end

    return self._client:request("POST", "/_api/foxx", {
        query = query,
        raw_body = zipData,
        headers = { ["Content-Type"] = "application/zip" }
    })
end

--[[
    Install a Foxx service from JavaScript code

    @param mount (string): Mount path for the service
    @param code (string): JavaScript service code
    @param options (table, optional): Installation options
    @return table: Installed service info
]]
function Foxx:installFromJS(mount, code, options)
    if not mount or mount == "" then
        error("Foxx: mount is required")
    end
    if not code then
        error("Foxx: code is required")
    end

    local query = { mount = mount }
    if options then
        if options.development then query.development = true end
        if options.setup ~= nil then query.setup = options.setup end
        if options.legacy then query.legacy = true end
    end

    return self._client:request("POST", "/_api/foxx", {
        query = query,
        raw_body = code,
        headers = { ["Content-Type"] = "application/javascript" }
    })
end

--[[
    Replace a Foxx service

    @param mount (string): Mount path
    @param source (string): URL or path to new service source
    @param options (table, optional): Options
        - teardown (boolean): Run teardown script
        - setup (boolean): Run setup script
        - legacy (boolean): Install in legacy mode
        - force (boolean): Force replacement
        - configuration (table): Service configuration
        - dependencies (table): Service dependencies
    @return table: Replaced service info
]]
function Foxx:replace(mount, source, options)
    if not mount or mount == "" then
        error("Foxx: mount is required")
    end
    if not source or source == "" then
        error("Foxx: source is required")
    end

    local query = { mount = mount }
    if options then
        if options.teardown ~= nil then query.teardown = options.teardown end
        if options.setup ~= nil then query.setup = options.setup end
        if options.legacy then query.legacy = true end
        if options.force then query.force = true end
    end

    local body = {
        source = source
    }
    if options then
        if options.configuration then body.configuration = options.configuration end
        if options.dependencies then body.dependencies = options.dependencies end
    end

    return self._client:put("/_api/foxx/service", body, { query = query })
end

--[[
    Upgrade a Foxx service

    @param mount (string): Mount path
    @param source (string): URL or path to new service source
    @param options (table, optional): Options (same as replace)
    @return table: Upgraded service info
]]
function Foxx:upgrade(mount, source, options)
    if not mount or mount == "" then
        error("Foxx: mount is required")
    end
    if not source or source == "" then
        error("Foxx: source is required")
    end

    local query = { mount = mount }
    if options then
        if options.teardown ~= nil then query.teardown = options.teardown end
        if options.setup ~= nil then query.setup = options.setup end
        if options.legacy then query.legacy = true end
        if options.force then query.force = true end
    end

    local body = {
        source = source
    }
    if options then
        if options.configuration then body.configuration = options.configuration end
        if options.dependencies then body.dependencies = options.dependencies end
    end

    return self._client:patch("/_api/foxx/service", body, { query = query })
end

--[[
    Uninstall a Foxx service

    @param mount (string): Mount path
    @param options (table, optional): Options
        - teardown (boolean): Run teardown script (default: true)
    @return table: Operation result
]]
function Foxx:uninstall(mount, options)
    if not mount or mount == "" then
        error("Foxx: mount is required")
    end

    local query = { mount = mount }
    if options and options.teardown ~= nil then
        query.teardown = options.teardown
    end

    return self._client:delete("/_api/foxx/service", { query = query })
end

-- ============================================================================
-- Service Configuration
-- ============================================================================

--[[
    Get service configuration

    @param mount (string): Mount path
    @return table: Configuration
]]
function Foxx:getConfiguration(mount)
    if not mount or mount == "" then
        error("Foxx: mount is required")
    end
    return self._client:get("/_api/foxx/configuration", {
        query = { mount = mount }
    })
end

--[[
    Update service configuration

    @param mount (string): Mount path
    @param configuration (table): Configuration values
    @return table: Updated configuration
]]
function Foxx:updateConfiguration(mount, configuration)
    if not mount or mount == "" then
        error("Foxx: mount is required")
    end
    return self._client:patch("/_api/foxx/configuration", configuration, {
        query = { mount = mount }
    })
end

--[[
    Replace service configuration

    @param mount (string): Mount path
    @param configuration (table): New configuration
    @return table: New configuration
]]
function Foxx:replaceConfiguration(mount, configuration)
    if not mount or mount == "" then
        error("Foxx: mount is required")
    end
    return self._client:put("/_api/foxx/configuration", configuration, {
        query = { mount = mount }
    })
end

-- ============================================================================
-- Service Dependencies
-- ============================================================================

--[[
    Get service dependencies

    @param mount (string): Mount path
    @return table: Dependencies
]]
function Foxx:getDependencies(mount)
    if not mount or mount == "" then
        error("Foxx: mount is required")
    end
    return self._client:get("/_api/foxx/dependencies", {
        query = { mount = mount }
    })
end

--[[
    Update service dependencies

    @param mount (string): Mount path
    @param dependencies (table): Dependency values
    @return table: Updated dependencies
]]
function Foxx:updateDependencies(mount, dependencies)
    if not mount or mount == "" then
        error("Foxx: mount is required")
    end
    return self._client:patch("/_api/foxx/dependencies", dependencies, {
        query = { mount = mount }
    })
end

--[[
    Replace service dependencies

    @param mount (string): Mount path
    @param dependencies (table): New dependencies
    @return table: New dependencies
]]
function Foxx:replaceDependencies(mount, dependencies)
    if not mount or mount == "" then
        error("Foxx: mount is required")
    end
    return self._client:put("/_api/foxx/dependencies", dependencies, {
        query = { mount = mount }
    })
end

-- ============================================================================
-- Development Mode
-- ============================================================================

--[[
    Enable development mode for a service

    @param mount (string): Mount path
    @return table: Updated service info
]]
function Foxx:enableDevelopment(mount)
    if not mount or mount == "" then
        error("Foxx: mount is required")
    end
    return self._client:post("/_api/foxx/development", {}, {
        query = { mount = mount }
    })
end

--[[
    Disable development mode for a service

    @param mount (string): Mount path
    @return table: Updated service info
]]
function Foxx:disableDevelopment(mount)
    if not mount or mount == "" then
        error("Foxx: mount is required")
    end
    return self._client:delete("/_api/foxx/development", {
        query = { mount = mount }
    })
end

-- ============================================================================
-- Scripts
-- ============================================================================

--[[
    List available scripts for a service

    @param mount (string): Mount path
    @return table: Available scripts
]]
function Foxx:listScripts(mount)
    if not mount or mount == "" then
        error("Foxx: mount is required")
    end
    return self._client:get("/_api/foxx/scripts", {
        query = { mount = mount }
    })
end

--[[
    Run a script for a service

    @param mount (string): Mount path
    @param scriptName (string): Script name
    @param args (table, optional): Script arguments
    @return any: Script result
]]
function Foxx:runScript(mount, scriptName, args)
    if not mount or mount == "" then
        error("Foxx: mount is required")
    end
    if not scriptName or scriptName == "" then
        error("Foxx: scriptName is required")
    end
    return self._client:post("/_api/foxx/scripts/" .. scriptName, args or {}, {
        query = { mount = mount }
    })
end

-- ============================================================================
-- Other Operations
-- ============================================================================

--[[
    Get service README

    @param mount (string): Mount path
    @return string: README content
]]
function Foxx:readme(mount)
    if not mount or mount == "" then
        error("Foxx: mount is required")
    end
    local _, response = self._client:get("/_api/foxx/readme", {
        query = { mount = mount },
        headers = { ["Accept"] = "text/plain" }
    })
    return response.body
end

--[[
    Get service Swagger documentation

    @param mount (string): Mount path
    @return table: Swagger/OpenAPI spec
]]
function Foxx:swagger(mount)
    if not mount or mount == "" then
        error("Foxx: mount is required")
    end
    return self._client:get("/_api/foxx/swagger", {
        query = { mount = mount }
    })
end

--[[
    Download service bundle

    @param mount (string): Mount path
    @return string: Zip file data
]]
function Foxx:download(mount)
    if not mount or mount == "" then
        error("Foxx: mount is required")
    end
    local _, response = self._client:request("POST", "/_api/foxx/download", {
        query = { mount = mount },
        headers = { ["Accept"] = "application/zip" }
    })
    return response.body
end

--[[
    Run tests for a service

    @param mount (string): Mount path
    @param options (table, optional): Test options
        - reporter (string): "default", "suite", "stream", "xunit", "tap"
        - idiomatic (boolean): Use reporter's idiomatic format
        - filter (string): Filter test cases by name
    @return table: Test results
]]
function Foxx:runTests(mount, options)
    if not mount or mount == "" then
        error("Foxx: mount is required")
    end

    local query = { mount = mount }
    if options then
        if options.reporter then query.reporter = options.reporter end
        if options.idiomatic then query.idiomatic = true end
        if options.filter then query.filter = options.filter end
    end

    return self._client:post("/_api/foxx/tests", {}, { query = query })
end

--[[
    Commit local service state (cluster)

    @param replace (boolean, optional): Replace existing services
    @return table: Operation result
]]
function Foxx:commit(replace)
    local query = nil
    if replace then
        query = { replace = true }
    end
    return self._client:post("/_api/foxx/commit", {}, { query = query })
end

return Foxx
