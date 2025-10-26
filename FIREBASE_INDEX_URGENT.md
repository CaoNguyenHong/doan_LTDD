# 🚨 KHẨN CẤP: Tạo Firestore Index

## ❌ Vấn đề hiện tại
- **Thêm giao dịch được** nhưng **không hiển thị ngay**
- **Phải restart app** mới thấy dữ liệu
- **Lỗi Firestore Index** cần tạo ngay

## 🔥 CÁCH SỬA NGAY

### Bước 1: Truy cập Firebase Console
1. Mở: https://console.firebase.google.com/
2. Đăng nhập bằng tài khoản Google
3. Chọn project: **doanltdd-46bd4**

### Bước 2: Tạo Index
1. Trong sidebar, click **Firestore Database**
2. Click tab **Indexes**
3. Click **Create Index**

### Bước 3: Cấu hình Index
**Collection Group ID:** `transactions`

**Fields:**
1. **Field 1:**
   - Field path: `deleted`
   - Order: `Ascending`

2. **Field 2:**

   - Field path: `dateTime`
   - Order: `Descending`

### Bước 4: Tạo Index
1. Click **Create**
2. Chờ 2-5 phút để index build
3. Khi status = "Enabled" là xong

## 🧪 Test sau khi tạo index
1. Thêm giao dịch mới
2. Kiểm tra xem có hiển thị ngay không
3. Nếu vẫn không hiển thị, restart app

## 📱 Tính năng hiện tại
- ✅ Build thành công
- ✅ Thêm giao dịch được
- ✅ UI hiện đại
- ⏳ **Cần index để hiển thị realtime**

## 🎯 Sau khi tạo index
- ✅ Thêm giao dịch hiển thị ngay
- ✅ Không cần restart app
- ✅ Dữ liệu realtime
