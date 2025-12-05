# AQL Query Endpoint Tests
# Tests the interactive AQL query endpoint

# Test simple query
POST http://localhost:8080/query
Content-Type: application/json
{
    "query": "FOR i IN 1..5 RETURN i"
}
HTTP 200
[Asserts]
jsonpath "$.error" == false
jsonpath "$.result" count == 5
jsonpath "$.result[0]" == 1
jsonpath "$.result[4]" == 5


# Test query with bind vars
POST http://localhost:8080/query
Content-Type: application/json
{
    "query": "FOR i IN 1..@max RETURN i * @multiplier",
    "bindVars": {
        "max": 3,
        "multiplier": 10
    }
}
HTTP 200
[Asserts]
jsonpath "$.error" == false
jsonpath "$.result" count == 3
jsonpath "$.result[0]" == 10
jsonpath "$.result[1]" == 20
jsonpath "$.result[2]" == 30


# Test invalid query (should return error)
POST http://localhost:8080/query
Content-Type: application/json
{
    "query": "INVALID SYNTAX HERE"
}
HTTP 400
[Asserts]
jsonpath "$.error" == true
jsonpath "$.message" exists
