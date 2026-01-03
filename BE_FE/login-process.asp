<%@LANGUAGE="VBSCRIPT" CODEPAGE="65001"%>
<%
' --- QUAN TRỌNG: Cấu hình Buffer PHẢI NẰM TRÊN CÙNG ---
Response.Buffer = True
Response.CharSet = "UTF-8"
%>
<!-- #include file="/BE/db/connect.asp" -->
<%
' --- XỬ LÝ ĐĂNG NHẬP TỪ DROPDOWN HEADER ---

' Kiểm tra phương thức POST
If Request.ServerVariables("REQUEST_METHOD") <> "POST" Then
    Response.Redirect "index.asp"
    Response.End
End If

' Lấy thông tin từ form
Dim email, password
email = Trim(Request.Form("email"))
password = Trim(Request.Form("password"))

' Validation
If email = "" Or password = "" Then
    Response.Redirect "index.asp?login_error=empty"
    Response.End
End If

' Làm sạch dữ liệu để tránh SQL Injection
email = Replace(email, "'", "''")
password = Replace(password, "'", "''")

' Query kiểm tra user
Dim sql, rsUser
sql = "SELECT id, email, password, role, first_name, last_name, phone_number " & _
      "FROM users " & _
      "WHERE email = N'" & email & "' AND password = N'" & password & "'"

On Error Resume Next
Set rsUser = conn.Execute(sql)

If Err.Number <> 0 Then
    Response.Redirect "index.asp?login_error=db"
    rsUser.Close
    conn.Close
    Response.End
End If
On Error GoTo 0

' Kiểm tra kết quả
If Not rsUser.EOF Then
    ' === ĐĂNG NHẬP THÀNH CÔNG ===
    
    ' Lưu thông tin vào Session
    Session("UserID")    = CStr(rsUser("id"))
    Session("UserEmail") = rsUser("email")
    Session("FullName")  = rsUser("last_name") & " " & rsUser("first_name")
    Session("Role")      = rsUser("role")
    
    ' Lưu thêm phone_number nếu có
    If Not IsNull(rsUser("phone_number")) Then
        Session("phone_number") = rsUser("phone_number")
    End If
    
    ' Xác định URL chuyển hướng dựa trên role
    Dim role
    role = LCase(rsUser("role"))
    
    rsUser.Close
    Set rsUser = Nothing
    conn.Close
    
    
    If role = "admin" Then
        Response.Redirect "dashboard.asp"
    Else
        Response.Redirect "index.asp"
    End If
    
Else
    ' === ĐĂNG NHẬP THẤT BẠI ===
    rsUser.Close
    Set rsUser = Nothing
    conn.Close
    
    ' Quay về trang chủ với thông báo lỗi
    Response.Redirect "index.asp?login_error=invalid"
End If

Response.End
%>