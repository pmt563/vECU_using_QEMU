Chúng ta định nghĩa địa chỉ thanh ghi dữ liệu của UART0 và tạo các hàm để gửi ký tự, chuỗi và số nguyên. Việc ghi vào địa chỉ bộ nhớ này sẽ gửi dữ liệu đến cổng nối tiếp được mô phỏng.  

Một hàm itoa đơn giản (uart_putint) được triển khai để chuyển đổi số nguyên thành chuỗi có thể in được, một yêu cầu phổ biến trong lập trình bare-metal.   