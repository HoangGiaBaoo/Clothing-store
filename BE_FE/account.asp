<%@LANGUAGE="VBSCRIPT" CODEPAGE="65001"%>
<% Response.CharSet = "UTF-8" %>
<!-- #include file="/BE/db/connect.asp" -->
<%
' Bật Error Handling
On Error Resume Next

' Kiểm tra đăng nhập
If Session("UserID") = "" Or Not IsNumeric(Session("UserID")) Then
    If Not conn Is Nothing Then
        If conn.State = 1 Then conn.Close
        Set conn = Nothing
    End If
    Response.Redirect "login.asp"
    Response.End
End If

Dim userId : userId = CLng(Session("UserID"))

' XỬ LÝ CẬP NHẬT THÔNG TIN
If Request.ServerVariables("REQUEST_METHOD") = "POST" And Request.QueryString("action") = "update_profile" Then
    Dim updFirstName, updLastName, updPhone, updAddress
    updFirstName = Trim(Request.Form("first_name"))
    updLastName = Trim(Request.Form("last_name"))
    updPhone = Trim(Request.Form("phone"))
    updAddress = Trim(Request.Form("address"))
    
    ' Validate
    Dim errorMsg : errorMsg = ""
    If updFirstName = "" Then errorMsg = "Vui lòng nhập họ"
    If updLastName = "" Then errorMsg = "Vui lòng nhập tên"
    If updPhone = "" Then errorMsg = "Vui lòng nhập số điện thoại"
    
    If errorMsg = "" Then
        ' Cập nhật database
        Dim sqlUpdate
        sqlUpdate = "UPDATE users SET " & _
                   "first_name = N'" & Replace(updFirstName, "'", "''") & "', " & _
                   "last_name = N'" & Replace(updLastName, "'", "''") & "', " & _
                   "phone_number = '" & Replace(updPhone, "'", "''") & "', " & _
                   "address = N'" & Replace(updAddress, "'", "''") & "' " & _
                   "WHERE id = " & userId
        
        conn.Execute sqlUpdate
        Session("FullName")= updFirstName & " " & updLastName
        If Err.Number = 0 Then
            Response.Redirect "account.asp?msg=updated"
        Else
            Response.Redirect "account.asp?msg=error"
        End If
        Response.End
    End If
End If

' Lấy thông tin user
Dim sqlUser, rsUser
sqlUser = "SELECT * FROM users WHERE id = " & userId
Set rsUser = conn.Execute(sqlUser)

If rsUser.EOF Then
    rsUser.Close
    Set rsUser = Nothing
    If Not conn Is Nothing Then
        If conn.State = 1 Then conn.Close
        Set conn = Nothing
    End If
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
Set rsUser = Nothing

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
            min-height: 450px;
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

        /* Success/Error Messages */
        .alert-message {
            padding: 15px 20px;
            border-radius: 6px;
            margin-bottom: 25px;
            display: flex;
            align-items: center;
            gap: 12px;
            font-size: 1.4rem;
            animation: slideDown 0.3s;
        }

        @keyframes slideDown {
            from {
                opacity: 0;
                transform: translateY(-20px);
            }
            to {
                opacity: 1;
                transform: translateY(0);
            }
        }

        .alert-success {
            background: #e8f5e9;
            color: #2e7d32;
            border-left: 4px solid #4caf50;
        }

        .alert-error {
            background: #ffebee;
            color: #c62828;
            border-left: 4px solid #f44336;
        }

        /* Profile Section */
        .profile-view {
            max-width: 700px;
        }

        .profile-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 25px;
        }

        .btn-edit-profile {
            padding: 10px 25px;
            background: white;
            border: 2px solid #333;
            color: #333;
            border-radius: 6px;
            font-size: 1.4rem;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.3s;
            display: inline-flex;
            align-items: center;
            gap: 8px;
        }

        .btn-edit-profile:hover {
            background: #333;
            color: white;
        }

        .info-grid {
            display: grid;
            gap: 15px;
        }

        .info-row {
            display: flex;
            padding: 15px 0;
            border-bottom: 1px solid #f0f0f0;
        }

        .info-row:last-child {
            border-bottom: none;
        }

        .info-label {
            flex: 0 0 180px;
            color: #666;
            font-weight: 500;
            font-size: 1.4rem;
        }

        .info-value {
            flex: 1;
            color: #333;
            font-size: 1.5rem;
        }

        /* Profile Edit Form */
        .profile-form {
            max-width: 700px;
            display: none;
        }

        .profile-form.active {
            display: block;
        }

        .form-group {
            margin-bottom: 20px;
        }

        .form-group label {
            display: block;
            margin-bottom: 8px;
            font-weight: 600;
            color: #333;
            font-size: 1.4rem;
        }

        .form-group label span.required {
            color: #e53935;
        }

        .form-group input,
        .form-group textarea {
            width: 100%;
            padding: 12px 15px;
            border: 2px solid #e0e0e0;
            border-radius: 6px;
            font-size: 1.4rem;
            font-family: inherit;
            transition: border-color 0.3s;
        }

        .form-group input:focus,
        .form-group textarea:focus {
            outline: none;
            border-color: #333;
        }

        .form-group input:disabled {
            background: #f5f5f5;
            cursor: not-allowed;
            color: #999;
        }

        .form-group textarea {
            resize: vertical;
            min-height: 80px;
        }

        .form-group small {
            display: block;
            margin-top: 5px;
            font-size: 1.2rem;
            color: #999;
        }

        .form-actions {
            display: flex;
            gap: 15px;
            margin-top: 30px;
            padding-top: 20px;
            border-top: 2px solid #f0f0f0;
        }

        .btn-save {
            padding: 12px 35px;
            background: #333;
            color: white;
            border: none;
            border-radius: 6px;
            font-size: 1.5rem;
            font-weight: 600;
            cursor: pointer;
            transition: background 0.3s;
            display: inline-flex;
            align-items: center;
            gap: 8px;
        }

        .btn-save:hover {
            background: #000;
        }

        .btn-cancel {
            padding: 12px 35px;
            background: white;
            color: #666;
            border: 2px solid #e0e0e0;
            border-radius: 6px;
            font-size: 1.5rem;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.3s;
        }

        .btn-cancel:hover {
            border-color: #333;
            color: #333;
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

        /* Responsive */
        @media (max-width: 768px) {
            .account-container {
                flex-direction: column;
            }

            .account-sidebar {
                flex: none;
            }

            .profile-header {
                flex-direction: column;
                align-items: flex-start;
                gap: 15px;
            }

            .info-row {
                flex-direction: column;
                gap: 5px;
            }

            .info-label {
                flex: none;
            }

            .form-actions {
                flex-direction: column;
            }

            .btn-save,
            .btn-cancel {
                width: 100%;
                justify-content: center;
            }

            .orders-table {
                font-size: 14px;
            }

            .orders-table th,
            .orders-table td {
                padding: 10px 8px;
            }
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

                <%If Request.QueryString("msg") = "updated" Then%>
                <div class="alert-message alert-success">
                    <i class="fas fa-check-circle"></i>
                    <span>Cập nhật thông tin thành công!</span>
                </div>
                <%ElseIf Request.QueryString("msg") = "error" Then%>
                <div class="alert-message alert-error">
                    <i class="fas fa-exclamation-circle"></i>
                    <span>Có lỗi xảy ra. Vui lòng thử lại!</span>
                </div>
                <%End If%>

                <!-- Profile View Mode -->
                <div class="profile-view" id="profileView">
                    <div class="info-grid">
                        <div class="info-row">
                            <div class="info-label">Họ:</div>
                            <div class="info-value"><%=firstName%></div>
                        </div>
                        <div class="info-row">
                            <div class="info-label">Tên:</div>
                            <div class="info-value"><%=lastName%></div>
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
                            <div class="info-label">Địa chỉ:</div>
                            <div class="info-value"><%=address%></div>
                        </div>
                    </div>
                    <div class="profile-header">
                        <div></div>
                        <button class="btn-edit-profile" onclick="enableEditMode()">
                            <i class="fas fa-edit"></i>
                            <span>Chỉnh sửa</span>
                        </button>
                    </div>
                </div>

                <!-- Profile Edit Form -->
                <form class="profile-form" id="profileForm" method="POST" action="account.asp?action=update_profile">
                    <div class="form-group">
                        <label for="first_name">
                            Họ <span class="required">*</span>
                        </label>
                        <input type="text" id="first_name" name="first_name" value="<%=firstName%>" required placeholder="Nhập họ">
                    </div>

                    <div class="form-group">
                        <label for="last_name">
                            Tên <span class="required">*</span>
                        </label>
                        <input type="text" id="last_name" name="last_name" value="<%=lastName%>" required placeholder="Nhập tên">
                    </div>

                    <div class="form-group">
                        <label for="email">
                            Email
                        </label>
                        <input type="email" id="email" value="<%=email%>" disabled>
                        <small>Email không thể thay đổi</small>
                    </div>

                    <div class="form-group">
                        <label for="phone">
                            Số điện thoại <span class="required">*</span>
                        </label>
                        <input type="tel" id="phone" name="phone" value="<%=phone%>" required placeholder="Nhập số điện thoại">
                    </div>

                    <div class="form-group">
                        <label for="address">
                            Địa chỉ
                        </label>
                        <textarea id="address" name="address" placeholder="Nhập địa chỉ"><%=address%></textarea>
                    </div>

                    <div class="form-actions">
                        <button type="submit" class="btn-save">
                            <i class="fas fa-save"></i>
                            <span>Lưu thay đổi</span>
                        </button>
                        <button type="button" class="btn-cancel" onclick="cancelEditMode()">
                            <i class="fas fa-times"></i>
                            <span>Hủy</span>
                        </button>
                    </div>
                </form>
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
                            <th>Trạng thái đơn hàng</th>
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
                Set rsOrders = Nothing
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
            document.querySelectorAll('.sidebar-item').forEach(item => {
                item.classList.remove('active');
                if (item.getAttribute('data-section') === sectionName) {
                    item.classList.add('active');
                }
            });

            document.querySelectorAll('.content-section').forEach(section => {
                section.classList.remove('active');
            });
            document.getElementById(sectionName).classList.add('active');
            
            // Reset edit mode when switching sections
            if (sectionName !== 'profile') {
                cancelEditMode();
            }
        }

        document.querySelectorAll('.sidebar-item[data-section]').forEach(item => {
            item.addEventListener('click', function() {
                const section = this.getAttribute('data-section');
                showSection(section);
            });
        });

        // Profile Edit Functions
        function enableEditMode() {
            document.getElementById('profileView').style.display = 'none';
            document.getElementById('profileForm').classList.add('active');
        }

        function cancelEditMode() {
            document.getElementById('profileView').style.display = 'block';
            document.getElementById('profileForm').classList.remove('active');
            // Reset form to original values
            document.getElementById('profileForm').reset();
        }

        // Form validation before submit
        document.getElementById('profileForm').addEventListener('submit', function(e) {
            const firstName = document.getElementById('first_name').value.trim();
            const lastName = document.getElementById('last_name').value.trim();
            const phone = document.getElementById('phone').value.trim();

            if (firstName === '' || lastName === '' || phone === '') {
                e.preventDefault();
                alert('Vui lòng điền đầy đủ thông tin bắt buộc!');
                return false;
            }

            // Validate phone number (basic)
            const phoneRegex = /^[0-9]{10,11}$/;
            if (!phoneRegex.test(phone)) {
                e.preventDefault();
                alert('Số điện thoại không hợp lệ! Vui lòng nhập 10-11 chữ số.');
                return false;
            }

            return true;
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
                const params = new URLSearchParams();
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
            messageBox.style.display = 'block';
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
            const messageBox = document.getElementById('passwordMessage');
            messageBox.style.display = 'none';
        }

        // Auto hide success/error messages after 5 seconds
        window.addEventListener('DOMContentLoaded', function() {
            const alerts = document.querySelectorAll('.alert-message');
            alerts.forEach(alert => {
                setTimeout(function() {
                    alert.style.opacity = '0';
                    alert.style.transition = 'opacity 0.5s';
                    setTimeout(function() {
                        alert.style.display = 'none';
                    }, 500);
                }, 5000);
            });
        });
    </script>
    <script src="../../FE/js/header-footer.js"></script>
</body>
</html>
<%
' Clean up - Đóng connection
If Not conn Is Nothing Then
    If conn.State = 1 Then conn.Close
    Set conn = Nothing
End If
%>