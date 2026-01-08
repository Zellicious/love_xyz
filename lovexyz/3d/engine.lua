local sw,sh = love.graphics.getWidth(), love.graphics.getHeight()

local skyboxVerts = {
  {-1, -1,  1,  1/4, 1/3},
  { 1, -1,  1,  1/2, 1/3},
  { 1,  1,  1,  1/2, 2/3},

  {-1, -1,  1,  1/4, 1/3},
  { 1,  1,  1,  1/2, 2/3},
  {-1,  1,  1,  1/4, 2/3},
  --
  { 1, -1, -1,  3/4,   1/3},
  {-1, -1, -1,  1, 1/3},
  {-1,  1, -1,  1, 2/3},

  { 1, -1, -1,  3/4,   1/3},
  {-1,  1, -1,  1, 2/3},
  { 1,  1, -1,  3/4,   2/3},
  --
  {-1, -1, -1,  0,   1/3},
  {-1, -1,  1,  1/4, 1/3},
  {-1,  1,  1,  1/4, 2/3},

  {-1, -1, -1,  0,   1/3},
  {-1,  1,  1,  1/4, 2/3},
  {-1,  1, -1,  0,   2/3},

  { 1, -1,  1,  1/2, 1/3},
  { 1, -1, -1,  3/4, 1/3},
  { 1,  1, -1,  3/4, 2/3},

  { 1, -1,  1,  1/2, 1/3},
  { 1,  1, -1,  3/4, 2/3},
  { 1,  1,  1,  1/2, 2/3},

  {-1,  1,  1,  1/4, 2/3},
  { 1,  1,  1,  1/2, 2/3},
  { 1,  1, -1,  1/2, 1},

  {-1,  1,  1,  1/4, 2/3},
  { 1,  1, -1,  1/2, 1},
  {-1,  1, -1,  1/4, 1},

  {-1, -1, -1,  1/4, 0},
  { 1, -1, -1,  1/2, 0},
  { 1, -1,  1,  1/2, 1/3},

  {-1, -1, -1,  1/4, 0},
  { 1, -1,  1,  1/2, 1/3},
  {-1, -1,  1,  1/4, 1/3},
}
local engine = {}
engine.path = "lovexyz/"
-- engine stuff

engine.graphicsScale = 1

engine.canvas = love.graphics.newCanvas(
  math.ceil(sw*engine.graphicsScale),
  math.ceil(sh*engine.graphicsScale),
  {format="rgba8",readable=true}
  )
engine.depthCanvas = love.graphics.newCanvas(
  math.ceil(sw*engine.graphicsScale),
  math.ceil(sh*engine.graphicsScale),
  {
    format="depth24",
    type = "2d",
    readable=true
    
  }
  )

-- create shaders
engine.skyboxShader = love.graphics.newShader(engine.path.."3d/gl/transformSky.glsl")
engine.transformShader = love.graphics.newShader(engine.path.."3d/gl/lit.glsl",engine.path.."3d/gl/transform.glsl")
engine.transformOnly = love.graphics.newShader(engine.path.."3d/gl/shadowMapFrag.glsl",engine.path.."3d/gl/transform.glsl")
engine.colorCorrection = love.graphics.newShader(engine.path.."3d/gl/colorCorrect.glsl")

----
engine.shadowMap = love.graphics.newCanvas(
  1024,
  1024
  ,{format="r16f",readable=true}
)
engine.shadowMap:setFilter("linear","linear")

engine.shadowSize = 20
engine.sunProj = mat4.ortho(
    -engine.shadowSize, engine.shadowSize,
    -engine.shadowSize, engine.shadowSize,
    -512,512
  )
engine.sunProj = mat4.transpose(engine.sunProj)
----

-- base lighting params

engine.lighting = {}

engine.lighting.solidSkyColor = {.5,.5,.5}
engine.lighting.sunDirection = {.45,.87,-.25}

engine.lighting.colorCorrection = {
  brightness = 1,
  saturation = 1,
  contrast = 1
}

engine.lighting.ambient = .15
engine.lighting.specShininess = 64
engine.lighting.specStrength = .25

engine.lighting.shadowEnabled = true
engine.lighting.simpleShadows = false
engine.lighting.specularEnabled = true
engine.lighting.diffuseEnabled = true
engine.lighting.skyboxEnabled = true


----
engine.cam = {
  pos=vec3.new(0,0,3),
  rot=vec3.new(),
  fov = math.rad(90),
  matrix=mat4.identity()
}

engine.proj = mat4.perspective(
	engine.cam.fov,
	sw / sh,
	.1,
	512
)

engine.skyboxFormat = {
  {"VertexPosition", "float", 3},
  {"VertexTexCoord", "float", 2},
}
engine.skyboxMesh = love.graphics.newMesh(
  engine.skyboxFormat,
  skyboxVerts,
  "triangles",
  "static"
)
engine.skyTexture = love.graphics.newImage(engine.path.."3d/defaults/default_sky.png")
engine.skyboxMesh:setTexture(engine.skyTexture)

-- functions
local function buildView(cam)
	local rx = mat4.rotX(-cam.rot.x)
	local ry = mat4.rotY(-cam.rot.y)
	local rz = mat4.rotZ(-cam.rot.z)

	local r = mat4.mul(rz, mat4.mul(rx, ry))

	local t = mat4.translate_col(
  	-cam.pos.x,
  	-cam.pos.y,
  	-cam.pos.z
	 )

	return mat4.mul(r, t)
end

local function dirToEuler(dir)
  local yaw = math.atan2(dir.x, -dir.z)
  local pitch = math.asin(-dir.y)
  local roll = 0
    
  return vec3.new(pitch, yaw, roll)
end

local function buildSunView(sunDir,cam)
  local dir = vec3.new(sunDir[1],sunDir[2],sunDir[3]):normalize()
  local dirRot = dirToEuler(dir)
  local rx = mat4.rotX(dirRot.x)
	local ry = mat4.rotY(dirRot.y)
	local rz = mat4.rotZ(0)

	local r = mat4.mul(rz, mat4.mul(rx, ry))

	local t = mat4.translate_col(
  	dir.x-cam.pos.x,
  	dir.y-cam.pos.y,
  	dir.z-cam.pos.z
	 )

	return mat4.mul(r, t)
end

function engine.perfDebug()
  love.graphics.push()
  love.graphics.translate(8,8)
  
  love.graphics.setColor(0,0,0,.7)
  love.graphics.rectangle("fill",0,0,256,32+16)
  
  love.graphics.push()
  love.graphics.translate(8,8)
  
  love.graphics.setColor(1,1,1)
  love.graphics.print(string.format("%.2f fps",1/love.timer.getAverageDelta()))
  
  love.graphics.setColor(1,1,1)
  love.graphics.print(string.format("%.2f live fps",1/love.timer.getDelta()),0,16)
  
  love.graphics.pop()
  
  love.graphics.setColor(1,1,1)
  
  love.graphics.pop()
end

function engine.refreshCanvases()
  sw,sh = love.graphics.getWidth(), love.graphics.getHeight()
  
  engine.canvas:release()
  engine.depthCanvas:release()
  
  engine.canvas = love.graphics.newCanvas(
    math.ceil(sw*engine.graphicsScale),
    math.ceil(sh*engine.graphicsScale),
    {format="rgba8",readable=true}
    )
  engine.depthCanvas = love.graphics.newCanvas(
    math.ceil(sw*engine.graphicsScale),
    math.ceil(sh*engine.graphicsScale),
    {
      format="depth24",
      type = "2d",
      readable=true
      
    }
    )
  engine.sunProj = mat4.ortho(
    -engine.shadowSize, engine.shadowSize,
    -engine.shadowSize, engine.shadowSize,
    -512,512
  )
  engine.sunProj = mat4.transpose(engine.sunProj)
  engine.proj = mat4.perspective(
  	engine.cam.fov,
  	sw / sh,
  	.1,
  	512
  )
end

function engine.draw()
  love.graphics.setCanvas({engine.canvas,nil, depthstencil = engine.depthCanvas, depth = true})
  love.graphics.clear(engine.lighting.solidSkyColor[2],engine.lighting.solidSkyColor[3],engine.lighting.solidSkyColor[1],1,false,1)
  ----
  
	local view = buildView(engine.cam)
	local viewNoTranslation = {
    view[1], view[2], view[3],  0,
    view[5], view[6], view[7],  0,
    view[9], view[10],view[11], 0,
    0, 0, 0, 1
    }
    
	
  local mvp = mat4.mul(mat4.mul(engine.proj, view),engine.cam.matrix)
  local mvpNoTranslate = mat4.mul(engine.proj, viewNoTranslation)
  
  local sunView = buildSunView(engine.lighting.sunDirection,engine.cam)
  local sunMVP = mat4.mul(engine.sunProj, sunView)
  local sunMVPNoTranslate = {
    sunView[1], sunView[2], sunView[3],  0,
    sunView[5], sunView[6], sunView[7],  0,
    sunView[9], sunView[10],sunView[11], 0,
    0, 0, 0, 1
    }
  
  
  ---- skybox
  if not engine.lighting.skyboxEnabled then goto skyboxEnd end
  
  love.graphics.setMeshCullMode("front")
  love.graphics.setDepthMode("lequal", false)
  love.graphics.setShader(engine.skyboxShader)
  engine.skyboxShader:send("u_MVP", mat4.mul(mvpNoTranslate,mat4.scale(1,-1,1)))
  
  love.graphics.draw(engine.skyboxMesh)
  
  ::skyboxEnd::
  
  ---- shadow map
  if not engine.lighting.shadowEnabled then goto shadowMapEnd end
  
  love.graphics.setCanvas({engine.shadowMap, depth = true})
  love.graphics.clear()
  
  love.graphics.setMeshCullMode("back")
  love.graphics.setDepthMode("less", true)
  
  love.graphics.setShader(engine.transformOnly)
  engine.transformOnly:send("u_MVP", sunMVP)
  for _, model in ipairs(triangles.loadedModels) do
    if not model.visible then goto skip end
    
    local modelMatrix = model.transformMatrix
    engine.transformOnly:send("u_ModelMatrix", modelMatrix)
    love.graphics.draw(model.mesh)
    
    ::skip::
  end
  ::shadowMapEnd::
  ----
  
  
  
  
  ---- main canvas render
  love.graphics.setCanvas({engine.canvas,nil, depthstencil = engine.depthCanvas, depth = true})
  
  love.graphics.setMeshCullMode("back")
  love.graphics.setDepthMode("less", true)
  
  love.graphics.setShader(engine.transformShader)
  
  engine.transformShader:send("shadowMap", engine.shadowMap)
  engine.transformShader:send("u_SunMVP", sunMVP)
  
  engine.transformShader:send("u_MVP", mvp)
  for _, model in ipairs(triangles.loadedModels) do
    if not model.visible then goto skip end
    
    local modelMatrix = model.transformMatrix
    engine.transformShader:send("u_ModelMatrix", modelMatrix)
    love.graphics.draw(model.mesh)
    
    ::skip::
  end
  
  ---- send lighting info to fragment
  engine.transformShader:send("u_ShadowMapSize",{engine.shadowMap:getWidth(),engine.shadowMap:getHeight()})
  engine.transformShader:send("u_LightDir", engine.lighting.sunDirection)
  engine.transformShader:send("u_CamPosWorld", {engine.cam.pos.x,engine.cam.pos.y,engine.cam.pos.z})
  engine.transformShader:send("u_Ambient", engine.lighting.ambient)
  engine.transformShader:send("u_Shininess", engine.lighting.specShininess)
  engine.transformShader:send("u_Specular", engine.lighting.specStrength)
  
  engine.transformShader:send("diffuseEnabled",engine.lighting.diffuseEnabled)
  engine.transformShader:send("specularEnabled",engine.lighting.specularEnabled)
  engine.transformShader:send("shadowEnabled",engine.lighting.shadowEnabled)
  engine.transformShader:send("simpleShadows",engine.lighting.simpleShadows)
  
  ---- finally draw the canvas
  love.graphics.setCanvas()
  
  love.graphics.setShader(engine.colorCorrection)
  engine.colorCorrection:send("u_Brightness",engine.lighting.colorCorrection.brightness)
  engine.colorCorrection:send("u_Saturation",engine.lighting.colorCorrection.saturation)
  engine.colorCorrection:send("u_Contrast",engine.lighting.colorCorrection.contrast)
  
  love.graphics.setDepthMode("always", false)
  love.graphics.draw(engine.canvas, 0, 0, 0, sw/engine.canvas:getWidth(),sh/engine.canvas:getHeight())
  ----
  
  love.graphics.setShader()
end


return engine