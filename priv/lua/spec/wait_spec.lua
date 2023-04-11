local wait = require("wait")

_G.set_job_progress = spy.new(function() end)
_G.wait_ms = spy.new(function() end)
_G.os = { time = function() return 1000 end }

describe("wait()", function()
  before_each(function()
    _G.set_job_progress:clear()
    _G.wait_ms:clear()
  end)

  for _, test in pairs({
    { seconds = 0.1, wait_count = 1, job_count = 0, ms = { 100 } },
    { seconds = 100, wait_count = 101, job_count = 101, ms = { 1000 } },
    { seconds = 111.1, wait_count = 112, job_count = 112, ms = { 1000, 100 } },
  }) do
    it("waits " .. test.seconds .. " seconds", function()
      wait(test.seconds * 1000)

      if test.job_count > 0 then
        assert.spy(set_job_progress).was.called_with("Waiting " .. test.seconds .. "s",
          { percent = 0, status = "Waiting", time = 1000000 })
      end
      assert.spy(wait_ms).was.called(test.wait_count)
      for _, i in pairs(test.ms) do
        assert.spy(wait_ms).was.called_with(i)
      end
      if test.job_count > 0 then
        assert.spy(set_job_progress).was.called_with("Waiting " .. test.seconds .. "s",
          { percent = 100, status = "Complete", time = 1000000 })
      end
      assert.spy(set_job_progress).was.called(test.job_count)
    end)
  end
end)
