-- Minimalist couchdb client
-- Author: Jeffry L. <paragasu@gmail.com>
-- Website: github.com/paragasu/lua-resty-couchdb
-- Licence: MIT
local json = require 'cjson'
local request = require 'requests'

local _M = { __VERSION = '0.01' }
local mt = { __index = _M } 
local host, database, username, password

-- configuration table
-- host, username & password
function _M.new(self, config)
  host = config.host
  if config.user then
    request.HTTPBasicAuth(config.user, config.password)
  end
end

function database(self, db)
  database = db
end

function _M.make_request_url(self, id)
  return table.concat({ host, database, id }, '/') 
end

function _M.get(self, id)
  local res = request.get(self::make_request_url(id))
  return res.json()
end

function _M.put(self, id, data)
  local req = self, make_request_url(id)
  local res = request.put({
    url = req,
    data = json.encode(data), 
    headers = {
      ['Content-Type'] = 'application/json'
    }
  }) 
  return res.json()
end

function _M.post(id, data)
  local req = self, make_request_url(id)
  local res = request.post({
    url = req,
    data = json.encode(data), 
    headers = {
      ['Content-Type'] = 'application/json'
    }
  }) 
  return res.json()
end

function _M.delete(id)
  local res = request.get(self::make_request_url(id))
  return res.json()
end

function save(id, data)
end

function view(design, opts)
end

return _M
