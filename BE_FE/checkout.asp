<%@LANGUAGE="VBSCRIPT" CODEPAGE="65001"%>
<%
' --- 0. CẤU HÌNH & KIỂM TRA ĐĂNG NHẬP ---
Response.Buffer = True
%>
<!-- #include file="/BE/db/connect.asp" -->
<%
' CHẶN KHÁCH VÃNG LAI: Nếu chưa đăng nhập -> Về trang Login
If IsEmpty(Session("UserID")) Or Session("UserID") = "" Then
    Response.Redirect "login.asp?msg=login_to_checkout&ret=checkout.asp"
End If

Dim currentSessionID
currentSessionID = Session("UserID") ' Lấy Giỏ hàng theo ID thành viên

' --- 1. HÀM XỬ LÝ TIẾNG VIỆT (Giữ nguyên của bạn) ---
Sub WriteUTF8(text)
    If IsNull(text) Or text = "" Then Exit Sub
    
    Dim stream
    Set stream = Server.CreateObject("ADODB.Stream")
    stream.Open
    stream.Type = 2 ' Text
    stream.Charset = "UTF-8"
    stream.WriteText text
    
    stream.Position = 0
    stream.Type = 1 ' Binary
    
    If stream.Size > 3 Then
        stream.Position = 3 
        Dim binaryData
        binaryData = stream.Read
        Response.BinaryWrite binaryData
    End If
    
    stream.Close
    Set stream = Nothing
End Sub

' --- 2. LẤY THÔNG TIN KHÁCH HÀNG (ĐỂ ĐIỀN SẴN FORM) ---
Dim myName, myPhone, myAddress, myEmail
myName = ""
myPhone = ""
myAddress = ""
myEmail = ""

' Query lấy thông tin người dùng
Dim rsUser
' Lưu ý: Hãy đảm bảo bảng Users của bạn có các cột phone_number, address. Nếu chưa có thì nó sẽ để trống.
' Tôi dùng ISNULL để tránh lỗi nếu cột đó chưa có dữ liệu
Set rsUser = conn.Execute("SELECT first_name, last_name, email, phone_number, address FROM users WHERE id = " & currentSessionID)

If Not rsUser.EOF Then
    myName = Trim(rsUser("last_name") & " " & rsUser("first_name"))
    myEmail = rsUser("email")
    
    If Not IsNull(rsUser("phone_number")) Then myPhone = rsUser("phone_number")
    If Not IsNull(rsUser("address")) Then myAddress = rsUser("address")
End If
rsUser.Close
Set rsUser = Nothing


' --- 3. LOGIC LẤY GIỎ HÀNG ---

' Kiểm tra giỏ hàng có trống không
Dim rsCount
Set rsCount = conn.Execute("SELECT COUNT(*) FROM Cart WHERE SessionID = '" & currentSessionID & "'")
If rsCount(0) = 0 Then
    rsCount.Close
    Response.Redirect "index.asp" ' Giỏ hàng trống, chuyển về trang chủ
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

' Lấy danh sách sản phẩm
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
                <input type="text" name="fullName" placeholder="Họ và tên" required class="inp-text" value="<%=myName%>">
            </div>
            <div class="form-row">
                <div class="form-group half">
                    <input type="email" name="email" placeholder="Email" class="inp-text" value="<%=myEmail%>">
                </div>
                <div class="form-group half">
                    <input type="text" name="phone" placeholder="Số điện thoại" required class="inp-text" value="<%=myPhone%>">
                </div>
            </div>
            <div class="form-group">
                <input type="text" name="address" placeholder="Địa chỉ" required class="inp-text" value="<%=myAddress%>">
            </div>
            
            <% Dim noteFromCart : noteFromCart = Request.QueryString("note") %>
            <div class="form-group">
                <textarea name="note" placeholder="Ghi chú" class="inp-text" style="height: 80px"><%=noteFromCart%></textarea>
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
                If IsNull(rsList("MainImage")) Or rsList("MainImage") = "" Then 
                    pImg = "images/no-image.jpg" 
                Else 
                    pImg = rsList("MainImage")
                End If
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
                        <% =rsList("ColorName") %> / <% Call WriteUTF8(rsList("SizeName")) %>
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
            try {
                let response = await fetch(file);
                if (response.ok) {
                    document.getElementById(id).innerHTML = await response.text();
                }
            } catch (e) { console.error("Error loading component:", e); }
        }
        loadComponent("header", "../FE/customer/component/header.asp");
        loadComponent("footer", "../FE/customer/component/footer.html");
    </script>
    <script src="../../FE/js/header-footer.js"></script>
</body>
</html>
<%
rsList.Close
Set rsList = Nothing
conn.Close
Set conn = Nothing
%>