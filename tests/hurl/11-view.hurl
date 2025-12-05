# View Module Tests
# Tests ArangoSearch view operations

GET http://localhost:8080/test/view
HTTP 200
[Asserts]
body contains "List Views"
body contains "Create ArangoSearch View"
body contains "Get View"
body contains "View Properties"
body contains "Drop View"
body contains "0 failed"
body not contains "✗"
