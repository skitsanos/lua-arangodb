# Full Test Suite
# Runs the complete test suite through OpenResty

GET http://localhost:8080/test
HTTP 200
[Asserts]
body contains "lua-arangodb Test Suite"
body contains "Server Tests"
body contains "Database Tests"
body contains "Collection Tests"
body contains "Document Tests"
body contains "Query Tests"
body contains "Index Tests"
body contains "Transaction Tests"
body contains "Cleanup"
body contains "0 failed"
body contains "Done."
body not contains "FATAL"
body not contains "✗"
