#!/bin/sh
# chamado pelo MONTAR.bat, salva a saida em montar_log.txt
cd /cygdrive/c/projetos/jogo-de-reflexo
sh montar_tudo.sh > montar_log.txt 2>&1
echo "CODIGO_SAIDA=$?" >> montar_log.txt
tail -5 montar_log.txt
