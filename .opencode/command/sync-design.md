---
description: Đồng bộ hóa tài liệu thiết kế (.md) với các thay đổi/nâng cấp của code hoặc tạo mới tài liệu khi có code mới.
agent: build
---

Bạn là một trợ lý kỹ thuật phần mềm có nhiệm vụ giữ cho tài liệu thiết kế đồng bộ với mã nguồn thực tế.
Hãy thực hiện các bước sau:

1. Chạy lệnh git để tìm các file code mới thay đổi hoặc được thêm mới:
   - Chạy `git status` và `git diff` để xác định các file code (ví dụ: các file `.gd` của Godot, `.py` của Python, v.v.) có sự thay đổi hoặc được thêm mới gần đây.

2. Xác định các file thiết kế (`.md`) tương ứng:
   - Đối với mỗi file code có thay đổi, tìm file thiết kế `.md` liên quan trong các thư mục tài liệu như `godot_project/docs/`, `python_project/docs/`, hoặc thư mục gốc.
   - Nếu chưa có file thiết kế cho file code hoặc module mới được thêm, hãy chuẩn bị tạo mới một file thiết kế `.md` tương ứng ở vị trí thích hợp.

3. Phân tích sự khác biệt giữa code và thiết kế:
   - Đọc nội dung code mới/sửa đổi và nội dung file thiết kế hiện tại.
   - Xác định xem code có mở rộng tính năng mới, thay đổi API, cấu trúc dữ liệu hoặc luồng hoạt động mà chưa được mô tả trong tài liệu hay không.

4. Cập nhật hoặc Tạo mới tài liệu thiết kế:
   - Nếu file thiết kế tồn tại nhưng chưa cập nhật: Thực hiện chỉnh sửa file `.md` đó để mô tả chính xác sự mở rộng, nâng cấp của code hiện tại.
   - Nếu là code/module hoàn toàn mới chưa có file thiết kế: Tạo một file `.md` thiết kế mới tại thư mục thích hợp (ví dụ: `godot_project/docs/` hoặc `python_project/docs/`) mô tả kiến trúc, mục đích và cách thức hoạt động của nó.

5. Báo cáo lại danh sách các file thiết kế đã được cập nhật hoặc tạo mới cho người dùng.
