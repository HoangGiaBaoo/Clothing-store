<%@LANGUAGE="VBSCRIPT" CODEPAGE="65001"%>
<%
' --- QUAN TRỌNG: Cấu hình Buffer PHẢI NẰM TRÊN CÙNG (Trước cả include) ---
Response.Buffer = True
%>
<!-- #include file="/BE/db/connect.asp" -->
<%
' --- BIẾN LƯU THÔNG BÁO ---
Dim errorMsg
errorMsg = ""

' --- 1. HỨNG LINK QUAY VỀ (RETURN URL) ---
Dim returnUrl
returnUrl = Request.QueryString("ret")
If returnUrl = "" Then returnUrl = Request.Form("returnUrl")

' --- XỬ LÝ ĐĂNG NHẬP ---
If Request.ServerVariables("REQUEST_METHOD") = "POST" Then
    
    Dim email, pass
    email = Trim(Request.Form("txtEmail"))
    pass  = Trim(Request.Form("txtPass"))

    If email = "" Or pass = "" Then
        errorMsg = "Vui lòng nhập đầy đủ thông tin!"
    Else
        email = Replace(email, "'", "''")
        pass  = Replace(pass, "'", "''")

        ' [FIX]: Dùng đúng tên bảng users và cột id
        Dim sql, rsUser
        sql = "SELECT id, email, password, role, first_name, last_name FROM users WHERE email = N'" & email & "' AND password = N'" & pass & "'"
        
        Set rsUser = conn.Execute(sql)

        If Not rsUser.EOF Then
            ' === ĐĂNG NHẬP THÀNH CÔNG ===
            
            ' [FIX]: Ép kiểu ID thành chuỗi (CStr) để lưu Session chắc chắn hơn
            Session("UserID")    = CStr(rsUser("id"))
            Session("UserEmail") = rsUser("email")
            Session("FullName")  = rsUser("last_name") & " " & rsUser("first_name")
            Session("Role")      = rsUser("role")
            
            ' Lấy role để điều hướng
            Dim role
            role = LCase(rsUser("role"))

            ' --- CHUYỂN HƯỚNG MỀM (Soft Redirect) ---
            Dim targetUrl, finalRedirect
            targetUrl = Request.Form("returnUrl") 
            
            If targetUrl <> "" Then
                finalRedirect = targetUrl
            Else
                If role = "admin" Then
                    finalRedirect = "admin/dashboard.asp"
                Else
                    finalRedirect = "index.asp"
                End If
            End If
            
            rsUser.Close
            Set rsUser = Nothing
            conn.Close
            
            ' HTML chuyển hướng (Giúp trình duyệt kịp lưu Cookie Session)
            %>
            <!DOCTYPE html>
            <html>
            <head>
                <meta charset="UTF-8">
                <title>Đang chuyển hướng...</title>
                <meta http-equiv="refresh" content="0;url=<%=finalRedirect%>">
                <script>window.location.href = '<%=finalRedirect%>';</script>
            </head>
            <body>
                <p style="text-align:center; margin-top:50px;">
                    Đăng nhập thành công! <br> ID: <%=Session("UserID")%> <br>
                    Đang chuyển hướng... <a href="<%=finalRedirect%>">Click vào đây</a>
                </p>
            </body>
            </html>
            <%
            Response.End
        Else
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
    <title>Đăng nhập - TORANO</title>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/normalize/8.0.1/normalize.min.css">
    <link rel="stylesheet" href="../../assets/css/base.css">
    <link rel="stylesheet" href="../../assets/css/main.css">
    <link rel="stylesheet" href="../../assets/css/header-footer.css">
    <link rel="stylesheet" href="../../assets/css/login.css">
    <link rel="stylesheet" href="/assets/fonts/fontawesome-free-6.7.2-web/css/all.min.css">
    <style>
        .error-message { background-color: #ffe6e6; color: #d63031; padding: 10px; margin-bottom: 15px; border: 1px solid #ffcccc; text-align: center; }
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
                        <input type="hidden" name="returnUrl" value="<%=Server.HTMLEncode(returnUrl)%>">
                        
                        <% If errorMsg <> "" Then %>
                            <div class="error-message"><%=errorMsg%></div>
                        <% End If %>
                        
                        <% If Request.QueryString("msg") = "login_required" Then %>
                             <div class="error-message" style="background-color:#e3f2fd;color:#0d47a1;">Vui lòng đăng nhập để thêm vào giỏ.</div>
                        <% End If %>

                        <input type="email" name="txtEmail" placeholder="Email" required value="<%=Request.Form("txtEmail")%>">
                        <input type="password" name="txtPass" placeholder="Mật khẩu" required>
                        
                        <div class="form-footer">
                            <button type="submit" class="btn-submit">ĐĂNG NHẬP</button>
                        </div>
                    </form>
                </div>
            </div>
        </div>
        <div id="footer"></div>
    </div>
    <script>
        // Load header/footer JS (Giữ nguyên code JS của bạn)
        async function loadComponent(id, file) { try { let r = await fetch(file); if (r.ok) document.getElementById(id).innerHTML = await r.text(); } catch (e) {} }
        loadComponent("header", "../FE/customer/component/header.asp");
        loadComponent("footer", "../FE/customer/component/footer.html");
    </script>
</body>
</html>