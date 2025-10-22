// #include "crash_detector.h"
// #include <stddef.h>

// static double sma_buffer[64];
// static int sma_index = 0;
// static double sma_sum = 0.0;
// static bool buffer_filled = false;

// void crash_detector_init(void) {
//     for (int i = 0; i < SMA_WINDOW_SIZE; ++i) {
//         sma_buffer[i] = 0.0;
//     }
//     sma_index = 0;
//     sma_sum = 0.0;
//     buffer_filled = false;
// }

// bool crash_detector_process_sample(double new_value) {
//     sma_sum -= sma_buffer[sma_index];
//     sma_buffer[sma_index] = new_value;
//     sma_sum += new_value;

//     int current_index = sma_index;
//     sma_index = (sma_index + 1) % SMA_WINDOW_SIZE;

//     if (!buffer_filled && sma_index == 0) {
//         buffer_filled = true;
//     }

//     if (!buffer_filled) {
//         return false;
//     }

//     double current_sma = sma_sum / SMA_WINDOW_SIZE;

//     int past_index = (current_index - DELTA_WINDOW + SMA_WINDOW_SIZE) % SMA_WINDOW_SIZE;
//     double past_value_in_buffer = sma_buffer[past_index];
    
//     if (current_sma > CRASH_THRESHOLD) {
//         double delta = current_sma - past_value_in_buffer;
//         if (delta > DELTA_THRESHOLD) {
//             return true; 
//         }
//     }

//     return false;
// }