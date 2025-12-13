<%@LANGUAGE="VBSCRIPT" CODEPAGE="65001"%>
<% Response.CharSet = "UTF-8" %>
<!-- #include file="/BE/db/connect.asp" -->

<%
' --- 2. LẤY DỮ LIỆU ---
Dim action, cartID, change
action = Request.QueryString("action")
cartID = Request.QueryString("id")

' Kiểm tra dữ liệu đầu vào để tránh lỗi
If cartID <> "" And IsNumeric(cartID) Then
    
    ' --- TRƯỜNG HỢP 1: CẬP NHẬT SỐ LƯỢNG (+/-) ---
    If action = "update" Then
        change = Request.QueryString("change")
        
        If IsNumeric(change) Then
            change = CInt(change)
            
            ' Logic: Chỉ trừ khi số lượng > 1 (để không bị về 0 hoặc âm)
            ' Nếu đang là 1 mà bấm trừ thì giữ nguyên (hoặc bạn có thể cho xóa luôn tùy ý)
            
            Dim sqlUpdate
            sqlUpdate = "UPDATE Cart SET Quantity = Quantity + " & change & " " & _
                        "WHERE CartID = " & cartID & " AND (Quantity + " & change & ") > 0"
            
            conn.Execute sqlUpdate
        End If

    ' --- TRƯỜNG HỢP 2: XÓA SẢN PHẨM (X) ---
    ElseIf action = "delete" Then
        
        conn.Execute "DELETE FROM Cart WHERE CartID = " & cartID
        
    End If
    
End If

' --- 3. ĐÓNG KẾT NỐI VÀ QUAY VỀ ---
conn.Close
Set conn = Nothing

' Quay lại trang giỏ hàng để nó tính toán lại tổng tiền mới
Response.Redirect "cart.asp"
%>