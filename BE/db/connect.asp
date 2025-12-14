<%
' --- BẮT BUỘC: KÍCH HOẠT SESSION ĐỂ KHÔNG BỊ LỖI 00000000 ---
If IsEmpty(Session("InitSession")) Then
    Session("InitSession") = 1
End If
%>
<%
' ==============================
'  FILE: connect.asp (fix UTF-8)
' ==============================
On Error Resume Next

Set conn = Server.CreateObject("ADODB.Connection")
Set rs   = Server.CreateObject("ADODB.Recordset")
Set rs1  = Server.CreateObject("ADODB.Recordset")

' ===== THÔNG TIN SQL =====
sql_server   = "ALEXXXX\MSSQLSERVER04"
sql_database = "torano"
sql_user     = "sa"
sql_pass     = "dream1012"

strconn = "Provider=SQLOLEDB;Data Source=" & sql_server & _
          ";Initial Catalog=" & sql_database & _
          ";User ID=" & sql_user & ";Password=" & sql_pass & ";"

conn.Open strconn

If Err.Number <> 0 Then
    Response.Write "<b style='color:red'>❌ Lỗi kết nối SQL Server:</b><br>"
    Response.Write Err.Description & "<br><br>"
    Response.Write "<b>➡ Hãy kiểm tra lại:</b><br>"
    Response.Write "- SQL Server đã chạy chưa?<br>"
    Response.Write "- Server name đúng chưa? (ALEXXXX\MSSQLSERVER04)<br>"
    Response.Write "- User sa đúng mật khẩu chưa?<br>"
    Response.End
End If

'Response.Write "<b style='color:green'>✅ Kết nối thành công!</b>"
%>
