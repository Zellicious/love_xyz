-----


local obj = {}

local function faceNormal(a, b, c)
  local ax, ay, az = a.pos.x, a.pos.y, a.pos.z
  local bx, by, bz = b.pos.x, b.pos.y, b.pos.z
  local cx, cy, cz = c.pos.x, c.pos.y, c.pos.z
  
  local abx, aby, abz = bx - ax, by - ay, bz - az
  local acx, acy, acz = cx - ax, cy - ay, cz - az

  local nx = aby * acz - abz * acy
  local ny = abz * acx - abx * acz
  local nz = abx * acy - aby * acx
  local len = math.sqrt(nx*nx + ny*ny + nz*nz)
  if len > 0 then
    nx, ny, nz = nx/len, ny/len, nz/len
  else
    nx, ny, nz = 0, 0, 1
  end

  return nx, ny, nz
end

function obj.loadVerts(path)
	local positions = {}
	local normals   = {}
	local uvs       = {}

	local meshVerts = {}

	for line in love.filesystem.lines(path) do
		local t = {}
		for w in line:gmatch("%S+") do
			t[#t+1] = w
		end

		if t[1] == "v" then
			positions[#positions+1] = vec3.new(
				tonumber(t[2]),
				-tonumber(t[3]),
				tonumber(t[4])
			)

		elseif t[1] == "vt" then
			uvs[#uvs+1] = { tonumber(t[2]), 1-tonumber(t[3]) }

		elseif t[1] == "vn" then
			normals[#normals+1] = vec3.new(
				-tonumber(t[2]),
				tonumber(t[3]),
				-tonumber(t[4])
			)

		elseif t[1] == "f" then
			local face = {}

			for i = 2, #t do
				local vi, ti, ni = t[i]:match("(%d+)/?(%d*)/?(%d*)")

				face[#face+1] = {
					pos = positions[tonumber(vi)],
					uv  = uvs[tonumber(ti)] or {0,0},
					n   = normals[tonumber(ni)] or nil
				}
			end

			-- triangle fan: v1, v(i), v(i+1)
			for i = 2, #face - 1 do
				local a = face[1]
				local b = face[i]
				local c = face[i + 1]

        local na, nb, nc = a.n, b.n, c.n
        if not na or not nb or not nc then
          local nx, ny, nz = faceNormal(a, b, c)
          na = { x = nx, y = ny, z = nz }
          nb = na
          nc = na
        end
        meshVerts[#meshVerts+1] = {
          a.pos.x, a.pos.y, a.pos.z,
          na.x,    na.y,    na.z,
          a.uv[1], a.uv[2]
        }
        meshVerts[#meshVerts+1] = {
          b.pos.x, b.pos.y, b.pos.z,
          nb.x,    nb.y,    nb.z,
          b.uv[1], b.uv[2]
        }
        meshVerts[#meshVerts+1] = {
          c.pos.x, c.pos.y, c.pos.z,
          nc.x,    nc.y,    nc.z,
          c.uv[1], c.uv[2]
        }
			end
		end
	end

	return meshVerts
end

return obj