# Graph Module Tests
# Tests graph operations: create, vertices, edges, drop

GET http://localhost:8080/test/graph
HTTP 200
[Asserts]
body contains "Create Graph"
body contains "List Graphs"
body contains "Get Graph"
body contains "List Vertex Collections"
body contains "Create Vertex"
body contains "Drop Graph"
body contains "0 failed"
body not contains "✗"
