# BÁO CÁO KẾT QUẢ THỰC HIỆN MINI-PROJECT 3 (TUẦN 8)
## HỌC PHẦN: PHÁT TRIỂN ỨNG DỤNG DI ĐỘNG ĐA NỀN TẢNG (CROSS-PLATFORM MOBILE APP DEVELOPMENT)
### ĐỀ TÀI: PAYMENT SCREENSHOT EXPENSE TRACKER (VKU EXPENSE QR)

---

## THÔNG TIN SINH VIÊN THỰC HIỆN
* **Họ và tên:** Nguyễn Thị Huyền (Nguyen Thi Huyen)
* **Mã sinh viên:** 23IT110
* **Lớp sinh hoạt:** 23IT
* **Đơn vị đào tạo:** Trường Đại học Công nghệ Thông tin và Truyền thông Việt - Hàn (VKU), Đại học Đà Nẵng
* **Số lượng thành viên:** 01 thành viên (Độc lập thực hiện 100% các hạng mục từ kiến trúc, xử lý thuật toán QR/OCR, bảo mật Firebase Auth, Cloud Firestore, Firebase Storage, UI/UX đến kiểm thử tự động).
* **GitHub Repository:** [https://github.com/nt-hzy3n/mobile_mini_project3](https://github.com/nt-hzy3n/mobile_mini_project3)
* **Link tải trực tiếp file APK (Direct Download):** [https://github.com/nt-hzy3n/mobile_mini_project3/releases/download/v1.0.0/vku_expense_qr.apk](https://github.com/nt-hzy3n/mobile_mini_project3/releases/download/v1.0.0/vku_expense_qr.apk)
* **Link GitHub Releases:** [https://github.com/nt-hzy3n/mobile_mini_project3/releases/tag/v1.0.0](https://github.com/nt-hzy3n/mobile_mini_project3/releases/tag/v1.0.0)
* **File APK trong thư mục dự án:** `vku_expense_qr.apk` (hoặc `build/app/outputs/flutter-apk/app-release.apk`)

---

## 1. TỔNG QUAN DỰ ÁN & BỐI CẢNH THỰC TẾ (PROJECT OVERVIEW)

### 1.1. Mục tiêu và ý tưởng thích ứng thực tế
Dự án được xây dựng dựa trên yêu cầu cốt lõi của **Mini-Project 3 (Tuần 8)** về bóc tách chi tiêu từ hình ảnh và lưu trữ dữ liệu đám mây đa thiết bị. Nhận thấy thói quen thực tế của người dùng và sinh viên tại Việt Nam hiện nay chủ yếu thanh toán không tiền mặt qua ứng dụng ngân hàng di động (VietQR, NAPAS247, MBBank, Vietcombank, Techcombank,...), ứng dụng **VKU Expense QR** được phát triển chuyên biệt để:
1. Xác thực người dùng bằng **Firebase Authentication (Email & Password)**, hỗ trợ Đăng nhập, Đăng ký, Quên mật khẩu và duy trì phiên làm việc liên tục giữa các lần mở app.
2. Cho phép người dùng nhập ảnh chụp màn hình chuyển khoản ngân hàng qua **Thư viện ảnh (Gallery)**, **Chụp ảnh camera (Camera Capture)** hoặc **Quét trực tiếp (Live QR Scanner)**.
3. Tự động giải mã chuỗi mã QR theo tiêu chuẩn quốc gia **VietQR / EMVCo TLV** khi có mã QR trên ảnh.
4. Tích hợp công nghệ nhận dạng ký tự quang học **Google ML Kit Text Recognition chạy 100% On-Device** làm phương án dự phòng (Fallback) khi ảnh không có QR hoặc là QR tĩnh không chứa trường số tiền.
5. Xây dựng bộ phân tích biểu thức chính quy và quy luật tiếng Việt (**Heuristic Regex Parser**) bóc tách chuẩn xác: Số tiền VNĐ, Ngày giao dịch, Thời gian (HH:mm), Người nhận, Ngân hàng, Số tài khoản ngân hàng và Nội dung giao dịch.
6. Hợp nhất thông minh dữ liệu theo chiến lược **Hybrid Merger (QR > OCR > Manual)** gắn nhãn minh bạch nguồn gốc dữ liệu.
7. Cung cấp màn hình **"Kiểm tra giao dịch" (Review & Verify Screen)** có form validation chặt chẽ để người dùng rà soát, chỉnh sửa trước khi lưu.
8. **Lưu trữ đám mây phân lập theo từng tài khoản người dùng (User-scoped)**:
   - **Cloud Firestore:** `users/{uid}/expenses/{expenseId}`
   - **Firebase Storage:** `users/{uid}/expenses/{expenseId}/payment_image.jpg`
   - Ngăn chặn người dùng truy cập dữ liệu của người dùng khác theo Firebase Security Rules.
   - Hỗ trợ **Đồng bộ hóa đa thiết bị (Multi-Device Synchronization)** qua Firestore Realtime Streams.

---

## 2. BẢNG ĐỐI SOÁT TÍNH NĂNG ĐÃ HOÀN THÀNH (FEATURE CHECKLIST)

| STT | Phân hệ tính năng | Trạng thái | Chi tiết triển khai kỹ thuật |
|---|---|:---:|---|
| **1** | **Firebase Authentication** | ✅ Complete | Tích hợp `firebase_auth`: Đăng ký, Đăng nhập, Đăng xuất, Quên mật khẩu, phiên đăng nhập bền vững (`authStateChanges`), chuyển mã lỗi sang tiếng Việt. |
| **2** | **Phân quyền User-Scoped Firestore** | ✅ Complete | Lưu trữ subcollection `users/{uid}/expenses/{expenseId}`. Hồ sơ người dùng tại `users/{uid}`. Phân lập dữ liệu hoàn toàn giữa các tài khoản. |
| **3** | **Phân quyền User-Scoped Storage** | ✅ Complete | Tải ảnh chụp màn hình biên lai lên `users/{uid}/expenses/{expenseId}/payment_image.jpg`. Lưu `imageUrl` trong Firestore; xóa đồng bộ Storage khi xóa expense. |
| **4** | **Bảo mật Security Rules** | ✅ Complete | `firestore.rules` và `storage.rules` ràng buộc nghiêm ngặt `request.auth.uid == userId`, cấm triệt để truy cập công khai ngoài tài khoản. |
| **5** | **Input Đa Dạng (Screenshots / Camera)** | ✅ Complete | Tích hợp `image_picker` và `mobile_scanner`, hỗ trợ chọn ảnh chụp màn hình giao dịch chuyển khoản từ Gallery, chụp trực tiếp từ Camera và quét live camera thời gian thực. |
| **6** | **VietQR / EMVCo TLV Parser** | ✅ Complete | Phân tích cấu trúc mã QR EMVCo TLV (Tag 38 NAPAS Consumer, Tag 54 Số tiền VND, Tag 59 Người nhận, Tag 62.08 Nội dung) và VietQR URL / Key-Value format. |
| **7** | **Google ML Kit OCR On-Device Fallback** | ✅ Complete | Sử dụng thư viện `google_mlkit_text_recognition` chạy mô hình On-Device 100% ngoại tuyến, bảo mật thông tin tài chính người dùng, độ trễ nhận diện thấp (< 350ms). |
| **8** | **Heuristic Regex Parser (VN Banking)** | ✅ Complete | Trích xuất toàn diện: Số tiền VNĐ (`1,000,000 VND`, `1.000.000 đ`), Ngày (`DD/MM/YYYY`), Giờ (`HH:mm`), Người nhận, Ngân hàng (`MBBank`, `VCB`,...), Số tài khoản (8-18 số), và Nội dung chuyển khoản. |
| **9** | **Hybrid Payment Data Merger** | ✅ Complete | Cơ chế kết hợp ưu tiên: `QR > OCR > Manual`. Ưu tiên số tiền từ QR, bổ sung người nhận/thời gian từ OCR; gán nhãn độ tin cậy (`Mã QR xác thực`, `Nhận diện OCR`, `Kết hợp QR + OCR`, `Nhập thủ công`). |
| **10** | **Review & Verify Screen ("Kiểm tra giao dịch")** | ✅ Complete | Màn hình bắt buộc trước khi lưu Firebase: hiển thị ảnh giao dịch, nguồn trích xuất, số tiền, người nhận, ngân hàng, số tài khoản (có nút ẩn/hiện bảo mật), ngày, giờ, nội dung, danh mục. Cho phép sửa đổi 100%. |
| **11** | **Form Validation Chặt Chẽ** | ✅ Complete | Áp dụng `Form`, `GlobalKey<FormState>`, `TextEditingController`, `FocusNode`. Bắt lỗi số tiền âm/bằng 0, email định dạng chuẩn, mật khẩu xác nhận khớp, họ tên >= 2 ký tự. |
| **12** | **Interactive CustomPainter Charts** | ✅ Complete | **100% không dùng thư viện biểu đồ bên thứ ba**: Tự vẽ `CategoryDonutChart` bằng `Canvas.drawArc` với animation xoay mượt mà và `WeeklyBarChart` bằng `Canvas.drawRRect` hỗ trợ chạm cột (tap) hiển thị tooltip số tiền. |
| **13** | **Material 3 Design & Dark Theme** | ✅ Complete | Chuẩn Material 3 tông màu VKU Navy (`#0D3268`), phân cấp thị giác hiện đại, hỗ trợ Chế độ Tối (Dark Mode) lưu cấu hình qua `SharedPreferences`, 100% tiếng Việt chuẩn hóa. |
| **14** | **State Management & Điều hướng Auth** | ✅ Complete | `flutter_riverpod` (`AsyncNotifier`, `StreamProvider`) lắng nghe thời gian thực; `go_router` với redirect tự động bảo vệ route và tự chuyển hướng khi đăng xuất. |
| **15** | **Kiểm thử tự động (Test Suite)** | ✅ Complete | Đạt **33/33 bài test Pass 100%**: Bao gồm unit tests phân tích VietQR TLV, OCR Heuristic Regex, Hybrid Data Merger, User-scoped Firestore/Storage, Auth Validation, CustomPainter Charts, ExpenseCard. |

---

## 3. BẢNG ĐẶC TẢ HEURISTIC REGEX PARSER

| Trường thông tin | Phương pháp trích xuất | Biểu thức Regex / Logic Heuristic | Ví dụ thực tế hỗ trợ |
|---|---|---|---|
| **Số tiền (Amount)** | Regex tiền tệ VNĐ + Context ưu tiên | `(?:tổng\s*tiền\|số\s*tiền\|chuyển\s*tiền\|total)[\s:=-]*([0-9.,\s]+(?:\s*(?:vnd\|vnđ\|đ))?)` | `1,000,000 VND`, `1.000.000 đ`, `1000000` |
| **Ngày giao dịch (Date)** | Date regex chuẩn | `\b(\d{1,2})[/.-](\d{1,2})[/.-](\d{4})\b` | `28/09/2026`, `28-09-2026`, `28.09.2026` |
| **Thời gian (Time)** | Time regex (HH:mm) | `\b([01]?\d\|2[0-3]):([0-5]\d)(?::([0-5]\d))?\b` | `17:53` (từ `17:53 - 28/09/2026`) |
| **Người nhận (Recipient)** | Lọc nhãn Người nhận + Tên in hoa loại trừ tiêu đề hệ thống | Tìm dòng sau `Người nhận:`, `Đến:` hoặc dòng in hoa 2 từ trở lên, loại trừ blacklist | `NGUYEN THI THUONG` |
| **Ngân hàng (Bank)** | Heuristic danh mục ngân hàng Việt Nam | Đối chiếu danh mục `_knownBanks` (MBBank, Vietcombank, Techcombank, BIDV, Agribank,...) hoặc chuỗi chứa `Bank` | `MBBank (MB)`, `Vietcombank (VCB)` |
| **Số tài khoản (Account)** | Regex số 8 - 18 chữ số | `\b\d{8,18}\b` ưu tiên sau từ khóa `STK`, `Số tài khoản` | `41212106082002` *(Che mờ: `********2002`)* |
| **Nội dung (Description)** | Regex dòng nội dung / Lời nhắn | Tìm dòng sau `Nội dung:`, `Lời nhắn:` hoặc chứa `chuyen tien`, `thanh toan` | `NGUYEN THI HUYEN chuyen tien` |

---

## 4. KIẾN TRÚC HỆ THỐNG & CẤU TRÚC THƯ MỤC

### 4.1. Cấu trúc mã nguồn dự án
```
lib/
├── app/
│   ├── app.dart                   # Root Widget kết nối Riverpod & MaterialApp.router
│   ├── router.dart                # Điều hướng GoRouter với Auth Redirects & StatefulShellRoute
│   └── theme.dart                 # Hệ thống bảng màu Material 3 (VKU Navy Seed, Light/Dark)
├── core/
│   ├── constants/                 # Hằng số ứng dụng, danh mục chi tiêu, bảng từ khóa
│   ├── formatters/                # Bộ định dạng tiền tệ Việt Nam (VNĐ) và ngày giờ
│   ├── services/                  # Firebase Storage Service (User-scoped), Permission Service
│   └── utils/                     # Trình kiểm tra biểu mẫu (Validators: Amount, Date, Time, Merchant)
├── data/
│   ├── models/                    # Model dữ liệu Expense (Firestore Document serialization, banking fields)
│   └── repositories/
│       ├── auth_repository.dart   # Quản lý xác thực Firebase Auth, hồ sơ Firestore, dịch lỗi tiếng Việt
│       └── expense_repository.dart# Repository chi tiêu gắn với UID người dùng (users/{uid}/expenses)
├── features/
│   ├── analytics/                 # Phân hệ Báo cáo: CategoryDonutChart & WeeklyBarChart (CustomPainter)
│   ├── auth/                      # Phân hệ Xác thực: LoginScreen, RegisterScreen, ForgotPasswordScreen
│   ├── expenses/                  # Phân hệ Chi tiêu: Danh sách, tìm kiếm ngân hàng, lọc chip, chi tiết
│   ├── home/                      # Phân hệ Trang chủ: Thẻ số dư gradient, chi tiêu gần đây, nút thêm nhanh
│   ├── scanner/                   # Phân hệ Quét & OCR thông minh:
│   │   ├── data/                  # VietQR TLV Parser, ML Kit OCR, Heuristic Regex, Hybrid Merger
│   │   ├── models/                # QrPaymentData, ScanResult
│   │   └── presentation/          # Màn hình Scanner Live/Gallery và Màn hình "Kiểm tra giao dịch"
│   └── settings/                  # Phân hệ Cài đặt: Hồ sơ tài khoản, Đăng xuất, Giao diện Sáng/Tối
├── firebase_options.dart          # Cấu hình DefaultFirebaseOptions cho Android và Web
├── firestore.rules                # Quy tắc bảo mật dữ liệu Firestore (User-scoped access)
├── storage.rules                  # Quy tắc bảo mật hình ảnh Storage (User-scoped access)
└── providers/
    ├── auth_provider.dart         # Providers quản lý trạng thái đăng nhập và hồ sơ người dùng
    ├── expense_provider.dart      # Providers chi tiêu liên kết theo UID của tài khoản hiện tại
    ├── scanner_provider.dart      # Provider luồng quét mã và bóc tách dữ liệu
    └── theme_provider.dart        # Provider chế độ Sáng/Tối
```

### 4.2. Luồng xử lý dữ liệu hoàn chỉnh (Auth → Scan → Process → Persist → Sync)
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

## 5. BẢO MẬT & QUYỀN RIÊNG TƯ DỮ LIỆU (PRIVACY & SECURITY RULES)

### 5.1. Phân lập tài nguyên người dùng (User-Scoped Isolation)
1. **Cloud Firestore:**
   Toàn bộ bản ghi chi tiêu được lưu trữ tại đường dẫn phân cấp: `users/{uid}/expenses/{expenseId}`. Mỗi người dùng chỉ truy cập vào nhánh cây dữ liệu của chính mình.
2. **Firebase Storage:**
   Toàn bộ ảnh chụp màn hình thanh toán được lưu trữ tại: `users/{uid}/expenses/{expenseId}/payment_image.jpg`.
3. **Quy tắc bảo mật Firestore (`firestore.rules`):**
   ```javascript
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /users/{userId} {
         allow read, write: if request.auth != null && request.auth.uid == userId;

         match /expenses/{expenseId} {
           allow read, write: if request.auth != null && request.auth.uid == userId;
         }
       }
     }
   }
   ```
4. **Quy tắc bảo mật Storage (`storage.rules`):**
   ```javascript
   rules_version = '2';
   service firebase.storage {
     match /b/{bucket}/o {
       match /users/{userId}/expenses/{expenseId}/{fileName} {
         allow read, write: if request.auth != null && request.auth.uid == userId;
       }
     }
   }
   ```

### 5.2. Che mờ thông tin tài chính nhạy cảm
* Số tài khoản ngân hàng từ mã VietQR được tự động che mờ hiển thị dạng `********2002` (chỉ hiển thị 4 chữ số cuối) trên toàn bộ Dashboard, Thẻ chi tiêu và Danh sách giao dịch. Màn hình chi tiết hỗ trợ ẩn/hiện an toàn.

---

## 6. KẾT QUẢ KIỂM THỬ & ĐÁNH GIÁ (TESTING & VERIFICATION)

### 6.1. Phân tích tĩnh mã nguồn (`flutter analyze`)
* **Kết quả:** **0 issues found** (Hoàn toàn sạch lỗi và cảnh báo linting, tuân thủ chặt chẽ quy tắc Flutter/Dart).

### 6.2. Kiểm thử tự động (`flutter test`)
* **Kết quả:** **33/33 tests PASS 100%**:
  1. `auth_validation_test.dart` (5 tests): Định dạng email hợp lệ, độ dài mật khẩu (>= 6 ký tự), kiểm tra xác nhận mật khẩu khớp, chuyển đổi mã lỗi `FirebaseAuthException` sang tiếng Việt, đăng xuất làm sạch phiên làm việc.
  2. `user_scoped_firestore_test.dart` (2 tests): Kiểm chứng sự phân lập dữ liệu độc lập giữa User A và User B (User B không thể thấy chi tiêu của User A), kiểm tra định dạng đường dẫn ảnh Storage User-scoped.
  3. `qr_parser_test.dart` (5 tests): Phân tích VietQR EMVCo chuẩn (Tag 38, 54, 59, 62.08), URL query parameters, Key-Value format, QR tĩnh không có số tiền, QR chuỗi thô.
  4. `heuristic_parser_test.dart` (6 tests): Phân tích ảnh chụp màn hình ngân hàng thực tế, nhận diện các định dạng tiền tệ VNĐ, ngày `DD/MM/YYYY`, thời gian `HH:mm`, người nhận, ngân hàng và số tài khoản.
  5. `payment_data_merger_test.dart` (4 tests): Độ ưu tiên QR > OCR, kết hợp Hybrid QR tĩnh + OCR số tiền, chế độ OCR thuần, che mờ số tài khoản.
  6. `form_validation_test.dart` (5 tests): Ràng buộc số tiền (> 0), tên người nhận (>= 2 ký tự), ngày giao dịch, giờ giao dịch (HH:mm), ghi chú.
  7. `firestore_model_test.dart` (3 tests): Khởi tạo và serialization model Expense sang Firestore Map với trường Timestamp, lưu trữ banking fields, masked account number; thao tác CRUD trên ExpenseRepository; các phương thức phân tích chi phí theo tháng, tuần và danh mục.
  8. `charts_widget_test.dart` (2 tests): Render widget biểu đồ tròn `CategoryDonutChart` và biểu đồ cột tuần `WeeklyBarChart` sử dụng Canvas API thuần.
  9. `expense_card_test.dart` (1 test): Render thẻ khoản chi `ExpenseCard` với thông tin người nhận, số tiền định dạng VNĐ, nhãn nguồn gốc và sự kiện tap.

### 6.3. Biên dịch Release APK & Tải ứng dụng
* **Lệnh biên dịch độc lập:** `flutter build apk --release`
* **File APK tạo ra:** `build/app/outputs/flutter-apk/app-release.apk` (Dung lượng: `101 MB`, chứa toàn bộ model On-device OCR và Firebase).
* **Link tải trực tiếp file APK (Direct Download):** [https://github.com/nt-hzy3n/mobile_mini_project3/releases/download/v1.0.0/vku_expense_qr.apk](https://github.com/nt-hzy3n/mobile_mini_project3/releases/download/v1.0.0/vku_expense_qr.apk)
* **Trang GitHub Releases:** [https://github.com/nt-hzy3n/mobile_mini_project3/releases/tag/v1.0.0](https://github.com/nt-hzy3n/mobile_mini_project3/releases/tag/v1.0.0)
* **Tệp tin cục bộ trong thư mục dự án:** `vku_expense_qr.apk` (tại thư mục gốc) hoặc `build/app/outputs/flutter-apk/app-release.apk`.

---

## 7. KẾT LUẬN & ĐÁNH GIÁ MỨC ĐỘ ĐÁP ỨNG RUBRIC

Dự án **VKU Expense QR** đã hoàn thành 100% tất cả các tiêu chí của môn học và đáp ứng toàn diện yêu cầu tích hợp **Firebase Authentication** và **User-Scoped Persistence**:
* **Firebase Authentication:** Quản lý tài khoản an toàn qua Email/Password, tự động duy trì phiên làm việc, tự động bảo vệ điều hướng ứng dụng qua `GoRouter`.
* **Firebase Firestore:** Đóng vai trò là nguồn dữ liệu duy nhất (Single Source of Truth) lưu trữ toàn bộ các trường giao dịch tài chính theo subcollection `users/{uid}/expenses`.
* **Firebase Storage:** Lưu trữ ảnh chụp màn hình thanh toán theo cấu trúc `users/{uid}/expenses/{expenseId}/payment_image.jpg`, liên kết qua `imageUrl` trong Firestore.
* **Đồng bộ hóa đa thiết bị:** Người dùng đăng nhập cùng một tài khoản trên thiết bị A và thiết bị B sẽ thấy dữ liệu chi tiêu đồng bộ ngay lập tức nhờ Firestore realtime streams.
* **Kiểm soát quyền truy cập chặt chẽ:** Cấu hình Security Rules ngăn chặn người dùng truy cập dữ liệu của người dùng khác theo Firebase Security Rules, không cho phép truy cập công khai ngoài tài khoản chủ sở hữu.
* Toàn bộ mã nguồn SQLite cũ đã được loại bỏ hoàn toàn, đảm bảo kiến trúc sạch sẽ và nhất quán.
