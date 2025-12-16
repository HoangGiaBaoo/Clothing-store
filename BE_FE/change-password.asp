<%@LANGUAGE="VBSCRIPT" CODEPAGE="65001"%>
<% Response.CharSet = "UTF-8" %>
<!-- #include file="/BE/db/connect.asp" -->
<%
Response.ContentType = "application/json"

' Kiểm tra đăng nhập
If Session("UserID") = "" Or Not IsNumeric(Session("UserID")) Then
    Response.Write "{""success"":false,""message"":""Vui lòng đăng nhập""}"
    Response.End
End If

Dim userId : userId = CLng(Session("UserID"))

' Lấy dữ liệu từ form
Dim currentPassword, newPassword, confirmPassword
currentPassword = Trim(Request.Form("current_password"))
newPassword = Trim(Request.Form("new_password"))
confirmPassword = Trim(Request.Form("confirm_password"))

' Validation
If currentPassword = "" Or newPassword = "" Or confirmPassword = "" Then
    Response.Write "{""success"":false,""message"":""Vui lòng điền đầy đủ thông tin""}"
    Response.End
End If

If Len(newPassword) < 6 Then
    Response.Write "{""success"":false,""message"":""Mật khẩu mới phải có ít nhất 6 ký tự""}"
    Response.End
End If

If newPassword <> confirmPassword Then
    Response.Write "{""success"":false,""message"":""Mật khẩu xác nhận không khớp""}"
    Response.End
End If

If currentPassword = newPassword Then
    Response.Write "{""success"":false,""message"":""Mật khẩu mới phải khác mật khẩu hiện tại""}"
    Response.End
End If

' Kiểm tra mật khẩu hiện tại
Dim sqlCheck, rsCheck
sqlCheck = "SELECT password FROM users WHERE id = " & userId

Set rsCheck = conn.Execute(sqlCheck)

If rsCheck.EOF Then
    Response.Write "{""success"":false,""message"":""Người dùng không tồn tại""}"
    rsCheck.Close
    conn.Close
    Response.End
End If

Dim storedPassword : storedPassword = rsCheck("password")
rsCheck.Close

' So sánh mật khẩu (nếu bạn dùng hash thì cần verify hash)
' Giả sử password lưu dạng plain text (KHÔNG NÊN dùng trong production)
If storedPassword <> currentPassword Then
    Response.Write "{""success"":false,""message"":""Mật khẩu hiện tại không đúng""}"
    conn.Close
    Response.End
End If

' Cập nhật mật khẩu mới
' LƯU Ý: Trong thực tế NÊN hash password trước khi lưu
Dim sqlUpdate
sqlUpdate = "UPDATE users SET password = '" & Replace(newPassword, "'", "''") & "' WHERE id = " & userId

On Error Resume Next
conn.Execute sqlUpdate

If Err.Number <> 0 Then
    Response.Write "{""success"":false,""message"":""Có lỗi xảy ra khi cập nhật mật khẩu""}"
    conn.Close
    Response.End
End If
On Error GoTo 0

' Thành công
Response.Write "{""success"":true,""message"":""Đổi mật khẩu thành công""}"

conn.Close
Set conn = Nothing
%>