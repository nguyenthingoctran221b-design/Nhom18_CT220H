# 🍽️ Smart E-Menu Indochine — Hệ Thống Đặt Món & Quản Lý Nhà Hàng Thông Minh

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-Firestore-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)
![Provider](https://img.shields.io/badge/State_Management-Provider-42A5F5?style=for-the-badge)
![License](https://img.shields.io/badge/License-MIT-green.svg?style=for-the-badge)

> **Smart E-Menu Indochine** là giải pháp phần mềm đặt món ăn điện tử và quản lý nhà hàng toàn diện được thiết kế theo phong cách nghệ thuật Đông Dương (Indochine Style). Ứng dụng tích hợp công nghệ đồng bộ thời gian thực qua Cloud Firestore, hỗ trợ tối ưu trên màn hình máy tính bảng (Tablet/Landscape mode) nhằm nâng cao trải nghiệm thực khách và tối ưu quy trình vận hành giữa Khách hàng - Bếp - Thu ngân - Quản lý.

---

## 📌 Tổng Quan Dự Án & Bối Cảnh

* **Môn học / Học phần:** Niên luận / Đồ án môn học CT220H
* **Đơn vị:** Trường Công nghệ Thông tin & Truyền thông — Đại học Cần Thơ (CTU)
* **Phong cách thiết kế UI/UX:** Indochine Elegance (Sự hòa quyện giữa nét hoài cổ Đông Dương và giao diện hiện đại, tinh tế).

---

## ✨ Tính Năng Nổi Bật Theo Vai Trò

### 📱 1. Khách Hàng (E-Menu Digital Order)
- **Menu điện tử trực quan:** Khám phá danh mục thực đơn phong phú (Khai vị, Món chính, Món nướng, Tráng miệng, Đồ uống...).
- **Chi tiết món ăn:** Hình ảnh chất lượng cao, mô tả nguyên liệu, giá cả và tùy chỉnh yêu cầu ghi chú đặc biệt (ví dụ: *ít cay, không hành*).
- **Giỏ hàng real-time:** Thêm/bớt món linh hoạt, tự động tính tổng tiền và thuế/phí.
- **Tính năng mở rộng:** Gọi nhân viên hỗ trợ tại bàn, theo dõi trạng thái món ăn đang được chế biến.

### 👨‍🍳 2. Nhà Bếp & Điều Phối (Kitchen Display System - KDS)
- **Đồng bộ thời gian thực:** Nhận đơn gọi món mới tức thì từ bàn khách hàng qua Firebase Cloud Firestore.
- **Phân khu bếp tự động:** Tự động lọc đơn theo từng phân khu chuyên trách (*Bếp nóng, Bếp lạnh, Pha chế, Nướng/Xào...*).
- **Quản lý quy trình chế biến:** Cập nhật trạng thái món ăn đơn giản 1-touch (`Chờ xử lý` ➔ `Đang chế biến` ➔ `Hoàn thành`).

### 💵 3. Thu Ngân (Cashier & Billing System)
- **Sơ đồ bàn trực quan:** Quản lý trạng thái từng bàn theo màu sắc (*Bàn trống, Đang dùng bữa, Chờ thanh toán*).
- **Duyệt & Tính tiền:** Kiểm tra chi tiết đơn hàng của từng bàn, áp dụng mã giảm giá/khuyến mãi.
- **Xuất hóa đơn PDF:** Tự động tạo và in hóa đơn thanh toán định dạng PDF chuyên nghiệp (`pdf`, `printing`).
- **Tra cứu lịch sử:** Lưu trữ và tìm kiếm lịch sử hóa đơn giao dịch theo ngày/ca làm việc.

### 📊 4. Quản Lý (Manager Dashboard & Operations)
- **Biểu đồ thống kê doanh thu:** Thống kê doanh thu theo ngày, tuần, tháng với biểu đồ trực quan linh hoạt (`fl_chart`).
- **Phân tích món ăn bán chạy:** Báo cáo Top món ăn được yêu thích nhất để tối ưu kho nguyên liệu.
- **Quản lý thực đơn (CRUD):** Thêm món mới, cập nhật giá, chỉnh sửa danh mục hoặc ẩn món tạm hết hàng.

---

## 🛠️ Công Nghệ & Thư Viện Sử Dụng

| Hạng mục | Công nghệ / Thư viện | Mô tả |
| :--- | :--- | :--- |
| **Framework** | Flutter (Dart SDK `>=3.0.0 <4.0.0`) | Xây dựng giao diện ứng dụng đa nền tảng, tối ưu Landscape |
| **Backend & Database** | Firebase Core & Cloud Firestore | Lưu trữ dữ liệu và đồng bộ trạng thái Real-time |
| **State Management** | Provider | Quản lý trạng thái giỏ hàng & dữ liệu ứng dụng |
| **Data Visualization** | `fl_chart` | Vẽ biểu đồ doanh thu và báo cáo thống kê |
| **Report Export** | `pdf` & `printing` | Xuất và in hóa đơn thanh toán PDF |
| **UI Design System** | Custom Indochine Theme | Font chữ `Playfair Display`, phối màu vàng đồng & xanh rêu |

---

## 📂 Cấu Trúc Thư Mục (Project Structure)

```text
lib/
├── core/
│   ├── constants/       # Định nghĩa bảng màu (AppColors), kiểu chữ, hằng số UI
│   └── utils/           # Helper khởi tạo dữ liệu mẫu (DummyDataGenerator)
├── models/              # Data Models (FoodItem, Order, TableModel, User...)
├── providers/           # State Management (CartProvider, OrderProvider...)
├── screens/             # Màn hình chức năng phân theo vai trò
│   ├── auth/            # Màn hình Đăng nhập & Phân quyền truy cập
│   ├── cashier/         # Quản lý thu ngân, sơ đồ bàn & xuất hóa đơn
│   ├── chef/            # Màn hình KDS điều phối nhà bếp
│   ├── e-menu/          # Giao diện menu điện tử dành cho khách hàng
│   ├── manager/         # Dashboard báo cáo doanh thu & quản lý menu
│   └── welcome/         # Màn hình chào mừng & lựa chọn chế độ
├── services/            # Firebase Firestore Service & xử lý dữ liệu
├── widgets/             # Reusable UI Components (CartDialog, FoodCard, StatusBadge...)
└── main.dart            # Điểm khởi chạy ứng dụng (Entrypoint & Theme config)
```

---

## 🚀 Hướng Dẫn Cài Đặt & Chạy Ứng Dụng

### 📋 Yêu cầu tiên quyết
- đã cài đặt **Flutter SDK** (phiên bản `>= 3.0.0`).
- **Android Studio** hoặc **VS Code** (đã cài Flutter/Dart plugin).
- Thiết bị thật hoặc Emulator/Simulator hỗ trợ chế độ xoay ngang (Landscape).

### 🔧 Các bước thực hiện

1. **Clone repository về máy local:**
   ```bash
   git clone https://github.com/nguyenthingoctran221b-design/Nhom18_CT220H.git
   cd Nhom18_CT220H/UD_dat_mon_an
   ```

2. **Cài đặt các gói phụ thuộc (Dependencies):**
   ```bash
   flutter pub get
   ```

3. **Cấu hình Firebase:**
   - Dự án đã tích hợp file `lib/firebase_options.dart`.
   - Nếu sử dụng Firebase Project riêng, hãy chạy FlutterFire CLI để liên kết:
     ```bash
     flutterfire configure
     ```

4. **Khởi chạy ứng dụng:**
   ```bash
   flutter run
   ```

---

## 👥 Tác Giả & Đóng Góp (Credits & Contributors)

Dự án được thực hiện bởi nhóm sinh viên **Nhóm 18 — HP CT220H**:

* 👩‍💻 **Nguyễn Thị Ngọc Trân**
  - **MSSV:** B2303907
  - **Email:** `tranb2303907@student.ctu.edu.vn`
  - **Đơn vị:** Trường Công nghệ Thông tin & Truyền thông — Đại học Cần Thơ (CTU)
* 👨‍💻 **Thành viên đồng phát triển** — Nhóm 18 (CT220H - CTU)

---

## 📄 Giấy Phép (License)

Dự án này được phân phối dưới giấy phép **MIT License**. Bạn có thể tự do tham khảo, sử dụng hoặc phát triển thêm cho mục đích học tập và nghiên cứu.
