<%@LANGUAGE="VBSCRIPT" CODEPAGE="65001"%>
<% Response.CharSet = "UTF-8" %>
<!-- #include file="/BE/db/connect.asp" -->
<%
' Kiểm tra đăng nhập
If Session("UserID") = "" Or Not IsNumeric(Session("UserID")) Then
    Response.Redirect "login.asp"
    Response.End
End If

Dim userId : userId = CLng(Session("UserID"))

' Lấy thông tin user
Dim sqlUser, rsUser
sqlUser = "SELECT * FROM users WHERE id = " & userId
Set rsUser = conn.Execute(sqlUser)

If rsUser.EOF Then
    Response.Redirect "login.asp"
    Response.End
End If

Dim firstName, lastName, email, phone, address
firstName = rsUser("first_name")
lastName = rsUser("last_name")
email = rsUser("email")
phone = rsUser("phone_number")
address = rsUser("address")
rsUser.Close

' Lấy đơn hàng
Dim sqlOrders, rsOrders
Dim orderStatus : orderStatus = Request.QueryString("status")
If orderStatus = "" Then orderStatus = "all"

Select Case orderStatus
    Case "pending"
        sqlOrders = "SELECT * FROM Orders WHERE UserID = " & userId & " AND Status = 1 ORDER BY OrderDate DESC"
    Case "shipping"
        sqlOrders = "SELECT * FROM Orders WHERE UserID = " & userId & " AND Status = 2 ORDER BY OrderDate DESC"
    Case "completed"
        sqlOrders = "SELECT * FROM Orders WHERE UserID = " & userId & " AND Status = 3 ORDER BY OrderDate DESC"
    Case "cancelled"
        sqlOrders = "SELECT * FROM Orders WHERE UserID = " & userId & " AND Status = 0 ORDER BY OrderDate DESC"
    Case Else ' all
        sqlOrders = "SELECT * FROM Orders WHERE UserID = " & userId & " ORDER BY OrderDate DESC"
End Select

Set rsOrders = conn.Execute(sqlOrders)
%>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Tài khoản của bạn - TORANO</title>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/normalize/8.0.1/normalize.min.css">
    <link rel="stylesheet" href="../../assets/css/base.css">
    <link rel="stylesheet" href="../../assets/css/main.css">
    <link rel="stylesheet" href="../../assets/css/header-footer.css">
    <link rel="stylesheet" href="/assets/fonts/fontawesome-free-6.7.2-web/css/all.min.css">
    <style>

        .page-title {
            text-align: center;
            font-size: 28px;
            font-weight: 600;
            margin-bottom: 40px;
            position: relative;
            padding-bottom: 15px;
        }

        .page-title::after {
            content: '';
            position: absolute;
            bottom: 0;
            left: 50%;
            transform: translateX(-50%);
            width: 60px;
            height: 3px;
            background: #333;
        }

        .account-container {
            max-width: 1200px;
            margin: 0 auto;
            display: flex;
            gap: 30px;
        }

        /* Sidebar */
        .account-sidebar {
            flex: 0 0 250px;
            background: white;
            padding: 20px 0;
            border-radius: 8px;
            height: fit-content;
        }

        .sidebar-title {
            font-size: 16px;
            font-weight: 600;
            padding: 0 20px 15px;
            border-bottom: 1px solid #e0e0e0;
            text-transform: uppercase;
        }

        .sidebar-menu {
            list-style: none;
            padding: 10px 0;
        }

        .sidebar-item {
            padding: 12px 20px;
            cursor: pointer;
            transition: all 0.2s;
            display: flex;
            align-items: center;
            gap: 10px;
            color: #666;
            font-size: 1.4rem;
        }

        .sidebar-item:hover {
            background: #f5f5f5;
            color: #333;
        }

        .sidebar-item.active {
            background: #f0f0f0;
            color: #333;
            font-weight: 600;
            border-left: 3px solid #333;
        }

        /* Main Content */
        .account-content {
            flex: 1;
            background: white;
            padding: 30px;
            border-radius: 8px;
            min-height: 500px;
            font-size: 1.6rem;
        }

        .content-section {
            display: none;
        }

        .content-section.active {
            display: block;
        }

        .section-title {
            font-size: 20px;
            font-weight: 600;
            margin-bottom: 20px;
            padding-bottom: 10px;
            border-bottom: 2px solid #f0f0f0;
        }

        /* Profile Section */
        .info-grid {
            display: grid;
            gap: 15px;
            max-width: 600px;
        }

        .info-row {
            display: flex;
            padding: 12px 0;
            border-bottom: 1px solid #f0f0f0;
        }

        .info-label {
            flex: 0 0 150px;
            color: #666;
            font-weight: 500;
        }

        .info-value {
            flex: 1;
            color: #333;
        }

        .btn-view-address {
            display: inline-block;
            padding: 8px 20px;
            background: white;
            border: 1px solid #333;
            color: #333;
            text-decoration: none;
            border-radius: 4px;
            margin-top: 15px;
            transition: all 0.3s;
        }

        .btn-view-address:hover {
            background: #333;
            color: white;
        }

        /* Orders Section */
        .orders-tabs {
            display: flex;
            gap: 30px;
            border-bottom: 2px solid #f0f0f0;
            margin-bottom: 30px;
        }

        .order-tab {
            padding: 12px 0;
            cursor: pointer;
            color: #666;
            font-weight: 500;
            position: relative;
            transition: color 0.2s;
        }

        .order-tab:hover {
            color: #333;
        }

        .order-tab.active {
            color: #333;
            font-weight: 600;
        }

        .order-tab.active::after {
            content: '';
            position: absolute;
            bottom: -2px;
            left: 0;
            right: 0;
            height: 2px;
            background: #333;
        }

        /* Order Table */
        .orders-table {
            width: 100%;
            border-collapse: collapse;
        }

        .orders-table thead {
            background: #f9f9f9;
        }

        .orders-table th {
            padding: 15px;
            text-align: left;
            font-weight: 600;
            color: #333;
            border-bottom: 2px solid #e0e0e0;
        }

        .orders-table td {
            padding: 15px;
            border-bottom: 1px solid #f0f0f0;
            color: #666;
        }

        .orders-table tbody tr {
            cursor: pointer;
            transition: background 0.2s;
        }

        .orders-table tbody tr:hover {
            background: #fafafa;
        }

        .order-id {
            color: #333;
            font-weight: 600;
        }

        .order-amount {
            color: #333;
            font-weight: 600;
        }

        .order-status {
            display: inline-block;
            padding: 4px 12px;
            border-radius: 12px;
            font-size: 13px;
            font-weight: 500;
        }

        .status-pending {
            background: #fff3e0;
            color: #f57c00;
        }

        .status-shipping {
            background: #e3f2fd;
            color: #1976d2;
        }

        .status-completed {
            background: #e8f5e9;
            color: #388e3c;
        }

        .status-cancelled {
            background: #ffebee;
            color: #d32f2f;
        }

        .empty-message {
            text-align: center;
            padding: 60px 20px;
            color: #999;
        }

        /* Logout */
        .btn-logout {
            width: 100%;
            padding: 12px;
            background: #e53935;
            color: white;
            border: none;
            border-radius: 4px;
            font-size: 15px;
            font-weight: 600;
            cursor: pointer;
            transition: background 0.3s;
        }

        .btn-logout:hover {
            background: #c62828;
        }

        /* Responsive */
        @media (max-width: 768px) {
            .account-container {
                flex-direction: column;
            }

            .account-sidebar {
                flex: none;
            }

            .orders-table {
                font-size: 14px;
            }

            .orders-table th,
            .orders-table td {
                padding: 10px 8px;
            }
        }
        /* Password Form */
        .password-form {
            max-width: 500px;
        }

        .form-group-password {
            margin-bottom: 20px;
        }

        .form-group-password label {
            display: block;
            margin-bottom: 8px;
            font-weight: 500;
            color: #333;
        }

        .form-group-password input {
            width: 100%;
            padding: 10px 15px;
            border: 1px solid #e0e0e0;
            border-radius: 4px;
            font-size: 14px;
            transition: border-color 0.2s;
        }

        .form-group-password input:focus {
            outline: none;
            border-color: #333;
        }

        .form-group-password small {
            display: block;
            margin-top: 5px;
            font-size: 12px;
        }

        .form-actions {
            display: flex;
            gap: 15px;
            margin-top: 30px;
        }

        .btn-save-password {
            padding: 10px 30px;
            background: #333;
            color: white;
            border: none;
            border-radius: 4px;
            font-size: 14px;
            font-weight: 600;
            cursor: pointer;
            transition: background 0.3s;
        }

        .btn-save-password:hover {
            background: #000;
        }

        .btn-cancel-password {
            padding: 10px 30px;
            background: white;
            color: #666;
            border: 1px solid #e0e0e0;
            border-radius: 4px;
            font-size: 14px;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.3s;
        }

        .btn-cancel-password:hover {
            border-color: #333;
            color: #333;
        }

        .password-message {
            margin-top: 20px;
            padding: 12px 15px;
            border-radius: 4px;
            font-size: 14px;
            display: none;
        }

        .password-message.success {
            display: block;
            background: #e8f5e9;
            color: #2e7d32;
            border: 1px solid #a5d6a7;
        }

        .password-message.error {
            display: block;
            background: #ffebee;
            color: #c62828;
            border: 1px solid #ef9a9a;
        }
    </style>
</head>
<body>
    <div id="header"></div>

    <h1 class="page-title">Tài khoản của bạn</h1>

    <div class="account-container">
        <!-- Sidebar -->
        <div class="account-sidebar">
            <div class="sidebar-title">Tài khoản</div>
            <ul class="sidebar-menu">
                <li class="sidebar-item active" data-section="profile">
                    <span>○</span> Thông tin tài khoản
                </li>
                <li class="sidebar-item" data-section="password">
                    <span>○</span> Đổi mật khẩu
                </li>
                <li class="sidebar-item" data-section="orders">
                    <span>○</span> Đơn mua
                </li>
                <li class="sidebar-item" onclick="logout()">
                    <span>○</span> Đăng xuất
                </li>
            </ul>
        </div>

        <!-- Main Content -->
        <div class="account-content">
            <!-- Profile Section -->
            <div class="content-section active" id="profile">
                <h2 class="section-title">Thông tin tài khoản</h2>
                <div class="info-grid">
                    <div class="info-row">
                        <div class="info-label">Họ và tên:</div>
                        <div class="info-value"><%=firstName%> <%=lastName%></div>
                    </div>
                    <div class="info-row">
                        <div class="info-label">Email:</div>
                        <div class="info-value"><%=email%></div>
                    </div>
                    <div class="info-row">
                        <div class="info-label">Số điện thoại:</div>
                        <div class="info-value"><%=phone%></div>
                    </div>
                    <div class="info-row">
                        <div class="info-label">Quốc gia:</div>
                        <div class="info-value">Vietnam</div>
                    </div>
                    <div class="info-row">
                        <div class="info-label">Địa chỉ:</div>
                        <div class="info-value"><%=address%></div>
                    </div>
                </div>
            </div>

            <!-- Password Section -->
            <div class="content-section" id="password">
                <h2 class="section-title">Đổi mật khẩu</h2>
                <p style="color: #999; margin-bottom: 20px;">Để bảo mật tài khoản, vui lòng không chia sẻ mật khẩu cho người khác</p>

                <form id="changePasswordForm" class="password-form">
                    <div class="form-group-password">
                        <label for="currentPassword">Mật khẩu hiện tại <span style="color: red;">*</span></label>
                        <input type="password" id="currentPassword" required placeholder="Nhập mật khẩu hiện tại">
                    </div>

                    <div class="form-group-password">
                        <label for="newPassword">Mật khẩu mới <span style="color: red;">*</span></label>
                        <input type="password" id="newPassword" required placeholder="Nhập mật khẩu mới">
                        <small style="color: #999;">Mật khẩu phải có ít nhất 6 ký tự</small>
                    </div>

                    <div class="form-group-password">
                        <label for="confirmPassword">Xác nhận mật khẩu mới <span style="color: red;">*</span></label>
                        <input type="password" id="confirmPassword" required placeholder="Nhập lại mật khẩu mới">
                    </div>

                    <div class="form-actions">
                        <button type="submit" class="btn-save-password">Xác nhận</button>
                        <button type="button" class="btn-cancel-password" onclick="resetPasswordForm()">Hủy</button>
                    </div>
                </form>

                <div id="passwordMessage" class="password-message"></div>
            </div>


            <!-- Orders Section -->
            <div class="content-section" id="orders">
                <h2 class="section-title">Danh sách đơn hàng mới nhất</h2>

                <div class="orders-tabs">
                    <div class="order-tab <%If orderStatus = "all" Then%>active<%End If%>" 
                         onclick="filterOrders('all')">Tất cả</div>
                    <div class="order-tab <%If orderStatus = "pending" Then%>active<%End If%>" 
                         onclick="filterOrders('pending')">Chờ xử lý</div>
                    <div class="order-tab <%If orderStatus = "shipping" Then%>active<%End If%>" 
                         onclick="filterOrders('shipping')">Đang giao</div>
                    <div class="order-tab <%If orderStatus = "completed" Then%>active<%End If%>" 
                         onclick="filterOrders('completed')">Hoàn tất</div>
                    <div class="order-tab <%If orderStatus = "cancelled" Then%>active<%End If%>" 
                         onclick="filterOrders('cancelled')">Đã hủy</div>
                </div>

                <%
                If rsOrders.EOF Then
                %>
                    <div class="empty-message">Bạn chưa có đơn hàng nào</div>
                <%
                Else
                %>
                <table class="orders-table">
                    <thead>
                        <tr>
                            <th>Mã đơn hàng</th>
                            <th>Ngày đặt</th>
                            <th>Thành tiền</th>
                            <th>Trạng thái thanh toán</th>
                            <th>Vận chuyển</th>
                        </tr>
                    </thead>
                    <tbody>
                        <%
                        Do While Not rsOrders.EOF
                            Dim orderId, orderDate, finalAmount, status
                            orderId = rsOrders("OrderID")
                            orderDate = rsOrders("OrderDate")
                            finalAmount = rsOrders("FinalAmount")
                            status = rsOrders("Status")
                            
                            Dim statusText, statusClass
                            Select Case status
                                Case 1
                                    statusText = "Chờ xử lý"
                                    statusClass = "status-pending"
                                Case 2
                                    statusText = "Đang giao"
                                    statusClass = "status-shipping"
                                Case 3
                                    statusText = "Hoàn tất"
                                    statusClass = "status-completed"
                                Case 0
                                    statusText = "Đã hủy"
                                    statusClass = "status-cancelled"
                            End Select
                        %>
                        <tr onclick="viewOrderDetail(<%=orderId%>)">
                            <td class="order-id">#<%=orderId%></td>
                            <td><%=FormatDateTime(orderDate, 2)%></td>
                            <td class="order-amount"><%=FormatNumber(finalAmount, 0)%>₫</td>
                            <td><span class="order-status <%=statusClass%>"><%=statusText%></span></td>
                            <td><span class="order-status <%=statusClass%>"><%=statusText%></span></td>
                        </tr>
                        <%
                            rsOrders.MoveNext
                        Loop
                        %>
                    </tbody>
                </table>
                <%
                End If
                rsOrders.Close
                %>
            </div>
        </div>
    </div>

    <div id="footer"></div>

    <script>
        // Load header/footer
        async function loadComponent(id, file) {
            try {
                let res = await fetch(file);
                if(res.ok) document.getElementById(id).innerHTML = await res.text();
            } catch(e) { console.error(e); }
        }
        loadComponent("header", "../../FE/customer/component/header.asp");
        loadComponent("footer", "../../FE/customer/component/footer.html");

        // Sidebar navigation
        function showSection(sectionName) {
            // Update sidebar
            document.querySelectorAll('.sidebar-item').forEach(item => {
                item.classList.remove('active');
                if (item.getAttribute('data-section') === sectionName) {
                    item.classList.add('active');
                }
            });

            // Update content
            document.querySelectorAll('.content-section').forEach(section => {
                section.classList.remove('active');
            });
            document.getElementById(sectionName).classList.add('active');
        }

        document.querySelectorAll('.sidebar-item[data-section]').forEach(item => {
            item.addEventListener('click', function() {
                const section = this.getAttribute('data-section');
                showSection(section);
            });
        });

        // Filter orders
        function filterOrders(status) {
            window.location.href = 'account.asp?status=' + status + '#orders';
        }

        // View order detail
        function viewOrderDetail(orderId) {
            window.location.href = 'order-detail.asp?id=' + orderId;
        }

        // Logout
        function logout() {
            if (confirm('Bạn có chắc muốn đăng xuất?')) {
                window.location.href = 'logout.asp';
            }
        }

        // Auto scroll to orders if hash exists
        if (window.location.hash === '#orders') {
            showSection('orders');
        }
        // Change Password Form
        document.getElementById('changePasswordForm').addEventListener('submit', async function(e) {
            e.preventDefault();

            const currentPassword = document.getElementById('currentPassword').value;
            const newPassword = document.getElementById('newPassword').value;
            const confirmPassword = document.getElementById('confirmPassword').value;
            const messageBox = document.getElementById('passwordMessage');

            // Validation
            if (newPassword.length < 6) {
                showMessage('Mật khẩu mới phải có ít nhất 6 ký tự', 'error');
                return;
            }

            if (newPassword !== confirmPassword) {
                showMessage('Mật khẩu xác nhận không khớp', 'error');
                return;
            }

            if (currentPassword === newPassword) {
                showMessage('Mật khẩu mới phải khác mật khẩu hiện tại', 'error');
                return;
            }

            try {
                const params = new URLSearchParams(new FormData(this));

                params.append('current_password', currentPassword);
                params.append('new_password', newPassword);
                params.append('confirm_password', confirmPassword);

                const response = await fetch('/BE_FE/change-password.asp', {
                    method: "POST",
                    headers: {
                        "Content-Type": "application/x-www-form-urlencoded"
                    },
                    body: params.toString()
                });

                const result = await response.json();

                if (result.success) {
                    showMessage('Đổi mật khẩu thành công!', 'success');
                    resetPasswordForm();
                } else {
                    showMessage(result.message || 'Có lỗi xảy ra. Vui lòng thử lại.', 'error');
                }
            } catch (error) {
                console.error('Error:', error);
                showMessage('Không thể kết nối đến server. Vui lòng thử lại sau.', 'error');
            }
        });

        function showMessage(message, type) {
            const messageBox = document.getElementById('passwordMessage');

            messageBox.style.display = 'block'; // 🔥 BẬT LẠI
            messageBox.textContent = message;
            messageBox.className = 'password-message ' + type;

            if (type === 'success') {
                setTimeout(() => {
                    messageBox.style.display = 'none';
                }, 5000);
            }
        }

        function resetPasswordForm() {
            document.getElementById('changePasswordForm').reset();
        }
    </script>
    <script src="../../FE/js/header-footer.js"></script>
</body>
</html>
<%
conn.Close
Set conn = Nothing
%>