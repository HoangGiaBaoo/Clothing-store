<%@LANGUAGE="VBSCRIPT" CODEPAGE="65001"%>
<!--#include file="/BE/db/connect.asp" -->
<%
' 1. Cấu hình Tiếng Việt & Bộ đệm
Response.Buffer = True
Session.CodePage = 65001
Response.CharSet = "UTF-8"
%>

<%
' --- BIẾN LƯU THÔNG BÁO ---
Dim errorMsg
errorMsg = ""

' --- XỬ LÝ KHI NGƯỜI DÙNG BẤM POST ---
If Request.ServerVariables("REQUEST_METHOD") = "POST" Then
    
    Dim email, pass
    ' Lấy dữ liệu từ Form (dựa theo name="...")
    email = Trim(Request.Form("txtEmail"))
    pass  = Trim(Request.Form("txtPass"))

    ' 1. Validate
    If email = "" Or pass = "" Then
        errorMsg = "Vui lòng nhập đầy đủ thông tin!"
    Else
        ' 2. Làm sạch dữ liệu (Chống SQL Injection đơn giản)
        email = Replace(email, "'", "''")
        pass  = Replace(pass, "'", "''")

        ' 3. Truy vấn Database
        Dim sql, rsUser
        ' Lưu ý: Password là NVARCHAR nên so sánh trực tiếp
        sql = "SELECT id, email, password, role, first_name, last_name FROM Users WHERE email = N'" & email & "' AND password = N'" & pass & "'"
        
        Set rsUser = conn.Execute(sql)

        If Not rsUser.EOF Then
            ' === ĐĂNG NHẬP THÀNH CÔNG ===
            
            ' A. Lưu Session quan trọng
            Session("UserID")    = rsUser("id")          ' Mapping: id trong DB -> UserID trong Session
            Session("UserEmail") = rsUser("email")
            Session("FullName")  = rsUser("last_name") & " " & rsUser("first_name")
            Session("Role")      = rsUser("role")        ' Lưu role để dùng sau này

            ' B. LOGIC GỘP GIỎ HÀNG (QUAN TRỌNG)
            ' Chuyển giỏ hàng của khách vãng lai (SessionID cũ) sang cho UserID này
            Dim oldSessionID
            oldSessionID = Session.SessionID
            
            If oldSessionID <> "" Then
                ' Cập nhật bảng Cart: Đổi chủ sở hữu từ SessionID trình duyệt -> UserID
                conn.Execute "UPDATE Cart SET SessionID = '" & Session("UserID") & "' WHERE SessionID = '" & oldSessionID & "'"
            End If

            ' C. Kiểm tra Role và Chuyển hướng
            Dim role
            role = LCase(rsUser("role")) ' Chuyển về chữ thường để so sánh cho chắc chắn

            ' Dọn dẹp đối tượng kết nối
            rsUser.Close
            Set rsUser = Nothing
            conn.Close

            If role = "customer" Then
                Response.Redirect "index.asp"
            ElseIf role = "admin" Then
                Response.Redirect "admin/dashboard.asp" ' Ví dụ nếu có trang admin
            Else
                ' Các role khác (hoặc mặc định) cũng về trang chủ
                Response.Redirect "index.asp"
            End If
            
        Else
            ' === ĐĂNG NHẬP THẤT BẠI ===
            errorMsg = "Email hoặc mật khẩu không chính xác!"
            rsUser.Close
            Set rsUser = Nothing
        End If
    End If
End If
%>

<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Đăng nhập - TORANO</title>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/normalize/8.0.1/normalize.min.css">
    
    <link rel="stylesheet" href="../../assets/css/base.css">
    <link rel="stylesheet" href="../../assets/css/main.css">
    <link rel="stylesheet" href="../../assets/css/header-footer.css">
    <link rel="stylesheet" href="../../assets/css/login.css">
    
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link rel="stylesheet" href="/assets/fonts/fontawesome-free-6.7.2-web/css/all.min.css">
    <link href="https://fonts.googleapis.com/css2?family=Roboto:ital,wght@0,100..900;1,100..900&display=swap" rel="stylesheet">
    
    <style>
        /* CSS nhỏ để hiển thị lỗi đẹp hơn */
        .error-message {
            background-color: #ffe6e6;
            color: #d63031;
            padding: 10px;
            margin-bottom: 15px;
            border: 1px solid #ffcccc;
            border-radius: 4px;
            text-align: center;
            font-size: 14px;
        }
    </style>
</head>
<body>
    <div class="app">
        <div id="header"></div>
        
        <div class="body">
            <div class="container">
                <div class="form-wrapper">
                    <div class="tabs">
                        <div class="tab active">Đăng nhập</div>
                        <div class="tab-divider">|</div>
                        <div class="tab"><a href="register.asp" style="text-decoration:none; color:#333;">Đăng ký</a></div>
                    </div>

                    <form class="form" id="loginForm" method="POST" action="login.asp">
                        
                        <% If errorMsg <> "" Then %>
                            <div class="error-message">
                                <i class="fas fa-exclamation-triangle"></i> <%=errorMsg%>
                            </div>
                        <% End If %>

                        <input type="email" name="txtEmail" placeholder="Vui lòng nhập email của bạn" required value="<%=Request.Form("txtEmail")%>">
                        
                        <input type="password" name="txtPass" placeholder="Vui lòng nhập mật khẩu" required>
                        
                        <div class="recaptcha-notice">
                            This site is protected by reCAPTCHA and the Google 
                            <a href="#">Privacy Policy</a> and 
                            <a href="#">Terms of Service</a> apply.
                        </div>

                        <div class="form-footer">
                            <button type="submit" class="btn-submit">ĐĂNG NHẬP</button>
                            <div class="links">
                                <p>Bạn chưa có tài khoản? <a href="register.asp">Đăng ký</a></p>
                                <p>Bạn quên mật khẩu? <a href="#">Quên mật khẩu?</a></p>
                            </div>
                        </div>
                    </form>
                    </div>
            </div>
        </div>

        <div id="footer"></div>
    </div>

    <script>
        async function loadComponent(id, file) {
            try {
                let response = await fetch(file);
                if (response.ok) {
                    document.getElementById(id).innerHTML = await response.text();
                }
            } catch (e) { console.error("Error loading component:", e); }
        }
        // Kiểm tra lại đường dẫn Header/Footer của bạn
        loadComponent("header", "../FE/customer/component/header.html");
        loadComponent("footer", "../FE/customer/component/footer.html");
    </script>
    <script src="../../FE/js/header-footer.js"></script>
</body>
</html>