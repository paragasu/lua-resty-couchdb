-- Minimalist couchdb client for lua resty
-- Author: Jeffry L. <paragasu@gmail.com>
-- Website: github.com/paragasu/lua-resty-couchdb
-- Licence: MIT
local database

-- check if cjson already exist in global scope
-- as in init_by_lua_block 
local json = json or require 'cjson'

local _M = { __VERSION = '1.00' }
local mt = { __index = _M } 

-- construct full url request string
-- based on available params
local make_request_url = function(id)
  return '/' .. database .. '/' .. id
end

-- build valid view options
-- as in http://docs.couchdb.org/en/1.6.1/api/ddoc/views.html 
local build_view_query = function(opts_or_key)
  if type(opts_or_key) == "table" then
    return ngx.encode_args(opts_or_key)
  else
    return 'key="' .. opts_or_key .. '"'
  end 
end

-- configuration table
function _M.new(self, db)
  database = db
  return setmetatable(_M, mt)
end

-- make a couchdb get request
function _M.get(self, id)
  local req = make_request_url(id)
  return ngx.location.capture(req, { method = ngx.HTTP_GET })
end


-- make a couchdb put request
function _M.put(self, id, data)
  local req = make_request_url(id)
  local params = {
    method = ngx.HTTP_PUT,
    body   = json.encode(data)
  }
  return ngx.location.capture(req, params)
end

-- make a couchdb post request
function _M.post(self, id, data)
  local params = {
    method = ngx.HTTP_PUT,
    body   = json.encode(data)
  }
  local req = make_request_url(id)
  return ngx.location.capture(req, params)
end

-- delete doc
function _M.delete(self, id)
  local req = make_request_url(id)
  return ngx.location.capture(req, { method = ngx.HTTP_GET })
end


-- save document 
-- automatically find out the latest rev
function _M.save(self, id, data)
  local req = make_request_url(id) 
  local old = self:get(id)
  if old then
    data._rev = old.body._rev
    return self:put(id, data)
  end 
end


-- query couchdb design doc
-- opts_or_key assume option or key if string provided
-- construct url query format /_design/design_name/_view/view_name?opts
-- Note: the key params must be enclosed in double quotes
function _M.view(self, design_name, view_name, opts_or_key)
  local s   = build_view_query(opts_or_key)
  local req = { '', database, '_design', design_name, '_view',  view_name, '?' .. s } 
  return self:get(table.concat(req, '/'))
end

return _M
