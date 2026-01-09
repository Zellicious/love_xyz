--[[

This is a demo file, containing the demo from preview.gif (deleted)


]]

-----

lovexyz = require("lovexyz")

-----

function love.load()
  -- newTexture: load texture and store it
	uvTex = triangles.newTexture("assets/tex/tex2.png","UVTex")
	uvTex2 = triangles.newTexture("assets/tex/tex.png","UVTex2")
	
	-- loadModel: load model objs
	teapot = triangles.loadModel("assets/highp_models/teapot.obj")
	suzanne = triangles.loadModel("assets/highp_models/suzanne.obj")
	
	pillar = triangles.loadModel("assets/lowp_models/cube_uv.obj")
	
	floor = triangles.loadModel("assets/lowp_models/cube_uv.obj")
  
  -- model: set textures and transforms
	floor.mesh:setTexture(uvTex)
	teapot.mesh:setTexture(uvTex2)
	suzanne.mesh:setTexture(uvTex2)
	
	teapot:scale(.06,.06,.06)
	teapot:move(0,1,0)
	
	suzanne:scale(1,1,1)
	suzanne:move(4,.6,0)
	
	floor:scale(16,16,16)
	floor:move(0,18,0)
	
	pillar:scale(1,4,1)
	pillar:move(-4,-2,.5)

  --lovexyz.lighting.simpleShadows = true
	lovexyz.canvas:setFilter("linear","linear")
	
	-- per model lighting
	teapot.mtl.reflectionStrength = 1
	teapot.mtl.baseReflectionStrength = .1
	teapot.mtl.specStrength= 1
end

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

function love.update(dt)
	dt = math.min(dt,1)
  teapot:rotY(dt)
  suzanne:rotate(dt*.8,dt,dt*.6)

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
	lovexyz.cam.pos =	lovexyz.cam.pos	- right * (dx * speed)	- forward * (dy * speed)
	lovexyz.cam.rot.y = lovexyz.cam.rot.y - mdx * speed
	lovexyz.cam.rot.x = lovexyz.cam.rot.x + mdy * speed
	
end

function love.resize(w,h)
  lovexyz.refreshCanvases()
end


function love.draw()
  lovexyz.draw()
  lovexyz.perfDebug()
end