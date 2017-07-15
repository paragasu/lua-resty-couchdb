local i = require 'inspect'
local json = require 'cjson'
local couchdb = require 'resty.couchdb'
local couch = couchdb:new({
  host = 'http://127.0.0.1:5984',
  user = 'admin',
  password = 'admin'
})

local db = couch:db('test')

require 'busted.runner'()

describe('Database', function()
  
  setup(function()
    local res, err = db:destroy()
    assert.are.equal(res.status, 200)
  end)

  it('Create test database', function()
    local res, err = db:create() 
    assert.are.equal(res.status, 201)
  end)

  it('Add member', function()
    local res, err = db:add_member("test@colead")
    assert.are.equal(res.status, 200)
  end)

  it('Check member', function()
    local res, err = db:get('_security')
    local body = json.decode(res.body)
    assert.are.equal(body.members.names[1], "test@colead")
  end)

end)
