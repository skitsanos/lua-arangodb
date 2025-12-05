--[[
    Pure Lua Base64 encoding/decoding
    Compatible with ngx.encode_base64/ngx.decode_base64 when available
]]

local base64 = {}

-- Use OpenResty's built-in if available
if ngx and ngx.encode_base64 then
    base64.encode = ngx.encode_base64
    base64.decode = ngx.decode_base64
    return base64
end

-- Base64 character set
local b64chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'

-- Encoding table
local encoding = {}
for i = 1, 64 do
    encoding[i - 1] = b64chars:sub(i, i)
end

-- Decoding table
local decoding = {}
for i = 1, 64 do
    decoding[b64chars:sub(i, i)] = i - 1
end

function base64.encode(data)
    if not data then return nil end

    local result = {}
    local len = #data
    local i = 1

    while i <= len do
        local a = data:byte(i) or 0
        local b = data:byte(i + 1) or 0
        local c = data:byte(i + 2) or 0

        local n = (a * 65536) + (b * 256) + c

        table.insert(result, encoding[math.floor(n / 262144) % 64])
        table.insert(result, encoding[math.floor(n / 4096) % 64])
        table.insert(result, encoding[math.floor(n / 64) % 64])
        table.insert(result, encoding[n % 64])

        i = i + 3
    end

    -- Add padding
    local padding = (3 - (len % 3)) % 3
    for j = 1, padding do
        result[#result - j + 1] = '='
    end

    return table.concat(result)
end

function base64.decode(data)
    if not data then return nil end

    -- Remove padding
    data = data:gsub('=', '')

    local result = {}
    local len = #data
    local i = 1

    while i <= len do
        local a = decoding[data:sub(i, i)] or 0
        local b = decoding[data:sub(i + 1, i + 1)] or 0
        local c = decoding[data:sub(i + 2, i + 2)] or 0
        local d = decoding[data:sub(i + 3, i + 3)] or 0

        local n = (a * 262144) + (b * 4096) + (c * 64) + d

        if i + 1 <= len then
            table.insert(result, string.char(math.floor(n / 65536) % 256))
        end
        if i + 2 <= len then
            table.insert(result, string.char(math.floor(n / 256) % 256))
        end
        if i + 3 <= len then
            table.insert(result, string.char(n % 256))
        end

        i = i + 4
    end

    return table.concat(result)
end

return base64
