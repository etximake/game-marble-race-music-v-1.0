# Music Ball Video Engine - Design Docs

## Muc tieu

Du an nay tao video dang music game/simulation cho YouTube Shorts/TikTok. Mode dau tien la music bouncing ball (`circle_bounce`):

- Python project nhap bai nhac, cat thanh cac note clip nho, tao `video_config.json`.
- Godot project doc `video_config.json`, chon `game_mode`, chay active mode, phat note theo trigger, ve visual, render video raw.

## Workflow MVP

```text
input song
  -> Python project
  -> generated/jobs/job_001/note_clips/
  -> generated/jobs/job_001/video_config.json
  -> User mo Godot
  -> Godot doc video_config.json
  -> Godot render video raw
```

## Ranh gioi trach nhiem

Python lam:

1. Nhap bai nhac.
2. Cat bai nhac thanh `note_0001.wav`, `note_0002.wav`, ...
3. Tao `video_config.json`.

Godot lam:

1. Doc `video_config.json`.
2. Chon active mode theo `game_mode`.
3. Tao scene/visual theo config va mode.
4. Khi active mode emit note trigger thi phat note tiep theo.
5. Render video raw.

## File trung tam

Hai file trung tam cua moi job la:

```text
generated/jobs/job_001/video_config.json
generated/jobs/job_001/gameplay_config.json
```

`video_config.json` chua du lieu audio/job. `gameplay_config.json` la snapshot gameplay do Python tao tu shared preset. Moi thay doi giua Python va Godot phai thong qua cap file nay.

## Tai lieu kien truc

- `MVP_IMPLEMENTATION_CHECKLIST.md`: thu tu trien khai MVP theo Clean Architecture.
- `shared/README.md`: tong quan shared contract.
- `shared/VALIDATION_RULES.md`: schema validation va semantic validation cho `video_config.json`.
- `python_project/docs/06_Clean_Architecture.md`: kien truc code Python project.
- `godot_project/docs/07_Clean_Architecture.md`: kien truc code Godot project.

## Hướng dẫn thiết lập khi chạy ở máy tính khác (Setup & Installation Guide)

Do cấu hình `.gitignore` không đẩy các file môi trường ảo (`.env`), cache của Godot (`.godot/`), tệp video kết quả (`.mp4`), và các thư mục dữ liệu bài hát đã xử lý (`generated/`) lên kho lưu trữ, hãy làm theo hướng dẫn dưới đây để thiết lập dự án trên máy tính mới:

### 1. Yêu cầu hệ thống và phần mềm cần cài đặt trước (Prerequisites)
*   **Python 3.10+**: Dùng để chạy pipeline xử lý âm thanh và sinh cấu hình.
*   **Godot Engine v4.5 Stable** (bản Standard hoặc Console): Dùng để render và chạy mô phỏng vật lý.
*   **FFmpeg**: Cực kỳ quan trọng, bắt buộc phải cài đặt trên hệ thống và thêm vào biến môi trường `PATH`. Thư viện `pydub` của Python yêu cầu FFmpeg để giải mã (decode) và cắt (slice) các file âm thanh (`.mp3`, `.wav`).

### 2. Các bước cài đặt chi tiết

#### Bước 1: Thiết lập môi trường ảo Python & Cài đặt thư viện
Chạy các lệnh sau từ thư mục gốc của dự án:
```bash
# Tạo môi trường ảo tại thư mục python_project/.env
python -m venv python_project/.env

# Kích hoạt môi trường ảo:
# - Trên Windows (PowerShell):
.\python_project\.env\Scripts\Activate.ps1
# - Trên Windows (Command Prompt):
.\python_project\.env\Scripts\activate.bat
# - Trên macOS / Linux:
source python_project/.env/bin/activate

# Cài đặt các thư viện cần thiết
pip install pydub jsonschema pytest
```

#### Bước 2: Cài đặt và cấu hình FFmpeg
*   **Windows**:
    1. Tải bản build FFmpeg mới nhất (từ gyan.dev hoặc nguồn uy tín).
    2. Giải nén vào một thư mục (ví dụ `C:\ffmpeg`).
    3. Thêm đường dẫn tới thư mục `bin` (ví dụ `C:\ffmpeg\bin`) vào biến môi trường `PATH` của User hoặc System.
    4. Mở terminal mới và kiểm tra bằng lệnh: `ffmpeg -version`.
*   **macOS**: Cài đặt qua Homebrew: `brew install ffmpeg`
*   **Linux**: Cài đặt qua package manager: `sudo apt update && sudo apt install ffmpeg`

#### Bước 3: Chuẩn bị nhạc nguồn và Sinh dữ liệu Job (Generate Job Data)
Trước khi chạy mô phỏng trên Godot, bạn cần chạy script Python để sinh ra cấu hình và các file nhạc cắt nhỏ (vì thư mục `generated/` không có sẵn trên Git):
1. Đặt file nhạc nguồn (ví dụ: `Cupid - Twin Ver (mp3cut.net).mp3`) vào thư mục `python_project/source/`.
2. Kiểm tra và chỉnh sửa cấu hình job trong `python_project/job_profile.json` (đường dẫn nhạc nguồn `input_path`, thời lượng `target_duration_seconds`, v.v.).
3. Chạy script tạo dữ liệu:
   ```bash
   python python_project/main.py --profile python_project/job_profile.json
   ```
   Sau khi hoàn tất thành công, thư mục `generated/jobs/job_002/` (hoặc tên job tương ứng trong profile) sẽ được tạo ra cùng với file `video_config.json`, `gameplay_config.json` và thư mục `note_clips/` chứa các nốt nhạc được cắt nhỏ.

#### Bước 4: Khởi động và chạy dự án trong Godot
*   **Sử dụng Godot Editor**: Mở Godot Editor 4.5, chọn **Import** và trỏ đến thư mục gốc của dự án này. Đảm bảo cấu hình đường dẫn config mặc định trong `scripts/presentation/Main.gd` (biến `config_path`) đang trỏ đúng tới job mong muốn để chạy debug nhanh bằng Editor.
*   **Chạy chế độ Render Headless (Dòng lệnh)**:
    ```powershell
    # Ví dụ trên Windows chạy bằng Godot Console CLI:
    & "đường_dẫn_đến_godot\Godot_v4.5-stable_win64_console.exe" --headless --path "D:\đường_dẫn_dự_án" -- --config "res://generated/jobs/job_002/video_config.json"
    ```

