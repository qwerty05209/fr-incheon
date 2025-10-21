import sys as q,shutil as x,subprocess as y,struct as z,pefile
from pathlib import Path
from cryptography.hazmat.primitives.serialization import pkcs7
def r(p):
 s=x.which("signtool")
 if not s:return None,None
 try:
  p=y.run([s,"verify","/pa","/v",str(p)],capture_output=True,text=True,timeout=30)
  return p.returncode,p.stdout+p.stderr
 except Exception:return None,None
def n(p):
 try:a=pefile.PE(str(p),fast_load=True)
 except pefile.PEFormatError:return None
 try:
  b=a.OPTIONAL_HEADER.DATA_DIRECTORY
  if len(b)<=4:return None
  c,d,e=b[4],int(c.VirtualAddress),int(c.Size)
  if d==0 or e==0:return None
  f=a.__data__[d:d+e]
  if len(f)<8:return None
  g=z.unpack_from("<I",f,0)[0]
  if g>len(f):g=len(f)
  h=f[8:g]
  if not h:return None
  try:i=pkcs7.load_der_pkcs7_certificates(h)
  except Exception:return None
  j=[k.subject.rfc4514_string() for k in i]
  return j
 except Exception:return None
def l(p,c=False):
 p=Path(p)
 if not p.exists():raise FileNotFoundError("없잖아")
 m=p.rglob("*") if c else p.iterdir()
 for f in m:
  if not f.is_file():continue
  _=r(f)[0]
  if _ is not None:continue
  k,o=n(f),False
  if not k:continue
  for i in k:
   if "JNESS"in i:o=True
  if o:print("파일:",f)
if __name__=="__main__":
 if len(q.argv)<2:
  print("python fr.py <check path> [--recursive]")
  q.exit(1)
 l(q.argv[1],c="--recursive"in q.argv[2:])