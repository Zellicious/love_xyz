--[[
 _                               
| | _____   _______  ___   _ ____
| |/ _ \ \ / / _ \ \/ / | | |_  /
| | (_) \ V /  __/>  <| |_| |/ / 
|_|\___/ \_/ \___/_/\_\\__, /___|
                       |___/     

]]

local basePathName = (...)

-- globals
_G.vec3 = require(basePathName..".math.vec3")
_G.mat4 = require(basePathName..".math.mat4")

_G.triangles = require(basePathName..".3d.lua.triangles")
_G.obj = require(basePathName..".3d.lua.obj")

-- main engine
engine = require(basePathName..".3d.engine")
engine.path = basePathName

engine._VERSION = "lovexyz 0.8.0-alpha"
engine.patchNotes = [[
**MINOR**
- heavily redesigned the entire render pipeline (some parameters were removed, replaced with textures)
- new skybox rendering solution (via shader, fixed edges)

**PATCH**
- revert to semi-PBR
- changed default sky

]]

print(engine._VERSION)
print(engine.patchNotes)

local engine = engine
_G.engine = nil
return engine