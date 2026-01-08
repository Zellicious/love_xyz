local vec3 = {}
vec3.__index = vec3

function vec3.new(x,y,z)
return setmetatable({
  x = x or 0,
  y = y or 0,
  z = z or 0
},vec3)
end

function vec3.__add(a,b)
return vec3.new(
  a.x+b.x,
  a.y+b.y,
  a.z+b.z
)
end

function vec3.__sub(a,b)
return vec3.new(
  a.x-b.x,
  a.y-b.y,
  a.z-b.z
)
end

function vec3.__mul(a, b)
-- scalar * vec3
if type(a) == "number" then
return vec3.new(
  a * b.x,
  a * b.y,
  a * b.z
)

-- vec3 * scalar
elseif type(b) == "number" then
return vec3.new(
  a.x * b,
  a.y * b,
  a.z * b
)

-- vec3 * vec3
elseif getmetatable(a) == vec3 and getmetatable(b) == vec3 then
return vec3.new(
  a.x * b.x,
  a.y * b.y,
  a.z * b.z
)
end
end

function vec3:len()
return math.sqrt(self.x*self.x + self.y*self.y + self.z*self.z)
end

function vec3:cross(other)
return vec3.new(
  self.y * other.z - self.z * other.y,
  self.z * other.x - self.x * other.z,
  self.x * other.y - self.y * other.x
)
end

function vec3:dot(other)
return self.x * other.x + self.y * other.y + self.z * other.z
end

-- return normalized copy
function vec3:normalize()
local l = self:len()
if l > 0 then
return vec3.new(self.x/l, self.y/l, self.z/l)
else
  return vec3.new(0,0,0)
end
end

return vec3