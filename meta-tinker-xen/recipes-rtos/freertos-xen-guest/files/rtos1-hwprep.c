// SPDX-License-Identifier: MIT
/*
 * rtos1-hwprep: get the SPI TFT hardware ready for the FreeRTOS guest.
 *
 * rtos1 drives an ILI9341 panel itself through the SPI2 controller and
 * GPIO5 (passed through with iomem in rtos1.cfg), but the clock unit and
 * the pin mux (GRF) are shared by the whole SoC and stay with dom0. This
 * runs in dom0 before "xl create rtos1":
 *   - ungates sclk_spi2 and pclk_spi2
 *   - sets sclk_spi2 to GPLL / n, at most 50 MHz (the guest divides by 2)
 *   - muxes header pins 23/19/21/24 to SPI2 CLK/TXD/RXD/CSN0 and
 *     pins 18 (GPIO5_B3, RESET) and 22 (GPIO5_C3, DC) to GPIO
 * Every register written uses the RK3288 write-mask (upper 16 bits), so
 * only these bits change and nothing else in dom0 is disturbed.
 */
#include <fcntl.h>
#include <stdint.h>
#include <stdio.h>
#include <sys/mman.h>
#include <unistd.h>

#define CRU_BASE        0xff760000UL
#define GRF_BASE        0xff770000UL

#define CRU_GPLL_CON0   0x030
#define CRU_GPLL_CON1   0x034
#define CRU_CLKSEL39    0x0fc   /* sclk_spi2: bit 7 cpll/gpll, bits 6:0 divider - 1 */
#define CRU_CLKGATE2    0x168   /* bit 11 sclk_spi2 */
#define CRU_CLKGATE6    0x178   /* bit 6 pclk_spi2 */

#define GRF_GPIO5B_IOMUX 0x050
#define GRF_GPIO5C_IOMUX 0x054
#define GRF_GPIO8A_IOMUX 0x080
#define GRF_GPIO8B_IOMUX 0x084

#define SPI_MAX_HZ      50000000ULL
#define WM( mask, val ) ( ( ( uint32_t ) ( mask ) << 16 ) | ( val ) )

static volatile uint32_t * map( int fd, unsigned long base )
{
    void * p = mmap( NULL, 0x1000, PROT_READ | PROT_WRITE, MAP_SHARED, fd, base );

    return p == MAP_FAILED ? NULL : p;
}

int main( void )
{
    volatile uint32_t * cru, * grf;
    uint32_t con0, con1, nr, no, nf, div;
    uint64_t gpll;
    int fd = open( "/dev/mem", O_RDWR | O_SYNC );

    if( fd < 0 )
    {
        perror( "rtos1-hwprep: /dev/mem" );
        return 1;
    }

    cru = map( fd, CRU_BASE );
    grf = map( fd, GRF_BASE );

    if( !cru || !grf )
    {
        perror( "rtos1-hwprep: mmap" );
        return 1;
    }

    /* clocks on (gate bit 0 = running) */
    cru[ CRU_CLKGATE2 / 4 ] = WM( 1 << 11, 0 );
    cru[ CRU_CLKGATE6 / 4 ] = WM( 1 << 6, 0 );

    /* GPLL = 24 MHz * NF / NR / NO (RK3066-type PLL) */
    con0 = cru[ CRU_GPLL_CON0 / 4 ];
    con1 = cru[ CRU_GPLL_CON1 / 4 ];
    nr = ( ( con0 >> 8 ) & 0x3f ) + 1;
    no = ( con0 & 0xf ) + 1;
    nf = ( con1 & 0x1fff ) + 1;
    gpll = 24000000ULL * nf / nr / no;
    div = ( uint32_t ) ( ( gpll + SPI_MAX_HZ - 1 ) / SPI_MAX_HZ );
    if( div < 1 )
        div = 1;
    if( div > 128 )
        div = 128;
    cru[ CRU_CLKSEL39 / 4 ] = WM( 0xff, ( 1 << 7 ) | ( div - 1 ) );

    /* pins: 2 bits per pin, 0 = GPIO, 1 = SPI2 */
    grf[ GRF_GPIO5B_IOMUX / 4 ] = WM( 3 << 6, 0 );              /* B3 RESET */
    grf[ GRF_GPIO5C_IOMUX / 4 ] = WM( 3 << 6, 0 );              /* C3 DC */
    grf[ GRF_GPIO8A_IOMUX / 4 ] = WM( 0xf << 12, 5 << 12 );     /* A6 CLK, A7 CSN0 */
    grf[ GRF_GPIO8B_IOMUX / 4 ] = WM( 0xf, 5 );                 /* B0 RXD, B1 TXD */

    printf( "rtos1-hwprep: SPI2 clock %llu Hz (GPLL %llu Hz / %u), "
            "TFT pins muxed (SPI2 + GPIO5 B3/C3)\n",
            ( unsigned long long ) ( gpll / div ), ( unsigned long long ) gpll, div );
    return 0;
}
