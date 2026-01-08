-- barebones init.lua, will upgrade later

local basePathName = (...)

_G.vec3 = require(basePathName..".math.vec3")
_G.mat4 = require(basePathName..".math.mat4")

_G.triangles = require(basePathName..".3d.lua.triangles")
_G.obj = require(basePathName..".3d.lua.obj")

engine = require(basePathName..".3d.engine")
engine.path = basePathName

engine._VERSION = "0.3.2-alpha"
print(engine._VERSION)

local engine = engine
_G.engine = nil
return engine