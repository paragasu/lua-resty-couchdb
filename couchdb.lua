-- Minimalist couchdb client for lua resty
-- Author: Jeffry L. <paragasu@gmail.com>
-- Website: github.com/paragasu/lua-resty-couchdb
-- Licence: MIT

local http = require 'resty.http'
local json = json or require 'cjson'
local _M = { __VERSION = '4.0-0' }
local mt = { __index = _M } 
local i  = require 'inspect'
local database = nil

-- @param config table 
-- config.host couchdb db host and port 
-- config.username couchdb username
-- config.password couchdb password
function _M.new(config)
  if not config then error("Missing couchdb config") end
  if not config.user then error("Missing couchdb user") end
  if not config.host then error("Missing couchdb server host") end
  if not config.password then error("Missing couchdb password config") end
  _M.host = config.host
  _M.auth_basic_hash = ngx.encode_base64(config.user .. ':' .. config.password)
  return setmetatable(_M, mt)
end

local function is_table(t) return type(t) == 'table' end

  -- modified from https://www.reddit.com/r/lua/comments/417v44/efficient_table_comparison
local function is_table_equal(a,b)
  local t1,t2 = {}, {}
  if not is_table(a) then return false end
  if not is_table(b) then return false end
  if #a ~= #b then return false end
  for k,v in pairs(a) do t1[k] = (t1[k] or 0) + 1 end
  for k,v in pairs(b) do t2[k] = (t2[k] or 0) + 1 end
  for k,v in pairs(t1) do if v ~= t2[k] then return false end end
  for k,v in pairs(t2) do if v ~= t1[k] then return false end end
  return true
end

local function create_url(path, method, params)
  if not database then error("Database not exists") end
  if not path then return _M.host .. '/' .. database end
  local url = _M.host .. '/' .. database .. '/' .. path 
  if params ~= nil and (method == 'GET' or method == 'DELETE') then
    return url .. '?' .. ngx.encode_args(params) 
  end
  return url
end

-- build valid view options
-- as in http://docs.couchdb.org/en/1.6.1/api/ddoc/views.html 
-- key, startkey, endkey, start_key and end_key is json
-- startkey or end_key must be surrounded by double quote
local function build_query_params(opts_or_key)
  if is_table(opts_or_key) then
    return ngx.encode_args(opts_or_key) 
  else
    return string.format('key="%s"', opts_or_key)
  end
end

function _M.db(self, database_name)
  local db = {}
  database = database_name

  local function request(method, path, params)
    local httpc = http.new()
    local args  = {
    method  = method, 
    body    = json.encode(params),
    ssl_verify = false,
    headers = { 
        ['Content-Type']  = 'application/json',
        ['Authorization'] = 'Basic ' .. _M.auth_basic_hash
      }
    }
    local url = create_url(path, method, params)
    local res, err = httpc:request_uri(url, args)
    if not res then return nil, err end
    if res.status == 200 or res.status == 201 then
      return json.decode(res.body)
    else
      return nil, json.decode(res.body)
    end
  end

  -- save document 
  -- automatically find out the latest rev
  function db.save(self, doc)
    local old, err = db:get(doc._id)
    local params = old or {} 
    -- only update if data has changes
    if is_table_equal(params, doc) then return doc end
    for k,v in pairs(doc) do params[k] = v end
    local res = db:put(params)
    return db:get(res.id)
  end

  -- query couchdb design doc
  -- opts_or_key assume option or key if string provided
  -- construct url query format /_design/design_name/_view/view_name?opts
  -- Note: the key params must be enclosed in double quotes
  function db.view(self, design_name, view_name, opts_or_key)
    local req = { '_design', design_name, '_view',  view_name, '?' .. build_query_params(opts_or_key) } 
    local url = table.concat(req, '/')
    return db:get(url)
  end

  function db.all_docs(self, args)
    return db:get('_all_docs?' ..  build_query_params(args))
  end

  function db.delete(self, doc)
    if not is_table(doc) then return nil, 'Delete param is not a valid doc table' end
    return request('DELETE', doc._id, { rev = doc._rev }) 
  end

  function db.get(self, id) return request('GET', id) end
  function db.put(self, doc) return request('PUT', doc._id, doc) end
  function db.post(self, doc) return request('POST', nil, doc) end
  function db.find(self, options) return db.post('_find', options) end
  function db.create() return request('PUT') end
  function db.destroy() return request('DELETE') end
 
  return db 
end

return _M
