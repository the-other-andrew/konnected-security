describe("device", function()
  local device

  setup(function()
    require("spec/nodemcu_stubs")
    device = require("device")
  end)

  it("has expected properties", function()
    assert.equal(device.swVersion, "2.2.5")
    assert.equal(device.hwVersion, "2.2.5")
    assert.equal(device.name, "Konnected")
  end)

end)