#ifndef CRASH_DETECTOR_H
#define CRASH_DETECTOR_H

#include <stdbool.h>

// Cấu hình thuật toán
#define SMA_WINDOW_SIZE 10 // Kích thước cửa sổ trung bình trượt
#define DELTA_WINDOW    5  // Khoảng cách để tính delta
#define CRASH_THRESHOLD 0.001 // Ngưỡng gia tốc (mm/ms^2)
#define DELTA_THRESHOLD 0.0005 // Ngưỡng thay đổi gia tốc



// Khởi tạo module phát hiện va chạm
void crash_detector_init(void);

// Xử lý một mẫu gia tốc mới và trả về true nếu phát hiện va chạm
bool crash_detector_process_sample(double new_value);

#endif // CRASH_DETECTOR_H