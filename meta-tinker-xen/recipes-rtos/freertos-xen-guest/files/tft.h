/*
 * ILI9341 320x240 SPI TFT driven directly by the FreeRTOS guest.
 *
 * Xen passes two RK3288 pages through to rtos1 (iomem in rtos1.cfg):
 *   SPI2  0xff130000  header pins 23 SCLK, 19 MOSI, 21 MISO, 24 CS0
 *   GPIO5 0xff7c0000  header pin 22 DC (GPIO5_C3), pin 18 RESET (GPIO5_B3)
 * dom0 switches the SPI2 clocks on and sets the pin mux before the guest
 * starts (rtos1-hwprep, run by rtos1-start).
 */
#ifndef RTOS_TFT_H
#define RTOS_TFT_H

#include <stdint.h>

#define TFT_W   320
#define TFT_H   240

/* RGB565 */
#define TFT_BLACK   0x0000
#define TFT_WHITE   0xffff
#define TFT_RED     0xf800
#define TFT_GREEN   0x07e0
#define TFT_BLUE    0x001f
#define TFT_YELLOW  0xffe0
#define TFT_ORANGE  0xfd20
#define TFT_GREY    0x8410
#define TFT_DKGREY  0x2104
#define TFT_NAVY    0x0010

void tft_init( void );      /* resets and configures the panel; uses vTaskDelay */
void tft_fill( uint32_t x, uint32_t y, uint32_t w, uint32_t h, uint16_t color );
/* 5x7 font in a 6x8 cell, scaled by `scale`; returns the x after the text */
uint32_t tft_text( uint32_t x, uint32_t y, const char * s, uint32_t scale,
                   uint16_t fg, uint16_t bg );

#endif
