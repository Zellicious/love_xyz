local triangles = {}
triangles.path = "lovexyz/"

triangles.__index = triangles
triangles.meshes = {}
triangles.loadedModels={}
triangles.textureCache = {}

triangles.format = {
	{"VertexPosition", "float", 3},
	{"VertexNormal",   "float", 3},
	{"VertexTexCoord", "float", 2}
}

function isPowerOfTwo(n)
  if n <= 0 then return false end
  while n % 2 == 0 do
    n = n / 2
  end
  return n == 1
end

local function packVertex(v)
	return {
		v.pos.x,  v.pos.y,  v.pos.z,
		v.norm.x, v.norm.y, v.norm.z,
		v.uv[1],  v.uv[2]
	}
end

function triangles.add(v1, v2, v3, usage)
  if not (v1 and v2 and v3) then return end
	local verts = {
		packVertex(v1),
		packVertex(v2),
		packVertex(v3)
	}

	local mesh = love.graphics.newMesh(
		triangles.format,
		verts,
		"triangles",
		usage or "static"
	)

	triangles.meshes[#triangles.meshes + 1] = mesh
	return mesh
end

function triangles.newTexture(path,name)
  assert(love.filesystem.getInfo(path),"File not found: "..path)
  local tex = love.graphics.newImage(path)
  
  if isPowerOfTwo(tex:getHeight()) and isPowerOfTwo(tex:getWidth()) then
    tex = love.graphics.newImage(path,{mipmaps=true})
  end
	tex:setWrap("repeat", "repeat")
	
	triangles.textureCache[name] = tex
	return tex
end

function triangles.loadModel(path,usage,lookupName)
  assert(love.filesystem.getInfo(path),"File not found: "..path)
  local verts = obj.loadVerts(path)
  local mesh = love.graphics.newMesh(
		triangles.format,
		verts,
		"triangles",
		usage or "static"
	)
	local model = {
	  mesh=mesh,
	  transformMatrix=mat4.identity(),
	  mtl={
	    
	  },
	  visible=true
	}
	
	function model:move(dx, dy, dz)
    local T = mat4.translate_col(dx, dy, dz)
    self.transformMatrix = mat4.mul(T, self.transformMatrix)
	end
	
	function model:scale(sx, sy, sz)
    local S = mat4.scale(sx, sy, sz)
    self.transformMatrix = mat4.mul(S, self.transformMatrix)
  end
	
  function model:rotX(angle)
    local R = mat4.rotX(angle)
    self.transformMatrix = mat4.mul(self.transformMatrix, R)
  end
  
  function model:rotY(angle)
    local R = mat4.rotY(angle)
    self.transformMatrix = mat4.mul(self.transformMatrix, R)
  end
  
  function model:rotZ(angle)
    local R = mat4.rotZ(angle)
    self.transformMatrix = mat4.mul(self.transformMatrix, R)
  end
  
  function model:rotate(rx, ry, rz)
    if rx ~= 0 then self:rotX(rx) end
    if ry ~= 0 then self:rotY(ry) end
    if rz ~= 0 then self:rotZ(rz) end
  end
	
	triangles.meshes[#triangles.meshes + 1] = mesh
	triangles.loadedModels[lookupName or #triangles.loadedModels + 1] = model
	
	return model
end

return triangles