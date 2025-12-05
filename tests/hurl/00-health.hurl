# Health Check Test
# Verifies the OpenResty server and ArangoDB connection are working

GET http://localhost:8080/health
HTTP 200
[Asserts]
body contains "ok"
