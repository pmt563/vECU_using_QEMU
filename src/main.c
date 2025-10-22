#include <stdio.h>
#include <stdbool.h>
#include <string.h>
#include <ctype.h>
#include <stdlib.h> 
#include <stdint.h>
#include "crash_detector.h"

extern void initialise_monitor_handles(void);

#define MAX_SAMPLES       500
#define FILE_PATH         "src/Shopping-cart-impact_10kmph_Side-curves.txt"
#define LINE_BUFFER_SIZE  256

typedef struct {
    float timestamp_ms;
    float acceleration;
} SensorSample;

static SensorSample g_sensor_data[MAX_SAMPLES];
static int g_sample_count = 0;

static inline bool is_skippable_line(const char *s) {
    if (!s) return true;
    while (*s && isspace((unsigned char)*s)) s++;
    return (*s=='\0' || *s=='#' || *s=='$');
}

static void short_delay(void) {
    for (volatile uint32_t i = 0; i < 200000; ++i) {}
}

static void _hold_forever(int code){
    printf("[trap-exit] program requested exit(%d) — holding...\n", code);
    while (1) {}
}
void __wrap__exit(int status){ _hold_forever(status); }
void __wrap_exit (int status){ _hold_forever(status); }

static int load_sensor_data(void) {
    FILE *fp = fopen(FILE_PATH, "r");
    if (!fp) { perror("[load] fopen"); return -1; }

    char line[LINE_BUFFER_SIZE];
    g_sample_count = 0;

    while (fgets(line, sizeof(line), fp) && g_sample_count < MAX_SAMPLES) {
        if (is_skippable_line(line)) continue;

        char *p = line;
        char *endp;

        float t = strtof(p, &endp);
        if (endp == p) continue;       
        p = endp;

        float a = strtof(p, &endp);
        if (endp == p) continue;

        g_sensor_data[g_sample_count].timestamp_ms = t;
        g_sensor_data[g_sample_count].acceleration = a;
        g_sample_count++;

        if ((g_sample_count % 50) == 0) {
            printf("[load] parsed %d lines...\n", g_sample_count);
        }
    }

    fclose(fp);
    printf("[load] Read %d samples\n", g_sample_count);
    return (g_sample_count > 0) ? 0 : -1;
}

int main(void) {
    initialise_monitor_handles();
    setvbuf(stdout, NULL, _IONBF, 0);
    setvbuf(stderr, NULL, _IONBF, 0);

    printf("[main] hello from semihosting\n");
    printf("[main] M1: opening %s\n", FILE_PATH);

    FILE *f = fopen(FILE_PATH, "r");
    if (!f) { perror("[main] fopen"); while(1){ putchar('!'); short_delay(); } }
    fclose(f);
    printf("[main] M3: file opened OK\n");

    printf("[main] M3.5: before load_sensor_data\n");
    int rc = load_sensor_data();
    printf("[main] M4: load_sensor_data rc=%d\n", rc);
    if (rc != 0) { printf("[main] load failed\n"); while(1){ putchar('!'); short_delay(); } }

    crash_detector_init();
    printf("[main] M5: processing %d samples...\n", g_sample_count);

    bool detected = false;
    for (int i = 0; i < g_sample_count; ++i) {
        bool crash = crash_detector_process_sample(g_sensor_data[i].acceleration);
        if (crash) {
            printf("[main] !!! CRASH at %.2f ms !!!\n", g_sensor_data[i].timestamp_ms);
            detected = true;
            break;
        }
    }
    if (!detected) printf("[main] No crash detected.\n");

    printf("[main] M6: entering keep-alive loop\n");
}
