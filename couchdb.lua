-- Minimalist couchdb client for lua resty
-- Author: Jeffry L. <paragasu@gmail.com>
-- Website: github.com/paragasu/lua-resty-couchdb
-- Licence: MIT
local database

-- check if cjson already exist in global scope
-- as in init_by_lua_block 
local inspect = require 'inspect'
local json = json or require 'cjson'

local _M = { __VERSION = '2.0-1' }
local mt = { __index = _M } 

-- construct full url request string
-- based on available params
local make_request_url = function(id)
  if not database then error("Database not exists") end
  return '/' .. database .. '/' .. id
end

-- check if value exist in a table
local has_value = function(tbl, val)
  for i=1, #tbl do 
    if tbl[i] == val then return true end
  end
  return false
end

-- build valid view options
-- as in http://docs.couchdb.org/en/1.6.1/api/ddoc/views.html 
-- key, startkey, endkey, start_key and end_key is json
local build_view_query = function(opts_or_key)
  if type(opts_or_key) == 'string' then
    return 'key="' .. opts_or_key .. '"'
  end
  local params   = {}
  local json_key = {'key', 'startkey', 'start_key', 'endkey', 'end_key'}
  for k, v in pairs(opts_or_key) do
    local exists = has_value(json_key, k)
    local value  = exists and ngx.escape_uri(json.encode(v)) or v
    table.insert(params, k .. '=' .. value)
  end
  return table.concat(params, '&')
end

-- configuration table
function _M:new(db)
  database = db
  return setmetatable(_M, mt)
end

-- create database
function _M:create_db(db)
  ngx.req.set_header('Content-Type', 'application/json')
  return ngx.location.capture('/' .. db, { method = ngx.HTTP_PUT })
end

-- make a couchdb get request
function _M:get(id)
  local req = make_request_url(id)
  return ngx.location.capture(req, { method = ngx.HTTP_GET })
end

-- make a couchdb put request
function _M:put(id, data)
  ngx.req.set_header('Content-Type', 'application/json')
  return ngx.location.capture(make_request_url(id), { method = ngx.HTTP_PUT, body = json.encode(data) })
end

-- make a couchdb post request
function _M:post(data)
  ngx.req.set_header('Content-Type', 'application/json')
  return ngx.location.capture('/' .. database, { method = ngx.HTTP_POST, body = json.encode(data) })
end

-- http://localhost:5984/_utils/docs/api/database/find.html
function _M:find(options)
  local params = {
    method = ngx.HTTP_POST,
    body   = json.encode(options)
  }
  ngx.log(ngx.ERR, inspect(params))
  ngx.req.set_header('Content-Type', 'application/json')
  return ngx.location.capture('/' .. database .. '/_find', params)
end

-- delete doc
-- TODO: only query for existing _rev if not exists
function _M:delete(id)
  local req = make_request_url(id)
  local old = self:get(id)
  if old then
    local data = json.decode(old.body)
    local query = { rev = data._rev }
    return ngx.location.capture(req, { method=ngx.HTTP_DELETE,  args=query })
  end
  ngx.log(ngx.ERR, 'Failed to delete :' .. id .. ' not found')
end

-- save document 
-- automatically find out the latest rev
function _M:save(id, data)
  local req = make_request_url(id) 
  local old = self:get(id)
  if old then
    local params = json.decode(old.body)
    for k,v in pairs(data) do params[k] = v end
    return self:put(id, params)
  end 
end

-- query couchdb design doc
-- opts_or_key assume option or key if string provided
-- construct url query format /_design/design_name/_view/view_name?opts
-- Note: the key params must be enclosed in double quotes
function _M:view(design_name, view_name, opts_or_key)
  local req = { '_design', design_name, '_view',  view_name, '?' .. build_view_query(opts_or_key) } 
  return self:get(table.concat(req, '/'))
end


-- add name in the current database members list
function _M:add_member(name)
  return self:put('_security', {
    members = {
      names = { name } 
    } 
  })
end

return _M
