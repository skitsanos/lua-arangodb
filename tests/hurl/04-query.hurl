# Query Module Tests
# Tests AQL query execution and cursor operations

GET http://localhost:8080/test/query
HTTP 200
[Asserts]
body contains "Execute Query"
body contains "Query with Bind Vars"
body contains "Query All (pagination)"
body contains "Query Iterator"
body contains "Parse Query"
body contains "Explain Query"
body contains "Get Tracking Properties"
body contains "0 failed"
body not contains "✗"
