local module = ...

infinateLoops = {}

local function turnOffIn(pin, on_state, delay, times, pause)
  local off = on_state == 0 and 1 or 0
  times = times or -1

  if (times == -1) then
    infinateLoops[pin] = true
  end

  print("Heap:", node.heap(), "Actuator Pin:", pin, "Momentary:", delay, "Repeat:", times, "Pause:", pause)

  tmr.create():alarm(delay, tmr.ALARM_SINGLE, function()
    print("Heap:", node.heap(), "Actuator Pin:", pin, "State:", off)
    gpio.write(pin, off)
    times = times - 1

    if (times > 0 or infinateLoops[pin]) and pause then
      tmr.create():alarm(pause, tmr.ALARM_SINGLE, function()
        print("Heap:", node.heap(), "Actuator Pin:", pin, "State:", on_state)
        gpio.write(pin, on_state)
        turnOffIn(pin, on_state, delay, times, pause)
      end)
    end
  end)
end

local function process(request)
  if request.method == "GET" then
    if request.query then
      request.query.pin = request.query.pin or "all"
    end
    local body = {}
    if request.query.pin == "all" then
      local sensors = require("sensors")
      for i, sensor in pairs(sensors) do
        table.insert(body, { pin = sensor.pin, state = sensor.state })
      end
    else
      body = { {
        pin = request.query.pin,
        state = gpio.read(request.query.pin)
      } }
    end
    return sjson.encode(body)
  end

  if request.contentType == "application/json" then
    if request.method == "PUT" then
      local function updatePin(payload)
        local pin = tonumber(payload.pin)
        local state = tonumber(payload.state)
        local times = tonumber(payload.times)
        print("Heap:", node.heap(), "Actuator Pin:", pin, "State:", state)

        if infinateLoops[pin] then
          infinateLoops[pin] = false
        end

        gpio.write(pin, state)

        blinktimer:start()
        if payload.momentary then
          turnOffIn(pin, state, payload.momentary, times, payload.pause)
          if (times == -1) then state = -1 end -- this indicates an infinate repeat
          return { pin = pin, state = state }
        else
          return { pin = pin, state = state }
        end
      end

      if request.body[1] then
        local ret = {}
        for i in pairs(request.body) do
          table.insert(ret, updatePin(request.body[i]))
        end
        return sjson.encode(ret)
      else
        return sjson.encode(updatePin(request.body))
      end
    end
  end
end

return function(request)
  package.loaded[module] = nil
  module = nil
  return process(request)
end