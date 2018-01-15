-- Minimalist couchdb client for lua resty
-- Author: Jeffry L. <paragasu@gmail.com>
-- Website: github.com/paragasu/lua-resty-couchdb
-- Licence: MIT

local http = require 'resty.http'
local json = json or require 'cjson'
local i  = require 'inspect'
local _M = { __VERSION = '3.1-2' }
local mt = { __index = _M } 

-- configuration table
-- @param config table 
-- config.host couchdb db host and port 
-- config.username couchdb username
-- config.password couchdb password
function _M:new(config)
  if not config then error("Missing couchdb config") end
  if not config.user then error("Missing couchdb user") end
  if not config.host then error("Missing couchdb server host") end
  if not config.password then error("Missing couchdb password config") end
  _M.host = config.host
  _M.auth_basic_hash = ngx.encode_base64(config.user .. ':' .. config.password)
  return setmetatable(_M, mt)
end

function _M.get_uuid()
  local httpc = http.new()    
  local res, err = httpc:request_uri(_M.host .. '/_uuids', { method = GET }) 
  if not res then return nil, err end
  local body = json.decode(res.body)
  return body.uuids[1] 
end

-- @param db string database name
function _M:db(dbname)
  local self = {}
  local database = dbname

  function request(method, path, params)
    local httpc = http.new()
    local args  = {
      method  = method, 
      body    = json.encode(params),
      headers = { 
        ['Content-Type']  = 'application/json',
        ['Authorization'] = 'Basic ' .. _M.auth_basic_hash
      },
      ssl_verify = false
    }
    local url = create_url(path, method, params)
    --ngx.log(ngx.ERR, 'request ', url, i(args))
    return httpc:request_uri(url, args)
  end

  -- construct full url request string
  -- @params id doc id
  -- @params method http method
  -- @param params query params
  function create_url(id, method, params)
    if not database then error("Database not exists") end
    if not id then return _M.host .. '/' .. database end
    local url = _M.host .. '/' .. database .. '/' .. id 
    if params ~= nil and (method == 'GET' or method == 'DELETE') then
      return url .. '?' .. ngx.encode_args(params) 
    end
    return url
  end

  -- create database
  function self:create()
    return request('PUT')
  end

  function self:destroy()
    return request('DELETE');
  end

  -- add name in the current database members list
  function self:add_member(name)
    local res, err = self:get('_security')
    local data = json.decode(res.body)
    if not data.members then  
      data.members = {}
      data.members.names = { name } 
    else
      local current_members = data.members.names
      data.members.names = table.insert(current_members, name) 
    end
    return self:put('_security', data)
  end

  -- make a couchdb get request
  function self:get(id)
    return request('GET', id)
  end

  -- make a couchdb put request
  function self:put(id, data)
    return request('PUT', id, data) 
  end

  -- make a couchdb post request
  function self:post(data)
    return request('POST', nil, data)
  end

  -- http://localhost:5984/_utils/docs/api/database/find.html
  function self:find(options)
    return self:post('_find', options)
  end

  -- delete doc
  -- TODO: only query for existing _rev if not exists
  function self:delete(id)
    local info, err = self:get(id)
    if not info then error('Failed to delete :' .. id .. ' not found') end
    local data = json.decode(info.body)
    return request('DELETE', id, { rev = data._rev })
  end

  -- save document 
  -- automatically find out the latest rev
  function self:save(id, data)
    local old = self:get(id)
    if old then
      local params = json.decode(old.body)
      for k,v in pairs(data) do params[k] = v end
      return self:put(id, params)
    end 
  end

  -- build valid view options
  -- as in http://docs.couchdb.org/en/1.6.1/api/ddoc/views.html 
  -- key, startkey, endkey, start_key and end_key is json
  -- startkey or end_key must be surrounded by double quote
  function self:build_query_params(opts_or_key)
    if type(opts_or_key) == 'string' then
      return 'key="' .. opts_or_key .. '"'
    end
    return ngx.encode_args(opts_or_key) 
  end

  -- query couchdb design doc
  -- opts_or_key assume option or key if string provided
  -- construct url query format /_design/design_name/_view/view_name?opts
  -- Note: the key params must be enclosed in double quotes
  function self:view(design_name, view_name, opts_or_key)
    local req = { '_design', design_name, '_view',  view_name, '?' .. self:build_query_params(opts_or_key) } 
    local url = table.concat(req, '/')
    return self:get(url)
  end

  function self:all_docs(args)
    local req = { '_all_docs', self:build_query_params(args) }
    local url = table.concat(req, '/')
    return self:get(url)
  end
 
  return self 
end

return _M
