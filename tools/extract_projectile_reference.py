"""Extract the original EV 1.0.5 projectile frames used as model references."""
from pathlib import Path
from PIL import Image, ImageDraw
from inspect_ev import read_resources
from extract_title_art import decode
ROOT = Path(__file__).resolve().parents[1]
FRAMES = [('Space bomb',214,16,16),('Heavy rocket',212,32,28),
          ('Missile',206,24,20),('Torpedo',204,16,16),('Decoy flare',218,8,8)]
if __name__ == '__main__':
    source = next((ROOT/'research/extracted').rglob('EV Graphics.rsrc'))
    resources = read_resources(source.read_bytes())
    folder = ROOT/'research/decoded/projectile-reference'
    folder.mkdir(exist_ok=True)
    atlas = Image.new('RGB',(700,150),'#202020')
    draw = ImageDraw.Draw(atlas)
    for index,(name,rid,width,height) in enumerate(FRAMES):
        resource = next(r for r in resources if r['type']=='PICT' and r['id']==rid)
        image = decode(resource['data']).crop((0,0,width,height))
        image.save(folder/f'{rid}.png')
        atlas.paste(image.resize((width*4,height*4),Image.Resampling.NEAREST),(index*140,0))
        draw.text((index*140+4,125),name,fill='white')
    atlas.save(folder/'original-projectiles.png')
