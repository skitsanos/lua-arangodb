# Index Module Tests
# Tests index management operations

GET http://localhost:8080/test/index
HTTP 200
[Asserts]
body contains "List Indexes"
body contains "Create Persistent Index"
body contains "Create Unique Index"
body contains "Create TTL Index"
body contains "Create Geo Index"
body contains "Get Index"
body contains "Drop Index"
body contains "0 failed"
body not contains "✗"
