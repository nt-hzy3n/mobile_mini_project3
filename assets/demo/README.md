# Thư mục Ảnh Mẫu Test (Demo Payment QR)

Thư mục này chứa ảnh mẫu để kiểm thử tính năng **Quét ảnh từ Thư viện (Gallery)** của ứng dụng **VKU Expense QR**.

---

### 1. Chuỗi mã QR mẫu để tạo ảnh thử nghiệm:

Bạn có thể sao chép các chuỗi sau vào bất kỳ công cụ tạo QR nào (ví dụ: [qr-code-generator.com](https://www.qr-code-generator.com/) hoặc tiện ích tạo QR):

#### Mẫu 1: Chuẩn VietQR / NAPAS247 (Highlands Coffee - 150.000 đ)
```text
00020101021238540010A00000072701240006970422011003456789010208QRIBFTTA530370454061500005802VN5916HIGHLANDS COFFEE62190815Thanh toan cafe6304E8A9
```
* **Số tiền:** 150.000 VND
* **Cửa hàng:** HIGHLANDS COFFEE
* **Nội dung:** Thanh toan cafe
* **Ngân hàng:** MBBank
* **Số tài khoản:** 0345678901

#### Mẫu 2: Chuẩn Key-Value Payment QR (GearVN Đà Nẵng - 750.000 đ)
```text
amount=750000;merchant=GearVN Da Nang;note=Ban phim co;bank=VCB
```
* **Số tiền:** 750.000 VND
* **Cửa hàng:** GearVN Da Nang
* **Ghi chú:** Ban phim co

#### Mẫu 3: Chuẩn VietQR URL (Chuyển khoản học phí FAHASA - 220.000 đ)
```text
https://img.vietqr.io/image/970422-0987654321-compact2.png?amount=220000&accountName=Nha%20Sach%20FAHASA&addInfo=Giao%20trinh%20Flutter
```

---

### 2. Cách kiểm thử trên thiết bị / Máy ảo:
1. Lưu ảnh chứa mã QR hoặc ảnh chụp màn hình chuyển khoản ngân hàng vào thư viện ảnh máy.
2. Mở ứng dụng **VKU Expense QR** -> Chọn **Quét thanh toán**.
3. Bấm nút **Chọn ảnh (Gallery)** ở góc dưới bên trái.
4. Chọn ảnh cần phân tích:
   - Nếu ảnh có QR: Ứng dụng tự động đọc payload VietQR/EMVCo.
   - Nếu ảnh là hóa đơn/biên lai không có QR: Ứng dụng tự động chuyển sang Google ML Kit OCR nhận diện số tiền, ngày tháng và tên cửa hàng.
