# 🔥 Hướng dẫn tạo Firestore Index

## ❌ Lỗi hiện tại
```
The query requires an index. You can create it here: 
https://console.firebase.google.com/v1/r/project/doanltdd-46bd4/firestore/indexes?create_composite=...
```

## ✅ Cách sửa

### Bước 1: Truy cập Firebase Console
1. Mở link: https://console.firebase.google.com/
2. Đăng nhập bằng tài khoản Google
3. Chọn project: **doanltdd-46bd4**

### Bước 2: Tạo Firestore Index
1. Trong sidebar, click **Firestore Database**
2. Click tab **Indexes**
3. Click nút **Create Index**

### Bước 3: Cấu hình Index
**Collection Group ID:** `transactions`

**Fields:**
1. **Field 1:**
   - Field path: `deleted`
   - Order: `Ascending`

2. **Field 2:**
   - Field path: `dateTime` 
   - Order: `Descending`

3. **Field 3:**
   - Field path: `__name__`
   - Order: `Descending`

### Bước 4: Tạo Index
1. Click **Create**
2. Chờ index được build (2-5 phút)
3. Khi status chuyển thành "Enabled" là xong

## 🧪 Test sau khi tạo index
1. Chạy ứng dụng: `flutter run`
2. Thử thêm giao dịch mới
3. Kiểm tra xem giao dịch có hiển thị trong danh sách không

## 📝 Lưu ý
- Index chỉ cần tạo 1 lần
- Sau khi tạo xong, ứng dụng sẽ hoạt động bình thường
- Không cần restart ứng dụng, chỉ cần hot reload
