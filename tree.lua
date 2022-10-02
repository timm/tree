local l=require"treelib"
local help=[[
Install:
  git clone http://github.com/timm/tree]]

local the={
  p   = 2,
  min = .5,
  far = .95,
  bins= 8,
  some= 512,
  seed= 937162211,
  file= "../data/auto93.csv" }

local XY, SYM, NUM, DATA = l.obj"XY", l.obj"SYM", l.obj"NUM", l.obj"DATA"
local lt, oo, push = l.lt, l.oo, l.push

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

function SYM:new(s,n) 
  self.at, self.txt = n,s end
function SYM:add(x) 
  return x end
function SYM:dist(x,y)
  return x=="?" and y=="?" and 1 or x==y and 0 or 1 end
function SYM:discretize(s) --> s; discretizing a symbol just returns that symbol
  return s end

function NUM:new(s,n) 
  self.at, self.txt, self.lo, self.hi = n,s, 1E31, -1E31 end
function NUM:add(x) 
  if x ~= "?" then
    self.lo = math.min(x, self.lo)
    self.hi = math.max(x, self.hi) end end
function NUM:norm(x,    lo,hi)
  lo,hi = self.lo,self.hi
  return x=="?" and 0  or (hi-lo)<1E-9 and 0 or (x-lo)/(hi-lo) end
function NUM:dist(x,y)
  if x=="?" and y=="?" then return 1 end
  x,y = self:norm(x), self:norm(y)
  if x=="?" then x=y<.5 and 1 or 0 end
  if y=="?" then y=x<.5 and 1 or 0 end
  return maths.abs(x-y) end
function NUM:discretize(n) --> num; discretize `Num`s,rounded to (hi-lo)/bins
  local tmp = (self.hi - self.lo)/(the.bins - 1)
  return self.hi == self.lo and 1 or math.floor(n/tmp + .5)*tmp end 

function DATA:new(src)
  self.rows, self.cols = {},nil
  local function isNum(s)   return s:find"^[A-Z]" end
  local function isGoal(s)  return s:find"[!+-]$" end
  local function isKlass(s) return s:find"!" end
  local function isSkip(s)  return s:find":$" end
  local function head(t)
    local cols = {names=t, all={}, x={}, y={}}
    for k,v in pairs(t) do
      local col = push(cols.all, (isNum(v) and NUM or SYM)(v,k))
      if not isSkip(v) then
        if isKlass(v) then cols.klass=col end
        push(cols[isGoal(v) and "y" or "x"], col) end end end
      return cols end   
  local function add(t) 
    if not self.cols then self.cols=head(t) else  
      push(self.rows,t) 
      for _,cols in pairs(self.nums) do
        for _,col in pairs(cols) do col:add(t[col.at]) end end end end 
  if type(src)=="string" then l.csv(src,add) else l.map(src or {},add) end 

function DATA:clone(  init)
  data = DATA({self.names}) 
  map(init or {}, function(row) data:add(row) end)
  return data end  

function DATA:dist(row1,row2)
  local d,n = 0,0
  for _,col in pairs(self.cols.x) do
    local inc= col:dist( col:norm(row1[col.at]), col:norm(row2[col.at]))
    d = d + inc^the,p
    n = n + 1 end
  return (d/n)^(1/the.p) end

function DATA:around(row,rows,      t)
  t=map(rows or self.rows, function(r) return {row=r, d=self:dist(row,r)} end)
  return sort(t, lt"d") end

function DATA:far(row, rows) 
  local t = self:around(row,rows)
  return t[the.far*#t//1] end

function DATA:half(  above)
  local some,A,B,c,xs,ys,d,proj
  some = l.many(self.rows, the.some)
  A = above or self:far(l.any(some), some) 
  B = self:far(y, some)
  c = self:dist(A,B)
  function d(r1,r2) return self:dist(r1,r2) end
  function proj(r)  return {r=row, x=(d(a,r)^2 + c^2 - d(b,r)^2)/(2*c)} end
  xs,ys = self:clone(), self:clone()
  for i,rw in pairs(sort(map(self.rows, proj), lt"x")) do
    if i<=self.rows//2 then xs:add(rw.x) else ys:add(rw.x) end end
  return xs,ys,x,y,c end 

function DATA:tree(  stop,    above)
  stop = stop or (#self.rows)^the.min
  if #self.rows >= stop then
    xs,ys,x,y  = self:half(above)
    self.gain  = self:ent() - .5*(xs:ent() + ys:ent())
    self.left  = xs:tree(stop, x)
    self.right = ys:tree(stop, y) end
  return self end

function DATA:ent()
  if not self._ent then 
    self._ent = 0
    for _,col in pairs(self.cols.x) do
      local d = {}
      for _,row in pairs(self.rows) do
        v = row[col.at]
        if v ~= "?" then v=col:discretize(v); d[v] = 1 + (d[v] or 0) end end 
      self._ent = self._ent + l.ent(d) end end
  return self._ent end

local data=DATA("../data/auto93.csv", l.oo)
oo(data.nums)
l.rogues()
