<%@LANGUAGE="VBSCRIPT" CODEPAGE="65001"%>
<%
' --- 0. CẤU HÌNH ---
Response.Buffer = True
%>
<!-- #include file="/BE/db/connect.asp" -->
<%
' --- HÀM XỬ LÝ TIẾNG VIỆT (Lấy từ Checkout sang) ---
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

' --- 1. LẤY ID ĐƠN HÀNG TỪ URL ---
Dim orderId
orderId = Request.QueryString("id")

' Validate: Nếu không có ID hoặc ID không phải số -> Đá về trang chủ
If orderId = "" Or Not IsNumeric(orderId) Then
    Response.Redirect "index.asp"
End If

' --- 2. TRUY VẤN THÔNG TIN ĐƠN HÀNG CHÍNH (Bảng Orders) ---
Dim sqlOrder, rsOrder
sqlOrder = "SELECT * FROM Orders WHERE OrderID = " & orderId

Set rsOrder = conn.Execute(sqlOrder)

If rsOrder.EOF Then
    ' Không tìm thấy đơn hàng này trong DB
    rsOrder.Close
    Response.Redirect "index.asp"
End If

' Lưu các biến cần dùng
Dim recName, recPhone, recAddress, recEmail, payMethod, note, subTotal, shipFee, finalTotal
recName = rsOrder("ReceiverName")
recPhone = rsOrder("ReceiverPhone")
recAddress = rsOrder("ReceiverAddress")
recEmail = rsOrder("ReceiverEmail")
payMethod = rsOrder("PaymentMethod") ' Lấy phương thức thanh toán gốc
note = rsOrder("Note")

' ÉP KIỂU DOUBLE ĐỂ SO SÁNH CHÍNH XÁC
subTotal = CDbl(rsOrder("TotalAmount"))
shipFee = CDbl(rsOrder("ShippingFee"))
finalTotal = CDbl(rsOrder("FinalAmount"))

' Format lại phương thức thanh toán cho đẹp (Hardcode text tiếng Việt thì không cần WriteUTF8 nếu file lưu chuẩn UTF-8)

If payMethod = "COD" Then
    payMethodText = "Thanh toán khi nhận hàng (COD)"
End If

rsOrder.Close
Set rsOrder = Nothing

' --- 3. TRUY VẤN CHI TIẾT SẢN PHẨM TRONG ĐƠN (Bảng OrderDetails + Products) ---
Dim sqlDetails, rsDetails
sqlDetails = "SELECT od.Quantity, od.Price, od.Color, od.Size, p.ProductName, " & _
             "(SELECT TOP 1 ImageURL FROM ProductImages WHERE ProductID = p.ProductID AND IsMainImage = 1) AS MainImage " & _
             "FROM OrderDetails od " & _
             "INNER JOIN Products p ON od.ProductID = p.ProductID " & _
             "WHERE od.OrderID = " & orderId

Set rsDetails = Server.CreateObject("ADODB.Recordset")
rsDetails.Open sqlDetails, conn
%>

<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Đặt hàng thành công - TORANO</title>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/normalize/8.0.1/normalize.min.css">
    <link rel="stylesheet" href="../../assets/css/base.css">
    <link rel="stylesheet" href="../../assets/css/main.css">
    <link rel="stylesheet" href="../../assets/css/header-footer.css">
    <link rel="stylesheet" href="/assets/fonts/fontawesome-free-6.7.2-web/css/all.min.css">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <link href="https://fonts.googleapis.com/css2?family=Roboto:wght@400;500;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="../../assets/css/order-success.css">
</head>
<body>
    <div id="header"></div>

    <div class="success-wrapper">
        <div class="col-main">
            <div class="success-header">
                <i class="fa-regular fa-circle-check success-icon"></i>
                <div class="success-title">
                    <h2>Đặt hàng thành công</h2>
                    <p>Mã đơn hàng #<%=orderId%></p>
                    <p>Cảm ơn bạn đã mua hàng!</p>
                </div>
            </div>

            <div class="order-info-box">
                <div class="info-section">
                    <h3 class="info-title">Thông tin đơn hàng</h3>
                    <div class="info-content">
                        <p><strong>Thông tin giao hàng</strong></p>
                        <p><% =recName %></p>
                        <p><%=recPhone%></p>
                        <p><% =recAddress %></p>
                        <% If recEmail <> "" Then %><p><%=recEmail%></p><% End If %>
                    </div>
                </div>
                 <% If note <> "" Then %>
                <div class="info-section">
                     <p><strong>Ghi chú:</strong> <% =note %></p>
                </div>
                 <% End If %>

                <div class="info-section">
                    <h3 class="info-title"> Thanh toán khi nhận hàng (COD) </h3>
                    
                </div>
            </div>

            <div class="action-area">
                <div class="need-help">
                    <i class="fa-regular fa-circle-question"></i> Cần hỗ trợ? <a href="#">Liên hệ chúng tôi</a>
                </div>
                <a href="index.asp" class="btn-continue">Tiếp tục mua hàng</a>
            </div>
        </div>

        <div class="col-sidebar">
            <% 
            Dim pImg
            Do While Not rsDetails.EOF 
                If IsNull(rsDetails("MainImage")) Or rsDetails("MainImage") = "" Then 
                    pImg = "images/no-image.jpg" 
                Else 
                    pImg = rsDetails("MainImage")
                End If
            %>
            <div class="sidebar-item">
                <div class="item-thumb-wrap">
                    <img src="<%=pImg%>" alt="Product Image" class="item-thumb">
                    <span class="item-qty-badge"><%=rsDetails("Quantity")%></span>
                </div>
                <div class="item-details">
                    <h4><% Call WriteUTF8(rsDetails("ProductName")) %></h4>
                    <div class="item-variant">
                        <% =rsDetails("Color") %> / <% Call WriteUTF8(rsDetails("Size")) %>
                    </div>
                </div>
                <div class="item-row-price">
                    <%=FormatNumber(rsDetails("Price") , 0)%>₫
                </div>
            </div>
            <% 
                rsDetails.MoveNext
            Loop 
            %>

            <div class="price-summary">
                <div class="summary-row">
                    <span>Tạm tính</span>
                    <span><%=FormatNumber(subTotal, 0)%>₫</span>
                </div>
                <div class="summary-row">
                    <span>Phí vận chuyển</span>
                    <span>
                        <% If CDbl(shipFee) < 1 Then %>
                            Miễn phí
                        <% Else %>
                            <%=FormatNumber(shipFee, 0)%>₫
                        <% End If %>
                    </span>
                </div>
                <div class="summary-row total">
                    <span class="total-label">Tổng cộng</span>
                    <span><span class="total-currency">VND</span> <%=FormatNumber(finalTotal, 0)%>₫</span>
                </div>
            </div>
        </div>
    </div>

    <div id="footer"></div>
    
    <script>
        async function loadComponent(id, file) {
            try { let res = await fetch(file); if(res.ok) document.getElementById(id).innerHTML = await res.text(); } catch(e) {}
        }
        loadComponent("header", "../FE/customer/component/header.asp");
        loadComponent("footer", "../FE/customer/component/footer.html");
    </script>
</body>
</html>
<%
' Dọn dẹp recordset cuối cùng
rsDetails.Close
Set rsDetails = Nothing
conn.Close
Set conn = Nothing
%>