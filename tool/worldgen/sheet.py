import sys, glob
from PIL import Image
S = '/tmp/claude-0/-home-user-solitaire-app/2159d7d9-0583-50a7-a346-78ef31ed353a/scratchpad/'
names = sys.argv[2:]
ims = [Image.open(S + n).resize((270, 480)) for n in names]
cols = min(len(ims), 4)
rows = (len(ims) + cols - 1) // cols
out = Image.new('RGB', (cols * 270, rows * 480))
for i, im in enumerate(ims):
    out.paste(im, ((i % cols) * 270, (i // cols) * 480))
out.save(S + sys.argv[1])
