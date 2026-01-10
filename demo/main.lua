--[[

This is a demo file, its updated from the legacy demo
This demo is designed to test engine capabilities

]]

-----

lovexyz = require("lovexyz")

-----

function love.load()
  -- lovexyz params
  --lovexyz.lighting.shadowEnabled = false
  lovexyz.lighting.colorCorrection.brightness = 1
  lovexyz.lighting.colorCorrection.saturation = 1
  
  lovexyz.shadowSize = 32
  lovexyz.lighting.shadowSmoothness = 1

  lovexyz.cam.fov = math.rad(60)
  lovexyz.cam.pos = vec3.new(-4.1,-5.5,-4.1)
  lovexyz.cam.rot = vec3.new(math.rad(16),math.pi + math.rad(33),0)

  -- load Socrates.obj
  socrates = triangles.loadModel("assets/Socrates.obj","static","socrates")

  -- load Socrates's textures
  socrates_col = triangles.newTexture("assets/socrates_col.png","socrates_col")
  socrates_ao = triangles.newTexture("assets/socrates_ao.png","socrates_ao")
  socrates_rough = triangles.newTexture("assets/socrates_rough.png","socrates_rough")

  -- scale Socrates
  socrates:scale(.05,.05,.05)

  -- set textures on mesh and mtl
  socrates.mtl.metallic = 0

  socrates.mtl.aoTex = triangles.textureCache["socrates_ao"]
  socrates.mtl.roughTex = triangles.textureCache["socrates_rough"]
  socrates.mesh:setTexture(triangles.textureCache["socrates_col"])
end

-- movement function
local function getCameraDirs(cam)
	local yaw = cam.rot.y
	local pitch = -cam.rot.x
	local cosY = math.cos(yaw)
	local sinY = math.sin(yaw)
	local sinX = math.sin(pitch)
	local cosX = math.cos(pitch)
	local right = vec3.new(
		cosY,
		0,
		-sinY
	)
	local forward = vec3.new(
		sinY*cosX,
		sinX,
		cosY*cosX
	)

	return right, forward
end

local function move(dt)
  local dx = 0
  local dy = 0

  local mdx = 0
  local mdy = 0

  local speed = dt*4

  if love.keyboard.isDown("w") then
    dy = 1
  end
  if love.keyboard.isDown("s") then
    dy = -1
  end

  if love.keyboard.isDown("a") then
    dx = 1
  end
  if love.keyboard.isDown("d") then
    dx = -1
  end

  if love.keyboard.isDown("up") then
    mdy = -1
  end
  if love.keyboard.isDown("down") then
    mdy = 1
  end

  if love.keyboard.isDown("left") then
    mdx = -1
  end
  if love.keyboard.isDown("right") then
    mdx = 1
  end


  local m = math.sqrt(dx*dx+dy*dy)
  if m > 0 then
    dx = dx/m
    dy = dy/m
  end

  local right, forward = getCameraDirs(lovexyz.cam)
  lovexyz.cam.pos = lovexyz.cam.pos - right * (dx * speed)  - forward * (dy * speed)
  lovexyz.cam.rot.y = lovexyz.cam.rot.y - mdx * speed
  lovexyz.cam.rot.x = lovexyz.cam.rot.x + mdy * speed
end

function love.update(dt)
	dt = math.min(dt,1)
  move(dt)

  -- rotate Socrates
  triangles.loadedModels["socrates"]:rotY(dt*.1) -- or socrates:rotY(dt*.1)
end

function love.resize(w,h)
  lovexyz.refreshCanvases()
end


function love.draw()
  lovexyz.draw()
  lovexyz.perfDebug()
end