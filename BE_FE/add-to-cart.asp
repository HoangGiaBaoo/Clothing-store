<%@LANGUAGE="VBSCRIPT" CODEPAGE="65001"%>
<!-- #include file="/BE/db/connect.asp" -->

<%
' --- 1. LẤY DỮ LIỆU (CÁCH CHUẨN VBSCRIPT) ---
Dim productId, color, size, qty

' Lấy trực tiếp từ URL (Cách này an toàn, không gây lỗi Script)
productId = Request.QueryString("id")
color     = Request.QueryString("color")
size      = Request.QueryString("size")
qty       = Request.QueryString("qty")

' --- 2. KIỂM TRA & LÀM SẠCH DỮ LIỆU ---

' Nếu không có ID thì về trang chủ
If productId = "" Or Not IsNumeric(productId) Then 
    Response.Redirect "index.asp"
End If

' Nếu số lượng lỗi thì mặc định là 1
If qty = "" Or Not IsNumeric(qty) Then 
    qty = 1 
Else 
    qty = CInt(qty)
End If

' Xử lý chuỗi để tránh lỗi SQL (Thay dấu nháy đơn)
' Trim() để cắt khoảng trắng thừa
color = Replace(Trim(color), "'", "''")
size  = Replace(Trim(size), "'", "''")

' --- 3. XỬ LÝ DATABASE ---
Dim sessID
sessID = Session.SessionID


' A. TÌM VARIANT ID (ID Biến thể)
Dim variantID, rsVar
variantID = 0 ' Mặc định là 0 (Số), KHÔNG dùng NULL

' Lưu ý chữ N trước biến chuỗi để hỗ trợ Unicode tốt nhất có thể
Dim sqlVar
sqlVar = "SELECT TOP 1 VariantID FROM ProductVariants " & _
         "WHERE ProductID = " & productId & _
         " AND ColorName = N'" & color & "' AND SizeName = N'" & size & "'"

If IsObject(conn) Then
    Set rsVar = conn.Execute(sqlVar)
    If Not rsVar.EOF Then 
        variantID = rsVar("VariantID")
    End If
    rsVar.Close
    Set rsVar = Nothing
End If

' B. KIỂM TRA GIỎ HÀNG
Dim sqlCheck, rsCheck
sqlCheck = "SELECT * FROM Cart " & _
           "WHERE SessionID = '" & sessID & "' " & _
           "AND ProductID = " & productId & _
           " AND ColorName = N'" & color & "' AND SizeName = N'" & size & "'"

Set rsCheck = Server.CreateObject("ADODB.Recordset")
rsCheck.Open sqlCheck, conn, 1, 3 ' Mode ghi (1, 3)

If Not rsCheck.EOF Then
    ' --- TRƯỜNG HỢP 1: SẢN PHẨM ĐÃ CÓ -> CỘNG DỒN ---
    rsCheck("Quantity") = rsCheck("Quantity") + qty
    rsCheck.Update
Else
    ' --- TRƯỜNG HỢP 2: CHƯA CÓ -> THÊM MỚI ---
    rsCheck.AddNew
    rsCheck("SessionID") = sessID
    rsCheck("ProductID") = productId
    
    ' Chỉ lưu VariantID nếu tìm thấy (lớn hơn 0)
    If variantID > 0 Then 
        rsCheck("VariantID") = variantID
    End If
    
    rsCheck("ColorName") = color
    rsCheck("SizeName") = size
    rsCheck("Quantity") = qty
    rsCheck("AddedDate") = Now()
    rsCheck.Update
End If

' --- 4. DỌN DẸP & CHUYỂN HƯỚNG ---
rsCheck.Close
Set rsCheck = Nothing
conn.Close
Set conn = Nothing

' Quay về trang giỏ hàng
Response.Redirect "cart.asp"
%>