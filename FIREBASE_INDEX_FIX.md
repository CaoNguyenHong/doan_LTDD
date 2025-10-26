# Firebase Indexes Deployment Guide

## 🚨 **Lỗi Firebase Indexes**

Ứng dụng đang gặp lỗi Firestore indexes. Cần deploy các indexes sau:

### **Các Indexes Cần Thiết:**

1. **Expenses Collection:**
   - Fields: `deleted` (ASC), `dateTime` (DESC), `__name__` (DESC)

2. **Accounts Collection:**
   - Fields: `deleted` (ASC), `createdAt` (DESC), `__name__` (DESC)

3. **Budgets Collection:**
   - Fields: `deleted` (ASC), `createdAt` (DESC), `__name__` (DESC)

### **Cách Deploy:**

#### **Option 1: Firebase Console (Recommended)**
1. Vào [Firebase Console](https://console.firebase.google.com/)
2. Chọn project `doanltdd-46bd4`
3. Vào **Firestore Database** → **Indexes**
4. Click **Create Index**
5. Tạo từng index theo thông tin trên

#### **Option 2: Firebase CLI**
```bash
# Login vào Firebase
firebase login

# Set project
firebase use doanltdd-46bd4

# Deploy indexes
firebase deploy --only firestore:indexes
```

#### **Option 3: Direct Links**
Click vào các links sau để tạo indexes tự động:

**Expenses Index:**
https://console.firebase.google.com/v1/r/project/doanltdd-46bd4/firestore/indexes?create_composite=Ck9wcm9qZWN0cy9kb2FubHRkZC00NmJkNC9kYXRhYmFzZXMvKGRlZmF1bHQpL2NvbGxlY3Rpb25Hcm91cHMvZXhwZW5zZXMvaW5kZXhlcy9fEAEaCwoHZGVsZXRlZBABGgwKCGRhdGVUaW1lEAIaDAoIX19uYW1lX18QAg

**Accounts Index:**
https://console.firebase.google.com/v1/r/project/doanltdd-46bd4/firestore/indexes?create_composite=Ck9wcm9qZWN0cy9kb2FubHRkZC00NmJkNC9kYXRhYmFzZXMvKGRlZmF1bHQpL2NvbGxlY3Rpb25Hcm91cHMvYWNjb3VudHMvaW5kZXhlcy9fEAEaCwoHZGVsZXRlZBABGg0KCWNyZWF0ZWRBdBACGgwKCF9fbmFtZV9fEAI

**Budgets Index:**
https://console.firebase.google.com/v1/r/project/doanltdd-46bd4/firestore/indexes?create_composite=Ck5wcm9qZWN0cy9kb2FubHRkZC00NmJkNC9kYXRhYmFzZXMvKGRlZmF1bHQpL2NvbGxlY3Rpb25Hcm91cHMvYnVkZ2V0cy9pbmRleGVzL18QARoLCgdkZWxldGVkEAEaDQoJY3JlYXRlZEF0EAIaDAoIX19uYW1lX18QAg

### **Sau Khi Deploy:**
- Restart ứng dụng
- Các lỗi Firestore sẽ biến mất
- Analytics sẽ hoạt động bình thường

### **Lưu Ý:**
- Indexes có thể mất vài phút để build
- Kiểm tra status trong Firebase Console
- Nếu vẫn lỗi, thử restart app

