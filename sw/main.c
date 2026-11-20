/*
 * main.c - programa do Nios II do jogo de reflexo
 *
 * Quem mede o tempo e o hardware (cronometro_ms.v). Aqui fica so a logica
 * do jogo: esperar o tempo sorteado, ver se apertou cedo, acender os LEDs,
 * ler o tempo e guardar recorde/ranking.
 *
 * KEY0 = comecar / reagir
 * KEY1 = apagar recorde e ranking
 */
#include <stdio.h>
#include <unistd.h>
#include "system.h"
#include "altera_avalon_pio_regs.h"

/* modos do display (PIO modo) */
#define MODO_TEMPO   0
#define MODO_PLAY    1
#define MODO_ESPERA  2
#define MODO_CEDO    3

/* comandos do cronometro (PIO comando) */
#define PARADO  0
#define ARMAR   1
#define ZERAR   2

#define TAMANHO_RANKING 5

int ranking_tempo[TAMANHO_RANKING];
int ranking_rodada[TAMANHO_RANKING];
int ranking_quantidade = 0;
int recorde = 0;    /* 0 = ainda nao tem */


void mostra_no_display(int modo)
{
    IOWR_ALTERA_AVALON_PIO_DATA(MODO_BASE, modo);
}

void acende_leds(int valor)
{
    IOWR_ALTERA_AVALON_PIO_DATA(LEDS_BASE, valor);
}

void comando_cronometro(int comando)
{
    IOWR_ALTERA_AVALON_PIO_DATA(COMANDO_BASE, comando);
}

void zera_cronometro(void)
{
    comando_cronometro(ZERAR);
    comando_cronometro(PARADO);
}

/* os botoes (KEY) da DE10-Lite valem 0 quando apertados */
int botao_jogo_apertado(void)
{
    int botoes = IORD_ALTERA_AVALON_PIO_DATA(BOTOES_BASE);
    if ((botoes & 1) == 0)
        return 1;
    else
        return 0;
}

int botao_apagar_apertado(void)
{
    int botoes = IORD_ALTERA_AVALON_PIO_DATA(BOTOES_BASE);
    if ((botoes & 2) == 0)
        return 1;
    else
        return 0;
}

void espera_soltar_botao(void)
{
    while (botao_jogo_apertado()) {
        usleep(10000);
    }
    usleep(30000);   /* debounce */
}

/* le o tempo em BCD e converte pra ms. ex: 0x0243 -> 243 */
int le_tempo_ms(void)
{
    int bcd = IORD_ALTERA_AVALON_PIO_DATA(TEMPO_BASE);

    int segundos = (bcd >> 12) & 0xF;
    int centenas = (bcd >> 8)  & 0xF;
    int dezenas  = (bcd >> 4)  & 0xF;
    int unidades =  bcd        & 0xF;

    return segundos * 1000 + centenas * 100 + dezenas * 10 + unidades;
}

void pisca_leds(int vezes)
{
    int i;
    for (i = 0; i < vezes; i++) {
        acende_leds(0x3FF);
        usleep(150000);
        acende_leds(0);
        usleep(150000);
    }
}

/* coloca o tempo no ranking na posicao certa (menor primeiro) */
void adiciona_no_ranking(int tempo, int rodada)
{
    int posicao, i;

    posicao = 0;
    while (posicao < ranking_quantidade && ranking_tempo[posicao] <= tempo) {
        posicao++;
    }

    if (posicao >= TAMANHO_RANKING) {
        return;   /* pior que todos e o ranking ta cheio */
    }

    if (ranking_quantidade < TAMANHO_RANKING) {
        ranking_quantidade++;
    }
    /* empurra os outros pra baixo */
    for (i = ranking_quantidade - 1; i > posicao; i--) {
        ranking_tempo[i]  = ranking_tempo[i - 1];
        ranking_rodada[i] = ranking_rodada[i - 1];
    }

    ranking_tempo[posicao]  = tempo;
    ranking_rodada[posicao] = rodada;
}

void mostra_ranking(void)
{
    int i;
    printf("------ RANKING ------\n");
    for (i = 0; i < ranking_quantidade; i++) {
        printf("%d. %d.%03d s  (rodada %d)\n",
               i + 1, ranking_tempo[i] / 1000, ranking_tempo[i] % 1000, ranking_rodada[i]);
    }
    printf("---------------------\n");
}

void apaga_ranking(void)
{
    ranking_quantidade = 0;
    recorde = 0;
    printf("\nRecorde e ranking apagados!\n");
}


int main(void)
{
    int rodada = 0;
    int espera_ms, i, tempo, apertou_cedo;

    printf("\n========================================\n");
    printf("  JOGO DE REFLEXO - DE10-Lite + Nios II\n");
    printf("========================================\n");
    printf("KEY0: comecar / reagir\n");
    printf("KEY1: apagar recorde e ranking\n");

    acende_leds(0);
    zera_cronometro();
    mostra_no_display(MODO_PLAY);

    while (1) {

        /* espera apertar pra comecar */
        printf("\nAperte KEY0 para comecar.\n");
        while (!botao_jogo_apertado()) {
            if (botao_apagar_apertado()) {
                apaga_ranking();
                mostra_no_display(MODO_PLAY);
                while (botao_apagar_apertado()) {
                    usleep(10000);
                }
            }
            usleep(10000);
        }

        /* sorteia a espera: 1000 ms + (0 a 4095) */
        espera_ms = 1000 + (IORD_ALTERA_AVALON_PIO_DATA(SORTEIO_BASE) & 0xFFF);

        espera_soltar_botao();
        rodada++;

        printf("Rodada %d: espere os LEDs acenderem...\n", rodada);
        zera_cronometro();
        acende_leds(0);
        mostra_no_display(MODO_ESPERA);

        /* espera o tempo sorteado, olhando se apertou antes */
        apertou_cedo = 0;
        for (i = 0; i < espera_ms; i++) {
            usleep(1000);
            if (botao_jogo_apertado()) {
                apertou_cedo = 1;
                break;
            }
        }

        if (apertou_cedo) {
            mostra_no_display(MODO_CEDO);
            printf("CEDO DEMAIS! Voce apertou antes dos LEDs acenderem. Rodada nao vale.\n");
            espera_soltar_botao();
            continue;
        }

        /* VAI: acende os leds e arma o cronometro */
        acende_leds(0x3FF);
        comando_cronometro(ARMAR);

        /* o hardware para o tempo sozinho quando aperta,
           aqui so espera pra saber que acabou */
        while (!botao_jogo_apertado()) {
            if (le_tempo_ms() >= 9999) {
                break;   /* ninguem apertou */
            }
        }

        acende_leds(0);
        comando_cronometro(PARADO);
        mostra_no_display(MODO_TEMPO);

        tempo = le_tempo_ms();

        if (tempo >= 9999) {
            printf("Tempo esgotado! Ninguem apertou.\n");
        } else {
            printf("Seu tempo: %d.%03d s\n", tempo / 1000, tempo % 1000);

            if (recorde == 0 || tempo < recorde) {
                recorde = tempo;
                printf("*** NOVO RECORDE! ***\n");
                pisca_leds(3);
            }

            adiciona_no_ranking(tempo, rodada);
            mostra_ranking();
        }

        espera_soltar_botao();
    }

    return 0;
}
