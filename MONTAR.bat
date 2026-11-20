@echo off
REM Monta o projeto (Platform Designer + Quartus + C). Nao precisa da placa.
REM A saida fica em montar_log.txt
echo Montando o projeto... pode demorar alguns minutos.
call "C:\intelFPGA_lite\18.1\nios2eds\Nios II Command Shell.bat" sh /cygdrive/c/projetos/jogo-de-reflexo/rodar_montagem.sh
echo.
echo Terminou. Veja o montar_log.txt
pause
