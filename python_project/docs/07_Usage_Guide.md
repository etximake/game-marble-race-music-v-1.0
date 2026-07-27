# 07 - Hướng dẫn sử dụng Python Project

Tài liệu này hướng dẫn cách chạy và tùy chỉnh chương trình xử lý âm thanh và sinh file cấu hình cho dự án Godot.

## 1. Yêu cầu hệ thống và môi trường

Dự án sử dụng Python 3.10.x. Các thư viện phụ thuộc chính bao gồm:
*   `jsonschema`: Để validate file cấu hình đầu ra `video_config.json`.
*   `pydub`: Cắt và xử lý âm thanh.
*   `pytest`: Để chạy các bài test.

Môi trường ảo `.env` đã được thiết lập sẵn tại thư mục gốc của dự án.

## 2. Cách chạy chương trình

Chương trình được thiết kế chạy trực tiếp với các cấu hình cứng được khai báo bên trong mã nguồn để đơn giản hóa thao tác.

Thực hiện chạy lệnh sau từ thư mục gốc của dự án:

```bash
# Trên Windows PowerShell
& "D:\HOANG HA\Tai lieu game godot\game-marble-race-music-v-1.0\.env\Scripts\python.exe" python_project/main.py
```

## 3. Cách tùy chỉnh tham số

Mở file `python_project/main.py` và sửa trực tiếp các biến cấu hình trong hàm `main()`:

```python
def main():
    # Điều chỉnh trực tiếp các tham số ở đây:
    input_path = "source/DIA DELÍCIA (Slowed) [AsFdNBMCwPM].mp3"  # Đường dẫn đến file nhạc đầu vào (.wav hoặc .mp3)
    job_id = "job_001"                      # ID của Job để phân biệt thư mục xuất kết quả
    slice_mode_str = "fixed_interval"       # Chế độ cắt: "fixed_interval" hoặc "manual_markers"
    interval = 0.2                          # Khoảng thời gian cắt mỗi nốt (giây) cho chế độ fixed_interval
    markers = []                            # Danh sách mốc thời gian cắt cho chế độ manual_markers (ví dụ: [0.5, 1.2, 2.0])
    max_notes = 400                         # Số lượng nốt cắt tối đa để tránh lỗi bộ nhớ/âm thanh
    fade_in_ms = 3                          # Thời gian fade-in (mili giây) để tránh tiếng click/pop
    fade_out_ms = 3                         # Thời gian fade-out (mili giây) để tránh tiếng click/pop
```

## 4. Cấu trúc kết quả đầu ra

Sau khi chạy thành công, kết quả sẽ được tạo tại thư mục:
`generated/jobs/{job_id}/`

Cấu trúc gồm:
*   `video_config.json`: File cấu hình chính chứa thông tin video, âm thanh, gameplay và các phase tiến trình. Godot sẽ trực tiếp đọc file này.
*   `source_audio.wav`: File nhạc gốc đã được chuẩn hóa về định dạng Mono 44100Hz.
*   `metadata.json`: Lưu trữ thông tin phụ về quá trình xử lý (số lượng nốt, thời gian chạy).
*   `note_clips/`: Thư mục chứa các file nốt nhạc nhỏ (`note_0001.wav`, `note_0002.wav`,...) đã được cắt kèm hiệu ứng fade-in/fade-out 3ms.

## 5. Chạy kiểm tra Unit Test

Để đảm bảo các quy tắc xử lý nghiệp vụ hoạt động ổn định và chính xác, chạy lệnh test sau:

```bash
& "D:\HOANG HA\Tai lieu game godot\game-marble-race-music-v-1.0\.env\Scripts\python.exe" -m pytest python_project/
```
