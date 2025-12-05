# Analyzer Module Tests
# Tests ArangoSearch analyzer operations

GET http://localhost:8080/test/analyzer
HTTP 200
[Asserts]
body contains "List Analyzers"
body contains "Create Text Analyzer"
body contains "Get Analyzer"
body contains "Delete Analyzer"
body contains "0 failed"
body not contains "✗"
