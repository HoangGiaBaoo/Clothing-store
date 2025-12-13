<!--#include file="/BE/db/connect.asp"-->
<%
Response.ContentType = "application/json"

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
Dim cmd
Set cmd = Server.CreateObject("ADODB.Command")
cmd.ActiveConnection = conn
cmd.CommandText = "INSERT INTO Users (First_Name, Last_Name, Gender, Birthday, Email, Password) VALUES (?, ?, ?, ?, ?, ?)"
cmd.CommandType = 1

cmd.Parameters.Append cmd.CreateParameter("@first", 202, 1, 100, first)
cmd.Parameters.Append cmd.CreateParameter("@last", 202, 1, 100, last)
cmd.Parameters.Append cmd.CreateParameter("@gender", 202, 1, 20, gender)
cmd.Parameters.Append cmd.CreateParameter("@birthday", 7,   1, , birthday) ' adDate
cmd.Parameters.Append cmd.CreateParameter("@email", 202, 1, 150, email)
cmd.Parameters.Append cmd.CreateParameter("@password", 202, 1, 255, password)

cmd.Execute
Set cmd = Nothing


Response.Write "{""status"":""success"",""message"":""Đăng ký thành công""}"

conn.Close
Set conn = Nothing
%>
