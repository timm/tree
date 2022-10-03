local l=require"treelib"
local T=require"tree"
local cli,lt,o,oo,push,rnd,run,sort=l.cli,l.lt,l.o,l.oo,l.push,l.rnd,l.run,l.sort
local the=T.the
local DATA=T.DATA

local go={}
function go.the() oo(the) end

function go.rand()
  local t,a={},{10,20,30,40}
  for i=1,100 do push(t, l.rint(#a)) end end

function go.csv() 
  local i=1
  l.csv(the.file,function(row) i=i+1; if i<10 then oo(row) end end) end

function go.data() 
  local data=DATA(the.file) 
  oo(data.cols.x[1])
  return data.cols.x[1].hi == 8 end

function go.dist() 
  local data=DATA(the.file) 
  print(data:dist(data._rows[1],data._rows[2])) end 

function go.dists() 
  local data=DATA(the.file) 
  local all={}
  for _,row in pairs(data._rows) do
    push(all, rnd(data:dist(data._rows[1],row),3)) end 
  oo(sort(all)) end

function go.sorted()
  local data=DATA(the.file) 
  oo(data.cols.names)
  local rows=data:cheat() 
  for i = 1,#rows,1 do
    print(rows[i].rank, o(rows[i].cells)) end end

function go.clone() 
  local data1=DATA(the.file) 
  local data2=data1:clone(data1._rows)
  oo{b4=data1.cols.x[2].hi, now=data2.cols.x[2].hi}
  return data1.cols.x[2].hi == data2.cols.x[2].hi end 

function go.half()
  local data=DATA(the.file) 
  local xs,ys,x,y= data:half() 
  oo{dist=data:dist(x,y),  xsize=#xs._rows, ysize= #ys._rows}
  return data:dist(x,y)> .8 and 199== #xs._rows and 199 ==  #ys._rows end

function go.tree()
  local data=DATA(the.file)
  local _,parents= data:tree(4) 
  print("\n"..the.file,#data._rows)
  for _,parent in pairs(parents) do
     print(rnd(parent.gain,3), o{id=parent._id, level=parent.level, entropy=rnd(data:ent(parent._rows),3), nrows=#parent._rows}) end end

function go.sneak()
  local out={}
  local usedys={}
  local known={}
  for i=1,20 do
    io.write(".");io.flush()
    local data=DATA(the.file)
    data:cheat()
    for _,row in pairs(data:sneak()._rows) do  push(out,row.rank) end 
    local n=0; for _,row in pairs(data._rows) do if row.usedy then push(known,row.rank);  n=n+1 end end ; push(usedys,n) 
    end
  print("")
  out=sort(out); print("GUESSED",o(l.map({0,.1,.3,.5,.7,.9},function(p) return l.per(out,p) end)), l.fmt(" %-30s",the.file)) 
  print(               "KNOWN  ",o(l.pers(sort(known), {0,.1,.3,.5,.7,.9})))
  io.write(            "EVALED  ",o(l.pers(sort(usedys), {0,.1,.3,.5,.7,.9})))
end

the=cli(the)
os.exit(run(go,the))
