<%@LANGUAGE="VBSCRIPT" CODEPAGE="65001"%>
<%
' --- 0. CẤU HÌNH PHẢI Ở TRÊN CÙNG ---
Response.Buffer = True


' Xóa Cache
Response.Expires = -1
Response.ExpiresAbsolute = Now() - 1
Response.AddHeader "pragma", "no-cache"
Response.CacheControl = "no-cache"
%>
<!-- #include file="/BE/db/connect.asp" -->
<%
' --- 1. LẤY DỮ LIỆU ---
Dim productId, color, size, qty
productId = Request.QueryString("id")
color     = Request.QueryString("color")
size      = Request.QueryString("size")
qty       = Request.QueryString("qty")

' --- 2. VALIDATE ---
If productId = "" Or Not IsNumeric(productId) Then Response.Redirect "index.asp"
If qty = "" Or Not IsNumeric(qty) Then qty = 1 Else qty = CInt(qty)
If qty < 1 Then qty = 1
color = Replace(Trim(color), "'", "''")
size  = Replace(Trim(size), "'", "''")

' --- 3. [CHECK LOGIN KỸ HƠN] ---
' Kiểm tra cả IsNull và rỗng
Dim userID
userID = Session("UserID")

If IsEmpty(userID) Or IsNull(userID) Or CStr(userID) = "" Then
    ' Chưa đăng nhập -> Lấy link hiện tại -> Chuyển về Login
    Dim qs, retUrl
    qs = Request.ServerVariables("QUERY_STRING")
    retUrl = Server.URLEncode("add-to-cart.asp?" & qs)
    
    Response.Redirect "login.asp?msg=login_required&ret=" & retUrl
End If

' --- 4. THÊM VÀO GIỎ ---
Dim sessID
sessID = userID ' Đã lấy ở trên

' A. Tìm VariantID
Dim variantID, sqlVar, rsVar
variantID = 0 
sqlVar = "SELECT TOP 1 VariantID FROM ProductVariants WHERE ProductID = " & productId & " AND ColorName = N'" & color & "' AND SizeName = N'" & size & "'"

If IsObject(conn) Then
    Set rsVar = conn.Execute(sqlVar)
    If Not rsVar.EOF Then variantID = rsVar("VariantID")
    rsVar.Close
End If

' B. Cập nhật Cart
Dim sqlCheck, rsCheck
sqlCheck = "SELECT * FROM Cart WHERE SessionID = '" & sessID & "' AND ProductID = " & productId & " AND ColorName = N'" & color & "' AND SizeName = N'" & size & "'"

Set rsCheck = Server.CreateObject("ADODB.Recordset")
rsCheck.Open sqlCheck, conn, 1, 3 

If Not rsCheck.EOF Then
    rsCheck("Quantity") = rsCheck("Quantity") + qty
    rsCheck("AddedDate") = Now()
    rsCheck.Update
Else
    rsCheck.AddNew
    rsCheck("SessionID") = sessID
    rsCheck("ProductID") = productId
    If variantID > 0 Then rsCheck("VariantID") = variantID
    rsCheck("ColorName") = color
    rsCheck("SizeName") = size
    rsCheck("Quantity") = qty
    rsCheck("AddedDate") = Now()
    rsCheck.Update
End If

rsCheck.Close
conn.Close

' Xong -> Về giỏ
Response.Redirect "cart.asp"
%>