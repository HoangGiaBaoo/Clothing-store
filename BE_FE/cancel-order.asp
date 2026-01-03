<%@LANGUAGE="VBSCRIPT" CODEPAGE="65001"%>
<% Response.CharSet = "UTF-8" %>
<!-- #include file="/BE/db/connect.asp" -->
<%
Response.ContentType = "application/json"

' Kiểm tra đăng nhập
If Session("user_id") = "" Or Not IsNumeric(Session("user_id")) Then
    Response.Write "{""success"":false,""message"":""Vui lòng đăng nhập""}"
    Response.End
End If

Dim userId : userId = CLng(Session("user_id"))

' Kiểm tra phương thức POST
If Request.ServerVariables("REQUEST_METHOD") <> "POST" Then
    Response.Write "{""success"":false,""message"":""Invalid request method""}"
    Response.End
End If

' Lấy order_id từ form
Dim orderId : orderId = Request.Form("order_id")

' Validation
If orderId = "" Or Not IsNumeric(orderId) Then
    Response.Write "{""success"":false,""message"":""Mã đơn hàng không hợp lệ""}"
    Response.End
End If

orderId = CLng(orderId)

' Kiểm tra đơn hàng có tồn tại và thuộc về user này không
Dim sqlCheck, rsCheck
sqlCheck = "SELECT OrderID, Status FROM Orders WHERE OrderID = " & orderId & " AND UserID = " & userId

Set rsCheck = conn.Execute(sqlCheck)

If rsCheck.EOF Then
    ' Đơn hàng không tồn tại hoặc không thuộc về user
    Response.Write "{""success"":false,""message"":""Không tìm thấy đơn hàng hoặc bạn không có quyền hủy đơn này""}"
    rsCheck.Close
    conn.Close
    Response.End
End If

' Kiểm tra trạng thái đơn hàng
Dim currentStatus : currentStatus = rsCheck("Status")
rsCheck.Close

' Chỉ cho phép hủy đơn hàng ở trạng thái "Chờ xử lý" (Status = 1)
If currentStatus <> 1 Then
    Dim statusMessage
    Select Case currentStatus
        Case 2
            statusMessage = "Đơn hàng đang giao, không thể hủy"
        Case 3
            statusMessage = "Đơn hàng đã hoàn tất, không thể hủy"
        Case 0
            statusMessage = "Đơn hàng đã được hủy trước đó"
        Case Else
            statusMessage = "Không thể hủy đơn hàng ở trạng thái hiện tại"
    End Select
    
    Response.Write "{""success"":false,""message"":""" & statusMessage & """}"
    conn.Close
    Response.End
End If

' Cập nhật trạng thái đơn hàng thành 0 (Đã hủy)
Dim sqlUpdate
sqlUpdate = "UPDATE Orders SET Status = 0 WHERE OrderID = " & orderId & " AND UserID = " & userId

On Error Resume Next
conn.Execute sqlUpdate

If Err.Number <> 0 Then
    Response.Write "{""success"":false,""message"":""Có lỗi xảy ra khi hủy đơn hàng: " & Err.Description & """}"
    conn.Close
    Response.End
End If
On Error GoTo 0

' Thành công
Response.Write "{""success"":true,""message"":""Hủy đơn hàng thành công""}"

conn.Close
Set conn = Nothing
%>