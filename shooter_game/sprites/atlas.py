from PIL import Image, ImageDraw
import numpy as np, json
im=Image.open('/tmp/claude-0/-home-user-omriweb/4c84a69a-95cf-51ee-b2a6-c44008e8609a/images/4.webp').convert('RGB')
a=np.asarray(im).astype(float)
lum=a.mean(2)
frames=json.load(open('frames.json'))
frames['death']=[(800,572,862,678),(886,585,952,678),(950,640,1045,678),(1040,640,1136,678)]
frames['melee']=[(325,738,418,830),(408,738,500,830),(498,738,628,830)]
frames['jump']=frames['jump'][:5]
USE=['idle','walk','run','jump','fall','slide','crouch','hurt','death','getup','melee','special','aim','shoot_rifle']
def dil(b,r):
    o=b.copy()
    for _ in range(r):
        n=o.copy(); n[1:]|=o[:-1]; n[:-1]|=o[1:]; n[:,1:]|=o[:,:-1]; n[:,:-1]|=o[:,1:]; o=n
    return o
def ero(b,r): return ~dil(~b,r)
PAD=3
crops={}
for name in USE:
    lst=[]
    for (x0,y0,x1,y1) in frames[name]:
        x0-=PAD; y0-=PAD; x1+=PAD+1; y1+=PAD+1
        sub=a[y0:y1,x0:x1]; L=lum[y0:y1,x0:x1]
        d=np.abs(L-19.0)
        alpha=np.clip((d-6.0)/8.0,0,1)
        from collections import deque
        H2,W2=alpha.shape
        def label(mk):
            lab=np.zeros((H2,W2),int); sizes=[]; k=0
            for yy in range(H2):
                for xx in range(W2):
                    if mk[yy,xx] and lab[yy,xx]==0:
                        k+=1; q=deque([(yy,xx)]); lab[yy,xx]=k; c=0
                        while q:
                            cy,cx=q.popleft(); c+=1
                            for dy,dx in ((1,0),(-1,0),(0,1),(0,-1)):
                                ny,nx=cy+dy,cx+dx
                                if 0<=ny<H2 and 0<=nx<W2 and mk[ny,nx] and lab[ny,nx]==0:
                                    lab[ny,nx]=k; q.append((ny,nx))
                        sizes.append(c)
            return lab,sizes
        # 0) מוחקים קו צל דק על הריצפה (מחבר בין דמויות שכנות)
        solid0=alpha>0.3
        for yy in range(max(H2-8,6),H2):
            above=solid0[yy-6:yy-2].any(0)
            alpha[yy,~above]=0
        # 1) רק הדמות עצמה
        lab,sizes=label(dil(alpha>0.3,1))
        big=int(np.argmax(sizes))+1
        keep=lab==big
        if name in ('melee','special'):
            for i2,c in enumerate(sizes):
                if c>0.06*max(sizes): keep|=lab==(i2+1)
        alpha=alpha*keep
        if name in ('walk','run','jump','slide'):   # חותכים חתיכות של השכן מימין (אחרי עמודה ריקה)
            ys0,xs0=np.nonzero(alpha>0.4)
            head_x=int(xs0[ys0<ys0.min()+6].mean())
            col=(alpha>0.4).sum(0)
            if name=='run':   # חלקים קטנים רחוק מימין לגוף = רגל של השכן
                l2,s2=label(alpha>0.3)
                mainc=int(np.argmax(s2))+1
                mx=np.nonzero(l2==mainc)[1].mean()
                for i2,c in enumerate(s2):
                    if i2+1==mainc: continue
                    xs3=np.nonzero(l2==(i2+1))[1]
                    if xs3.mean()>mx+22 and c<0.35*max(s2):
                        alpha[l2==(i2+1)]=0
                # ובתוך הרכיב הראשי: עמודות שהן "רגל זרה" מימין לראש
                alpha[:,head_x+48:]=0
            for xx in range(head_x+18,W2):
                if col[xx]<=1:
                    alpha[:,xx:]=0
                    break
        # 2) צללית מלאה: סוגרים חורים קטנים (המעיל כהה כמו הרקע)
        sil=ero(dil(alpha>0.35,3),3)
        hl,hs=label(~sil)
        for i2,c in enumerate(hs):
            if c<400:
                m2=hl==(i2+1)
                ys2,xs2=np.nonzero(m2)
                if ys2.min()>0 and xs2.min()>0 and ys2.max()<H2-1 and xs2.max()<W2-1:
                    sil[m2]=True
        alpha=np.maximum(alpha,sil*1.0)
        # רקע שנשאר בתוך הצללית: צובעים כהה כמו המעיל
        inside=sil&(np.abs(L-19.0)<7)
        sub=sub.copy(); sub[inside]=sub[inside]*0.45
        alpha=alpha*dil(alpha>0.5,2)   # בלי נקודות חלשות מסביב
        rgba=np.dstack([sub,alpha*255]).astype(np.uint8)
        ys,xs=np.nonzero(alpha>0.4)
        h=ys.max()-ys.min()+1
        top=ys.min()
        band=(ys>=top+0.25*h)&(ys<=top+0.55*h)
        ax=float(xs[band].mean()) if band.any() else float(xs.mean())
        ay=float(ys.max())
        lst.append((rgba,ax,ay))
    crops[name]=lst
# pack
ATW=2048
x=0;y=0;rowh=0
place={}
for name in USE:
    for i,(rgba,ax,ay) in enumerate(crops[name]):
        h,w=rgba.shape[:2]
        if x+w>ATW: x=0; y+=rowh+2; rowh=0
        place.setdefault(name,[]).append((x,y,w,h,round(ax,1),round(ay,1)))
        x+=w+2; rowh=max(rowh,h)
H=y+rowh
atlas=np.zeros((H,ATW,4),np.uint8)
for name in USE:
    for (rgba,ax,ay),(px,py,w,h,_,_) in zip(crops[name],place[name]):
        atlas[py:py+h,px:px+w]=rgba
Image.fromarray(atlas,'RGBA').save('/home/user/omriweb/shooter_game/sprites/hero.png')
print('atlas',ATW,H)
# GDScript data
lines=['extends RefCounted','# ============================================================','#  נתוני האנימציות של הדמות הראשית (נחתכו מה-SPRITE SHEET).','#  כל פריים: [x, y, w, h, ax, ay] בתוך sprites/hero.png','#  ax, ay = נקודת העיגון (מרכז הגוף בגובה כפות הרגליים)','# ============================================================','','const FRAMES := {']
for name in USE:
    lines.append('\t"%s": [%s],' % (name, ', '.join('[%d, %d, %d, %d, %.1f, %.1f]' % p for p in place[name])))
lines.append('}')
open('/home/user/omriweb/shooter_game/hero_anim.gd','w').write('\n'.join(lines)+'\n')
# preview: each anim row aligned on anchor
prev=Image.new('RGBA',(1400,len(USE)*130),(60,70,80,255))
dr=ImageDraw.Draw(prev)
for r,name in enumerate(USE):
    for i,(rgba,ax,ay) in enumerate(crops[name]):
        img=Image.fromarray(rgba,'RGBA')
        bx=80+i*150; by=r*130+120
        prev.alpha_composite(img,(int(bx-ax),int(by-ay)))
        dr.line([(bx-4,by),(bx+4,by)],fill=(255,0,0)); dr.line([(bx,by-4),(bx,by+4)],fill=(255,0,0))
    dr.text((4,r*130+4),name,fill=(255,255,0))
prev.save('animprev.png')
