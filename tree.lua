local l=require"treelib"
local help=[[
Install:
  git clone http://github.com/timm/tree]]

local the={
  _help=help,
  bins= 5,
  Far = .95,
  file= "../data/auto93.csv",
  go  = "nothing",
  help=false,
  min = .5,
  p   = 2,
  seed= 937162211,
  some= 512 }

local XY, ROW, SYM, NUM, DATA = l.obj"XY", l.obj"ROW", l.obj"SYM", l.obj"NUM", l.obj"DATA"
local gt,lt, o,oo, map,push,sort = l.gt,l.lt, l.o,l.oo, l.map,l.push,l.sort

function XY:new(s,n,nlo,nhi) --> XY; count the `y` values from `xlo` to `xhi`
          self.name= s                  -- name of this column
          self.at  = n                   -- offset for this column
          self.xlo = nlo                 -- min x seen so far
          self.xhi = nhi or nlo          -- max x seen so far
          self.n   = 0                   -- number of items seen
          self.y   = {} end              -- y symbols see so far

function ROW:new(t) --> ROW. 
  self.usedy = false
  self.rank = 0
  self.cells=t end

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
  n,s = n or 0, s or ""
  self.at, self.txt, self.lo, self.hi = n,s, 1E31, -1E31 
  self.w = s:find"-$" and -1 or 1 end

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
  return math.abs(x-y) end
function NUM:discretize(n) --> num; discretize `Num`s,rounded to (hi-lo)/bins
  local tmp = (self.hi - self.lo)/(the.bins - 1)
  return self.hi == self.lo and 1 or math.floor(n/tmp + .5)*tmp end 

function DATA:new(src)
  self._rows, self.cols = {},nil
  self.level,self.gain = 0,0
  if   type(src)=="string" 
  then l.csv(src,      function(t) self:add(t) end) 
  else l.map(src or {},function(t) self:add(t) end) end end

function DATA:add(t) --> nil. Accepts a simple table or a `ROW`. Updates `self.
  if not self.cols then self.cols=self:header(t) else  
    t = push(self._rows, t.cells and t or ROW(t)) 
    for _,cols in pairs({self.cols.x, self.cols.y}) do
      for _,col in pairs(cols) do col:add(t.cells[col.at]) end end end end

function DATA:header(t)
  local cols = {names=t, all={}, x={}, y={}}
  for n,s in pairs(t) do
    local function isNum()   return s:find"^[A-Z]" end
    local function isGoal()  return s:find"[!+-]$" end
    local function isKlass() return s:find"!$" end
    local function isSkip()  return s:find":$" end
    local col = push(cols.all, (isNum() and NUM or SYM)(s,n))
    if not isSkip() then
      if isKlass() then cols.klass=col end
      push(cols[isGoal() and "y" or "x"], col) end end 
  return cols end

function DATA:cheat()
  for i,row in pairs(self:sorted()) do
    row.usedy = false
    row.rank  = math.floor(.5 + 100*i/(#self._rows)) end 
  return self._rows end

function DATA:better(row1,row2) --> bool; returns true if `row1`'s goals better than `row2`
   local s1,s2,x,y=0,0
   row1.usedy,row2.usedy = true,true
   for _,col in pairs(self.cols.y) do
     x = col:norm(row1.cells[col.at])
     y = col:norm(row2.cells[col.at])
     s1= s1 - math.exp(col.w * (x-y)/#self.cols.y)
     s2= s2 - math.exp(col.w * (y-x)/#self.cols.y) end
   return s1/#self.cols.y < s2/#self.cols.y end

function DATA:sorted() --- sort `self.rows`
   return sort(self._rows, function(r1,r2) return self:better(r1,r2) end) end 
            
function DATA:clone(  init) --> data; return a table with the same structure
  local data = DATA()
  data:add(self.cols.names) 
  map(init or {}, function(row) data:add(row) end)
  return data end  

function DATA:dist(row1,row2)
  local d,n = 0,0
  for _,col in pairs(self.cols.x) do
    local x,y = row1.cells[col.at], row2.cells[col.at]
    local inc= col:dist(x,y)
    d = d + inc^the.p
    n = n + 1 end
  return (d/n)^(1/the.p) end

function DATA:around(row,rows,      t)
  t=map(rows or self._rows, function(r) return {row=r, d=self:dist(row,r)} end)
  return sort(t, lt"d") end

function DATA:far(row, rows) 
  local t = self:around(row,rows); return t[the.Far*#t//1].row end

function DATA:half(  above)
  local some,A,B,c,As,Bs,d,proj
  function d(r1,r2) return self:dist(r1,r2) end
  function proj(r)  return {r=r, x=(d(A,r)^2 + c^2 - d(B,r)^2)/(2*c)} end
  some = l.many(self._rows, the.some)
  A = above or self:far(l.any(some), some) 
  B = self:far(A, some)
  c = d(A,B)
  As,Bs = self:clone(), self:clone()
  for i,rw in pairs(sort(map(self._rows, proj), lt"x")) do
    if i<=(#self._rows)//2 then As:add(rw.r) else Bs:add(rw.r) end end
  return As,Bs,A,B,c end 

function DATA:tree(max)
  local stop = (#self._rows)^the.min
  local tmp,parents= {},{}
  local etop = self:ent()
  local max  = max or 1E32
  local function recurse(data,level,above)
    data.level = level
    if #data._rows >= stop and level <= max then
      local xs,ys,x,y  = data:half(above)
      tmp[data._id] = tmp[data._id] or push(parents,data)
      data.gain  = #data._rows/#self._rows*( etop - (self:ent(xs._rows) + self:ent(ys._rows))/2)
      data.tree={
        left= x,
        right= y,
        lefts  = recurse(xs,level+1,x),
        rights = recurse(ys,level+1,y)} end
    return data 
  end -------
  recurse(self,1) 
  return self,sort(parents,gt"gain") end

function DATA:sneak(  stop)
  local dead = {}
  local stop = stop or (#self._rows)^the.min
  local function recurse(data)
    if #data._rows < stop then return data else
      local _,parents=data:tree(3)
      local tree=parents[1].tree
      local doomed = data:better(tree.left,tree.right) and tree.rights or tree.lefts 
      for _,row in pairs(doomed._rows) do dead[row._id] = row._id end
      local survivors = map(data._rows, function(row) if not dead[row._id] then return row end end) 
      return recurse(self:clone(survivors)) end end
  return recurse(self) end

function DATA:ent(rows)
  local e = 0
  for _,col in pairs(self.cols.x) do
    local d = {}
    for _,row in pairs(rows or self._rows) do
      local v = row.cells[col.at]
      if v ~= "?" then v=col:discretize(v); d[v] = 1 + (d[v] or 0) end end 
    e = e + l.ent(d) end 
  return e end

return {the=the,DATA=DATA,NUM=NUM,ROW=ROW,SYM=SYM}

