extends RefCounted
class_name NivelDados
## O nível é dado, não cena: fácil de editar, fácil de testar, fácil de revisar no diff.

const PLATAFORMAS: Array[Rect2] = [
    Rect2(0, 320, 640, 40),      # chão
    Rect2(120, 250, 110, 16),
    Rect2(300, 195, 110, 16),
    Rect2(470, 140, 110, 16),
    Rect2(60, 130, 80, 16),
]

const MOEDAS: Array[Vector2] = [
    Vector2(175, 225),
    Vector2(355, 170),
    Vector2(525, 115),
    Vector2(100, 105),
    Vector2(600, 295),
]

const RAIO_COLETA := 18.0
