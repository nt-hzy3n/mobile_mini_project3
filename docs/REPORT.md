# BÁO CÁO KỸ THUẬT MINI-PROJECT 3 (WEEK 8)
## MÔN HỌC: PHÁT TRIỂN ỨNG DỤNG DI ĐỘNG ĐA NỀN TẢNG (CROSS-PLATFORM MOBILE APP DEVELOPMENT)

---

**ĐỀ TÀI:** XÂY DỰNG ỨNG DỤNG QUẢN LÝ CHI TIÊU TỪ ẢNH CHỤP MÀN HÌNH THANH TOÁN (PAYMENT SCREENSHOT EXPENSE TRACKER)  
**TÊN DỰ ÁN:** VKU Expense QR (`vku_expense_qr`)  
**TRƯỜNG:** Đại học Công nghệ Thông tin & Truyền thông Việt - Hàn (VKU), Đại học Đà Nẵng  
**SINH VIÊN THỰC HIỆN:** Nguyen Thi Huyen — **MÃ SINH VIÊN:** 23IT110  
**GITHUB REPOSITORY:** [https://github.com/nt-hzy3n/mobile_mini_project3](https://github.com/nt-hzy3n/mobile_mini_project3)  
**RELEASE APK:** [Tải file APK cài đặt (v1.0.0)](https://github.com/nt-hzy3n/mobile_mini_project3/releases/tag/v1.0.0) | File cục bộ: `vku_expense_qr.apk`  
**NGÀY NỘP:** 08/10/2026  

---

## 1. TỔNG QUAN DỰ ÁN & VẤN ĐỀ THỰC TẾ

### 1.1. Bối cảnh
Trong thời đại chuyển đổi số tài chính tại Việt Nam, người dùng thực hiện giao dịch ngân hàng hàng ngày thông qua quét mã VietQR/NAPAS247 và chuyển khoản trực tuyến (Mobile Banking). Tuy nhiên, hầu hết các ứng dụng quản lý tài chính hiện nay đều yêu cầu người dùng gõ tay thủ công, dẫn đến tình trạng quên ghi chép hoặc tốn nhiều thời gian.

### 1.2. Giải pháp: Payment Screenshot Expense Tracker
Ứng dụng **VKU Expense QR** tự động hóa quy trình ghi nhận chi tiêu từ ảnh chụp màn hình thanh toán hoặc biên lai ngân hàng:
1. Xác thực tài khoản người dùng qua **Firebase Authentication (Email & Password)**, hỗ trợ Đăng ký, Đăng nhập, Quên mật khẩu và duy trì phiên đăng nhập bền vững.
2. Cho phép người dùng chụp ảnh hoặc chọn ảnh chụp màn hình xác nhận giao dịch chuyển tiền thành công từ thư viện ảnh.
3. Tự động tìm và giải mã mã QR theo chuẩn **VietQR / EMVCo TLV** (Tag 38, Tag 54, Tag 59, Tag 62.08).
4. Nếu không có QR hoặc mã QR tĩnh thiếu số tiền/tên, ứng dụng tự động kích hoạt **Google ML Kit Text Recognition On-Device** để nhận diện văn bản hoàn toàn ngoại tuyến.
5. Thuật toán **Regex Heuristic Parser** bóc tách số tiền VNĐ, ngày giờ, người nhận, ngân hàng và nội dung chuyển khoản.
6. Động cơ **Hybrid Payment Data Merger** kết hợp dữ liệu theo độ ưu tiên `QR > OCR > Manual`.
7. Màn hình **Kiểm tra giao dịch (Review & Verify Screen)** bắt buộc người dùng xác nhận và cho phép chỉnh sửa 100% các trường trước khi lưu.
8. Dữ liệu được lưu trữ phân lập theo người dùng trên **Firebase Cloud Firestore (`users/{uid}/expenses`)** và **Firebase Storage (`users/{uid}/expenses/{expenseId}/payment_image.jpg`)**, hỗ trợ đồng bộ đa thiết bị thời gian thực.
9. Trực quan hóa dữ liệu qua biểu đồ **CustomPainter thuần túy** (Donut Chart & Weekly Bar Chart) đạt tốc độ vẽ 60fps.

---

## 2. BẢNG ĐẶC TẢ HEURISTIC REGEX PARSER

| Trường dữ liệu | Phương pháp trích xuất | Biểu thức Regex / Logic Heuristic | Ví dụ thực tế hỗ trợ |
|---|---|---|---|
| **Số tiền (Amount)** | Regex tiền tệ VNĐ + Context ưu tiên | `(?:tổng\s*tiền\|số\s*tiền\|chuyển\s*tiền\|total)[\s:=-]*([0-9.,\s]+(?:\s*(?:vnd\|vnđ\|đ))?)` | `1,000,000 VND`, `1.000.000 đ`, `1000000` |
| **Ngày giao dịch (Date)** | Date regex chuẩn | `\b(\d{1,2})[/.-](\d{1,2})[/.-](\d{4})\b` | `28/09/2026`, `28-09-2026`, `28.09.2026` |
| **Thời gian (Time)** | Time regex (HH:mm) | `\b([01]?\d\|2[0-3]):([0-5]\d)(?::([0-5]\d))?\b` | `17:53` (từ `17:53 - 28/09/2026`) |
| **Người nhận (Recipient)** | Lọc nhãn Người nhận + Tên in hoa loại trừ tiêu đề | Tìm dòng sau `Người nhận:`, `Đến:` hoặc dòng in hoa 2 từ trở lên, loại trừ blacklist | `NGUYEN THI THUONG` |
| **Ngân hàng (Bank)** | Heuristic ngân hàng Việt Nam | Đối chiếu danh mục `_knownBanks` (MBBank, Vietcombank, Techcombank, BIDV, Agribank,...) hoặc chuỗi chứa `Bank` | `MBBank (MB)`, `Vietcombank (VCB)` |
| **Số tài khoản (Account)** | Regex số 8 - 18 chữ số | `\b\d{8,18}\b` ưu tiên sau từ khóa `STK`, `Số tài khoản` | `41212106082002` *(Che mờ: `********2002`)* |
| **Nội dung (Description)** | Regex dòng nội dung / Lời nhắn | Tìm dòng sau `Nội dung:`, `Lời nhắn:` hoặc chứa `chuyen tien`, `thanh toan` | `NGUYEN THI HUYEN chuyen tien` |

---

## 3. KIẾN TRÚC HỆ THỐNG & DÒNG DỮ LIỆU

```
lib/
├── app/                  # Routing (GoRouter với Auth Redirects), Theme Material 3 (VKU Navy Seed)
├── core/                 # Constants, Formatters, Services (Firebase Storage User-scoped, Permissions), Validators
├── data/                 # Expense Model, ExpenseRepository (User-scoped), AuthRepository (Firebase Auth)
├── features/
│   ├── analytics/        # CategoryDonutChart & WeeklyBarChart (CustomPainter)
│   ├── auth/             # LoginScreen, RegisterScreen, ForgotPasswordScreen
│   ├── expenses/         # Danh sách chi tiêu, Tìm kiếm ngân hàng, Lọc chip, Chi tiết
│   ├── home/             # Tổng quan số dư, Khoản chi gần đây
│   ├── scanner/          # Live Scanner, VietQR Parser, ML Kit OCR, Heuristic, Review Screen
│   └── settings/         # Hồ sơ tài khoản người dùng, Đăng xuất, Chế độ Sáng/Tối
├── firebase_options.dart # Cấu hình DefaultFirebaseOptions cho Android và Web
├── firestore.rules       # Quy tắc bảo mật Firestore (User-scoped access)
├── storage.rules         # Quy tắc bảo mật Storage (User-scoped access)
└── providers/            # Riverpod Providers (Auth, Expense, Scanner, Theme)
```

```
                                 [ KHỞI ĐỘNG ỨNG DỤNG ]
                                            │
                                            ▼
                               [ FIREBASE INITIALIZE APP ]
                                            │
                                            ▼
                           [ FIREBASE AUTH (authStateChanges) ]
                                            │
                         ┌──────────────────┴──────────────────┐
                         ▼ (Chưa đăng nhập)                    ▼ (Đã đăng nhập)
                  [ MÀN HÌNH ĐĂNG NHẬP ]               [ AUTHENTICATED USER (uid) ]
                  (/login, /register)                          │
                         │ (Đăng nhập thành công)              ▼
                         └────────────────────────────► [ TRANG CHỦ DASHBOARD ]
                                                               │
                                                               ▼
                                             [ CHỤP / CHỌN ẢNH THANH TOÁN ]
                                                               │
                                                               ▼
                                                    [ QUÉT MÃ QR CODE ]
                                                               │
                                           ┌───────────────────┴───────────────────┐
                                           ▼ (Có mã QR)                            ▼ (Không có mã QR)
                                    [ Decode VietQR ]                       [ Google ML Kit OCR ]
                                           │                                       │
                                  ┌────────┴────────┐                              ▼
                                  ▼                 ▼                      [ Heuristic Parser ]
                            [Chuẩn VietQR]   [Key-Value/URL]               (Lọc tiền VND, ngày)
                                  │                 │                              │
                                  └────────┬────────┘                              │
                                           ▼                                       │
                                  Thiếu Amount / Tên? ──── (Có) ───────────────────┤
                                           │ (Không)                               │
                                           ▼                                       ▼
                                  [ Dữ liệu từ QR ]                         [ Dữ liệu từ OCR ]
                                           │                                       │
                                           └───────────────────┬───────────────────┘
                                                               ▼
                                               [ HYBRID PAYMENT DATA MERGER ]
                                                (Ưu tiên QR, bù đắp từ OCR)
                                                               │
                                                               ▼
                                                 [ MÀN HÌNH KIỂM TRA GIAO DỊCH ]
                                                    (Review & Verify Screen)
                                                               │
                                                               ▼
                                                [ XÁC THỰC FORM VALIDATION ]
                                                               │
                                                               ▼
                                      ┌────────────────────────┴────────────────────────┐
                                      ▼                                                 ▼
                             [ FIREBASE STORAGE ]                              [ CLOUD FIRESTORE ]
                     users/{uid}/expenses/{id}/payment_image.jpg           users/{uid}/expenses/{id}
                                      │                                                 │
                                      └────────────────────────┬────────────────────────┘
                                                               ▼
                                                      [ RIVERPOD STATE ]
                                                    (Realtime Stream theo UID)
                                                               ▼
                                               [ DASHBOARD / EXPENSES / CHARTS ]
                                                               │
                                                               ▼
                                               [ ĐỒNG BỘ ĐA THIẾT BỊ REALTIME ]
```

---

## 4. BẢO MẬT & QUYỀN RIÊNG TƯ DỮ LIỆU (PRIVACY & SECURITY)
1. **Firebase Authentication:** Mật khẩu được mã hóa an toàn bởi Firebase Authentication, không lưu trữ mật khẩu trong Firestore.
2. **User-scoped Isolation:** Bản ghi chi tiêu và ảnh chụp màn hình được bảo vệ độc quyền dưới thư mục của từng người dùng (`users/{uid}`). Ngăn chặn người dùng truy cập dữ liệu của người dùng khác theo Firebase Security Rules.
3. **Che mờ số tài khoản:** Số tài khoản ngân hàng từ mã VietQR được chuẩn hóa hiển thị dạng `********2002` nhằm bảo vệ quyền riêng tư người nhận.
4. **Quản lý dữ liệu Storage an toàn:** Ảnh giao dịch lưu riêng biệt trên Firebase Storage tại `users/{uid}/expenses/{expenseId}/payment_image.jpg`. Khi người dùng xóa một khoản chi tiêu, cả document Firestore và ảnh trên Storage đều được xóa sạch sẽ.

---

## 5. KẾT QUẢ KIỂM THỬ & ĐÁNH GIÁ (TESTING RESULTS)
* **Phân tích tĩnh (`flutter analyze`):** **0 issues found** (clean exit 0).
* **Kiểm thử tự động (`flutter test`):** **33/33 tests Pass 100%**:
  - `auth_validation_test.dart`: Kiểm tra hợp lệ email, mật khẩu, xác nhận mật khẩu, dịch mã lỗi FirebaseAuthException, đăng xuất (5 tests).
  - `user_scoped_firestore_test.dart`: Kiểm tra phân lập dữ liệu độc lập giữa User A và User B, định dạng đường dẫn Storage User-scoped (2 tests).
  - `qr_parser_test.dart`: Parse chuẩn VietQR EMVCo, URL query parameters, Key-Value payloads, QR không có số tiền (5 tests).
  - `heuristic_parser_test.dart`: Parse ảnh chuyển khoản ngân hàng mẫu thực tế, các định dạng tiền tệ VNĐ, ngày, giờ, người nhận, ngân hàng và số tài khoản (6 tests).
  - `payment_data_merger_test.dart`: Ưu tiên QR, fallback OCR, chế độ Hybrid, che mờ số tài khoản (4 tests).
  - `form_validation_test.dart`: Bắt lỗi số tiền âm/rỗng, tên người nhận, ngày, giờ HH:mm, nội dung (5 tests).
  - `firestore_model_test.dart`: Serialization/Deserialization model Firestore với Timestamps, banking fields, masked account number, thao tác CRUD Repository và analytics (3 tests).
  - `charts_widget_test.dart` & `expense_card_test.dart`: Widget test biểu đồ CustomPainter và thẻ chi tiêu (3 tests).
* **Biên dịch Release APK:** Tạo thành công `build/app/outputs/flutter-apk/app-release.apk`.
