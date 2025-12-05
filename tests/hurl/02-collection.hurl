# Collection Module Tests
# Tests collection operations: create, list, properties, drop

GET http://localhost:8080/test/collection
HTTP 200
[Asserts]
body contains "Create Document Collection"
body contains "List Collections"
body contains "Get Collection"
body contains "Collection Properties"
body contains "Collection Count"
body contains "Truncate Collection"
body contains "Create Edge Collection"
body contains "Drop Collections"
body contains "0 failed"
body not contains "✗"
