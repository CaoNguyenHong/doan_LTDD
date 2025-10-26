# Firebase Index Setup

## Vấn đề hiện tại
Ứng dụng gặp lỗi khi query transactions vì thiếu Firestore index.

## Lỗi gặp phải
```
The query requires an index. You can create it here: 
https://console.firebase.google.com/v1/r/project/doanltdd-46bd4/firestore/indexes?create_composite=...
```

## Cách sửa

### Bước 1: Truy cập Firebase Console
1. Mở link: https://console.firebase.google.com/
2. Chọn project: `doanltdd-46bd4`

### Bước 2: Tạo Firestore Index
1. Vào **Firestore Database** > **Indexes**
2. Click **Create Index**
3. Chọn **Collection Group ID**: `transactions`
4. Thêm các fields:
   - `deleted` (Ascending)
   - `dateTime` (Descending) 
   - `__name__` (Descending)
5. Click **Create**

### Bước 3: Chờ index được tạo
- Index sẽ mất vài phút để build
- Khi hoàn thành, ứng dụng sẽ hoạt động bình thường

## Index đã được cập nhật trong code
File `firestore.indexes.json` đã được cập nhật với index mới cho transactions collection.

## Test sau khi tạo index
1. Chạy ứng dụng: `flutter run`
2. Thử thêm giao dịch mới
3. Kiểm tra xem giao dịch có hiển thị trong danh sách không
