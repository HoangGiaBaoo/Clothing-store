<%@LANGUAGE="VBSCRIPT"%>
<!-- #include file="/BE/db/connect.asp" -->
<%
' --- HÀM XỬ LÝ TIẾNG VIỆT "BẤT CHẤP" SERVER (Dùng ADODB.Stream) ---
Sub WriteUTF8(text)
    If IsNull(text) Or text = "" Then Exit Sub
    
    Dim stream
    Set stream = Server.CreateObject("ADODB.Stream")
    stream.Open
    stream.Type = 2 ' Text
    stream.Charset = "UTF-8"
    stream.WriteText text
    
    ' Chuyển con trỏ về đầu để đổi sang chế độ Binary
    stream.Position = 0
    stream.Type = 1 ' Binary
    
    ' BỎ QUA 3 BYTE BOM (EF BB BF) DO ADODB TỰ SINH RA
    If stream.Size > 3 Then
        stream.Position = 3 
        Dim binaryData
        binaryData = stream.Read
        Response.BinaryWrite binaryData
    End If
    
    stream.Close
    Set stream = Nothing
End Sub
%>

<%
' --- LOGIC LẤY GIỎ HÀNG (Giữ nguyên logic của bạn) ---
Dim currentSessionID
currentSessionID = Session.SessionID

' Kiểm tra giỏ hàng
Dim rsCount
Set rsCount = conn.Execute("SELECT COUNT(*) FROM Cart WHERE SessionID = '" & currentSessionID & "'")
If rsCount(0) = 0 Then
    rsCount.Close
    Response.Redirect "index.asp"
End If
rsCount.Close

' Tính tổng tiền
Dim totalAmount, shippingFee, finalAmount
totalAmount = 0
Dim rsSum
Set rsSum = conn.Execute("SELECT ISNULL(SUM(Quantity * CAST(SalePrice AS DECIMAL(18,0))), 0) FROM Cart c INNER JOIN Products p ON c.ProductID = p.ProductID WHERE c.SessionID = '" & currentSessionID & "'")
If Not rsSum.EOF Then totalAmount = CDbl(rsSum(0))
rsSum.Close

If totalAmount >= 500000 Then shippingFee = 0 Else shippingFee = 30000
finalAmount = totalAmount + shippingFee

' Lấy danh sách (Lưu ý: Không cần xử lý Unicode ở câu SQL, chỉ cần lấy dữ liệu thô)
Dim sqlList, rsList
sqlList = "SELECT c.Quantity, c.ColorName, c.SizeName, p.ProductName, p.SalePrice, " & _
          "(SELECT TOP 1 ImageURL FROM ProductImages WHERE ProductID = p.ProductID AND IsMainImage = 1) AS MainImage " & _
          "FROM Cart c INNER JOIN Products p ON c.ProductID = p.ProductID " & _
          "WHERE c.SessionID = '" & currentSessionID & "'"

Set rsList = Server.CreateObject("ADODB.Recordset")
rsList.Open sqlList, conn
%>

<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Thanh toán - TORANO</title>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/normalize/8.0.1/normalize.min.css">
    <link rel="stylesheet" href="../../assets/css/base.css">
    <link rel="stylesheet" href="../../assets/css/main.css">
    <link rel="stylesheet" href="../../assets/css/header-footer.css">
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link rel="stylesheet" href="/assets/fonts/fontawesome-free-6.7.2-web/css/all.min.css">
    <link href="https://fonts.googleapis.com/css2?family=Roboto:wght@400;500;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="../../assets/css/checkout.css">
    <style>body { font-family: 'Roboto', sans-serif; }</style>
</head>
<body>
    <div id="header"></div>

    <div class="checkout-container">
    
    <div class="col-left">
        <div class="checkout-header">
            <a href="index.asp" class="logo">TORANO</a>
            <div class="breadcrumb">
                <a href="cart.asp">Giỏ hàng</a> <i class="fas fa-chevron-right"></i> <span>Thông tin giao hàng</span>
            </div>
        </div>

        <form action="process-checkout.asp" method="POST" id="checkoutForm">
            <h3>Thông tin giao hàng</h3>
            <div class="form-group">
                <input type="text" name="fullName" placeholder="Họ và tên" required class="inp-text">
            </div>
            <div class="form-row">
                <div class="form-group half">
                    <input type="email" name="email" placeholder="Email" class="inp-text">
                </div>
                <div class="form-group half">
                    <input type="text" name="phone" placeholder="Số điện thoại" required class="inp-text">
                </div>
            </div>
            <div class="form-group">
                <input type="text" name="address" placeholder="Địa chỉ" required class="inp-text">
            </div>
            <div class="form-group">
                <textarea name="note" placeholder="Ghi chú" class="inp-text" style="height: 80px"></textarea>
            </div>

            <h3>Phương thức vận chuyển</h3>
            <div class="shipping-method">
                <label class="radio-box">
                    <div class="radio-left">
                        <input type="radio" checked>
                        <span>Giao hàng tận nơi</span>
                    </div>
                    <span class="price"><%=FormatNumber(shippingFee, 0)%>₫</span>
                </label>
            </div>

            <h3>Phương thức thanh toán</h3>
            <div class="payment-method">
                <label class="radio-box">
                    <div class="radio-left">
                        <input type="radio" name="paymentMethod" value="COD" checked>
                        <span>Thanh toán khi nhận hàng (COD)</span>
                    </div>
                </label>
            </div>

            <div class="checkout-footer">
                <a href="cart.asp">Quay về giỏ hàng</a>
                <button type="submit" class="btn-order">HOÀN TẤT ĐƠN HÀNG</button>
            </div>
        </form>
    </div>

    <div class="col-right">
        <div class="order-summary">
            <% 
            Dim pImg
            Do While Not rsList.EOF 
                If IsNull(rsList("MainImage")) Then pImg = "images/no-image.jpg" Else pImg = rsList("MainImage")
            %>
            <div class="item">
                <div class="item-img">
                    <img src="<%=pImg%>" alt="Img">
                    <span class="qty-badge"><%=rsList("Quantity")%></span>
                </div>
                <div class="item-info">
                    <div class="item-name">
                        <% Call WriteUTF8(rsList("ProductName")) %>
                    </div>
                    
                    <div class="item-meta">
                        <% Call WriteUTF8(rsList("ColorName")) %> / <% Call WriteUTF8(rsList("SizeName")) %>
                    </div>
                </div>
                <div class="item-price">
                    <%=FormatNumber(rsList("SalePrice") * rsList("Quantity"), 0)%>₫
                </div>
            </div>
            <% 
                rsList.MoveNext
            Loop 
            %>

            <div class="pricing-line separator">
                <span>Tạm tính</span>
                <span><%=FormatNumber(totalAmount, 0)%>₫</span>
            </div>
            <div class="pricing-line">
                <span>Phí vận chuyển</span>
                <span><%=FormatNumber(shippingFee, 0)%>₫</span>
            </div>
            <div class="pricing-line total">
                <span>Tổng cộng</span>
                <span class="total-price"><%=FormatNumber(finalAmount, 0)%>₫</span>
            </div>
        </div>
    </div>
</div>
<div id="footer"></div>
    <script>
        async function loadComponent(id, file) {
            document.getElementById(id).innerHTML = await (await fetch(file)).text();
        }
        loadComponent("header", "../FE/customer/component/header.html");
        loadComponent("footer", "../FE/customer/component/footer.html");
    </script>

</body>
</html>
<%
rsList.Close
Set rsList = Nothing
conn.Close
Set conn = Nothing
%>