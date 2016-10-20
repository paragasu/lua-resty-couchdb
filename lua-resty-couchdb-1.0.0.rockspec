package = "lua-resty-couchdb"
version = "1.0.0"
source = {
   url = "git://github.com/paragasu/lua-resty-couchdb",
   tag = "v1.0.0"
}
description = {
   summary  = "Minimalist couchdb client for lua resty",
   homepage = "https://github.com/paragasu/lua-resty-couchdb",
   license  = "MIT",
   maintainer = "Jeffry L. <paragasu@gmail.com>"
}
dependencies = {
   "lua >= 5.1"
}
build = {
   type = "builtin",
   modules = {
      ["lua-couchdb"] = "couchdb.lua",
   }
}
