# -*- coding: utf-8 -*-
"""Registro central dos desenhos. Cada módulo de capítulo chama `desenho`."""

DESENHOS = []


def desenho(nome, legenda, cor, arte):
    if hasattr(arte, "arte"):          # aceita uma Tela do pincel
        arte = arte.arte()
    DESENHOS.append({"nome": nome, "legenda": legenda, "cor": cor, "arte": arte})


def limpar():
    DESENHOS.clear()
