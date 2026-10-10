# Payment Screenshot Expense Tracker (VKU Expense QR)

[![Flutter](https://img.shields.io/badge/Flutter-3.47.5-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.13.4-0175C2?logo=dart)](https://dart.dev)
[![Material 3](https://img.shields.io/badge/Material_3-VKU_Navy-0D3268)](https://m3.material.io)
[![Test](https://img.shields.io/badge/Tests-33%2F33%20Passed-brightgreen)](test/)
[![Release APK](https://img.shields.io/badge/Release_APK-v1.0.0-blue?logo=android)](https://github.com/nt-hzy3n/mobile_mini_project3/releases/tag/v1.0.0)
[![Demo Video](https://img.shields.io/badge/Demo_Video-MP4-E50914?logo=googlechrome)](https://github.com/nt-hzy3n/mobile_mini_project3/releases/download/v1.0.0/demo_video.mp4)

> **Course:** Cross-Platform Mobile App Development (VKU)  
> **Student:** Nguyen Thi Huyen (Student ID: 23IT110)  
> **GitHub Repository:** [https://github.com/nt-hzy3n/mobile_mini_project3](https://github.com/nt-hzy3n/mobile_mini_project3)  
> **Release APK Download:** [Download APK v1.0.0](https://github.com/nt-hzy3n/mobile_mini_project3/releases/download/v1.0.0/vku_expense_qr.apk) (hoặc xem file `vku_expense_qr.apk` tại thư mục gốc)  
> **Demo Walkthrough Video:** [Xem / Tải Video Demo](https://github.com/nt-hzy3n/mobile_mini_project3/releases/download/v1.0.0/demo_video.mp4) (hoặc xem file `docs/demo_video.mp4`)  
> **Project Scope:** Mini-Project 3 (Week 8)

---

## Overview
**Payment Screenshot Expense Tracker** (VKU Expense QR) là ứng dụng quản lý chi tiêu cá nhân thông minh trên Flutter. Thay vì nhập liệu thủ công từng khoản chi, người dùng chỉ cần chụp ảnh hoặc chọn ảnh chụp màn hình xác nhận giao dịch chuyển khoản ngân hàng (VietQR, NAPAS247, MBBank, Vietcombank,...). Ứng dụng tự động giải mã mã QR (nếu có) và kết hợp với **Google ML Kit Text Recognition on-device** để trích xuất đầy đủ số tiền, người nhận, ngân hàng, số tài khoản (được che mờ bảo mật), ngày giờ và nội dung giao dịch.

Dữ liệu được bảo vệ an toàn bằng **Firebase Authentication** và lưu trữ đám mây phân quyền theo từng tài khoản trên **Cloud Firestore** và **Firebase Storage**, hỗ trợ đồng bộ thời gian thực trên nhiều thiết bị.

---

## Problem
* Người dùng trẻ và sinh viên thực hiện chuyển khoản trực tuyến hàng ngày qua app ngân hàng nhưng thường ngại ghi chép vì việc gõ từng khoản tiền tốn thời gian.
* Nhiều biên lai điện tử là ảnh chụp màn hình không còn mã QR, hoặc chỉ có mã QR tĩnh (không chứa số tiền).
* Các giải pháp cloud OCR tiềm ẩn nguy cơ lộ lọt thông tin tài chính cá nhân nhạy cảm và yêu cầu kết nối mạng.
* Dữ liệu cục bộ không thể đồng bộ khi người dùng đổi điện thoại hoặc sử dụng đồng thời máy tính bảng và điện thoại.

---

## Solution
* **Firebase Authentication:** Xác thực tài khoản bằng Email/Password, quản lý phiên làm việc bền vững, hỗ trợ đăng nhập, đăng ký và quên mật khẩu bằng tiếng Việt.
* **Quy trình QR-First + OCR-Fallback/Hybrid:** Ưu tiên giải mã VietQR/EMVCo khi có QR hợp lệ. Nếu mã QR thiếu thông tin hoặc ảnh không có QR, hệ thống tự động kích hoạt **Google ML Kit OCR chạy 100% On-Device** (hoàn toàn ngoại tuyến).
* **Regex & Heuristic Parser:** Tự động chuẩn hóa các định dạng tiền tệ Việt Nam (`1,000,000 VND`, `1.000.000 đ`), nhận diện ngân hàng (`MBBank`, `VCB`, `TCB`,...), trích xuất người nhận và ngày giờ giao dịch.
* **Review & Verification Screen:** Màn hình xác nhận bắt buộc trước khi lưu vào Firebase, cho phép người dùng kiểm tra và chỉnh sửa mọi trường thông tin.
* **User-Scoped Cloud Storage & Firestore:** Mỗi người dùng sở hữu nhánh dữ liệu độc lập:
  - Firestore: `users/{uid}/expenses/{expenseId}`
  - Storage: `users/{uid}/expenses/{expenseId}/payment_image.jpg`
* **Bảo vệ quyền riêng tư & Phân quyền:** 100% dữ liệu OCR được xử lý cục bộ trên thiết bị, số tài khoản hiển thị dạng `********2002`, ngăn chặn người dùng truy cập dữ liệu của người dùng khác theo Firebase Security Rules.

---

## Main Workflow
```
KHỞI ĐỘNG ỨNG DỤNG
      │
      ▼
XÁC THỰC FIREBASE AUTH (authStateChanges)
 ┌────┴────────────────────────┐
 │ Đã đăng nhập?               │
 └────┬────────────────────────┘
      │
 ┌────┴───────────────┐
 │                    │
Có                   Chưa
 │                    │
 │                    ▼
 │              MÀN HÌNH ĐĂNG NHẬP / ĐĂNG KÝ (/login, /register)
 │                    │ (Đăng nhập thành công)
 └────►───────────────┘
      │
      ▼
HOME DASHBOARD (Dữ liệu theo UID người dùng)
      │
      ▼
THÊM CHI TIÊU (Quét camera / Chọn ảnh chuyển khoản)
      │
      ▼
NHẬN DIỆN MÃ QR (QR DETECTION)
 ┌────┴────────────────────────┐
 │ QR có dữ liệu đầy đủ?       │
 └────┬────────────────────────┘
      │
 ┌────┴───────────────┐
 │                    │
Có                   Không / Thiếu thông tin
 │                    │
 ▼                    ▼
QR PARSER       GOOGLE ML KIT OCR (On-Device)
 │                    │
 │                    ▼
 │              HEURISTIC REGEX PARSER
 │                    │
 └────┬───────────────┘
      │
      ▼
HYBRID DATA MERGE (QR > OCR > Manual)
      │
      ▼
KIỂM TRA GIAO DỊCH (Review & Verify Screen)
      │
      ▼
XÁC THỰC BIỂU MẪU (Form Validation)
      │
      ▼
┌─────────────────────────────┴─────────────────────────────┐
▼                                                           ▼
FIREBASE STORAGE (Tải ảnh biên lai)          CLOUD FIRESTORE (Lưu document chi tiêu)
users/{uid}/expenses/{id}/payment_image.jpg   users/{uid}/expenses/{expenseId}
└─────────────────────────────┬─────────────────────────────┘
                              │
                              ▼
RIVERPOD STATE MANAGEMENT (Realtime Stream theo UID)
                              │
                              ▼
CẬP NHẬT TỔNG QUAN (Dashboard) & THỐNG KÊ (CustomPainter Charts)
                              │
                              ▼
ĐỒNG BỘ ĐA THIẾT BỊ REALTIME (Multi-Device Synchronization)
```

---

## QR + OCR Processing
Ứng dụng áp dụng bảng quy tắc trích xuất Heuristic:

| Trường thông tin | Phương pháp trích xuất | Ví dụ thực tế hỗ trợ |
|---|---|---|
| **Số tiền (Amount)** | Regex tiền tệ VNĐ + Context ưu tiên (`SỐ TIỀN`, `CHUYỂN TIỀN`, `TOTAL`) | `1,000,000 VND`, `1.000.000 đ`, `1000000` |
| **Ngày giao dịch (Date)** | Date regex (`DD/MM/YYYY`, `DD-MM-YYYY`, `DD.MM.YYYY`) | `28/09/2026` |
| **Thời gian (Time)** | Time regex (`HH:mm`, `HH:mm:ss`) | `17:53` (từ `17:53 - 28/09/2026`) |
| **Người nhận (Recipient)** | Lọc nhãn Người nhận / Regex tên in hoa loại trừ tiêu đề hệ thống | `NGUYEN THI THUONG` |
| **Ngân hàng (Bank)** | Heuristic nhận diện danh mục ngân hàng Việt Nam | `MBBank (MB)`, `Vietcombank`, `Techcombank` |
| **Số tài khoản (Account)** | Regex số 8 - 18 chữ số kèm từ khóa STK / Số tài khoản | `41212106082002` (Mã hóa hiển thị: `********2002`) |
| **Nội dung (Description)** | Regex dòng nội dung / Lời nhắn chuyển khoản | `NGUYEN THI HUYEN chuyen tien` |

---

## Features
1. **Firebase Authentication:** Đăng nhập, đăng ký, quên mật khẩu, tự động duy trì trạng thái đăng nhập, đăng xuất với hộp thoại xác nhận.
2. **Quét trực tiếp qua Camera & Thư viện ảnh:** Khung ngắm laser động, nút bật flash, đổi camera, chọn ảnh chụp màn hình hoặc chụp ảnh trực tiếp.
3. **VietQR / EMVCo TLV Parser:** Giải mã Tag 38 (NAPAS247), Tag 54 (số tiền), Tag 59 (người thụ hưởng), Tag 62.08 (nội dung).
4. **Google ML Kit OCR On-Device:** Nhận diện ký tự quang học tốc độ cao, không cần internet.
5. **Màn hình Kiểm tra giao dịch (Review Screen):** Cho phép sửa toàn bộ trường, xác thực form chặt chẽ (`FormState`, `FocusNode`, `TextEditingController`).
6. **Cơ sở dữ liệu Firebase Cloud Firestore & Storage:** Đầy đủ CRUD, Realtime Streams, lưu trữ hình ảnh trên Firebase Storage phân lập theo `users/{uid}`.
7. **Biểu đồ CustomPainter thuần túy:**
   - Donut Chart động với `Canvas.drawArc` phân bổ 6 danh mục.
   - Weekly Bar Chart động với `Canvas.drawRRect` thể hiện chi tiêu 7 ngày (T2 - CN) có tooltip tương tác khi chạm.
8. **Material 3 & Dark Theme:** Màu chủ đạo VKU Navy (`#0D3268`), chuyển đổi mượt mà giữa Sáng/Tối qua `SharedPreferences`.

---

## Demo Video & Screenshots

### 🎬 Video Demo (Walkthrough)
* **Xem / Tải Video Demo từ GitHub Release:** [demo_video.mp4 (Release v1.0.0)](https://github.com/nt-hzy3n/mobile_mini_project3/releases/download/v1.0.0/demo_video.mp4)
* Video minh họa trọn vẹn quy trình hoạt động thực tế trên ứng dụng: Đăng nhập nhanh bằng tài khoản 1-Click Demo, chọn ảnh biên lai giao dịch chuyển khoản ngân hàng, hệ thống tự động bóc tách dữ liệu thông minh qua VietQR và Google ML Kit OCR on-device, kiểm tra form tại Review Screen, lưu trữ lên Cloud Firestore và đồng bộ biểu đồ thời gian thực.

### 📱 Ảnh chụp màn hình ứng dụng (Screenshots)
<p align="center">
  <img src="https://raw.githubusercontent.com/nt-hzy3n/mobile_mini_project3/master/docs/screenshots/01_login_screen.png" width="30%" alt="Login Screen" />
  <img src="https://raw.githubusercontent.com/nt-hzy3n/mobile_mini_project3/master/docs/screenshots/02_home_dashboard.png" width="30%" alt="Home Dashboard" />
  <img src="https://raw.githubusercontent.com/nt-hzy3n/mobile_mini_project3/master/docs/screenshots/03_review_verify_screen.png" width="30%" alt="Review Screen" />
</p>
<p align="center">
  <img src="https://raw.githubusercontent.com/nt-hzy3n/mobile_mini_project3/master/docs/screenshots/04_expense_detail_screen.png" width="30%" alt="Expense Detail" />
  <img src="https://raw.githubusercontent.com/nt-hzy3n/mobile_mini_project3/master/docs/screenshots/05_edit_expense_dialog.png" width="30%" alt="Edit Dialog" />
</p>

---

## Tech Stack
* **Framework:** Flutter 3.47.5 / Dart 3.13.4
* **Authentication:** `firebase_auth: ^6.2.0`
* **Cloud Persistence:** `cloud_firestore: ^6.10.0`, `firebase_storage: ^13.6.0`, `firebase_core: ^4.15.0`
* **State Management:** Riverpod 2 (`flutter_riverpod`)
* **Routing:** `go_router` (Auth redirects & StatefulShellRoute)
* **On-Device Vision:** `google_mlkit_text_recognition`, `google_mlkit_barcode_scanning`, `mobile_scanner`
* **Custom Charts:** Flutter Canvas API (`CustomPainter`, zero external chart packages)

---

## Architecture
Dự án được tổ chức theo cấu trúc module phân tầng:
```
lib/
├── app/                  # Routing (GoRouter với Auth Redirects), Theme Material 3
├── core/                 # Constants, Formatters, Services (Firebase Storage, Permissions), Validators
├── data/                 # Expense Model, ExpenseRepository (User-scoped), AuthRepository (Firebase Auth)
├── features/
│   ├── analytics/        # CustomPainter Donut & Bar Charts
│   ├── auth/             # LoginScreen, RegisterScreen, ForgotPasswordScreen
│   ├── expenses/         # Danh sách chi tiêu, Tìm kiếm, Lọc danh mục, Chi tiết
│   ├── home/             # Tổng quan số dư, Khoản chi gần đây
│   ├── scanner/          # Live Scanner, VietQR Parser, ML Kit OCR, Heuristic, Review Screen
│   └── settings/         # Cài đặt giao diện Sáng/Tối, Hồ sơ tài khoản, Đăng xuất, Bảo mật
├── firebase_options.dart # Cấu hình DefaultFirebaseOptions cho Android & Web
├── firestore.rules       # Quy tắc bảo mật dữ liệu Firestore (User-scoped)
├── storage.rules         # Quy tắc bảo mật hình ảnh Storage (User-scoped)
└── providers/            # Riverpod Providers (Auth, Expense, Scanner, Theme)
```

---

## Cài đặt & Sử dụng (Installation & Usage)

### 1. Cài đặt trực tiếp qua file APK
Tải và cài đặt trực tiếp ứng dụng lên điện thoại Android hoặc máy ảo:
* **Tải file APK:** [vku_expense_qr.apk (Release v1.0.0)](https://github.com/nt-hzy3n/mobile_mini_project3/releases/download/v1.0.0/vku_expense_qr.apk)

### 2. Chạy từ mã nguồn (Flutter)
**Yêu cầu:** Flutter SDK `>= 3.24.0` và Dart `>= 3.5.0`.

1. **Clone repository:**
   ```bash
   git clone https://github.com/nt-hzy3n/mobile_mini_project3.git
   cd mobile_mini_project3
   ```

2. **Cài đặt thư viện:**
   ```bash
   flutter pub get
   ```

3. **Chạy ứng dụng:**
   ```bash
   flutter run
   ```

4. **Chạy kiểm thử:**
   ```bash
   flutter test
   ```

5. **Biên dịch Release APK:**
   ```bash
   flutter build apk --release
   ```

### 3. Hướng dẫn sử dụng nhanh
* **Đăng nhập:** Đăng ký tài khoản mới bằng Email/Mật khẩu hoặc nhấn **"Dùng thử Demo"** tại màn hình đăng nhập để vào ngay ứng dụng với dữ liệu mẫu có sẵn.
* **Quét & Thêm chi tiêu:** Nhấn nút **Quét (+)** ở thanh điều hướng, chọn ảnh biên lai chuyển khoản (MBBank, Vietcombank, Techcombank, MoMo...) từ thư viện hoặc chụp trực tiếp. Ứng dụng tự động nhận diện mã VietQR hoặc quét chữ (OCR) để lấy số tiền, ngân hàng, STK, người nhận và nội dung.
* **Xác nhận & Chỉnh sửa:** Kiểm tra thông tin trên màn hình Review, chỉnh sửa nếu cần và nhấn **Lưu chi tiêu**.
* **Theo dõi & Phân tích:** Xem số dư và giao dịch gần đây trên trang chủ, xem biểu đồ tỷ lệ danh mục và chi tiêu theo tuần trong tab **Phân tích**.
* **Đổi giao diện:** Bật/tắt chế độ tối (Dark Theme) trong tab **Cài đặt**.
