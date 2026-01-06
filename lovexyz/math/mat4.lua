local mat4 = {}
mat4.__index = mat4

-- create identity matrix
function mat4.identity()
	return {
		1, 0, 0, 0,
		0, 1, 0, 0,
		0, 0, 1, 0,
		0, 0, 0, 1
	}
end

-- matrix * matrix
function mat4.mul(a, b)
	local r = {}
	for row = 0, 3 do
		for col = 0, 3 do
			local i = row * 4 + col + 1
			r[i] =
				a[row*4 + 1] * b[col + 1] +
				a[row*4 + 2] * b[col + 5] +
				a[row*4 + 3] * b[col + 9] +
				a[row*4 + 4] * b[col + 13]
		end
	end
	return r
end

function mat4.translate_row(x, y, z)
    local m = mat4.identity()

    m[13] = x or 0
    m[14] = y or 0
    m[15] = z or 0

    return m
end

function mat4.translate_col(x, y, z)
    local m = mat4.identity()
    m[4]  = x or 0
    m[8]  = y or 0
    m[12] = z or 0

    return m
end

function mat4.scale(sx, sy, sz)
    local m = mat4.identity()

    m[1]  = sx or 1
    m[6]  = sy or 1
    m[11] = sz or 1

    return m
end

function mat4.rotX(a)
    local c = math.cos(a)
    local s = math.sin(a)

    return {
        1,  0,  0,  0,
        0,  c, -s,  0,
        0,  s,  c,  0,
        0,  0,  0,  1
    }
end

function mat4.rotY(a)
    local c = math.cos(a)
    local s = math.sin(a)

    return {
         c,  0,  s, 0,
         0,  1,  0, 0,
        -s,  0,  c, 0,
         0,  0,  0, 1
    }
end

function mat4.rotZ(a)
    local c = math.cos(a)
    local s = math.sin(a)

    return {
         c, -s, 0, 0,
         s,  c, 0, 0,
         0,  0, 1, 0,
         0,  0, 0, 1
    }
end

-- matrix * vec4
function mat4.mulVec4(m, v)
	return {
		m[1]*v[1] + m[2]*v[2] + m[3]*v[3] + m[4]*v[4],
		m[5]*v[1] + m[6]*v[2] + m[7]*v[3] + m[8]*v[4],
		m[9]*v[1] + m[10]*v[2] + m[11]*v[3] + m[12]*v[4],
		m[13]*v[1] + m[14]*v[2] + m[15]*v[3] + m[16]*v[4]
	}
end

-- perspective
function mat4.perspective(fov, aspect, near, far)
	local f = 1 / math.tan(fov * 0.5)
	return {
		f / aspect, 0, 0, 0,
		0, f, 0, 0,
		0, 0, (far + near) / (near - far), (2 * far * near) / (near - far),
		0, 0, -1, 0
	}
end

function mat4.transpose(m)
	return {
		m[1],  m[5],  m[9],  m[13],
		m[2],  m[6],  m[10], m[14],
		m[3],  m[7],  m[11], m[15],
		m[4],  m[8],  m[12], m[16]
	}
end

function mat4.inverse(m)
  local inv = {}
  local det

  inv[1]  =  m[6]*m[11]*m[16] - m[6]*m[12]*m[15] - m[10]*m[7]*m[16] + m[10]*m[8]*m[15] + m[14]*m[7]*m[12] - m[14]*m[8]*m[11]
  inv[2]  = -m[2]*m[11]*m[16] + m[2]*m[12]*m[15] + m[10]*m[3]*m[16] - m[10]*m[4]*m[15] - m[14]*m[3]*m[12] + m[14]*m[4]*m[11]
  inv[3]  =  m[2]*m[7]*m[16]  - m[2]*m[8]*m[15]  - m[6]*m[3]*m[16]  + m[6]*m[4]*m[15]  + m[14]*m[3]*m[8]  - m[14]*m[4]*m[7]
  inv[4]  = -m[2]*m[7]*m[12]  + m[2]*m[8]*m[11]  + m[6]*m[3]*m[12]  - m[6]*m[4]*m[11]  - m[10]*m[3]*m[8]  + m[10]*m[4]*m[7]
  
  inv[5]  = -m[5]*m[11]*m[16] + m[5]*m[12]*m[15] + m[9]*m[7]*m[16]  - m[9]*m[8]*m[15]  - m[13]*m[7]*m[12] + m[13]*m[8]*m[11]
  inv[6]  =  m[1]*m[11]*m[16] - m[1]*m[12]*m[15] - m[9]*m[3]*m[16]  + m[9]*m[4]*m[15]  + m[13]*m[3]*m[12] - m[13]*m[4]*m[11]
  inv[7]  = -m[1]*m[7]*m[16]  + m[1]*m[8]*m[15]  + m[5]*m[3]*m[16]  - m[5]*m[4]*m[15]  - m[13]*m[3]*m[8]  + m[13]*m[4]*m[7]
  inv[8]  =  m[1]*m[7]*m[12]  - m[1]*m[8]*m[11]  - m[5]*m[3]*m[12]  + m[5]*m[4]*m[11]  + m[9]*m[3]*m[8]   - m[9]*m[4]*m[7]

  inv[9]  =  m[5]*m[10]*m[16] - m[5]*m[12]*m[14] - m[9]*m[6]*m[16]  + m[9]*m[8]*m[14]  + m[13]*m[6]*m[12] - m[13]*m[8]*m[10]
  inv[10] = -m[1]*m[10]*m[16] + m[1]*m[12]*m[14] + m[9]*m[2]*m[16]  - m[9]*m[4]*m[14]  - m[13]*m[2]*m[12] + m[13]*m[4]*m[10]
  inv[11] =  m[1]*m[6]*m[16]  - m[1]*m[8]*m[14]  - m[5]*m[2]*m[16]  + m[5]*m[4]*m[14]  + m[13]*m[2]*m[8]  - m[13]*m[4]*m[6]
  inv[12] = -m[1]*m[6]*m[12]  + m[1]*m[8]*m[10]  + m[5]*m[2]*m[12]  - m[5]*m[4]*m[10]  - m[9]*m[2]*m[8]   + m[9]*m[4]*m[6]

  inv[13] = -m[5]*m[10]*m[15] + m[5]*m[11]*m[14] + m[9]*m[6]*m[15]  - m[9]*m[7]*m[14]  - m[13]*m[6]*m[11] + m[13]*m[7]*m[10]
  inv[14] =  m[1]*m[10]*m[15] - m[1]*m[11]*m[14] - m[9]*m[2]*m[15]  + m[9]*m[3]*m[14]  + m[13]*m[2]*m[11] - m[13]*m[3]*m[10]
  inv[15] = -m[1]*m[6]*m[15]  + m[1]*m[7]*m[14]  + m[5]*m[2]*m[15]  - m[5]*m[3]*m[14]  - m[13]*m[2]*m[7]  + m[13]*m[3]*m[6]
  inv[16] =  m[1]*m[6]*m[11]  - m[1]*m[7]*m[10]  - m[5]*m[2]*m[11]  + m[5]*m[3]*m[10]  + m[9]*m[2]*m[7]   - m[9]*m[3]*m[6]

  det = m[1]*inv[1] + m[2]*inv[5] + m[3]*inv[9] + m[4]*inv[13]

  if det == 0 then return mat4.identity() end

  det = 1.0 / det
  for i=1,16 do
      inv[i] = inv[i] * det
  end

  return inv
end

function mat4.ortho(left, right, bottom, top, near, far)
  local rl = right - left
  local tb = top - bottom
  local fn = far - near

  return {
    2 / rl, 0,       0,        -(right + left) / rl,
    0,      2 / tb,  0,        -(top + bottom) / tb,
    0,      0,      -2 / fn,   -(far + near) / fn,
    0,      0,       0,         1
  }
end

local function normalize(x, y, z)
  local len = math.sqrt(x*x + y*y + z*z)
  return x/len, y/len, z/len
end

local function cross(ax, ay, az, bx, by, bz)
  return
    ay*bz - az*by,
    az*bx - ax*bz,
    ax*by - ay*bx
end

function mat4.lookAt(eye, target, up)
  local fx = target.x - eye.x
  local fy = target.y - eye.y
  local fz = target.z - eye.z
  fx, fy, fz = normalize(fx, fy, fz)

  local rx, ry, rz = cross(
    fx, fy, fz,
    up.x, up.y, up.z
  )
  rx, ry, rz = normalize(rx, ry, rz)

  local ux, uy, uz = cross(rx, ry, rz, fx, fy, fz)

  return {
     rx,  ry,  rz, -(rx*eye.x + ry*eye.y + rz*eye.z),
     ux,  uy,  uz, -(ux*eye.x + uy*eye.y + uz*eye.z),
    -fx, -fy, -fz,  (fx*eye.x + fy*eye.y + fz*eye.z),
     0,   0,   0,    1
  }
end

return mat4