#!/usr/bin/env bash
# Testes da colocação das pistas. Roda sem tela, em menos de um segundo.
set -e
cd "$(dirname "$0")"
python3 teste_pistas.py
