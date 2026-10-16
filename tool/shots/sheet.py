#!/usr/bin/env python3
"""Contact sheet of rendered frames:  python3 sheet.py OUT.png COLS SCALE file1.png file2.png ..."""
import sys
from PIL import Image
out, cols, scale = sys.argv[1], int(sys.argv[2]), float(sys.argv[3])
files = sys.argv[4:]
ims = [Image.open(f).convert('RGB') for f in files]
w, h = int(ims[0].width * scale), int(ims[0].height * scale)
rows = (len(ims) + cols - 1) // cols
sheet = Image.new('RGB', (cols * w + (cols + 1) * 8, rows * h + (rows + 1) * 8), (18, 18, 24))
for k, im in enumerate(ims):
    r, c = divmod(k, cols)
    sheet.paste(im.resize((w, h), Image.LANCZOS), (8 + c * (w + 8), 8 + r * (h + 8)))
sheet.save(out)
print(out, sheet.size)
