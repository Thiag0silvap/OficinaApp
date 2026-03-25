from PIL import Image
import sys

SRC = 'assets/images/logo.png'
DST = 'windows/runner/resources/app_icon.ico'

try:
    im = Image.open(SRC).convert('RGBA')
except Exception as e:
    print(f'ERROR: cannot open source image {SRC}: {e}')
    sys.exit(2)

sizes = [(256,256),(48,48),(32,32),(16,16)]
try:
    im.save(DST, format='ICO', sizes=sizes)
    print('OK: saved', DST)
except Exception as e:
    print('ERROR saving ICO:', e)
    sys.exit(3)
