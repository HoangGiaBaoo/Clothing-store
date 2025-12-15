<%@LANGUAGE="VBSCRIPT" CODEPAGE="65001"%>
<%
' 1. Cấu hình Tiếng Việt & Bộ đệm (Phải đặt đầu tiên)
Response.Buffer = True

%>
<!-- #include file="/BE/db/connect.asp" -->
<%
' --- BIẾN LƯU THÔNG BÁO ---
Dim errorMsg
errorMsg = ""

' --- BIẾN GIỮ LẠI GIÁ TRỊ FORM ---
Dim f_fname, f_lname, f_gender, f_birthday, f_email, f_phone, f_address
f_gender = "female" ' Mặc định là nữ
f_fname = ""
f_lname = ""
f_email = ""
f_phone = ""
f_address = ""
f_birthday = ""

' --- XỬ LÝ KHI NGƯỜI DÙNG BẤM ĐĂNG KÝ ---
If Request.ServerVariables("REQUEST_METHOD") = "POST" Then
    
    ' 1. Lấy dữ liệu từ Form
    f_fname    = Trim(Request.Form("first_name"))
    f_lname    = Trim(Request.Form("last_name"))
    f_gender   = Request.Form("gender")
    f_birthday = Request.Form("birthday")
    f_email    = Trim(Request.Form("email"))
    f_phone    = Trim(Request.Form("phone_number"))
    f_address  = Trim(Request.Form("address"))
    
    Dim f_pass
    f_pass     = Trim(Request.Form("password"))

    ' 2. Validate dữ liệu cơ bản
    ' (Phone và Address có thể để trống tùy bạn, ở đây tôi để bắt buộc để hỗ trợ Checkout sau này)
    If f_fname = "" Or f_lname = "" Or f_email = "" Or f_pass = "" Or f_birthday = "" Then
        errorMsg = "Vui lòng điền đầy đủ các trường bắt buộc (Họ tên, Email, Mật khẩu, Ngày sinh)!"
    Else
        ' 3. Làm sạch dữ liệu (Chống SQL Injection cơ bản)
        f_fname   = Replace(f_fname, "'", "''")
        f_lname   = Replace(f_lname, "'", "''")
        f_email   = Replace(f_email, "'", "''")
        f_pass    = Replace(f_pass, "'", "''")
        f_phone   = Replace(f_phone, "'", "''")
        f_address = Replace(f_address, "'", "''")
        
        ' Xử lý giới tính sang Tiếng Việt để lưu vào DB
        Dim genderDB
        If f_gender = "male" Then 
            genderDB = "Nam" 
        Else 
            genderDB = "Nữ"
        End If

        ' 4. KIỂM TRA EMAIL ĐÃ TỒN TẠI CHƯA
        Dim sqlCheck, rsCheck
        sqlCheck = "SELECT id FROM users WHERE email = '" & f_email & "'"
        Set rsCheck = conn.Execute(sqlCheck)

        If Not rsCheck.EOF Then
            errorMsg = "Email này đã được sử dụng. Vui lòng chọn email khác."
        Else
        ' 5. THỰC HIỆN ĐĂNG KÝ (INSERT)
                    Dim sqlInsert
                    
                    ' Cấu trúc bảng Users mới
                    sqlInsert = "INSERT INTO Users (email, password, first_name, last_name, phone_number, address, gender, birthday, role, status) " & _
                                "VALUES (" & _
                                "'" & f_email & "', " & _
                                "N'" & f_pass & "', " & _
                                "N'" & f_fname & "', " & _
                                "N'" & f_lname & "', " & _
                                "'" & f_phone & "', " & _
                                "N'" & f_address & "', " & _
                                "N'" & genderDB & "', " & _
                                "'" & f_birthday & "', " & _
                                "'customer', 1)"
            
            On Error Resume Next 
            conn.Execute sqlInsert
            
            If Err.Number <> 0 Then
                errorMsg = "Lỗi hệ thống: " & Err.Description
            Else
                ' Đăng ký thành công -> Chuyển sang trang Login
                Response.Redirect "login.asp?msg=registered" 
            End If
            On Error Goto 0
        End If
        
        rsCheck.Close
        Set rsCheck = Nothing
    End If
End If
%>

<!DOCTYPE html>
<html lang="vi">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Đăng ký - TORANO</title>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/normalize/8.0.1/normalize.min.css">
    
    <link rel="stylesheet" href="../../assets/css/base.css">
    <link rel="stylesheet" href="../../assets/css/main.css">
    <link rel="stylesheet" href="../../assets/css/header-footer.css">
    <link rel="stylesheet" href="../../assets/css/register.css">
    
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link rel="stylesheet" href="/assets/fonts/fontawesome-free-6.7.2-web/css/all.min.css">
    <link href="https://fonts.googleapis.com/css2?family=Roboto:ital,wght@0,100..900;1,100..900&display=swap" rel="stylesheet">
    
    <style>
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
                        <div class="tab"><a href="login.asp" style="text-decoration:none; color:inherit;">Đăng nhập</a></div>
                        <div class="tab-divider">|</div>
                        <div class="tab active">Đăng ký</div>
                    </div>

                    <form class="form" id="registerForm" method="POST" action="register.asp">
                        
                        <% If errorMsg <> "" Then %>
                            <div class="error-message">
                                <i class="fa-solid fa-triangle-exclamation"></i> <%=errorMsg%>
                            </div>
                        <% End If %>

                        <input type="text" name="first_name" placeholder="Họ" required value="<%=f_fname%>">
                        <input type="text" name="last_name" placeholder="Tên" required value="<%=f_lname%>">

                        <input type="text" name="phone_number" placeholder="Số điện thoại" value="<%=f_phone%>">
                        <input type="text" name="address" placeholder="Địa chỉ" value="<%=f_address%>">

                        <div class="gender-selection">
                            <label>
                                <input type="radio" name="gender" value="female" <%=IfStr(f_gender="female", "checked", "")%>>
                                <span>Nữ</span>
                            </label>
                            <label>
                                <input type="radio" name="gender" value="male" <%=IfStr(f_gender="male", "checked", "")%>>
                                <span>Nam</span>
                            </label>
                        </div>

                        <div style="margin-bottom: 15px;">
                            <label style="font-size: 12px; color: #666; display: block; margin-bottom: 5px;">Ngày sinh:</label>
                            <input type="date" name="birthday" required value="<%=f_birthday%>" style="width: 100%; padding: 15px 12px ; border: 1px solid #ddd; border-radius: 2px; outline:none;font-size: 14px;">
                        </div>

                        <input type="email" name="email" placeholder="Email" required value="<%=f_email%>">
                        <input type="password" name="password" placeholder="Mật khẩu" required>

                        <div class="form-footer">
                            <button type="submit" class="btn-submit">ĐĂNG KÝ</button>
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
                let res = await fetch(file);
                if(res.ok) document.getElementById(id).innerHTML = await res.text();
            } catch(e) {}
        }
        loadComponent("header", "../FE/customer/component/header.asp");
        loadComponent("footer", "../FE/customer/component/footer.html");
    </script>
    <script src="../../FE/js/header-footer.js"></script>
</body>
</html>

<%
' Hàm hỗ trợ in Checked cho Radio button
Function IfStr(condition, valTrue, valFalse)
    If condition Then IfStr = valTrue Else IfStr = valFalse
End Function

conn.Close
Set conn = Nothing
%>