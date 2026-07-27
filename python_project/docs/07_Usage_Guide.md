# 07 - Hướng dẫn sử dụng Python Project

Tài liệu này hướng dẫn cách chạy và tùy chỉnh chương trình xử lý âm thanh và sinh file cấu hình cho dự án Godot.

## 1. Yêu cầu hệ thống và môi trường

Dự án sử dụng Python 3.10.x. Các thư viện phụ thuộc chính bao gồm:
*   `jsonschema`: Để validate file cấu hình đầu ra `video_config.json`.
*   `pydub`: Cắt và xử lý âm thanh.
*   `pytest`: Để chạy các bài test.

Môi trường ảo `.env` đã được thiết lập sẵn tại thư mục gốc của dự án.

## 2. Cách chạy chương trình

Cấu hình tạo job nằm trong một profile JSON. Profile mặc định là
`python_project/job_profile.json`; có thể chọn profile khác bằng `--profile`.

Thực hiện chạy lệnh sau từ thư mục gốc của dự án:

```bash
# Trên Windows PowerShell
& "D:\HOANG HA\Tai lieu game godot\game-marble-race-music-v-1.0\.env\Scripts\python.exe" python_project/main.py

# Chọn profile job khác
& ".env\Scripts\python.exe" python_project/main.py --profile job_profile_002.json
```

## 3. Cách tùy chỉnh tham số

Chỉnh `python_project/job_profile.json` thay vì sửa mã nguồn:

```python
{
  "job_id": "job_002",
  "gameplay_template_path": "../shared/gameplay_template.json",
  "input_path": "source/another_song.mp3",
  "target_duration_seconds": 22.0,
  "slice_mode": "fixed_interval",
  "slice_interval_seconds": 0.4,
  "max_note_count": 400,
  "fade_in_ms": 3,
  "fade_out_ms": 3
}
```

## 4. Cấu trúc kết quả đầu ra

Sau khi chạy thành công, kết quả sẽ được tạo tại thư mục:
`generated/jobs/{job_id}/`

Cấu trúc gồm:
*   `video_config.json`: Job Music JSON chứa duration, output name, âm thanh, text và assets riêng của job. Godot merge file này với `gameplay_config.json` cùng thư mục.
*   `gameplay_config.json`: Snapshot gameplay được Python copy từ template tại thời điểm tạo job. Chứa mode, gameplay, visual, quiz, timeline và phases.
*   `source_audio.wav`: File nhạc gốc đã được chuẩn hóa về định dạng Mono 44100Hz.
*   `metadata.json`: Lưu trữ thông tin phụ về quá trình xử lý (số lượng nốt, thời gian chạy).
*   `note_clips/`: Thư mục chứa các file nốt nhạc nhỏ (`note_0001.wav`, `note_0002.wav`,...) đã được cắt kèm hiệu ứng fade-in/fade-out 3ms.

Godot không đọc trực tiếp `shared/gameplay_template.json` khi chạy job. File shared chỉ là preset đầu vào để Python tạo `gameplay_config.json`.

## 5. Chạy kiểm tra Unit Test

Để đảm bảo các quy tắc xử lý nghiệp vụ hoạt động ổn định và chính xác, chạy lệnh test sau:

```bash
& "D:\HOANG HA\Tai lieu game godot\game-marble-race-music-v-1.0\.env\Scripts\python.exe" -m pytest python_project/
```
