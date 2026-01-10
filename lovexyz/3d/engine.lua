local lg = love.graphics -- tired of typing love.graphics?

local sw,sh = lg.getWidth(), lg.getHeight()
local engine = {}
engine.path = "lovexyz/"
engine.EPSILON = .001
-- engine stuff

engine.graphicsScale = 1

engine.canvas = lg.newCanvas(
  math.ceil(sw*engine.graphicsScale),
  math.ceil(sh*engine.graphicsScale),
  {format="rgba8",readable=true}
  )
engine.depthCanvas = lg.newCanvas(
  math.ceil(sw*engine.graphicsScale),
  math.ceil(sh*engine.graphicsScale),
  {
    format="depth24",
    type = "2d",
    readable=true
    
  }
  )

-- create shaders
engine.skyboxShader = lg.newShader(engine.path.."3d/gl/transformSky.vert")
engine.transformShader = lg.newShader(engine.path.."3d/gl/main.glsl")
engine.shadowMapShader = lg.newShader(engine.path.."3d/gl/shadowMap.glsl")
engine.colorCorrection = lg.newShader(engine.path.."3d/gl/colorCorrect.frag")

engine.blkTex = lg.newImage(engine.path.."3d/defaults/blk.png")
engine.whTex = lg.newImage(engine.path.."3d/defaults/wh.png")
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

----
local supportedImgFormats = lg.getCanvasFormats()
if supportedImgFormats["r32f"] then
  engine.shadowMap = lg.newCanvas(
    2048,
    2048,
    {
      format="r32f",
      readable=true,
    }
  )
else
  engine.shadowMap = lg.newCanvas(
    2048,
    2048,
    {
      format="r16f",
      readable=true,
    }
  )
end
engine.shadowMap:setFilter("linear","linear")

engine.shadowSize = 64
engine.sunProj = mat4.ortho(
    -engine.shadowSize, engine.shadowSize,
    -engine.shadowSize, engine.shadowSize,
    -512,512
  )
engine.sunProj = mat4.transpose(engine.sunProj)
----

-- base lighting params

engine.lighting = {}

engine.lighting.solidSkyColor = {.25,.25,.25}
engine.lighting.sunDirection = {-.45,.5,-.25}

engine.lighting.colorCorrection = {
  brightness = 1,
  saturation = 1,
  contrast = 1
}

engine.lighting.shadowSmoothness = .35

engine.lighting.shadowEnabled = true
engine.lighting.simpleShadows = false
engine.lighting.reflectionsEnabled = true
engine.lighting.skyboxEnabled = true

----
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
engine.skyboxFormat = {
  {"VertexPosition", "float", 3},
  {"VertexTexCoord", "float", 2},
}


engine.skyboxMesh = lg.newMesh(
  engine.skyboxFormat,
  skyboxVerts,
  "triangles",
  "static"
)

engine.skyReflectionMap = lg.newCubeImage(engine.path.."3d/defaults/default_sky.png",{mipmaps = true})
engine.skyIrradianceMap = lg.newCubeImage(engine.path.."3d/defaults/default_irradiance.png",{mipmaps = true})

engine.skyTexture = lg.newCubeImage(engine.path.."3d/defaults/default_sky.png",{mipmaps=true})
----
engine.debug = {}

engine.debug.frameDtMs = 0

engine.shadowCanvasSize = 0
engine.mainCanvasSize = 0
engine.windowSize = 0

engine.debug.totalDrawCalls = 0


----
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

local function buildSunView(sunDir, cam)
  local dir = vec3.new(sunDir[1], sunDir[2], sunDir[3]):normalize()
  local target = cam.pos

  local lightPos = target - dir

  local up = math.abs(dir.y) > 0.99
      and vec3.new(0, 0, 1)
      or  vec3.new(0, 1, 0)

  return mat4.lookAt(lightPos, target, up)
end

function engine.perfDebug()
  
  local padding = 8
  local lineH = 16
  local width = sw/2

  local lines = 0
  for _ in pairs(engine.debug) do
    lines = lines + 1
  end

  local height = padding * 2 + lines * lineH

  lg.push()
  lg.translate(8, 8)

  lg.setColor(0,0,0,.7)
  lg.rectangle("fill", 0, 0, width, height,8,8)
  lg.setColor(1,1,1,1)
  lg.draw(engine.shadowMap,width+8,0,0,height/engine.shadowMap:getWidth(),height/engine.shadowMap:getWidth())

  lg.translate(padding, padding)
  lg.setColor(1, 1, 1)

  local y = 0
  for k, v in pairs(engine.debug) do
    lg.print(k .. ": " .. tostring(v), 0, y)
    y = y + lineH
  end

  lg.pop()
end

function engine.refreshCanvases()
  sw,sh = lg.getWidth(), lg.getHeight()
  
  engine.canvas:release()
  engine.depthCanvas:release()
  
  engine.canvas = lg.newCanvas(
    math.ceil(sw*engine.graphicsScale),
    math.ceil(sh*engine.graphicsScale),
    {format="rgba8",readable=true}
    )
  engine.depthCanvas = lg.newCanvas(
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
  lg.setCanvas({engine.canvas,nil, depthstencil = engine.depthCanvas, depth = true})
  lg.clear(engine.lighting.solidSkyColor[2],engine.lighting.solidSkyColor[3],engine.lighting.solidSkyColor[1],1,false,1)
  ----
  local drawCount = 0
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
  
  lg.setMeshCullMode("back")
  lg.setDepthMode("lequal", false)
  lg.setShader(engine.skyboxShader)
  engine.skyboxShader:send("u_MVP", mat4.mul(mvpNoTranslate,mat4.scale(1,1,1)))
  engine.skyboxShader:send("skybox", engine.skyTexture)
  
  lg.draw(engine.skyboxMesh)
  drawCount = drawCount + 1
  
  ::skyboxEnd::
  
  ---- shadow map 
  if not engine.lighting.shadowEnabled then goto shadowMapEnd end
  
  lg.setCanvas({engine.shadowMap, depth = true})
  lg.clear()
  
  lg.setMeshCullMode("back")
  lg.setDepthMode("lequal", true)
  
  lg.setShader(engine.shadowMapShader)
  engine.shadowMapShader:send("u_MVP", sunMVP)
  for _, model in pairs(triangles.loadedModels) do
    if not model.visible then goto skip end
    
    local modelMatrix = model.transformMatrix
    engine.shadowMapShader:send("u_ModelMatrix", modelMatrix)
    lg.draw(model.mesh)
    drawCount = drawCount + 1
    ::skip::
  end
  ::shadowMapEnd::
  ----
  
  
  
  
  ---- main canvas render 
  lg.setCanvas({engine.canvas,nil, depthstencil = engine.depthCanvas, depth = true})
  
  lg.setMeshCullMode("back")
  lg.setDepthMode("less", true)
  
  lg.setShader(engine.transformShader)
  
  engine.transformShader:send("shadowMap", engine.shadowMap)
  engine.transformShader:send("reflectionMap", engine.skyReflectionMap)
  engine.transformShader:send("irradianceMap", engine.skyIrradianceMap)

  engine.transformShader:send("u_SunMVP", sunMVP)
  
  engine.transformShader:send("u_MVP", mvp)
  for _, model in pairs(triangles.loadedModels) do
    if not model.visible then goto skip end
    local modelMatrix = model.transformMatrix
    engine.transformShader:send("u_ModelMatrix", modelMatrix)
    
    engine.transformShader:send("u_Metallic",model.mtl.metallic or 0)
    engine.transformShader:send("AOMap",model.mtl.aoTex or engine.whTex)
    engine.transformShader:send("RoughMap",model.mtl.roughTex or engine.whTex)

    lg.draw(model.mesh)
    
    
    drawCount = drawCount + 1
    ::skip::
  end
  
  ---- send lighting info to fragment
  engine.transformShader:send("u_ShadowMapTexel",{engine.shadowMap:getWidth(),engine.shadowMap:getHeight()})
  engine.transformShader:send("u_LightDir", engine.lighting.sunDirection)
  engine.transformShader:send("u_CamPosWorld", {engine.cam.pos.x,engine.cam.pos.y,engine.cam.pos.z})
  engine.transformShader:send("u_ShadowSmoothness", engine.lighting.shadowSmoothness)
   
  engine.transformShader:send("shadowEnabled",engine.lighting.shadowEnabled)
  engine.transformShader:send("reflectionsEnabled",engine.lighting.reflectionsEnabled)
  engine.transformShader:send("simpleShadows",engine.lighting.simpleShadows)
  
  ---- finally draw the canvas
  lg.setCanvas()
  
  lg.setShader(engine.colorCorrection)
  engine.colorCorrection:send("u_Brightness",engine.lighting.colorCorrection.brightness)
  engine.colorCorrection:send("u_Saturation",engine.lighting.colorCorrection.saturation)
  engine.colorCorrection:send("u_Contrast",engine.lighting.colorCorrection.contrast)
  
  lg.setDepthMode("always", false)
  lg.draw(engine.canvas, 0, 0, 0, sw/engine.canvas:getWidth(),sh/engine.canvas:getHeight())
  drawCount = drawCount + 1
  ----
  
  lg.setShader()
  
  -- update debugs
  engine.debug.frameDtMs = tostring(love.timer.getAverageDelta()*1000) .. " ms"
  
  engine.debug.shadowCanvasSize = tostring(engine.shadowMap:getWidth()) .. "x" .. tostring(engine.shadowMap:getHeight())
  engine.debug.mainCanvasSize = tostring(engine.canvas:getWidth()) .. "x" .. tostring(engine.canvas:getHeight())
  engine.debug.windowSize = tostring(sw) .. "x" .. tostring(sh)
  
  engine.debug.totalDrawCalls = drawCount
  
end


return engine