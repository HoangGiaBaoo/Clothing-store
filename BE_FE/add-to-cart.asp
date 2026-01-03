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
Dim productId, colorName, sizeName, quantity
productId = Request.QueryString("id")
colorName = Trim(Request.QueryString("color"))
sizeName = Trim(Request.QueryString("size"))
quantity = Request.QueryString("qty")

' --- 2. VALIDATE ---
If productId = "" Or Not IsNumeric(productId) Then Response.Redirect "index.asp"
If quantity = "" Or Not IsNumeric(quantity) Then quantity = 1 Else quantity = CInt(quantity)
If quantity < 1 Then quantity = 1

colorName = Replace(colorName, "'", "''")
sizeName = Replace(sizeName, "'", "''")

' --- 3. [CHECK LOGIN KỸ HƠN] ---
Dim userID
userID = Session("UserID")

If IsEmpty(userID) Or IsNull(userID) Or CStr(userID) = "" Then
    ' Chưa đăng nhập -> Lưu link hiện tại -> Chuyển về Login
    Dim qs, retUrl
    qs = Request.ServerVariables("QUERY_STRING")
    retUrl = Server.URLEncode("add-to-cart.asp?" & qs)
    Response.Redirect "login.asp?msg=login_required&ret=" & retUrl
    Response.End
End If

Dim sessID
sessID = userID
' --- 4. KIỂM TRA TỒN KHO TRƯỚC KHI THÊM ---
Dim sqlStock, rsStock, stockQty, variantID
variantID = 0

sqlStock = "SELECT VariantID, StockQuantity FROM ProductVariants " & _
           "WHERE ProductID = " & productId & _
           " AND ColorName = N'" & colorName & "'" & _
           " AND SizeName = N'" & sizeName & "'" & _
           " AND IsActive = 1"

Set rsStock = Server.CreateObject("ADODB.Recordset")
rsStock.Open sqlStock, conn

If rsStock.EOF Then
    rsStock.Close
    conn.Close
    Response.Write "<script>alert('Sản phẩm không tồn tại!'); history.back();</script>"
    Response.End
End If

' Lấy VariantID và số lượng tồn kho
variantID = rsStock("VariantID")
If IsNull(rsStock("StockQuantity")) Then
    stockQty = 0
Else
    stockQty = CLng(rsStock("StockQuantity"))
End If
rsStock.Close

' Kiểm tra số lượng hiện tại trong giỏ
Dim sqlCartQty, rsCartQty, currentCartQty
sqlCartQty = "SELECT Quantity FROM Cart " & _
             "WHERE SessionID = '" & sessID & "'" & _
             " AND ProductID = " & productId & _
             " AND ColorName = N'" & colorName & "'" & _
             " AND SizeName = N'" & sizeName & "'"

Set rsCartQty = Server.CreateObject("ADODB.Recordset")
rsCartQty.Open sqlCartQty, conn

If rsCartQty.EOF Then
    currentCartQty = 0
Else
    currentCartQty = CLng(rsCartQty("Quantity"))
End If
rsCartQty.Close

' Tính tổng số lượng sau khi thêm
Dim totalQty
totalQty = currentCartQty + quantity

' Kiểm tra có đủ hàng không
If stockQty <= 0 Then
    conn.Close
    Response.Write "<script>alert('San pham đa het hang!'); history.back();</script>"
    Response.End
End If

If totalQty > stockQty Then
    conn.Close
    Response.Write "<script>alert('Khong du hang trong kho! Chi con " & stockQty & " san pham (ban da co " & currentCartQty & " trong gio).'); history.back();</script>"
    Response.End
End If

' --- 5. THÊM VÀO GIỎ HÀNG (ĐÃ QUA KIỂM TRA TỒN KHO) ---
On Error Resume Next

Dim sqlCheck, rsCheck
sqlCheck = "SELECT * FROM Cart " & _
           "WHERE SessionID = '" & sessID & "'" & _
           " AND ProductID = " & productId & _
           " AND ColorName = N'" & colorName & "'" & _
           " AND SizeName = N'" & sizeName & "'"

Set rsCheck = Server.CreateObject("ADODB.Recordset")
rsCheck.Open sqlCheck, conn, 1, 3

If Not rsCheck.EOF Then
    ' Đã có trong giỏ -> Cập nhật số lượng
    rsCheck("Quantity") = rsCheck("Quantity") + quantity
    rsCheck("AddedDate") = Now()
    rsCheck.Update
Else
    ' Chưa có -> Thêm mới
    rsCheck.AddNew
    rsCheck("SessionID") = sessID
    rsCheck("ProductID") = productId
    If variantID > 0 Then rsCheck("VariantID") = variantID
    rsCheck("ColorName") = colorName
    rsCheck("SizeName") = sizeName
    rsCheck("Quantity") = quantity
    rsCheck("AddedDate") = Now()
    rsCheck.Update
End If

rsCheck.Close

If Err.Number <> 0 Then
    conn.Close
    Response.Write "<script>alert('Co loi xay ra: " & Err.Description & "'); history.back();</script>"
    Response.End
End If

' Cập nhật số lượng items trong Session
Dim sqlCountCart, rsCountCart
sqlCountCart = "SELECT COUNT(*) as TotalItems FROM Cart WHERE SessionID = '" & sessID & "'"
Set rsCountCart = conn.Execute(sqlCountCart)
Session("CartCount") = rsCountCart("TotalItems")
rsCountCart.Close

conn.Close

' --- 6. CHUYỂN HƯỚNG VỀ GIỎ HÀNG ---
Response.Redirect "cart.asp"
%>