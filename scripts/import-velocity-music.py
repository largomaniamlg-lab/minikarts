"""Fetch the user's exact TeknoAXE choice, verify CC BY 4.0, and package it locally.
Uses normal HTTPS proxy and CA verification; never substitutes a different song.
"""
import hashlib,html,json,re,subprocess,tempfile,urllib.parse,urllib.request
from pathlib import Path
SOURCE='https://teknoaxe.com/Link_Code_3.php?q=1702&genre=Drum_and_Bass'
ROOT=Path(__file__).resolve().parents[1]
LIMIT=32*1024*1024

def fetch(url):
    with urllib.request.urlopen(url,timeout=45) as response:
        data=response.read(LIMIT+1)
        if len(data)>LIMIT: raise RuntimeError('Audio exceeds 32 MiB')
        return data

page=fetch(SOURCE).decode('utf-8',errors='replace')
if not re.search(r'creativecommons\.org/licenses/by/4\.0',page,re.I):
    raise RuntimeError('Exact track page does not confirm CC BY 4.0; verify before distribution')
links=[html.unescape(x) for x in re.findall(r'(?:href|src)=[\"\']([^\"\']+)[\"\']',page,re.I)]
candidates=[x for x in links if re.search(r'\.mp3(?:$|[?&])|mobile_direct_download\.php\?file=',x,re.I)]
candidates=list(dict.fromkeys(candidates))
if len(candidates)>1: raise RuntimeError("Multiple MP3 links on track page; identify exact chosen download before import")
if not candidates: raise RuntimeError('No MP3 download found on selected track page')
url=urllib.parse.urljoin(SOURCE,candidates[0])
parts=urllib.parse.urlsplit(url)
if parts.hostname not in ['teknoaxe.com','www.teknoaxe.com']:
    raise RuntimeError('Audio uses another host; review its access before downloading')
url=urllib.parse.urlunsplit(('https',parts.netloc,parts.path,parts.query,''))
audio=fetch(url)
name=urllib.parse.parse_qs(parts.query).get('file',[''])[0]
if not name: name=urllib.parse.unquote(parts.path.rsplit('/',1)[-1])
name=Path(name).stem.replace('_',' ')
if not name: raise RuntimeError('Track title is missing')
asset=ROOT/'godot/assets/audio/velocity_music.ogg'
with tempfile.TemporaryDirectory(prefix='minikarts-music-') as folder:
    original=Path(folder)/'source.mp3';original.write_bytes(audio)
    info=json.loads(subprocess.check_output(['ffprobe','-v','error','-show_format','-show_streams','-of','json',str(original)]))
    duration=float(info['format']['duration'])
    if not 15<=duration<=1200 or not any(s['codec_type']=='audio' for s in info['streams']):
        raise RuntimeError('Unexpected audio stream/duration')
    converted=Path(folder)/'velocity.ogg'
    subprocess.run(['ffmpeg','-v','error','-i',str(original),'-vn','-af','loudnorm=I=-16:TP=-1.5:LRA=9','-ar','44100','-c:a','libvorbis','-q:a','3',str(converted)],check=True)
    asset.write_bytes(converted.read_bytes())
metadata={'track_id':1702,'circuit':'Velocidad','title':name,'author':'TeknoAXE','source':SOURCE,'download':url,'license':'CC BY 4.0','license_url':'https://creativecommons.org/licenses/by/4.0/','changes':'Converted to Ogg Vorbis and normalized loudness; full composition retained','original_sha256':hashlib.sha256(audio).hexdigest(),'ogg_sha256':hashlib.sha256(asset.read_bytes()).hexdigest(),'duration':duration}
(ROOT/'godot/assets/audio/velocity-music.json').write_text(json.dumps(metadata,ensure_ascii=False,indent=2)+'\n')
(ROOT/'CREDITS_MUSIC.md').write_text(f'# Música de Velocidad\n\n{name} — TeknoAXE.\n\nFuente: {SOURCE}\n\nLicencia: [Creative Commons Attribution 4.0](https://creativecommons.org/licenses/by/4.0/).\n\nAdaptación técnica: conversión a Ogg Vorbis y normalización de volumen. La composición completa se conserva.\n')
print(json.dumps({'title':name,'duration':duration,'bytes':asset.stat().st_size},ensure_ascii=False))
