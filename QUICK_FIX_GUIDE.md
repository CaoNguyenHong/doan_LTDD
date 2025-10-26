# 🚀 Hướng dẫn sửa lỗi nhanh

## ❌ Lỗi hiện tại
1. **Lỗi build:** Field `date` không tồn tại trong `Expense` model
2. **Lỗi Firestore Index:** Cần tạo index cho transactions collection

## ✅ Đã sửa
1. **✅ Lỗi build:** Đã sửa `TransactionConverter` và `ExpenseProvider`
2. **⏳ Lỗi Firestore Index:** Cần tạo index trong Firebase Console

## 🔥 Cần làm ngay

### Bước 1: Tạo Firestore Index
1. Mở: https://console.firebase.google.com/
2. Chọn project: **doanltdd-46bd4**
3. Vào **Firestore Database** > **Indexes**
4. Click **Create Index**

### Bước 2: Cấu hình Index
- **Collection Group ID:** `transactions`
- **Fields:**
  - `deleted` (Ascending)
  - `dateTime` (Descending) 
  - `__name__` (Descending)

### Bước 3: Chờ Index Build
- Index sẽ mất 2-5 phút để build
- Khi status = "Enabled" là xong

## 🧪 Test sau khi tạo index
1. Thử thêm giao dịch mới
2. Kiểm tra xem giao dịch có hiển thị trong danh sách không
3. Nếu vẫn không hiển thị, restart ứng dụng

## 📱 Tính năng hiện tại
- ✅ Quản lý ví nội bộ
- ✅ Giao dịch nâng cao (4 loại)
- ✅ Ngân sách thông minh
- ✅ UI hiện đại Material 3
- ⏳ Đồng bộ dữ liệu (cần index)

## 🎯 Sau khi tạo index
- ✅ Thêm giao dịch sẽ hiển thị ngay
- ✅ Dữ liệu realtime
- ✅ Không cần restart app
