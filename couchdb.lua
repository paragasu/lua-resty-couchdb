-- Minimalist couchdb client for lua resty
-- Author: Jeffry L. <paragasu@gmail.com>
-- Website: github.com/paragasu/lua-resty-couchdb
-- Licence: MIT
local database, auth

-- check if cjson already exist in global scope as in init_by_lua_block 
local i = require 'inspect'
local http = require 'resty.http'
local json = json or require 'cjson'

local _M = { __VERSION = '2.0-1' }
local mt = { __index = _M } 

-- construct full url request string
-- based on available params
local function make_request_url(id)
  if not database then error("Database not exists") end
  if not id then return '/' .. database end
  return '/' .. database .. '/' .. id
end

local function request(method, url, params)
  local httpc = http.new()
  return httpc:request_uri(make_request_url(url), {
    method  = method, 
    body    = json.encode(params),
    headers = { 
      ['Content-Type']  = 'application/json',
      ['Authorization'] = 'Basic ' .. ngx.encode_base64(auth) 
    },
    ssl_verify = false
  })
end

-- configuration table
-- @param db string database name
-- @param auth string "username:password" 
function _M:new(db, auth)
  database = db
  auth = auth
  return setmetatable(_M, mt)
end

-- create database
function _M:create_db(db)
  request('PUT')
end

-- make a couchdb get request
function _M:get(id)
  return request('GET', id)
end

-- make a couchdb put request
function _M:put(id, data)
  return request('PUT', id, data) 
end

-- make a couchdb post request
function _M:post(data)
  return request('POST', nil, data)
end

-- http://localhost:5984/_utils/docs/api/database/find.html
function _M:find(options)
  return self:post('_find', options)
end

-- delete doc
-- TODO: only query for existing _rev if not exists
function _M:delete(id)
  local old = self:get(id)
  if old then
    local data = json.decode(old.body)
    return request('DELETE', id, { rev = data._rev })
  else
    ngx.log(ngx.ERR, 'Failed to delete :' .. id .. ' not found')
  end
end

-- save document 
-- automatically find out the latest rev
function _M:save(id, data)
  local old = self:get(id)
  if old then
    local params = json.decode(old.body)
    for k,v in pairs(data) do params[k] = v end
    return self:put(id, params)
  end 
end

-- check if value exist in a table
local function has_value(tbl, val)
  for i=1, #tbl do 
    if tbl[i] == val then return true end
  end
  return false
end

-- build valid view options
-- as in http://docs.couchdb.org/en/1.6.1/api/ddoc/views.html 
-- key, startkey, endkey, start_key and end_key is json
local function build_view_query(opts_or_key)
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

-- query couchdb design doc
-- opts_or_key assume option or key if string provided
-- construct url query format /_design/design_name/_view/view_name?opts
-- Note: the key params must be enclosed in double quotes
function _M:view(design_name, view_name, opts_or_key)
  local req = { '_design', design_name, '_view',  view_name, '?' .. build_view_query(opts_or_key) } 
  local url = table.concat(req, '/')
  return self:get(url)
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
