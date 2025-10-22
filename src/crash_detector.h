#ifndef CRASH_DETECTOR_H
#define CRASH_DETECTOR_H

#include <stdbool.h>

#define SMA_WINDOW_SIZE 10
#define DELTA_WINDOW    5 
#define CRASH_THRESHOLD 0.001 
#define DELTA_THRESHOLD 0.0005 

void crash_detector_init(void);

bool crash_detector_process_sample(double new_value);

#endif 