#lua-resty-couchdb
Lua resty minimal couchdb client

#Installation
```
#luarocks install lua-resty-couchdb
```

#Usage
```
local couch = require 'couchdb'
local couchdb = couch:new({
  host: 'https://202.48.84.8:5472',
  username: 'admin',
  password: 'somepassword'
})

couchdb:database('_users')
```
