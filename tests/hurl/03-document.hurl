# Document Module Tests
# Tests document CRUD operations

GET http://localhost:8080/test/document
HTTP 200
[Asserts]
body contains "Create Document"
body contains "Get Document"
body contains "Document Exists"
body contains "Update Document"
body contains "Replace Document"
body contains "Create Many Documents"
body contains "Delete Document"
body contains "0 failed"
body not contains "✗"
