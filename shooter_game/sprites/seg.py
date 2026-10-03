from PIL import Image, ImageDraw
import numpy as np
from collections import deque
im=Image.open('/tmp/claude-0/-home-user-omriweb/4c84a69a-95cf-51ee-b2a6-c44008e8609a/images/4.webp').convert('RGB')
a=np.asarray(im).astype(float)
lum=a.mean(2)
bg=19.0
diff=np.abs(lum-bg)
mask=(lum<11)|(lum>34)
SECT={
 'idle':(20,465,42,165,8),'walk':(480,990,42,165,8),'run':(1005,1515,42,165,6),
 'jump':(20,485,195,352,6),'fall':(495,975,200,352,4),'slide':(990,1515,200,352,3),
 'crouch':(20,405,392,524,5),'shoot_rifle':(418,1010,392,524,5),'shoot_pistol':(1022,1515,392,524,5),
 'aim':(20,372,560,688,4),'turn':(385,772,560,688,4),'death':(785,1143,560,688,4),'getup':(1155,1515,560,688,4),
 'hurt':(20,272,722,838,3),'melee':(285,640,722,838,3),'special':(655,1022,722,838,3),
 'dirs':(20,430,868,980,5),'wpos':(445,930,868,980,4),
}
LABELS=[(15,20,150,38),(485,20,600,38),(1005,20,1100,38),(15,183,120,202),(495,183,600,202),(995,183,1100,202),
 (15,368,120,388),(420,368,600,388),(1030,368,1200,388),(15,537,200,556),(390,537,600,556),(790,537,900,556),(1160,537,1280,556),
 (15,700,120,720),(290,700,450,720),(660,700,820,720),(15,850,200,868),(450,850,620,868)]
for (x0,y0,x1,y1) in LABELS: mask[y0:y1,x0:x1]=False
def dil(b,r):
    o=b.copy()
    for _ in range(r):
        n=o.copy(); n[1:]|=o[:-1]; n[:-1]|=o[1:]; n[:,1:]|=o[:,:-1]; n[:,:-1]|=o[:,1:]; o=n
    return o
frames={}
dbg=im.copy(); dr=ImageDraw.Draw(dbg)
for name,(x0,x1,y0,y1,n) in SECT.items():
    m=dil(mask[y0:y1,x0:x1],3)
    H,W=m.shape
    seen=np.zeros_like(m); comps=[]
    for y in range(H):
        for x in range(W):
            if m[y,x] and not seen[y,x]:
                q=deque([(y,x)]); seen[y,x]=True; xs=[];ys=[]
                while q:
                    cy,cx=q.popleft(); xs.append(cx); ys.append(cy)
                    for dy,dx in ((1,0),(-1,0),(0,1),(0,-1)):
                        ny,nx=cy+dy,cx+dx
                        if 0<=ny<H and 0<=nx<W and m[ny,nx] and not seen[ny,nx]:
                            seen[ny,nx]=True; q.append((ny,nx))
                if len(xs)>250:
                    comps.append([min(xs),min(ys),max(xs),max(ys),len(xs)])
    # remove long thin lines (dividers)
    comps=[c for c in comps if not ((c[2]-c[0])>200 and (c[3]-c[1])<8) and not ((c[3]-c[1])>100 and (c[2]-c[0])<6)]
    comps.sort()
    # merge overlapping in x
    merged=[]
    for c in comps:
        if merged and c[0] < merged[-1][2]-6:
            m2=merged[-1]; merged[-1]=[min(m2[0],c[0]),min(m2[1],c[1]),max(m2[2],c[2]),max(m2[3],c[3]),m2[4]+c[4]]
        else: merged.append(c)
    print(name, 'want',n,'got',len(merged), [ (c[2]-c[0],c[3]-c[1]) for c in merged])
    frames[name]=[(c[0]+x0,c[1]+y0,c[2]+x0,c[3]+y0) for c in merged]
    for c in frames[name]: dr.rectangle(c,outline=(255,0,0))
dbg.save('segdbg.png')
import json; json.dump(frames,open('frames.json','w'))

# ---- פיצול לפי ראשים לקטעים שהתמזגו ----
def split_heads(name):
    x0,x1,y0,y1,n=SECT[name]
    m=mask[y0:y1,x0:x1]
    H,W=m.shape
    top=np.full(W,H)
    for x in range(W):
        ys=np.nonzero(m[:,x])[0]
        if len(ys): top[x]=ys.min()
    cand=sorted(range(W),key=lambda x: top[x])
    picks=[]
    for x in cand:
        if top[x]>=H: break
        if all(abs(x-p)>38 for p in picks):
            # must be a local minimum region
            picks.append(x)
        if len(picks)==n: break
    picks.sort()
    bounds=[0]+[ (picks[i]+picks[i+1])//2 for i in range(len(picks)-1)]+[W]
    out=[]
    for i in range(len(picks)):
        sub=m[:,bounds[i]:bounds[i+1]]
        ys,xs=np.nonzero(sub)
        out.append((int(xs.min()+bounds[i]+x0),int(ys.min()+y0),int(xs.max()+bounds[i]+x0),int(ys.max()+y0)))
    return out
for name in ['walk','run','slide','death','melee','shoot_rifle']:
    frames[name]=split_heads(name)
    print(name,[ (c[2]-c[0],c[3]-c[1]) for c in frames[name]])
frames['wpos']=[c for c in frames['wpos'] if c[2]-c[0]>15]
dbg=im.copy(); dr=ImageDraw.Draw(dbg)
for name,fl in frames.items():
    for c in fl: dr.rectangle(c,outline=(255,0,0))
dbg.save('segdbg.png')
json.dump(frames,open('frames.json','w'))
