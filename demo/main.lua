-----

lovexyz = require("lovexyz")

-----

function love.load()
	uvTex = triangles.newTexture("assets/tex/tex2.png","UVTex")
	uvTex2 = triangles.newTexture("assets/tex/tex.png","UVTex2")
	
	teapot = triangles.loadModel("assets/highp_models/teapot.obj")
	suzanne = triangles.loadModel("assets/highp_models/suzanne.obj")
	
	pillar = triangles.loadModel("assets/lowp_models/cube_uv.obj")
	
	floor = triangles.loadModel("assets/lowp_models/cube_uv.obj")
  
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
	
	lovexyz.canvas:setFilter("linear","linear")
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
function love.touchmoved(id, x, y, dx, dy)
	local speed = 1/100
	if x > love.graphics.getWidth() / 2 then
		lovexyz.cam.rot.y = lovexyz.cam.rot.y - dx * speed
		lovexyz.cam.rot.x = lovexyz.cam.rot.x + dy * speed
	else
		local right, forward = getCameraDirs(lovexyz.cam)
		lovexyz.cam.pos =
			lovexyz.cam.pos
			- right * (dx * speed)
			- forward * (dy * speed)
	end
end

function love.update(dt)
  teapot:rotY(dt)
  suzanne:rotate(dt*.8,dt,dt*.6)
end

function love.resize(w,h)
  lovexyz.refreshCanvases()
end


function love.draw()
  lovexyz.draw()
  love.graphics.print(string.format("%.2f fps",1/love.timer.getAverageDelta()))
end