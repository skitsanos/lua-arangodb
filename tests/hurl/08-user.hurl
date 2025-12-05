# User Module Tests
# Tests user management and permissions

GET http://localhost:8080/test/user
HTTP 200
[Asserts]
body contains "List Users"
body contains "Create User"
body contains "Get User"
body contains "User Exists"
body contains "Update User"
body contains "Set Database Permission"
body contains "Get Database Permission"
body contains "Delete User"
body contains "0 failed"
body not contains "✗"
