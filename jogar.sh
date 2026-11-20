#!/bin/sh
# Grava a placa e roda o jogo. Rodar pelo JOGAR.bat com a DE10-Lite no USB.
# Ctrl+C pra sair.
set -e
cd "$(dirname "$0")"

echo "=== Gravando o hardware na placa ==="
nios2-configure-sof quartus/reflexo.sof

echo "=== Carregando o programa no Nios II ==="
nios2-download -g software/app/reflexo.elf

echo "=== Console do jogo (Ctrl+C para sair) ==="
nios2-terminal
