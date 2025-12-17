<%@LANGUAGE="VBSCRIPT" CODEPAGE="65001"%>
<%
' --- 0. CẤU HÌNH & CHECK LOGIN ---
Response.Buffer = True
%>
<!-- #include file="/BE/db/connect.asp" -->
<%
' Chặn truy cập trực tiếp nếu chưa đăng nhập
If IsEmpty(Session("UserID")) Or Session("UserID") = "" Then
    Response.Redirect "login.asp"
End If

Dim userID
userID = Session("UserID")

' --- 1. LẤY DỮ LIỆU TỪ FORM CHECKOUT ---
Dim recName, recPhone, recEmail, recAddress, recNote, paymentMethod
recName    = Trim(Request.Form("fullName"))
recPhone   = Trim(Request.Form("phone"))
recEmail   = Trim(Request.Form("email"))
recAddress = Trim(Request.Form("address"))
recNote    = Trim(Request.Form("note"))
paymentMethod = Request.Form("paymentMethod")

' Làm sạch dữ liệu (Chống lỗi SQL khi có dấu nháy đơn)
recName    = Replace(recName, "'", "''")
recPhone   = Replace(recPhone, "'", "''")
recEmail   = Replace(recEmail, "'", "''")
recAddress = Replace(recAddress, "'", "''")
recNote    = Replace(recNote, "'", "''")

' --- 2. TÍNH TOÁN LẠI TỔNG TIỀN (Server Side) ---
Dim totalAmount, shippingFee, finalAmount
totalAmount = CDbl(0)  ' Ép kiểu Double
shippingFee = CDbl(30000)

Dim rsCart
Set rsCart = Server.CreateObject("ADODB.Recordset")

Dim sqlCart
sqlCart = "SELECT c.ProductID, c.Quantity, c.ColorName, c.SizeName, p.SalePrice " & _
          "FROM Cart c INNER JOIN Products p ON c.ProductID = p.ProductID " & _
          "WHERE c.SessionID = '" & userID & "'"

rsCart.Open sqlCart, conn, 1, 1

If rsCart.EOF Then
    rsCart.Close
    Response.Redirect "index.asp"
End If

' Vòng lặp tính tổng tiền - ÉP KIỂU ĐÚng
Do While Not rsCart.EOF
    If Not IsNull(rsCart("Quantity")) And Not IsNull(rsCart("SalePrice")) Then
        totalAmount = totalAmount + (CDbl(rsCart("Quantity")) * CDbl(rsCart("SalePrice")))
    End If
    rsCart.MoveNext
Loop

rsCart.MoveFirst 

' Logic phí ship
If totalAmount >= 500000 Then shippingFee = CDbl(0)
finalAmount = totalAmount + shippingFee

' --- 3. BẮT ĐẦU TRANSACTION ---
On Error Resume Next
conn.BeginTrans 

    ' A. INSERT VÀO ORDERS - Dùng CAST để đảm bảo kiểu DECIMAL
    Dim sqlOrder, newOrderID
    
    sqlOrder = "SET NOCOUNT ON; " & _
               "INSERT INTO Orders (UserID, OrderDate, TotalAmount, ShippingFee, FinalAmount, " & _
               "ReceiverName, ReceiverPhone, ReceiverAddress, ReceiverEmail, Note, PaymentMethod, Status) " & _
               "VALUES (" & userID & ", GETDATE(), " & _
               "CAST(" & Replace(CStr(totalAmount), ",", ".") & " AS DECIMAL(18,2)), " & _
               "CAST(" & Replace(CStr(shippingFee), ",", ".") & " AS DECIMAL(18,2)), " & _
               "CAST(" & Replace(CStr(finalAmount), ",", ".") & " AS DECIMAL(18,2)), " & _
               "N'" & recName & "', '" & recPhone & "', N'" & recAddress & "', '" & recEmail & "', " & _
               "N'" & recNote & "', '" & paymentMethod & "', 1); " & _
               "SELECT SCOPE_IDENTITY();"
    
    Dim rsID
    Set rsID = conn.Execute(sqlOrder)
    newOrderID = rsID(0)
    rsID.Close

    ' B. INSERT VÀO ORDER_DETAILS
    Dim sqlDetail
    Do While Not rsCart.EOF
        Dim pID, qty, price, color, size
        pID   = rsCart("ProductID")
        qty   = rsCart("Quantity")
        price = CDbl(rsCart("SalePrice"))
        
        color = rsCart("ColorName")
        If IsNull(color) Then color = ""
        size  = rsCart("SizeName")
        If IsNull(size) Then size = ""
        
        ' Ép kiểu DECIMAL cho Price
        sqlDetail = "INSERT INTO OrderDetails (OrderID, ProductID, Quantity, Price, Color, Size) " & _
                    "VALUES (" & newOrderID & ", " & pID & ", " & qty & ", " & _
                    "CAST(" & Replace(CStr(price), ",", ".") & " AS DECIMAL(18,2)), " & _
                    "N'" & color & "', N'" & size & "')"
        
        conn.Execute(sqlDetail)
        rsCart.MoveNext
    Loop
    rsCart.Close

    ' C. XÓA GIỎ HÀNG
    conn.Execute "DELETE FROM Cart WHERE SessionID = '" & userID & "'"

' --- 4. KIỂM TRA LỖI ---
If Err.Number <> 0 Then
    conn.RollbackTrans
    Response.Write "<h1>Có lỗi xảy ra!</h1>"
    Response.Write "<p>Chi tiết: " & Err.Description & "</p>"
    Response.End
Else
    conn.CommitTrans
    Session("CartCount") = 0
    Response.Redirect "order-success.asp?id=" & newOrderID
End If
%>