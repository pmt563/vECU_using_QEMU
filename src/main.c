#include <stdio.h>
#include <stdbool.h>
#include <string.h>
#include <ctype.h>
#include "crash_detector.h"

// rdimon semihosting (stdio)
extern void initialise_monitor_handles(void);

#define MAX_SAMPLES       500
#define FILE_PATH         "data/Shopping-cart-impact_10kmph_Side-curves.txt"
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

static int load_sensor_data(void) {
    initialise_monitor_handles();

    FILE *fp = fopen(FILE_PATH, "r");
    if (!fp) { printf("Error: open '%s' failed\n", FILE_PATH); return -1; }

    char line_buffer[LINE_BUFFER_SIZE];
    g_sample_count = 0;

    while (fgets(line_buffer, sizeof(line_buffer), fp) &&
           g_sample_count < MAX_SAMPLES) {
        if (is_skippable_line(line_buffer)) continue;

        float t=0.0f, a=0.0f;
        if (sscanf(line_buffer, "%f %f", &t, &a) == 2) {
            g_sensor_data[g_sample_count].timestamp_ms = t;
            g_sensor_data[g_sample_count].acceleration = a;
            g_sample_count++;
        }
    }
    fclose(fp);
    printf("Read %d samples\n", g_sample_count);
    return (g_sample_count>0)? 0 : -1;
}

int main(void) {
    if (load_sensor_data() != 0) {
        printf("Failed to load sensor data\n");
        while (1) {}
    }

    crash_detector_init();
    printf("Processing...\n");

    for (int i = 0; i < g_sample_count; ++i) {
        bool crash = crash_detector_process_sample(g_sensor_data[i].acceleration);
        if (crash) {
            printf("!!! CRASH at %.2f ms !!!\n", g_sensor_data[i].timestamp_ms);
            break;
        }
    }
    printf("Done.\n");
    while (1) {}
}
