"""Um borrão gaussiano de máscara, sem scipy — usa o Pillow."""
import numpy as np
from PIL import Image, ImageFilter


def suavizar_mascara(m, raio=3):
    img = Image.fromarray((np.clip(m, 0, 1) * 255).astype(np.uint8))
    img = img.filter(ImageFilter.GaussianBlur(raio))
    return np.asarray(img, dtype=np.float32) / 255.0
