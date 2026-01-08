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

engine._VERSION = "lovexyz 0.4.3-alpha"
engine.patchNotes = [[
**MINOR**
- merge frag and shader into one
- renamed engine.lua params (may not be updated at the documentation yet)

**PATCH**
- sacrifice shader accuracy for performance

]]

print(engine._VERSION)
print(engine.patchNotes)

local engine = engine
_G.engine = nil
return engine