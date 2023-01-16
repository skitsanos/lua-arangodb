# ArangoDB Client for OpenResty

### Dependencies

- lua-cjson
- base64
- lua-resty-http

### Testing with resty utility

1. Open a terminal window and navigate to your Lua script's directory.
2. Run the command `resty resty [your lua script name]` to execute the script.
3. If your Lua script requires any input or parameters, you can pass them as arguments after the script name.
4. For example, if your lua script is named 'test.lua' and it takes in a parameter 'name', you can run the command.'
   `resty test.lua name=John`.
5. The output of the script will be displayed in the terminal.
6. You can also redirect the output to a file by using the '>' operator, for example, `resty /usr/local/bin/resty
   test.lua name=John > output.txt`. This will save the script's output in a file named 'output.txt'.

**Example:**

Create a Lua file, for example `test.lua`:

```lua
local arangodb = require("arangodb")

local client = arangodb.new({
    endpoint = "http://127.0.0.1:8529",
    username = "root",
    password = "openSesame",
    db = "debug"
})

local success, results = pcall(function()
    return client.db.query("FOR i IN 1..10 RETURN i")
end)

if success then
   -- print the results
   for _, v in ipairs(results) do
      print(v)
   end
else
   -- print the error message
   print(results)
end
```

Now you could run it just like this:

```shell
resty src/test.lua
```

But because `arangodb` module is using few dependencies, you need to make sure they are installed:

```shell
luarocks install lua-cjson
luarocks install lbase64
luarocks install lua-resty-http
```

Then, when running with `resty` you need to provide the path to Lua libraries.

To include libraries installed by luarocks in your Lua script, you need to add the following line at the top of your
script

```lua
local luarocks_path = '/usr/local/share/lua/5.4/'
package.path = package.path .. ";" .. luarocks_path .. "?.lua"
```

Or run with `-I` argument pointing to luarocks libraries:
```shell
resty -I /usr/local/share/lua/5.4/ src/test.lua
```