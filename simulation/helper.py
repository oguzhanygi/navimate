from PIL import Image
import sys

def pgm_to_png(pgm_path, png_path=None):

    img = Image.open(pgm_path)
    # Convert to PNG and save
    if not png_path:
        png_path = pgm_path.rsplit('.', 1)[0] + '.png'
    img.save(png_path)
    print(f"Saved: {png_path}")
    
    return png_path
