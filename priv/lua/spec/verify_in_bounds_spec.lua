local verify_in_bounds = require("verify_in_bounds")

describe("verify_in_bounds()", function()
  local settings
  before_each(function()
    _G.garden_size = spy.new(function() return {x = 100, y = 200, z = 300} end)
    settings = {
      movement_stop_at_home_x = 1,
      movement_stop_at_home_y = 1,
      movement_stop_at_home_z = 1,
      movement_stop_at_max_x = 1,
      movement_stop_at_max_y = 1,
      movement_stop_at_max_z = 1,
      movement_home_up_z = 0,
    }
    _G.get_firmware_config = spy.new(function() return settings end)
    _G.toast = spy.new(function() end)
  end)

  it("accepts an empty coordinate table", function()
    assert.is_true(verify_in_bounds({}))
    assert.spy(toast).was_not_called()
  end)

  it("accepts coordinates within the bounds", function()
    assert.is_true(verify_in_bounds({x = 50, y = 150, z = 250}))
    assert.spy(garden_size).was.called(1)
    assert.spy(toast).was_not_called()
  end)

  it("accepts coordinates at the bounds", function()
    assert.is_true(verify_in_bounds({x = 100, y = 200, z = 300}))
    assert.is_true(verify_in_bounds({x = 0, y = 0, z = 0}))
    assert.spy(toast).was_not_called()
  end)

  it("checks only supplied axes", function()
    assert.is_true(verify_in_bounds({y = 200}))
    assert.spy(toast).was_not_called()
  end)

  it("rejects an exceeded x bound", function()
    assert.is_false(verify_in_bounds({x = 101}))
    assert.spy(toast).was.called_with(
      "The target coordinate is out of bounds: 101mm exceeds 100mm x-axis length. ", "error")
  end)

  it("rejects an exceeded y bound", function()
    assert.is_false(verify_in_bounds({y = 201}))
    assert.spy(toast).was.called_with(
      "The target coordinate is out of bounds: 201mm exceeds 200mm y-axis length. ", "error")
  end)

  it("rejects an exceeded z bound", function()
    assert.is_false(verify_in_bounds({z = 301}))
    assert.spy(toast).was.called_with(
      "The target coordinate is out of bounds: 301mm exceeds 300mm z-axis length. ", "error")
  end)

  it("reports all exceeded bounds in one toast", function()
    assert.is_false(verify_in_bounds({x = 101, y = 201, z = 301}))
    assert.spy(toast).was.called(1)
    assert.spy(toast).was.called_with(
      "The target coordinate is out of bounds: " ..
      "101mm exceeds 100mm x-axis length. " ..
      "201mm exceeds 200mm y-axis length. " ..
      "301mm exceeds 300mm z-axis length. ", "error")
  end)

  it("rejects a negative x coordinate", function()
    assert.is_false(verify_in_bounds({x = -1}))
    assert.spy(toast).was.called(1)
    assert.spy(toast).was.called_with(
      "The target coordinate is out of bounds: -1mm is below 0mm x-axis minimum. ", "error")
  end)

  it("rejects a negative y coordinate", function()
    assert.is_false(verify_in_bounds({y = -1}))
    assert.spy(toast).was.called(1)
    assert.spy(toast).was.called_with(
      "The target coordinate is out of bounds: -1mm is below 0mm y-axis minimum. ", "error")
  end)

  it("rejects a negative z coordinate", function()
    assert.is_false(verify_in_bounds({z = -1}))
    assert.spy(toast).was.called(1)
    assert.spy(toast).was.called_with(
      "The target coordinate is out of bounds: -1mm is below 0mm z-axis minimum. ", "error")
  end)

  it("reports lower and upper bound violations in one toast", function()
    assert.is_false(verify_in_bounds({x = -1, y = 201, z = -0.5}))
    assert.spy(toast).was.called(1)
    assert.spy(toast).was.called_with(
      "The target coordinate is out of bounds: " ..
      "-1mm is below 0mm x-axis minimum. " ..
      "201mm exceeds 200mm y-axis length. " ..
      "-0.5mm is below 0mm z-axis minimum. ", "error")
  end)

  it("checks the zero minimum even without positive configured lengths", function()
    _G.garden_size = spy.new(function() return {x = 0, y = -1, z = 0} end)
    assert.is_true(verify_in_bounds({x = 0, y = 0, z = 0}))
    assert.spy(toast).was_not_called()
    assert.is_false(verify_in_bounds({x = -1, y = -2, z = -3}))
    assert.spy(toast).was.called(1)
    assert.spy(toast).was.called_with(
      "The target coordinate is out of bounds: " ..
      "-1mm is below 0mm x-axis minimum. " ..
      "-2mm is below 0mm y-axis minimum. " ..
      "-3mm is below 0mm z-axis minimum. ", "error")
  end)

  for _, axis in ipairs({"x", "y", "z"}) do
    it("allows passing home on " .. axis .. " when stop_at_home is disabled", function()
      settings["movement_stop_at_home_" .. axis] = 0
      assert.is_true(verify_in_bounds({[axis] = -1}))
      assert.spy(toast).was_not_called()
      assert.is_false(verify_in_bounds({[axis] = 1000}))
    end)

    it("allows passing the far limit on " .. axis .. " when stop_at_max is disabled", function()
      settings["movement_stop_at_max_" .. axis] = 0
      assert.is_true(verify_in_bounds({[axis] = 1000}))
      assert.spy(toast).was_not_called()
      assert.is_false(verify_in_bounds({[axis] = -1}))
    end)
  end

  it("does not enable limits for missing settings", function()
    settings = {}
    assert.is_true(verify_in_bounds({x = -1, y = 1000, z = -1000}))
    assert.spy(toast).was_not_called()
  end)

  it("accepts negative z coordinates and both boundaries when negative_z is enabled", function()
    settings.movement_home_up_z = 1
    assert.is_true(verify_in_bounds({z = -150}))
    assert.is_true(verify_in_bounds({z = -300}))
    assert.is_true(verify_in_bounds({z = 0}))
    assert.spy(toast).was_not_called()
    assert.spy(get_firmware_config).was.called(3)
  end)

  it("rejects positive z past home when negative_z is enabled", function()
    settings.movement_home_up_z = 1
    assert.is_false(verify_in_bounds({z = 1}))
    assert.spy(toast).was.called_with(
      "The target coordinate is out of bounds: 1mm is above 0mm z-axis maximum. ", "error")
  end)

  it("rejects negative z past the far limit when negative_z is enabled", function()
    settings.movement_home_up_z = 1
    assert.is_false(verify_in_bounds({z = -301}))
    assert.spy(toast).was.called_with(
      "The target coordinate is out of bounds: -301mm is below -300mm z-axis minimum. ", "error")
  end)

  it("allows positive z past home when its stop_at_home is disabled", function()
    settings.movement_home_up_z = 1
    settings.movement_stop_at_home_z = 0
    assert.is_true(verify_in_bounds({z = 1}))
    assert.spy(toast).was_not_called()
    assert.is_false(verify_in_bounds({z = -301}))
  end)

  it("allows negative z past the far limit when its stop_at_max is disabled", function()
    settings.movement_home_up_z = 1
    settings.movement_stop_at_max_z = 0
    assert.is_true(verify_in_bounds({z = -301}))
    assert.spy(toast).was_not_called()
    assert.is_false(verify_in_bounds({z = 1}))
  end)

  it("does not enforce an unknown far limit for negative z", function()
    settings.movement_home_up_z = 1
    _G.garden_size = spy.new(function() return {x = 100, y = 200, z = 0} end)
    assert.is_true(verify_in_bounds({z = -1000}))
    assert.spy(toast).was_not_called()
    assert.is_false(verify_in_bounds({z = 1}))
  end)

  it("reports negative z violations together with other axes", function()
    settings.movement_home_up_z = 1
    assert.is_false(verify_in_bounds({x = -1, y = 201, z = -301}))
    assert.spy(toast).was.called(1)
    assert.spy(toast).was.called_with(
      "The target coordinate is out of bounds: " ..
      "-1mm is below 0mm x-axis minimum. " ..
      "201mm exceeds 200mm y-axis length. " ..
      "-301mm is below -300mm z-axis minimum. ", "error")
  end)

  it("ignores nonpositive configured lengths", function()
    _G.garden_size = spy.new(function() return {x = 0, y = -1, z = 300} end)
    assert.is_true(verify_in_bounds({x = 1000, y = 1000, z = 300}))
    assert.spy(toast).was_not_called()
    assert.is_false(verify_in_bounds({x = 1000, y = 1000, z = 301}))
    assert.spy(toast).was.called_with(
      "The target coordinate is out of bounds: 301mm exceeds 300mm z-axis length. ", "error")
  end)
end)
