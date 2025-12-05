--[[
    ArangoDB Analyzer Operations Module
    Handles text analyzer management for ArangoSearch
]]

local Analyzer = {}
Analyzer.__index = Analyzer

-- Analyzer types
Analyzer.TYPE_IDENTITY = "identity"
Analyzer.TYPE_DELIMITER = "delimiter"
Analyzer.TYPE_STEM = "stem"
Analyzer.TYPE_NORM = "norm"
Analyzer.TYPE_NGRAM = "ngram"
Analyzer.TYPE_TEXT = "text"
Analyzer.TYPE_AQL = "aql"
Analyzer.TYPE_PIPELINE = "pipeline"
Analyzer.TYPE_STOPWORDS = "stopwords"
Analyzer.TYPE_COLLATION = "collation"
Analyzer.TYPE_SEGMENTATION = "segmentation"
Analyzer.TYPE_NEAREST_NEIGHBORS = "nearest_neighbors"
Analyzer.TYPE_CLASSIFICATION = "classification"
Analyzer.TYPE_MINHASH = "minhash"
Analyzer.TYPE_GEOJSON = "geojson"
Analyzer.TYPE_GEOPOINT = "geopoint"
Analyzer.TYPE_GEO_S2 = "geo_s2"
Analyzer.TYPE_WILDCARD = "wildcard"

function Analyzer.new(client)
    local self = setmetatable({}, Analyzer)
    self._client = client
    return self
end

--[[
    List all analyzers in the current database

    @return table: Array of analyzer objects
]]
function Analyzer:list()
    local data = self._client:get("/_api/analyzer")
    return data.result
end

--[[
    Get an analyzer by name

    @param name (string): Analyzer name
    @return table: Analyzer information
]]
function Analyzer:get(name)
    if not name or name == "" then
        error("Analyzer: name is required")
    end
    return self._client:get("/_api/analyzer/" .. name)
end

--[[
    Check if an analyzer exists

    @param name (string): Analyzer name
    @return boolean: true if exists
]]
function Analyzer:exists(name)
    local ok, _ = pcall(function()
        return self:get(name)
    end)
    return ok
end

--[[
    Create an analyzer

    @param name (string): Analyzer name
    @param type (string): Analyzer type
    @param properties (table, optional): Type-specific properties
    @param features (table, optional): Features array ("frequency", "norm", "position", "offset")
    @return table: Created analyzer info
]]
function Analyzer:create(name, type, properties, features)
    if not name or name == "" then
        error("Analyzer: name is required")
    end
    if not type or type == "" then
        error("Analyzer: type is required")
    end

    local body = {
        name = name,
        type = type
    }

    if properties then
        body.properties = properties
    end

    if features then
        body.features = features
    end

    return self._client:post("/_api/analyzer", body)
end

--[[
    Delete an analyzer

    @param name (string): Analyzer name
    @param force (boolean, optional): Force deletion even if in use
    @return table: Operation result
]]
function Analyzer:delete(name, force)
    if not name or name == "" then
        error("Analyzer: name is required")
    end

    local query = nil
    if force then
        query = { force = true }
    end

    return self._client:delete("/_api/analyzer/" .. name, { query = query })
end

-- ============================================================================
-- Analyzer Type Helpers
-- ============================================================================

--[[
    Create an identity analyzer

    @param name (string): Analyzer name
    @param features (table, optional): Features
    @return table: Created analyzer
]]
function Analyzer:createIdentity(name, features)
    return self:create(name, Analyzer.TYPE_IDENTITY, nil, features)
end

--[[
    Create a delimiter analyzer

    @param name (string): Analyzer name
    @param delimiter (string): Delimiter character
    @param features (table, optional): Features
    @return table: Created analyzer
]]
function Analyzer:createDelimiter(name, delimiter, features)
    return self:create(name, Analyzer.TYPE_DELIMITER, {
        delimiter = delimiter
    }, features)
end

--[[
    Create a stem analyzer

    @param name (string): Analyzer name
    @param locale (string): Language locale (e.g., "en", "de")
    @param features (table, optional): Features
    @return table: Created analyzer
]]
function Analyzer:createStem(name, locale, features)
    return self:create(name, Analyzer.TYPE_STEM, {
        locale = locale
    }, features)
end

--[[
    Create a norm analyzer

    @param name (string): Analyzer name
    @param locale (string): Language locale
    @param options (table, optional): Options
        - case (string): "lower", "upper", "none"
        - accent (boolean): Preserve accents
    @param features (table, optional): Features
    @return table: Created analyzer
]]
function Analyzer:createNorm(name, locale, options, features)
    local properties = {
        locale = locale
    }
    if options then
        if options.case then properties.case = options.case end
        if options.accent ~= nil then properties.accent = options.accent end
    end
    return self:create(name, Analyzer.TYPE_NORM, properties, features)
end

--[[
    Create an n-gram analyzer

    @param name (string): Analyzer name
    @param options (table): N-gram options
        - min (number): Minimum n-gram length
        - max (number): Maximum n-gram length
        - preserveOriginal (boolean): Keep original token
        - startMarker (string): Start marker character
        - endMarker (string): End marker character
        - streamType (string): "binary", "utf8"
    @param features (table, optional): Features
    @return table: Created analyzer
]]
function Analyzer:createNgram(name, options, features)
    return self:create(name, Analyzer.TYPE_NGRAM, options, features)
end

--[[
    Create a text analyzer

    @param name (string): Analyzer name
    @param locale (string): Language locale
    @param options (table, optional): Text options
        - case (string): Case handling
        - accent (boolean): Accent handling
        - stemming (boolean): Enable stemming
        - stopwords (table): Array of stopwords
        - stopwordsPath (string): Path to stopwords file
        - edgeNgram (table): Edge n-gram options
    @param features (table, optional): Features
    @return table: Created analyzer
]]
function Analyzer:createText(name, locale, options, features)
    local properties = {
        locale = locale
    }
    if options then
        for k, v in pairs(options) do
            properties[k] = v
        end
    end
    return self:create(name, Analyzer.TYPE_TEXT, properties, features)
end

--[[
    Create an AQL analyzer

    @param name (string): Analyzer name
    @param queryString (string): AQL query
    @param options (table, optional): AQL options
        - collapsePositions (boolean): Collapse token positions
        - keepNull (boolean): Keep null results
        - batchSize (number): Batch size
        - memoryLimit (number): Memory limit
        - returnType (string): "string", "number", "bool"
    @param features (table, optional): Features
    @return table: Created analyzer
]]
function Analyzer:createAQL(name, queryString, options, features)
    local properties = {
        queryString = queryString
    }
    if options then
        for k, v in pairs(options) do
            properties[k] = v
        end
    end
    return self:create(name, Analyzer.TYPE_AQL, properties, features)
end

--[[
    Create a pipeline analyzer

    @param name (string): Analyzer name
    @param pipeline (table): Array of analyzer definitions
    @param features (table, optional): Features
    @return table: Created analyzer
]]
function Analyzer:createPipeline(name, pipeline, features)
    return self:create(name, Analyzer.TYPE_PIPELINE, {
        pipeline = pipeline
    }, features)
end

--[[
    Create a stopwords analyzer

    @param name (string): Analyzer name
    @param stopwords (table): Array of stopwords
    @param options (table, optional): Options
        - hex (boolean): Hex-encoded stopwords
    @param features (table, optional): Features
    @return table: Created analyzer
]]
function Analyzer:createStopwords(name, stopwords, options, features)
    local properties = {
        stopwords = stopwords
    }
    if options and options.hex then
        properties.hex = true
    end
    return self:create(name, Analyzer.TYPE_STOPWORDS, properties, features)
end

--[[
    Create a collation analyzer

    @param name (string): Analyzer name
    @param locale (string): ICU locale
    @param features (table, optional): Features
    @return table: Created analyzer
]]
function Analyzer:createCollation(name, locale, features)
    return self:create(name, Analyzer.TYPE_COLLATION, {
        locale = locale
    }, features)
end

--[[
    Create a segmentation analyzer

    @param name (string): Analyzer name
    @param options (table, optional): Options
        - break (string): "all", "alpha", "graphic"
        - case (string): Case handling
    @param features (table, optional): Features
    @return table: Created analyzer
]]
function Analyzer:createSegmentation(name, options, features)
    return self:create(name, Analyzer.TYPE_SEGMENTATION, options, features)
end

--[[
    Create a GeoJSON analyzer

    @param name (string): Analyzer name
    @param options (table, optional): Options
        - type (string): "shape", "centroid", "point"
        - options (table): GeoJSON options
    @param features (table, optional): Features
    @return table: Created analyzer
]]
function Analyzer:createGeoJSON(name, options, features)
    return self:create(name, Analyzer.TYPE_GEOJSON, options, features)
end

--[[
    Create a GeoPoint analyzer

    @param name (string): Analyzer name
    @param options (table, optional): Options
        - latitude (table): Latitude path(s)
        - longitude (table): Longitude path(s)
    @param features (table, optional): Features
    @return table: Created analyzer
]]
function Analyzer:createGeoPoint(name, options, features)
    return self:create(name, Analyzer.TYPE_GEOPOINT, options, features)
end

--[[
    Create a Geo S2 analyzer

    @param name (string): Analyzer name
    @param options (table, optional): Options
        - format (string): "latLngDouble", "latLngInt", "s2Point"
        - type (string): "shape", "centroid", "point"
        - options (table): S2 options
    @param features (table, optional): Features
    @return table: Created analyzer
]]
function Analyzer:createGeoS2(name, options, features)
    return self:create(name, Analyzer.TYPE_GEO_S2, options, features)
end

--[[
    Create a MinHash analyzer (Enterprise)

    @param name (string): Analyzer name
    @param analyzer (table): Nested analyzer definition
    @param numHashes (number): Number of hash values
    @param features (table, optional): Features
    @return table: Created analyzer
]]
function Analyzer:createMinHash(name, analyzer, numHashes, features)
    return self:create(name, Analyzer.TYPE_MINHASH, {
        analyzer = analyzer,
        numHashes = numHashes
    }, features)
end

--[[
    Create a classification analyzer (Enterprise)

    @param name (string): Analyzer name
    @param modelLocation (string): Path to model
    @param options (table, optional): Options
        - topK (number): Top K predictions
        - threshold (number): Probability threshold
    @param features (table, optional): Features
    @return table: Created analyzer
]]
function Analyzer:createClassification(name, modelLocation, options, features)
    local properties = {
        model_location = modelLocation
    }
    if options then
        if options.topK then properties.top_k = options.topK end
        if options.threshold then properties.threshold = options.threshold end
    end
    return self:create(name, Analyzer.TYPE_CLASSIFICATION, properties, features)
end

--[[
    Create a nearest neighbors analyzer (Enterprise)

    @param name (string): Analyzer name
    @param modelLocation (string): Path to model
    @param options (table, optional): Options
        - topK (number): Top K results
    @param features (table, optional): Features
    @return table: Created analyzer
]]
function Analyzer:createNearestNeighbors(name, modelLocation, options, features)
    local properties = {
        model_location = modelLocation
    }
    if options and options.topK then
        properties.top_k = options.topK
    end
    return self:create(name, Analyzer.TYPE_NEAREST_NEIGHBORS, properties, features)
end

--[[
    Create a wildcard analyzer

    @param name (string): Analyzer name
    @param ngramSize (number, optional): N-gram size (default: 3)
    @param analyzer (table, optional): Nested analyzer
    @param features (table, optional): Features
    @return table: Created analyzer
]]
function Analyzer:createWildcard(name, ngramSize, analyzer, features)
    local properties = {}
    if ngramSize then properties.ngramSize = ngramSize end
    if analyzer then properties.analyzer = analyzer end
    return self:create(name, Analyzer.TYPE_WILDCARD, properties, features)
end

return Analyzer
