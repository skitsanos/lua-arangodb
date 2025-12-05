--[[
    ArangoDB Admin Operations Module
    Handles server administration, monitoring, and cluster operations
]]

local Admin = {}
Admin.__index = Admin

function Admin.new(client)
    local self = setmetatable({}, Admin)
    self._client = client
    return self
end

-- ============================================================================
-- Server Information
-- ============================================================================

--[[
    Get server version

    @param details (boolean, optional): Include detailed info
    @return table: Version information
]]
function Admin:version(details)
    local query = nil
    if details then
        query = { details = true }
    end
    return self._client:get("/_api/version", { query = query })
end

--[[
    Get storage engine information

    @return table: Engine information
]]
function Admin:engine()
    return self._client:get("/_api/engine")
end

--[[
    Get server ID (cluster)

    @return table: Server ID
]]
function Admin:serverId()
    return self._client:get("/_admin/server/id")
end

--[[
    Get server role

    @return table: Server role (SINGLE, COORDINATOR, PRIMARY, AGENT)
]]
function Admin:serverRole()
    return self._client:get("/_admin/server/role")
end

--[[
    Get server availability

    @return table: Availability status
]]
function Admin:serverAvailability()
    return self._client:get("/_admin/server/availability")
end

--[[
    Get server mode

    @return table: Server mode (default, readonly)
]]
function Admin:serverMode()
    return self._client:get("/_admin/server/mode")
end

--[[
    Set server mode (readonly)

    @param mode (string): "default" or "readonly"
    @return table: Updated mode
]]
function Admin:setServerMode(mode)
    return self._client:put("/_admin/server/mode", { mode = mode })
end

--[[
    Get server license (Enterprise)

    @return table: License information
]]
function Admin:license()
    return self._client:get("/_admin/license")
end

--[[
    Set server license (Enterprise)

    @param license (string): License string
    @return table: Operation result
]]
function Admin:setLicense(license)
    return self._client:put("/_admin/license", { license = license })
end

-- ============================================================================
-- Statistics and Monitoring
-- ============================================================================

--[[
    Get server statistics

    @return table: Statistics
]]
function Admin:statistics()
    return self._client:get("/_admin/statistics")
end

--[[
    Get statistics description

    @return table: Statistics descriptions
]]
function Admin:statisticsDescription()
    return self._client:get("/_admin/statistics-description")
end

--[[
    Get metrics in Prometheus format

    @param serverId (string, optional): Server ID (cluster)
    @return string: Prometheus metrics
]]
function Admin:metrics(serverId)
    local query = nil
    if serverId then
        query = { serverId = serverId }
    end
    local data, response = self._client:get("/_admin/metrics/v2", {
        query = query,
        headers = { ["Accept"] = "text/plain" }
    })
    return response.body
end

--[[
    Get cluster metrics (cluster)

    @return string: Prometheus metrics
]]
function Admin:clusterMetrics()
    local _, response = self._client:get("/_admin/metrics/v2", {
        query = { mode = "read-global" },
        headers = { ["Accept"] = "text/plain" }
    })
    return response.body
end

-- ============================================================================
-- Log Operations
-- ============================================================================

--[[
    Get server log entries

    @param options (table, optional): Filter options
        - upto (string): Log level up to (fatal, error, warning, info, debug)
        - level (string): Exact log level
        - start (number): Start timestamp
        - size (number): Max entries
        - offset (number): Offset
        - search (string): Search text
        - sort (string): Sort direction (asc, desc)
        - serverId (string): Server ID (cluster)
    @return table: Log entries
]]
function Admin:logs(options)
    return self._client:get("/_admin/log/entries", { query = options })
end

--[[
    Get structured log entries

    @param options (table, optional): Filter options (same as logs)
    @return table: Structured log entries
]]
function Admin:logsStructured(options)
    return self._client:get("/_admin/log/structured", { query = options })
end

--[[
    Get log level settings

    @param serverId (string, optional): Server ID (cluster)
    @return table: Log levels by topic
]]
function Admin:logLevel(serverId)
    local query = nil
    if serverId then
        query = { serverId = serverId }
    end
    return self._client:get("/_admin/log/level", { query = query })
end

--[[
    Set log level

    @param levels (table): Topic => level mapping
    @param serverId (string, optional): Server ID (cluster)
    @return table: Updated log levels
]]
function Admin:setLogLevel(levels, serverId)
    local query = nil
    if serverId then
        query = { serverId = serverId }
    end
    return self._client:put("/_admin/log/level", levels, { query = query })
end

-- ============================================================================
-- Cluster Operations
-- ============================================================================

--[[
    Get cluster health

    @return table: Cluster health information
]]
function Admin:clusterHealth()
    return self._client:get("/_admin/cluster/health")
end

--[[
    Get cluster endpoints

    @return table: Array of cluster endpoints
]]
function Admin:clusterEndpoints()
    local data = self._client:get("/_api/cluster/endpoints")
    return data.endpoints
end

--[[
    Get cluster statistics (coordinator)

    @param dbserver (string, optional): DB-Server ID to query
    @return table: Cluster statistics
]]
function Admin:clusterStatistics(dbserver)
    local query = nil
    if dbserver then
        query = { DBserver = dbserver }
    end
    return self._client:get("/_admin/clusterStatistics", { query = query })
end

--[[
    Get cluster node info

    @return table: Cluster node information
]]
function Admin:clusterNodeInfo()
    return self._client:get("/_admin/cluster/nodeInfo")
end

--[[
    Get cluster node version

    @return table: Cluster node versions
]]
function Admin:clusterNodeVersion()
    return self._client:get("/_admin/cluster/nodeVersion")
end

--[[
    Perform maintenance operations on a DB-Server

    @param serverId (string): DB-Server ID
    @param mode (string): "maintenance" or "normal"
    @param options (table, optional): Options
        - timeout (number): Maintenance timeout in seconds
    @return table: Operation result
]]
function Admin:maintenance(serverId, mode, options)
    local body = { mode = mode }
    if options and options.timeout then
        body.timeout = options.timeout
    end
    return self._client:put("/_admin/cluster/maintenance/" .. serverId, body)
end

--[[
    Clean out a DB-Server (remove from cluster)

    @param serverId (string): DB-Server ID
    @return table: Job ID
]]
function Admin:cleanOutServer(serverId)
    return self._client:post("/_admin/cluster/cleanOutServer", { server = serverId })
end

--[[
    Resign leadership of a DB-Server

    @return table: Operation result
]]
function Admin:resignLeadership()
    return self._client:post("/_admin/cluster/resignLeadership", {})
end

--[[
    Move shard leadership

    @param options (table): Move options
        - database (string): Database name
        - collection (string): Collection name
        - shard (string): Shard name
        - fromServer (string): Source server
        - toServer (string): Target server
    @return table: Job ID
]]
function Admin:moveShard(options)
    return self._client:post("/_admin/cluster/moveShard", options)
end

--[[
    Rebalance shards

    @param options (table, optional): Rebalance options
        - maximumNumberOfMoves (number): Max moves per rebalance
        - leaderChanges (boolean): Include leader changes
        - moveLeaders (boolean): Move leaders
        - moveFollowers (boolean): Move followers
        - piFactor (number): Priority factor
        - databasesExcluded (table): Databases to exclude
    @return table: Rebalance plan
]]
function Admin:rebalanceShards(options)
    return self._client:post("/_admin/cluster/rebalanceShards", options or {})
end

--[[
    Execute rebalance plan

    @param version (number): Plan version
    @param moves (table): Array of shard moves
    @return table: Operation result
]]
function Admin:executeRebalance(version, moves)
    return self._client:post("/_admin/cluster/rebalanceShards", {
        version = version,
        moves = moves
    })
end

-- ============================================================================
-- Async Jobs
-- ============================================================================

--[[
    List pending/done async jobs

    @param status (string): "pending" or "done"
    @param count (number, optional): Max jobs to return
    @return table: Array of job IDs
]]
function Admin:jobs(status, count)
    local query = nil
    if count then
        query = { count = count }
    end
    return self._client:get("/_api/job/" .. status, { query = query })
end

--[[
    Get async job result

    @param jobId (string): Job ID
    @return table: Job result
]]
function Admin:jobResult(jobId)
    return self._client:put("/_api/job/" .. jobId, {})
end

--[[
    Cancel async job

    @param jobId (string): Job ID
    @return table: Operation result
]]
function Admin:cancelJob(jobId)
    return self._client:put("/_api/job/" .. jobId .. "/cancel", {})
end

--[[
    Delete async job results

    @param jobType (string): "all", "expired", or specific job ID
    @param stamp (number, optional): Timestamp for expired jobs
    @return table: Operation result
]]
function Admin:deleteJobs(jobType, stamp)
    local query = nil
    if stamp then
        query = { stamp = stamp }
    end
    return self._client:delete("/_api/job/" .. jobType, { query = query })
end

-- ============================================================================
-- Tasks
-- ============================================================================

--[[
    List scheduled tasks

    @return table: Array of tasks
]]
function Admin:tasks()
    local data = self._client:get("/_api/tasks")
    return data
end

--[[
    Get a task by ID

    @param taskId (string): Task ID
    @return table: Task information
]]
function Admin:task(taskId)
    return self._client:get("/_api/tasks/" .. taskId)
end

--[[
    Create a task

    @param options (table): Task options
        - name (string): Task name
        - command (string): JavaScript command
        - params (table): Parameters
        - period (number): Period in seconds (for recurring)
        - offset (number): Offset in seconds
        - id (string, optional): Custom task ID
        - runOnCoordinator (boolean): Run on coordinator (cluster)
    @return table: Created task
]]
function Admin:createTask(options)
    return self._client:post("/_api/tasks", options)
end

--[[
    Delete a task

    @param taskId (string): Task ID
    @return table: Operation result
]]
function Admin:deleteTask(taskId)
    return self._client:delete("/_api/tasks/" .. taskId)
end

-- ============================================================================
-- Miscellaneous
-- ============================================================================

--[[
    Get server time

    @return table: Server time
]]
function Admin:time()
    return self._client:get("/_admin/time")
end

--[[
    Echo request (for testing)

    @param body (table, optional): Request body
    @return table: Echoed request
]]
function Admin:echo(body)
    return self._client:post("/_admin/echo", body or {})
end

--[[
    Reload routing

    @return table: Operation result
]]
function Admin:reloadRouting()
    return self._client:post("/_admin/routing/reload", {})
end

--[[
    Execute server script (development mode only)

    @param script (string): JavaScript code
    @return any: Script result
]]
function Admin:execute(script)
    local data = self._client:post("/_admin/execute", nil, {
        raw_body = script,
        headers = { ["Content-Type"] = "application/x-javascript" }
    })
    return data
end

--[[
    Shutdown server

    @param soft (boolean, optional): Soft shutdown
    @return table: Operation result
]]
function Admin:shutdown(soft)
    local query = nil
    if soft then
        query = { soft = true }
    end
    return self._client:delete("/_admin/shutdown", { query = query })
end

--[[
    Compact all data

    @param options (table, optional): Options
        - changeLevel (boolean): Change compaction level
        - compactBottomMostLevel (boolean): Compact bottom-most level
    @return table: Operation result
]]
function Admin:compact(options)
    return self._client:put("/_admin/compact", options or {})
end

--[[
    Support info (for debugging)

    @return table: Support information
]]
function Admin:supportInfo()
    return self._client:get("/_admin/support-info")
end

return Admin
