# Transaction Module Tests
# Tests JavaScript and Stream transactions

GET http://localhost:8080/test/transaction
HTTP 200
[Asserts]
body contains "JavaScript Transaction"
body contains "Begin Stream Transaction"
body contains "List Transactions"
body contains "Transaction Run Helper"
body contains "0 failed"
body not contains "✗"
