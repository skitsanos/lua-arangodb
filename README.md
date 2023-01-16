# ArangoDB Client for OpenResty

### Dependencies

- [lua-cjson](https://luarocks.org/modules/openresty/lua-cjson)
- [base64](https://luarocks.org/modules/iskolbin/base64)
- [lua-resty-http](https://luarocks.org/modules/pintsized/lua-resty-http)

But because `arangodb` module uses these dependencies, you need to make sure they are installed; you can do it with [luarocks](https://luarocks.org/):

```shell
luarocks install lua-cjson
luarocks install lbase64
luarocks install lua-resty-http
```



## Methods

### `arangodb.new(options)`

`options` (table): A table containing the following fields:

- `endpoint` (string, required): The URL of the ArangoDB endpoint to connect to.
- `username` (string, optional): The username to use for authentication.
- `password` (string, optional): The password to use for authentication.
- `token` (string, optional): The JWT token to use for authentication.
- `database` (string, required): The name of the database to connect to.

```lua
local client = arangodb.new({
    endpoint = "http://127.0.0.1:8529",
    username = "root",
    password = "***********",
    database = "debug"
})
```

## `arangodb:version()`

Returns the version of the connected ArangoDB server.

## `arangodb.db:create(name, options, users)`

- `name` (string, required): The name of the database to create.

- `options` (table, optional): A table containing the following fields:
  - `sharding` (string, optional): The sharding method to use for new collections in this database. Valid values are: `flexible`, or `single`. The first two are equivalent. (cluster only)
  - `replicationFactor` (integer, optional): Default replication factor for new collections created in this database. Special values include “satellite”, which will replicate the collection to every DB-Server (Enterprise Edition only), and 1, which disables replication. (cluster only)
  - `writeConcern` (number, optional): Default write concern for new collections created in this database. It determines how many copies of each shard are required to be in sync on the different DB-Servers. If there are less than these many copies in the cluster a shard will refuse to write. Writes to shards with enough up-to-date copies will succeed at the same time however. The value of *writeConcern* can not be larger than *replicationFactor*. *(cluster only)*
  
- `users`(array, optional): An array of user objects. The users will be granted Administrate permissions for the new database. Users that do not exist yet will be created. If users are not specified or don't contain any users, the default user root will be used to ensure that the new database will be accessible after it is created. The root user is created with an empty password should it not exist. Each user object can contain the following attributes:
  - `username` (string, required): Login name of an existing user or one to be created.
   - `passwd` (string, optional): The user password as a string. If not specified, it will default to an empty string. The attribute is ignored for users that already exist.
  - `active` (boolean, optional): A flag indicating whether the user account should be activated or not. The default value is true. If set to false, then the user won’t be able to log into the database. The default is true. The attribute is ignored for users

Creating the database, without options or users provided:

```lua
client.db.create('demo')
```

Creating the database with users:

```lua
local users = {}
users[1] = { username = "user1", passwd = "password1", active = true }

client.db.create(
        "my_database",
        {
            sharding = "single",
            replicationFactor = 2,
            writeConcern = 2
        },
        users
)
```

## `arangodb.db:query(aql)`

- `aql` (string): The AQL query to execute.

Executes the specified AQL query on the connected ArangoDB instance. Returns the result of the query.



---



### Testing with resty utility

1. Open a terminal window and navigate to your Lua script's directory.
2. Run the command `resty resty [your lua script name]` to execute the script.
3. If your Lua script requires any input or parameters, you can pass them as arguments after the script name.
4. For example, if your Lua script is named 'test.lua' and it takes in a parameter 'name', you can run the command.'
   `resty test.lua name=John`.
5. The output of the script will be displayed in the terminal.
6. You can also redirect the output to a file by using the '>' operator, for example, `resty /usr/local/bin/resty
   test.lua name=John > output.txt`. This will save the script's output in a file named _output.txt_.

**Example:**

Create a Lua file, for example, `test.lua`:

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