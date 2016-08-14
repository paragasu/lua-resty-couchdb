-- Minimalist couchdb client
-- Author: Jeffry L. <paragasu@gmail.com>
-- Website: github.com/paragasu/lua-resty-couchdb
-- Licence: MIT
local json = require 'cjson'
local request = require 'requests'
local host, database

local _M = { __VERSION = '0.01' }
local mt = { __index = _M } 

-- configuration table
-- host, username & password
function _M.new(self, config)
  host = config.host
  if config.user then
    request.HTTPBasicAuth(config.user, config.password)
  end
end


-- db string set the database 
function database(self, db)
  database = db
end


-- construct full url request string
-- based on available params
function _M.make_request_url(self, id)
  return table.concat({ host, database, id }, '/') 
end


-- make a couchdb get request
function _M.get(self, id)
  local res = request.get(self:make_request_url(id))
  return res.json()
end


-- make a couchdb put request
function _M.put(self, id, data)
  local req = self:make_request_url(id)
  local res = request.put({
    url = req,
    data = json.encode(data), 
    headers = {
      ['Content-Type'] = 'application/json'
    }
  }) 
  return res.json()
end

-- make a couchdb post request
function _M.post(self, id, data)
  local req = self:make_request_url(id)
  local res = request.post({
    url = req,
    data = json.encode(data), 
    headers = {
      ['Content-Type'] = 'application/json'
    }
  }) 
  return res.json()
end

-- delete doc
function _M.delete(self, id)
  local res = request.get(self:make_request_url(id))
  return res.json()
end


-- save document 
-- automatically find out the latest rev
function _M.save(self, id, data)
  local req = self:make_request_url(id) 
  local old = self:get(id)
  if old then
    data._rev = old.body._rev
    return self:put(id, data)
  end 
end

-- build valid view options
-- as in http://docs.couchdb.org/en/1.6.1/api/ddoc/views.html 
function _M.build_view_query(qstr)
  if type(opts_or_key) == "table" then
    return ngx.encode_args(opts_or_key)
  else
    return 'key="' .. opts_or_key .. '"'
  end 
end


-- query couchdb design doc
-- opts_or_key assume option or key if string provided
-- construct url query format /_design/design_name/_view/view_name?opts
-- Note: the key params must be enclosed in double quotes
function _M.view(self, design_name, view_name, opts_or_key)
  local s   = self:build_view_query(opts_or_key)
  local req = { host, database, '_design', design_name, '_view',  view_name, '?' .. s } 
  return self:get(table.concat(req, '/'))
end

return _M
