# Admin Module Tests
# Tests server administration operations

GET http://localhost:8080/test/admin
HTTP 200
[Asserts]
body contains "Get Version"
body contains "Get Engine"
body contains "Get Statistics"
body contains "Get Server Role"
body contains "Get Server Time"
body contains "Get Log Level"
body contains "List Tasks"
body contains "0 failed"
body not contains "✗"
