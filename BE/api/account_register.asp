<!--#include file="/BE/db/connect.asp"-->
<%
Response.ContentType = "application/json"
Response.Charset = "UTF-8"

first = Request.Form("first_name")
last  = Request.Form("last_name")
gender = Request.Form("gender")
birthday = Request.Form("birthday")
email = Request.Form("email")
password = Request.Form("password") ' (Nên mã hoá sau này)

' Kiểm tra rỗng
If email = "" OR password = "" Then
    Response.Write "{""status"":""error"",""message"":""Thiếu thông tin""}"
    Response.End
End If

' Kiểm tra email đã tồn tại
Set rs = conn.Execute("SELECT * FROM Users WHERE Email='" & email & "'")

If Not rs.EOF Then
    Response.Write "{""status"":""error"",""message"":""Email đã tồn tại""}"
    Response.End
End If

' Thêm vào database
sql = "INSERT INTO Users (First_Name, Last_Name, Gender, Birthday, Email, Password) VALUES (" & _
      "'" & first & "'," & _
      "'" & last & "'," & _
      "'" & gender & "'," & _
      "'" & birthday & "'," & _
      "'" & email & "'," & _
      "'" & password & "')"

conn.Execute(sql)

Response.Write "{""status"":""success"",""message"":""Đăng ký thành công""}"

conn.Close
Set conn = Nothing
%>
