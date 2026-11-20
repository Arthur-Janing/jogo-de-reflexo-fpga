#!/bin/sh
# Monta tudo: Platform Designer, Quartus e o programa em C.
# Rodar pelo MONTAR.bat (ou no Nios II Command Shell: sh montar_tudo.sh)
# Nao precisa da placa ligada.
set -e
cd "$(dirname "$0")"
PASTA=$(pwd)

# se o .sof da DE10-Lite ja existe e nenhum arquivo do hardware mudou depois dele,
# pula o hardware (demora uns minutos).
PRECISA=sim
if [ -f "$PASTA/quartus/reflexo.sof" ] && grep -q "MAX 10" "$PASTA/quartus/reflexo.qsf" 2>/dev/null; then
    PRECISA=nao
    for arq in "$PASTA"/hw/*.v "$PASTA"/quartus/*.tcl "$PASTA"/quartus/*.sdc; do
        if [ "$arq" -nt "$PASTA/quartus/reflexo.sof" ]; then
            PRECISA=sim
        fi
    done
fi

if [ "$PRECISA" = "nao" ]; then
    echo "=== Hardware ja compilado (quartus/reflexo.sof). Pulando etapas 1 a 3 ==="
else
    # apaga restos de compilacao antiga antes de compilar
    cd "$PASTA/quartus"
    rm -rf db incremental_db sistema_nios sistema_nios.qsys sistema_nios.sopcinfo reflexo.*

    echo "=== 1/5 Montando o sistema do Nios II (Platform Designer) ==="
    qsys-script --script=criar_sistema_nios.tcl

    echo "=== 2/5 Gerando o Verilog do sistema ==="
    qsys-generate sistema_nios.qsys --synthesis=VERILOG --output-directory=sistema_nios

    echo "=== 3/5 Criando e compilando o projeto no Quartus ==="
    quartus_sh -t criar_projeto.tcl
    quartus_sh --flow compile reflexo
fi

echo "=== 4/5 Criando o BSP (bibliotecas do Nios II) ==="
cd "$PASTA"
rm -rf software
mkdir -p software/app
# o nios2-bsp do Quartus antigo as vezes retorna erro por causa de um aviso do cygwin
# mesmo gerando tudo certo, entao conferimos pelo Makefile
nios2-bsp hal software/bsp quartus/sistema_nios.sopcinfo \
    --set hal.enable_small_c_library true \
    --set hal.enable_reduced_device_drivers true || true
if [ ! -f software/bsp/Makefile ]; then
    echo "ERRO: o BSP nao foi gerado."
    exit 1
fi

echo "=== 5/5 Compilando o programa em C ==="
# copia com cat porque o cp do cygwin bagunca a permissao do arquivo
cat sw/main.c > software/app/main.c
chmod 644 software/app/main.c
nios2-app-generate-makefile --bsp-dir software/bsp --app-dir software/app \
    --src-files main.c --elf-name reflexo.elf
make -C software/app

echo ""
echo "PRONTO! Tudo montado."
echo "No laboratorio: ligue a DE10-Lite no USB e rode sh jogar.sh"
