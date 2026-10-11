import math,wave,struct,random
from pathlib import Path
root=Path(__file__).resolve().parents[1] / 'godot/assets/audio';root.mkdir(parents=True,exist_ok=True);rate=22050;random.seed(17)
def save(name,duration,fn):
 with wave.open(str(root/(name+'.wav')),'wb') as w:
  w.setparams((1,2,rate,0,'NONE','not compressed'))
  w.writeframes(b''.join(struct.pack('<h',int(max(-1,min(1,fn(i/rate)))*28000)) for i in range(int(duration*rate))))
def tone(t,f):return math.sin(2*math.pi*f*t)
for name,dur,start,end in [('jump',.23,240,800),('land',.13,100,40),('shoot',.18,1100,120),('spin',.65,450,70),('tick',.12,620,620),('go',.35,1000,1000)]:
 save(name,dur,lambda t,d=dur,a=start,b=end: .35*tone(t,a+(b-a)*t/(2*d))*math.sin(math.pi*t/d))
for name,dur in [('impact',.15),('box',.28),('brake',.6)]:
 save(name,dur,lambda t,d=dur:.23*(random.random()*2-1)*(1-t/d))
save('engine',1,lambda t:.18*(tone(t,80)+.45*tone(t,160)+.25*tone(t,240)))
# Original 32-bar chip groove, 120 bpm, exactly 64 seconds.
notes=[72,76,79,76,74,77,81,77,71,74,79,74,72,76,79,83]
chords=[48,53,55,48]
def music(t):
 step=int(t/.25);beat=t%.5;chord=chords[(step//16)%4]
 n=notes[step%16];f=440*2**((n-69)/12);e=(1-(t%.25)/.25)**1.5
 lead=.12*tone(t,f)*e+.03*tone(t,f*2)*e
 bass=.13*tone(t,440*2**((chord-69)/12))*math.exp(-beat*9)
 kick=.18*math.sin(2*math.pi*(65*beat+5*(1-math.exp(-beat*30))))*math.exp(-beat*23)
 hat=.035*(random.random()*2-1)*math.exp(-(t%.25)*70)
 return lead+bass+kick+hat
save('race_music',64,music)
