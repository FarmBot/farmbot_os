local api = require("api")

_G.json = {
    encode = spy.new(function(x) return x end),
    decode = spy.new(function(x) return x end),
  }
_G.inspect = require("inspect")
_G.send_message = spy.new(function() end)
_G.auth_token = spy.new(function() return "token" end)
_G.__SERVER_PATH = "server/"

describe("api()", function()
  before_each(function()
    _G.send_message:clear()
  end)

  it("returns response", function()
    _G.http = spy.new(function() return { status = 200, body = "response"}, nil end)

    local response = api({ url = "url" })

    assert.spy(http).was.called()
    assert.spy(http).was.called_with({
      method = "GET",
      url = "server/url",
      headers = {
        Accept = "application/json",
        Authorization = "bearer token",
      },
    })
    assert.are_equal("response", response)
  end)

  it("merges inputs", function()
    _G.http = spy.new(function() return { status = 200, body = "response"}, nil end)

    local response = api({
      url = "url",
      method = "POST",
      headers = { test = "header" },
      body = { test = "body" },
    })

    assert.spy(http).was.called()
    assert.spy(http).was.called_with({
      method = "POST",
      url = "server/url",
      headers = {
        Accept = "application/json",
        Authorization = "bearer token",
        test = "header",
      },
      body = { test = "body" }
    })
    assert.are_equal("response", response)
  end)

  it("handles network error", function()
    _G.http = spy.new(function() return { status = 400, body = ""}, "error" end)

    local response = api({ url = "url" })

    assert.is_falsy(response)
    assert.spy(send_message).was.called_with("error", "NETWORK ERROR: \"error\"")
  end)

  it("handles http error", function()
    _G.http = spy.new(function() return { status = 400, body = {}}, nil end)

    local response = api({ url = "url" })

    assert.is_falsy(response)
    assert.spy(send_message).was.called_with("error", "HTTP ERROR: {\n  body = {},\n  status = 400\n}")
  end)

  it("handles missing url", function()
    _G.http = spy.new(function() end)

    local response = api({})

    assert.spy(http).was_not_called()
    assert.is_falsy(response)
    assert.spy(send_message).was.called_with("error", "Missing URL in HTTP request")
  end)
end)
