#include "crash_detector.h"
#include <stddef.h>

#define INTEGRATION_WINDOW 200
#define SAMPLE_TIME 0.01f
#define VELOCITY_THRESHOLD 0.0005f

static float velocity_integral = 0.0f;
static int sample_count = 0;

void crash_detector_init(void) {
    velocity_integral = 0.0f;
    sample_count = 0;
}

bool crash_detector_process_sample(double acceleration) {
    velocity_integral += (float)acceleration * SAMPLE_TIME;
    sample_count++;
    
    if (sample_count >= INTEGRATION_WINDOW) {
        if (velocity_integral > VELOCITY_THRESHOLD) {
            return true; 
        }
        
        velocity_integral = 0.0f;
        sample_count = 0;
    }
    
    return false;
}