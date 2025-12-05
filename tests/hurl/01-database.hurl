# Database Module Tests
# Tests database operations: list, create, exists, drop

GET http://localhost:8080/test/database
HTTP 200
[Asserts]
body contains "List Databases"
body contains "Create Database"
body contains "Database Exists"
body contains "Drop Database"
body contains "0 failed"
body not contains "✗"
