local Ring=include("bits/lib/Ring")
local debug=include("bits/lib/debug")
local rings = {}
local rings2 = {}

radians = {
  A0 = 0,
  A90 = math.pi/2,
  A180 = math.pi,
  A270 = 3 * math.pi/2
}


-- todo: before randomizing, allow emphasis on low, mid or high


function rate_to_radians(rate)
  -- this is an arbitrary conversion
  -- nominal rate looks acceptable at 1/10 radians
  return rate/10
end


function render_zigzag()
  local y_offset = 4
  screen.line_width(1)
  screen.level(1)
  screen.move(0,32 - y_offset/2)
  screen.level(3)
  for i=1,32,1 do
    screen.line(
      i*4,
      32 - y_offset/2 + (i%2 * y_offset)
    )
  end
  screen.stroke()
  screen.update()

end


function animate(stage)
  screen.clear()
  for i=1,6,1 do
    rings[i]:render()
    rings2[i]:render()
  end
  render_zigzag()
end


function count()
	ready = true
end

rates = {}
pans = {}
levels = {}
positions = {}
function randomize_all()
  local rate_values = {0.5, 1, 2, -0.5, -1, -2}
  for i=1,6 do
    rates[i] = rate_values[math.random(#rate_values)]
    levels[i] = math.random()*0.5+0.2 
    pans[i] = 0.5-math.random()
    positions[i] = 1+math.random(8)*0.25
    softcut.level(i, levels[i])
    softcut.rate(i, rates[i])
    softcut.position(i,positions[i])
  end
  print("rates:")
  print(rates[1])
end

function enable_all()
  local pan_locations = {-1, -.5, -.25, .25, .5, 1}
  for i=1,6 do
    softcut.enable(i,1)
    softcut.buffer(i,1)
    softcut.loop(i,math.random(5))
    softcut.loop_start(i,1)
    softcut.loop_end(i,math.random(10))
    softcut.play(i,1)
    softcut.pan(i, pan_locations[i])
  end
end


function init()  
  -- init softcut
  -- file = _path.dust.."code/softcut-studies/lib/whirl1.aif"
  file = _path.dust.."audio/etsuko/sea-minor/sea-minor-chords.wav"

  softcut.buffer_clear()

  --- buffer_read_mono (file, start_src, start_dst, dur, ch_src, ch_dst)
  softcut.buffer_read_mono(file,40,1,20,1,1)
  
  enable_all()
  randomize_all()
  

  -- init rings
  local y_offset = 18
  for i=1,6,1 do
    rings[i] = Ring:new({
      x=i*16 + 8,
      y=32 + y_offset + (-2 * y_offset * (i%2)),
      a1=radians.A0,
      a2=radians.A90,
      radius=6,
      rate=rates[i],
      bg=0,
      thickness=2,
      level=4,
    })
  end
  for i=1,6,1 do
    rings2[i] = Ring:new({
      x=i*16 + 8,
      y=32 + y_offset + (-2 * y_offset * (i%2)),
      a1=radians.A90,
      a2=radians.A180,
      radius=6,
      rate=rates[i]/2,
      bg=0,
      level=15,
      thickness=2
    })
  end


  
  -- init clock
  c = metro.init(count, 1/60)
  c:start()

end

function key(n,z)
  if n==3 and z==1 then

    randomize_all()
  end
end


function refresh()
	if ready then
		animate()
		ready = false
	end
end

