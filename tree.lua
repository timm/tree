local l=require"treelib"
local the={
  seed=937162211
}
local obj=l.obj

XY=obj"XY"

function XY:new(s,n,nlo,nhi) --> XY; count the `y` values from `xlo` to `xhi`
          self.name= s                  -- name of this column
          self.at  = n                   -- offset for this column
          self.xlo = nlo                 -- min x seen so far
          self.xhi = nhi or nlo          -- max x seen so far
          self.n   = 0                   -- number of items seen
          self.y   = {} end              -- y symbols see so far

function XY:__tostring() --> str;  print
  local x,lo,hi,big = self.name, self.xlo, self.xhi, math.huge
  if     lo ==  hi  then return fmt("(%s == %s)", x, lo)
  elseif hi ==  big then return fmt("(%s >  %s)", x, lo)
  elseif lo == -big then return fmt("(%s <= %s)", x, hi)
  else                   return fmt("(%s <  %s <= %s)", lo,x,hi) end end

function XY:add(nx,sy,  n) --> nil;   `n`[=1] times,count `sy`. Expand to cover `nx` 
  if nx~="?" then
    n = n or 1
    self.n     = n + self.n 
    self.y[sy] = n + (self.y[sy] or 0)    -- count
    if nx < self.xlo then self.xlo=nx end -- expand
    if nx > self.xhi then self.xhi=nx end end end

function XY:merge(xy) --> XY;  combine two items (assumes both from same column)
  local combined = XY(self.name, self.at, self.xlo, xy.xhi)
  for y,n in pairs(self.y) do combined:add(self.xlo,y,n) end
  for y,n in pairs(xy.y)   do combined:add(xy.xhi,  y,n) end
  return combined end

function XY:simpler(xy,nMin) --> XY; if whole simpler than parts, return merged self+xy
  local whole = self:merge(xy)
  if self.n < nMin or xy.n < nMin then return whole end -- merge if too small
  local e1,e2,e12= ent(self.y), ent(xy.y), ent(whole.y)
  if e12 <= (self.n*e1 + xy.n*e2)/whole.n               -- merge if whole simpler
  then return whole end end

function load(src,    data)
  local function add(row)
          if data then data:add(row) else data=DATA(row) end end 
  if type(src)=="string" then l.csv(src, add) else map(src or {},add) end
  return data end

function tree(src)
  local names,xlohis,lohis = {},{},{}
  local function add(t) if names then push(rows,t) else names=names end end
  if type(src)=="string" then l.csv(src,add) else l.map(src or {},add) end
end
