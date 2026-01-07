-- barebones init.lua, will upgrade later

local basePathName = (...)

vec3 = require(basePathName..".math.vec3")
mat4 = require(basePathName..".math.mat4")

triangles = require(basePathName..".3d.lua.triangles")
obj = require(basePathName..".3d.lua.obj")

engine = require(basePathName..".3d.engine")
engine.path = basePathName

engine._VERSION = "lovexyz 1.1.9"
print(engine._VERSION)

local engine = engine
_G.engine = nil
return engine