<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Quản Lý Tài Khoản</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: Arial, sans-serif;
            background-color: #f5f5f5;
            padding: 20px;
        }

        .container {
            max-width: 1200px;
            margin: 0 auto;
            display: flex;
            gap: 20px;
        }

        .sidebar {
            width: 250px;
            background: white;
            padding: 20px;
            border-radius: 8px;
            height: fit-content;
        }

        .sidebar-item {
            padding: 12px 15px;
            margin-bottom: 5px;
            cursor: pointer;
            border-radius: 5px;
            transition: all 0.3s;
        }

        .sidebar-item:hover {
            background-color: #fee;
            color: #e53935;
        }

        .sidebar-item.active {
            color: #e53935;
            font-weight: bold;
        }

        .sidebar-title {
            font-weight: bold;
            font-size: 16px;
            margin-bottom: 10px;
        }

        .sub-menu {
            margin-left: 15px;
        }

        .content {
            flex: 1;
            background: white;
            padding: 30px;
            border-radius: 8px;
        }

        .content-title {
            font-size: 24px;
            margin-bottom: 10px;
            border-bottom: 1px solid #eee;
            padding-bottom: 15px;
        }

        .profile-section {
            display: none;
        }

        .profile-section.active,
        .address-section.active,
        .orders-section.active {
            display: block;
        }

        .form-group {
            margin-bottom: 20px;
            display: flex;
            align-items: center;
        }

        .form-group label {
            width: 150px;
            font-weight: 500;
        }

        .form-group input {
            flex: 1;
            padding: 10px;
            border: 1px solid #ddd;
            border-radius: 4px;
            max-width: 500px;
        }

        .form-group select {
            padding: 10px;
            border: 1px solid #ddd;
            border-radius: 4px;
        }

        .avatar-section {
            display: flex;
            align-items: center;
            margin-bottom: 30px;
        }

        .avatar-img {
            width: 100px;
            height: 100px;
            border-radius: 50%;
            object-fit: cover;
            margin-right: 20px;
            border: 2px solid #ddd;
        }

        .btn-select-image {
            padding: 8px 16px;
            background-color: white;
            border: 1px solid #ddd;
            border-radius: 4px;
            cursor: pointer;
        }

        .btn-select-image:hover {
            background-color: #f5f5f5;
        }

        .btn-save {
            padding: 10px 30px;
            background-color: #e53935;
            color: white;
            border: none;
            border-radius: 4px;
            cursor: pointer;
            margin-top: 20px;
        }

        .btn-save:hover {
            background-color: #c62828;
        }

        .address-section {
            display: none;
        }

        .address-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 30px;
        }

        .btn-add-address {
            padding: 10px 20px;
            background-color: #e53935;
            color: white;
            border: none;
            border-radius: 4px;
            cursor: pointer;
        }

        .btn-add-address:hover {
            background-color: #c62828;
        }

        .address-item {
            border: 1px solid #ddd;
            padding: 20px;
            margin-bottom: 15px;
            border-radius: 8px;
        }

        .address-name {
            font-weight: bold;
            margin-bottom: 5px;
        }

        .address-phone {
            color: #666;
            margin-bottom: 10px;
        }

        .address-detail {
            color: #333;
            margin-bottom: 10px;
        }

        .address-badge {
            display: inline-block;
            padding: 3px 8px;
            border: 1px solid #e53935;
            color: #e53935;
            border-radius: 3px;
            font-size: 12px;
            margin-right: 10px;
        }

        .modal {
            display: none;
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background-color: rgba(0, 0, 0, 0.5);
            z-index: 1000;
            justify-content: center;
            align-items: center;
        }

        .modal.active {
            display: flex;
        }

        .modal-content {
            background: white;
            padding: 30px;
            border-radius: 8px;
            width: 90%;
            max-width: 600px;
        }

        .modal-title {
            font-size: 20px;
            margin-bottom: 20px;
        }

        .modal-form-group {
            margin-bottom: 15px;
        }

        .modal-form-group label {
            display: block;
            margin-bottom: 5px;
            font-weight: 500;
        }

        .modal-form-group input,
        .modal-form-group select,
        .modal-form-group textarea {
            width: 100%;
            padding: 10px;
            border: 1px solid #ddd;
            border-radius: 4px;
        }

        .modal-buttons {
            display: flex;
            justify-content: flex-end;
            gap: 10px;
            margin-top: 20px;
        }

        .btn-cancel {
            padding: 10px 20px;
            background-color: white;
            border: 1px solid #ddd;
            border-radius: 4px;
            cursor: pointer;
        }

        .btn-submit {
            padding: 10px 20px;
            background-color: #e53935;
            color: white;
            border: none;
            border-radius: 4px;
            cursor: pointer;
        }

        .orders-section {
            display: none;
        }

        .order-tabs {
            display: flex;
            border-bottom: 2px solid #eee;
            margin-bottom: 20px;
        }

        .order-tab {
            padding: 15px 30px;
            cursor: pointer;
            border-bottom: 2px solid transparent;
            margin-bottom: -2px;
            transition: all 0.3s;
        }

        .order-tab:hover {
            color: #e53935;
        }

        .order-tab.active {
            color: #e53935;
            border-bottom-color: #e53935;
        }

        .order-content {
            display: none;
        }

        .order-content.active {
            display: block;
        }

        .order-item {
            border: 1px solid #ddd;
            padding: 20px;
            margin-bottom: 15px;
            border-radius: 8px;
        }

        .order-header {
            display: flex;
            justify-content: space-between;
            margin-bottom: 15px;
            padding-bottom: 10px;
            border-bottom: 1px solid #eee;
        }

        .order-status {
            color: #e53935;
            font-weight: bold;
        }

        .order-product {
            display: flex;
            gap: 15px;
            margin-bottom: 15px;
        }

        .order-product img {
            width: 80px;
            height: 80px;
            object-fit: cover;
            border: 1px solid #ddd;
            border-radius: 4px;
        }

        .order-product-info {
            flex: 1;
        }

        .order-product-name {
            font-weight: 500;
            margin-bottom: 5px;
        }

        .order-product-variant {
            color: #666;
            font-size: 14px;
            margin-bottom: 5px;
        }

        .order-product-price {
            font-weight: bold;
        }

        .order-total {
            text-align: right;
            font-size: 18px;
            margin-top: 15px;
            padding-top: 15px;
            border-top: 1px solid #eee;
        }

        .empty-message {
            text-align: center;
            padding: 50px;
            color: #666;
        }
    </style>
</head>
<body>
    <div class="container">
        <!-- Sidebar -->
        <div class="sidebar">
            <div class="sidebar-title">Tài Khoản Của Tôi</div>
            <div class="sub-menu">
                <div class="sidebar-item active" data-section="profile">Hồ Sơ</div>
                <div class="sidebar-item" data-section="address">Địa Chỉ</div>
                <div class="sidebar-item" data-section="password">Đổi Mật Khẩu</div>
            </div>
            <div class="sidebar-item" data-section="orders">Đơn Mua</div>
        </div>

        <!-- Main Content -->
        <div class="content">
            <!-- Profile Section -->
            <div class="profile-section active" id="profile">
                <h2 class="content-title">Hồ Sơ Của Tôi</h2>
                <p style="color: #666; margin-bottom: 30px;">Quản lý thông tin hồ sơ để bảo mật tài khoản</p>

                <div class="avatar-section">
                    <img src="https://via.placeholder.com/100" alt="Avatar" class="avatar-img" id="avatarPreview">
                    <div>
                        <input type="file" id="avatarInput" accept="image/*" style="display: none;">
                        <button class="btn-select-image" onclick="document.getElementById('avatarInput').click()">Chọn Ảnh</button>
                        <p style="color: #999; font-size: 12px; margin-top: 10px;">Dung lượng file tối đa 1 MB<br>Định dạng: .JPEG, .PNG</p>
                    </div>
                </div>

                <div class="form-group">
                    <label>Tên đăng nhập</label>
                    <input type="text" value="do.anh205" disabled>
                </div>

                <div class="form-group">
                    <label>Tên</label>
                    <input type="text" value="jasmineiz" id="userName">
                </div>

                <div class="form-group">
                    <label>Email</label>
                    <input type="email" value="ng***********@gmail.com">
                    <button class="btn-select-image" style="margin-left: 10px;">Thay Đổi</button>
                </div>

                <div class="form-group">
                    <label>Số điện thoại</label>
                    <input type="text" value="*********06">
                    <button class="btn-select-image" style="margin-left: 10px;">Thay Đổi</button>
                </div>

                <div class="form-group">
                    <label>Giới tính</label>
                    <div>
                        <input type="radio" name="gender" value="male"> Nam
                        <input type="radio" name="gender" value="female" checked style="margin-left: 20px;"> Nữ
                        <input type="radio" name="gender" value="other" style="margin-left: 20px;"> Khác
                    </div>
                </div>

                <div class="form-group">
                    <label>Ngày sinh</label>
                    <input type="text" value="**//**/1994">
                    <button class="btn-select-image" style="margin-left: 10px;">Thay Đổi</button>
                </div>

                <button class="btn-save">Lưu</button>
            </div>

            <!-- Address Section -->
            <div class="address-section" id="address">
                <div class="address-header">
                    <h2 class="content-title" style="margin: 0;">Địa chỉ của tôi</h2>
                    <button class="btn-add-address" onclick="openAddressModal()">+ Thêm địa chỉ mới</button>
                </div>

                <h3 style="margin-bottom: 15px;">Địa chỉ</h3>
                <div id="addressList">
                    <div class="address-item">
                        <div class="address-name">Đỗ Ánh | (+84) 357 474 306</div>
                        <div class="address-detail">Nhà số 17, ngách 99/187, thôn yên kiện<br>Xã Ngọc Hồi, Huyện Thanh Trì, Hà Nội</div>
                        <span class="address-badge">Mặc định</span>
                    </div>

                    <div class="address-item">
                        <div class="address-name">Đỗ Thị Hồng | (+84) 387 787 238</div>
                        <div class="address-detail">Công Ty Minh Phú Kho Đại La, Số 03, Đường Phan Trọng Tuệ<br>Xã Tam Hiệp, Huyện Thanh Trì, Hà Nội</div>
                        <span class="address-badge">Địa chỉ lấy hàng</span>
                    </div>

                    <div class="address-item">
                        <div class="address-name">Đỗ Mừng | (+84) 975 741 897</div>
                        <div class="address-detail">Số 15 Ngách 18 Ngõ 47 Khúc Thừa Dụ<br>Phường Vĩnh Niệm, Quận Lê Chân, Hải Phòng</div>
                    </div>

                    <div class="address-item">
                        <div class="address-name">Gỗ Bảo | (+84) 862 850 205</div>
                        <div class="address-detail">Số 7, Ngõ 76 Văn Hồ 3<br>Phường Lê Đại Hành, Quận Hai Bà Trưng, Hà Nội</div>
                    </div>
                </div>
            </div>

            <!-- Orders Section -->
            <div class="orders-section" id="orders">
                <h2 class="content-title">Đơn Mua</h2>
                
                <div class="order-tabs">
                    <div class="order-tab active" data-tab="all">Tất cả</div>
                    <div class="order-tab" data-tab="pending">Chờ xác nhận</div>
                    <div class="order-tab" data-tab="shipping">Chờ giao hàng</div>
                    <div class="order-tab" data-tab="completed">Hoàn thành</div>
                    <div class="order-tab" data-tab="cancelled">Đã hủy</div>
                </div>

                <div class="order-content active" id="all">
                    <!-- All orders will show here -->
                </div>

                <div class="order-content" id="pending">
                    <div class="order-item">
                        <div class="order-header">
                            <div class="order-status">🚚 Chờ xác nhận</div>
                        </div>
                        <div class="order-product">
                            <img src="https://via.placeholder.com/80" alt="Product">
                            <div class="order-product-info">
                                <div class="order-product-name">Áo Sơ Mi Hoa Cổ Đức Cộc Tay Classic</div>
                                <div class="order-product-variant">Xám Nhạt - L</div>
                                <div class="order-product-price">399,000đ x1</div>
                            </div>
                        </div>
                        <div class="order-total">Tổng tiền: <span style="color: #e53935;">399,000đ</span></div>
                    </div>

                    <div class="order-item">
                        <div class="order-header">
                            <div class="order-status">🚚 Chờ xác nhận</div>
                        </div>
                        <div class="order-product">
                            <img src="https://via.placeholder.com/80" alt="Product">
                            <div class="order-product-info">
                                <div class="order-product-name">Quần Kaki Straight Cotton</div>
                                <div class="order-product-variant">Ghi - M</div>
                                <div class="order-product-price">549,000đ x1</div>
                            </div>
                        </div>
                        <div class="order-total">Tổng tiền: <span style="color: #e53935;">549,000đ</span></div>
                    </div>
                </div>

                <div class="order-content" id="shipping">
                    <div class="empty-message">Bạn chưa có đơn hàng nào cần mua sắm</div>
                </div>

                <div class="order-content" id="completed">
                    <div class="order-item">
                        <div class="order-header">
                            <div class="order-status">✅ Giao hàng thành công</div>
                        </div>
                        <div class="order-product">
                            <img src="https://via.placeholder.com/80" alt="Product">
                            <div class="order-product-info">
                                <div class="order-product-name">Áo Sơ Mi Hoa Cổ Đức Cộc Tay Classic</div>
                                <div class="order-product-variant">Ghi - M</div>
                                <div class="order-product-price">349,000đ x1</div>
                            </div>
                        </div>
                        <div class="order-total">Tổng tiền: <span style="color: #e53935;">399,000đ</span></div>
                    </div>
                </div>

                <div class="order-content" id="cancelled">
                    <div class="empty-message">Bạn chưa có đơn hàng bị hủy</div>
                </div>
            </div>
        </div>
    </div>

    <!-- Modal Add Address -->
    <div class="modal" id="addressModal">
        <div class="modal-content">
            <h3 class="modal-title">Địa chỉ mới (dùng thông tin trước sắp nhập)</h3>
            
            <div class="modal-form-group">
                <label>Họ và tên</label>
                <input type="text" id="newAddressName" placeholder="Họ và tên">
            </div>

            <div class="modal-form-group">
                <label>Số điện thoại</label>
                <input type="text" id="newAddressPhone" placeholder="Số điện thoại">
            </div>

            <div class="modal-form-group">
                <label>Tỉnh/ Thành phố, Quận/Huyện, Phường/Xã</label>
                <select id="newAddressCity">
                    <option value="">Chọn tỉnh/thành phố</option>
                    <option value="hanoi">Hà Nội</option>
                    <option value="hcm">Hồ Chí Minh</option>
                    <option value="haiphong">Hải Phòng</option>
                </select>
            </div>

            <div class="modal-form-group">
                <label>Địa chỉ cụ thể</label>
                <textarea id="newAddressDetail" rows="3" placeholder="Địa chỉ cụ thể"></textarea>
            </div>

            <div class="modal-buttons">
                <button class="btn-cancel" onclick="closeAddressModal()">Trở Lại</button>
                <button class="btn-submit" onclick="addNewAddress()">Hoàn thành</button>
            </div>
        </div>
    </div>

    <script>
        // Sidebar navigation
        document.querySelectorAll('.sidebar-item').forEach(item => {
            item.addEventListener('click', function() {
                // Remove active class from all items
                document.querySelectorAll('.sidebar-item').forEach(i => i.classList.remove('active'));
                this.classList.add('active');

                // Hide all sections
                document.querySelectorAll('.profile-section, .address-section, .orders-section').forEach(section => {
                    section.classList.remove('active');
                });

                // Show selected section
                const section = this.getAttribute('data-section');
                document.getElementById(section).classList.add('active');
            });
        });

        // Avatar upload
        document.getElementById('avatarInput').addEventListener('change', function(e) {
            const file = e.target.files[0];
            if (file) {
                const reader = new FileReader();
                reader.onload = function(e) {
                    document.getElementById('avatarPreview').src = e.target.result;
                };
                reader.readAsDataURL(file);
            }
        });

        // Address Modal
        function openAddressModal() {
            document.getElementById('addressModal').classList.add('active');
        }

        function closeAddressModal() {
            document.getElementById('addressModal').classList.remove('active');
        }

        function addNewAddress() {
            const name = document.getElementById('newAddressName').value;
            const phone = document.getElementById('newAddressPhone').value;
            const city = document.getElementById('newAddressCity').value;
            const detail = document.getElementById('newAddressDetail').value;

            if (!name || !phone || !city || !detail) {
                alert('Vui lòng điền đầy đủ thông tin');
                return;
            }

            const addressList = document.getElementById('addressList');
            const newAddress = document.createElement('div');
            newAddress.className = 'address-item';
            newAddress.innerHTML = `
                <div class="address-name">${name} | ${phone}</div>
                <div class="address-detail">${detail}<br>${city}</div>
            `;
            addressList.appendChild(newAddress);

            // Clear form
            document.getElementById('newAddressName').value = '';
            document.getElementById('newAddressPhone').value = '';
            document.getElementById('newAddressCity').value = '';
            document.getElementById('newAddressDetail').value = '';

            closeAddressModal();
        }

        // Order tabs
        document.querySelectorAll('.order-tab').forEach(tab => {
            tab.addEventListener('click', function() {
                // Remove active class from all tabs
                document.querySelectorAll('.order-tab').forEach(t => t.classList.remove('active'));
                this.classList.add('active');

                // Hide all order contents
                document.querySelectorAll('.order-content').forEach(content => {
                    content.classList.remove('active');
                });

                // Show selected content
                const tabName = this.getAttribute('data-tab');
                document.getElementById(tabName).classList.add('active');
            });
        });

        // Populate "All" tab with all orders on page load
        window.addEventListener('DOMContentLoaded', function() {
            const allTab = document.getElementById('all');
            const pending = document.getElementById('pending').innerHTML;
            const completed = document.getElementById('completed').innerHTML;
            allTab.innerHTML = pending + completed;
        });
    </script>
</body>
</html>