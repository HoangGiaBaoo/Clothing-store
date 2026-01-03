<%@LANGUAGE="VBSCRIPT" CODEPAGE="65001"%>
<% Response.CharSet = "UTF-8" %>
<!-- #include file="/BE/db/connect.asp" -->
<%
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

' Kiểm tra đăng nhập
If Session("UserID") = "" Or Not IsNumeric(Session("UserID")) Then
    Response.Redirect "login.asp"
    Response.End
End If

Dim userId : userId = CLng(Session("UserID"))
Dim orderId : orderId = Request.QueryString("id")
Dim actionType : actionType = Request.QueryString("action")

' Validate orderId
If orderId = "" Or Not IsNumeric(orderId) Then
    Response.Redirect "account.asp"
    Response.End
End If

' XỬ LÝ HỦY ĐƠN HÀNG
If actionType = "cancel" And Request.ServerVariables("REQUEST_METHOD") = "POST" Then
    Dim cancelReason : cancelReason = Request.Form("cancelReason")
    
    ' Kiểm tra đơn hàng có thuộc về user này không và trạng thái có cho phép hủy không
    Dim sqlCheckCancel, rsCheckCancel
    sqlCheckCancel = "SELECT Status FROM Orders WHERE OrderID = " & orderId & " AND UserID = " & userId
    Set rsCheckCancel = conn.Execute(sqlCheckCancel)
    
    If Not rsCheckCancel.EOF Then
        Dim currentStatus : currentStatus = rsCheckCancel("Status")
        
        ' Chỉ cho phép hủy đơn hàng có trạng thái 1 (Chờ xử lý) hoặc 2 (Đang giao hàng)
        If currentStatus = 1 Or currentStatus = 2 Then
            ' Cập nhật trạng thái đơn hàng thành 0 (Đã hủy)
            Dim sqlCancelOrder
            sqlCancelOrder = "UPDATE Orders SET Status = 0, Note = " & _
                           "CASE WHEN Note IS NULL OR Note = '' " & _
                           "THEN N'Lý do hủy: " & Replace(cancelReason, "'", "''") & "' " & _
                           "ELSE Note + CHAR(13) + CHAR(10) + N'Lý do hủy: " & Replace(cancelReason, "'", "''") & "' " & _
                           "END " & _
                           "WHERE OrderID = " & orderId & " AND UserID = " & userId
            
            conn.Execute sqlCancelOrder
            
            ' Redirect về trang chi tiết với thông báo thành công
            Response.Redirect "order-detail.asp?id=" & orderId & "&msg=cancelled"
            Response.End
        End If
    End If
    rsCheckCancel.Close
End If

' Lấy thông tin đơn hàng
Dim sqlOrder, rsOrder
sqlOrder = "SELECT * FROM Orders WHERE OrderID = " & orderId & " AND UserID = " & userId
Set rsOrder = conn.Execute(sqlOrder)

If rsOrder.EOF Then
    Response.Redirect "account.asp"
    Response.End
End If

' Lấy thông tin đơn hàng
Dim orderDate, receiverName, receiverPhone, receiverEmail, receiverAddress, note
Dim totalAmount, shippingFee, finalAmount, paymentMethod, status

orderDate = rsOrder("OrderDate")
receiverName = rsOrder("ReceiverName")
receiverPhone = rsOrder("ReceiverPhone")
receiverEmail = rsOrder("ReceiverEmail")
receiverAddress = rsOrder("ReceiverAddress")
note = rsOrder("Note")
totalAmount = rsOrder("TotalAmount")
shippingFee = rsOrder("ShippingFee")
finalAmount = rsOrder("FinalAmount")
paymentMethod = rsOrder("PaymentMethod")
status = rsOrder("Status")

rsOrder.Close

' Xác định trạng thái
Dim statusText, statusClass, statusIcon
Select Case status
    Case 1
        statusText = "Chờ xử lý"
        statusClass = "status-pending"
        statusIcon = "fa-clock"
    Case 2
        statusText = "Đang giao hàng"
        statusClass = "status-shipping"
        statusIcon = "fa-truck"
    Case 3
        statusText = "Hoàn tất"
        statusClass = "status-completed"
        statusIcon = "fa-check-circle"
    Case 0
        statusText = "Đã hủy"
        statusClass = "status-cancelled"
        statusIcon = "fa-times-circle"
End Select

' Kiểm tra xem có cho phép hủy đơn không (chỉ hủy được khi status = 1 hoặc 2)
Dim canCancel : canCancel = (status = 1 Or status = 2)

' Lấy chi tiết sản phẩm trong đơn hàng với ảnh chính từ ProductImages
Dim sqlDetails, rsDetails
sqlDetails = "SELECT " & _
             "od.DetailID, od.ProductID, od.Quantity, od.Price, od.Color, od.Size, " & _
             "p.ProductName, " & _
             "pi.ImageURL " & _
             "FROM OrderDetails od " & _
             "LEFT JOIN Products p ON od.ProductID = p.ProductID " & _
             "LEFT JOIN ProductImages pi ON p.ProductID = pi.ProductID AND pi.IsMainImage = 1 " & _
             "WHERE od.OrderID = " & orderId & " " & _
             "ORDER BY od.DetailID"
Set rsDetails = conn.Execute(sqlDetails)
%>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Chi tiết đơn hàng #<%=orderId%> - TORANO</title>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/normalize/8.0.1/normalize.min.css">
    <link rel="stylesheet" href="../../assets/css/base.css">
    <link rel="stylesheet" href="../../assets/css/header-footer.css">
    <link rel="stylesheet" href="/assets/fonts/fontawesome-free-6.7.2-web/css/all.min.css">
    <style>
        .order-detail-container {
            max-width: 1200px;
            margin: 0 auto;
            padding: 40px 20px;
            font-size: 1.4rem;
        }

        .back-link {
            display: inline-flex;
            align-items: center;
            gap: 8px;
            color: #666;
            text-decoration: none;
            margin-bottom: 30px;
            font-size: 1.4rem;
            transition: color 0.2s;
        }

        .back-link:hover {
            color: #333;
        }

        .order-header {
            background: white;
            padding: 30px;
            border-radius: 8px;
            margin-bottom: 20px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.08);
        }

        .order-title {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 20px;
            padding-bottom: 20px;
            border-bottom: 2px solid #f0f0f0;
        }

        .order-title h1 {
            font-size: 2.4rem;
            font-weight: 600;
            color: #333;
        }

        .order-status-badge {
            display: inline-flex;
            align-items: center;
            gap: 8px;
            padding: 10px 20px;
            border-radius: 20px;
            font-size: 1.5rem;
            font-weight: 600;
        }

        .status-pending {
            background: #fff3e0;
            color: #f57c00;
        }

        .status-shipping {
            background: #e3f2fd;
            color: #1976d2;
        }

        .status-completed {
            background: #e8f5e9;
            color: #388e3c;
        }

        .status-cancelled {
            background: #ffebee;
            color: #d32f2f;
        }

        .order-info-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 20px;
        }

        .info-item {
            display: flex;
            flex-direction: column;
            gap: 5px;
        }

        .info-label {
            color: #999;
            font-size: 1.3rem;
            font-weight: 500;
        }

        .info-value {
            color: #333;
            font-size: 1.5rem;
            font-weight: 500;
        }

        /* Cancel Button */
        .cancel-order-section {
            margin-top: 20px;
            padding-top: 20px;
            border-top: 2px solid #f0f0f0;
            display: flex;
            justify-content: flex-end;
        }

        .btn-cancel-order {
            background: #fff;
            border: 2px solid #d32f2f;
            color: #d32f2f;
            padding: 12px 30px;
            font-size: 1.5rem;
            font-weight: 600;
            border-radius: 6px;
            cursor: pointer;
            transition: all 0.3s;
            display: inline-flex;
            align-items: center;
            gap: 8px;
        }

        .btn-cancel-order:hover {
            background: #d32f2f;
            color: white;
        }

        /* Modal */
        .modal {
            display: none;
            position: fixed;
            z-index: 1000;
            left: 0;
            top: 0;
            width: 100%;
            height: 100%;
            background-color: rgba(0,0,0,0.5);
            animation: fadeIn 0.3s;
        }

        @keyframes fadeIn {
            from { opacity: 0; }
            to { opacity: 1; }
        }

        .modal-content {
            background-color: #fefefe;
            margin: 10% auto;
            padding: 0;
            border-radius: 8px;
            width: 90%;
            max-width: 500px;
            box-shadow: 0 4px 20px rgba(0,0,0,0.15);
            animation: slideDown 0.3s;
        }

        @keyframes slideDown {
            from {
                transform: translateY(-50px);
                opacity: 0;
            }
            to {
                transform: translateY(0);
                opacity: 1;
            }
        }

        .modal-header {
            padding: 20px 25px;
            background: #d32f2f;
            color: white;
            border-radius: 8px 8px 0 0;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }

        .modal-header h2 {
            font-size: 1.8rem;
            font-weight: 600;
            margin: 0;
        }

        .close {
            color: white;
            font-size: 2.8rem;
            font-weight: bold;
            cursor: pointer;
            line-height: 1;
            transition: opacity 0.2s;
        }

        .close:hover {
            opacity: 0.7;
        }

        .modal-body {
            padding: 25px;
        }

        .form-group {
            margin-bottom: 20px;
        }

        .form-group label {
            display: block;
            margin-bottom: 8px;
            font-weight: 600;
            color: #333;
            font-size: 1.4rem;
        }

        .form-group textarea {
            width: 100%;
            padding: 12px;
            border: 2px solid #e0e0e0;
            border-radius: 6px;
            font-size: 1.4rem;
            font-family: inherit;
            resize: vertical;
            min-height: 100px;
            transition: border-color 0.3s;
        }

        .form-group textarea:focus {
            outline: none;
            border-color: #d32f2f;
        }

        .modal-footer {
            padding: 20px 25px;
            display: flex;
            gap: 10px;
            justify-content: flex-end;
            border-top: 1px solid #f0f0f0;
        }

        .btn {
            padding: 10px 25px;
            font-size: 1.4rem;
            font-weight: 600;
            border-radius: 6px;
            border: none;
            cursor: pointer;
            transition: all 0.3s;
        }

        .btn-secondary {
            background: #f5f5f5;
            color: #666;
        }

        .btn-secondary:hover {
            background: #e0e0e0;
        }

        .btn-danger {
            background: #d32f2f;
            color: white;
        }

        .btn-danger:hover {
            background: #b71c1c;
        }

        /* Success Message */
        .success-message {
            background: #e8f5e9;
            border-left: 4px solid #4caf50;
            color: #2e7d32;
            padding: 15px 20px;
            margin-bottom: 20px;
            border-radius: 4px;
            display: flex;
            align-items: center;
            gap: 10px;
            font-size: 1.4rem;
            animation: slideDown 0.3s;
        }

        .success-message i {
            font-size: 2rem;
        }

        /* Receiver Info Section */
        .receiver-section {
            background: white;
            padding: 30px;
            border-radius: 8px;
            margin-bottom: 20px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.08);
        }

        .section-title {
            font-size: 1.8rem;
            font-weight: 600;
            color: #333;
            margin-bottom: 20px;
            display: flex;
            align-items: center;
            gap: 10px;
        }

        .section-title i {
            color: #666;
        }

        .receiver-info {
            display: grid;
            gap: 15px;
        }

        .receiver-row {
            display: flex;
            gap: 10px;
            padding: 12px 0;
            border-bottom: 1px solid #f5f5f5;
        }

        .receiver-row:last-child {
            border-bottom: none;
        }

        .receiver-label {
            flex: 0 0 140px;
            color: #666;
            font-weight: 500;
        }

        .receiver-value {
            flex: 1;
            color: #333;
        }

        /* Products Section */
        .products-section {
            background: white;
            padding: 30px;
            border-radius: 8px;
            margin-bottom: 20px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.08);
        }

        .product-item {
            display: flex;
            gap: 20px;
            padding: 20px 0;
            border-bottom: 1px solid #f0f0f0;
        }

        .product-item:first-of-type {
            padding-top: 0;
        }

        .product-item:last-child {
            border-bottom: none;
        }

        .product-image {
            flex: 0 0 100px;
            height: 100px;
            border-radius: 8px;
            overflow: hidden;
            border: 1px solid #f0f0f0;
            background: #f9f9f9;
        }

        .product-image img {
            width: 100%;
            height: 100%;
            object-fit: cover;
        }

        .product-info {
            flex: 1;
            display: flex;
            flex-direction: column;
            gap: 8px;
        }

        .product-name {
            font-size: 1.6rem;
            font-weight: 600;
            color: #333;
            line-height: 1.4;
        }

        .product-variant {
            display: flex;
            gap: 15px;
            color: #666;
            font-size: 1.3rem;
        }

        .product-variant span {
            display: flex;
            align-items: center;
            gap: 5px;
        }

        .product-quantity {
            color: #666;
            font-size: 1.3rem;
        }

        .product-price {
            display: flex;
            flex-direction: column;
            align-items: flex-end;
            gap: 5px;
        }

        .unit-price {
            color: #666;
            font-size: 1.4rem;
        }

        .total-price {
            font-size: 1.7rem;
            font-weight: 600;
            color: #333;
        }

        /* Payment Summary */
        .payment-section {
            background: white;
            padding: 30px;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.08);
        }

        .payment-summary {
            max-width: 400px;
            margin-left: auto;
        }

        .summary-row {
            display: flex;
            justify-content: space-between;
            padding: 12px 0;
            font-size: 1.5rem;
        }

        .summary-row.total {
            border-top: 2px solid #f0f0f0;
            margin-top: 10px;
            padding-top: 20px;
            font-size: 1.8rem;
            font-weight: 600;
            color: #333;
        }

        .summary-label {
            color: #666;
        }

        .summary-value {
            color: #333;
            font-weight: 500;
        }

        .summary-row.total .summary-value {
            color: #e53935;
            font-size: 2rem;
        }

        .payment-method-info {
            background: #f9f9f9;
            padding: 15px;
            border-radius: 6px;
            margin-top: 20px;
            display: flex;
            align-items: center;
            gap: 10px;
            font-size: 1.4rem;
        }

        .payment-method-info i {
            color: #666;
        }

        .note-section {
            margin-top: 20px;
            padding-top: 20px;
            border-top: 1px solid #f0f0f0;
        }

        .note-label {
            color: #999;
            font-size: 1.3rem;
            margin-bottom: 8px;
            font-weight: 500;
        }

        .note-content {
            color: #666;
            font-size: 1.4rem;
            font-style: italic;
            background: #f9f9f9;
            padding: 12px 15px;
            border-radius: 6px;
        }

        .empty-products {
            text-align: center;
            padding: 40px 20px;
            color: #999;
        }

        @keyframes fadeOut {
            from { opacity: 1; }
            to { opacity: 0; }
        }

        /* Responsive */
        @media (max-width: 768px) {
            .order-detail-container {
                padding: 20px 15px;
            }

            .order-header,
            .receiver-section,
            .products-section,
            .payment-section {
                padding: 20px;
            }

            .order-title {
                flex-direction: column;
                align-items: flex-start;
                gap: 15px;
            }

            .order-title h1 {
                font-size: 2rem;
            }

            .product-item {
                flex-direction: column;
            }

            .product-image {
                flex: 0 0 auto;
                width: 100%;
                height: 200px;
            }

            .product-price {
                flex-direction: row;
                justify-content: space-between;
                align-items: center;
            }

            .payment-summary {
                max-width: 100%;
            }

            .modal-content {
                margin: 20% auto;
                width: 95%;
            }

            .cancel-order-section {
                justify-content: center;
            }

            .btn-cancel-order {
                width: 100%;
                justify-content: center;
            }
        }
    </style>
</head>
<body>
    <div id="header"></div>

    <div class="order-detail-container">
        <a href="account.asp#orders" class="back-link">
            <i class="fas fa-arrow-left"></i>
            <span>Quay lại đơn hàng</span>
        </a>

        <%If Request.QueryString("msg") = "cancelled" Then%>
        <div class="success-message">
            <i class="fas fa-check-circle"></i>
            <span>Đơn hàng đã được hủy thành công!</span>
        </div>
        <%End If%>

        <!-- Order Header -->
        <div class="order-header">
            <div class="order-title">
                <h1>Đơn hàng #<%=orderId%></h1>
                <span class="order-status-badge <%=statusClass%>">
                    <i class="fas <%=statusIcon%>"></i>
                    <%=statusText%>
                </span>
            </div>

            <div class="order-info-grid">
                <div class="info-item">
                    <span class="info-label">Ngày đặt hàng</span>
                    <span class="info-value"><%=FormatDateTime(orderDate, 2)%></span>
                </div>
                <div class="info-item">
                    <span class="info-label">Phương thức thanh toán</span>
                    <span class="info-value"><%=paymentMethod%></span>
                </div>
            </div>

            <%If canCancel Then%>
            <div class="cancel-order-section">
                <button class="btn-cancel-order" onclick="openCancelModal()">
                    <i class="fas fa-times-circle"></i>
                    <span>Hủy đơn hàng</span>
                </button>
            </div>
            <%End If%>
        </div>

        <!-- Receiver Information -->
        <div class="receiver-section">
            <h2 class="section-title">
                <i class="fas fa-map-marker-alt"></i>
                Thông tin người nhận
            </h2>
            <div class="receiver-info">
                <div class="receiver-row">
                    <span class="receiver-label">Người nhận:</span>
                    <span class="receiver-value"><%=receiverName%></span>
                </div>
                <div class="receiver-row">
                    <span class="receiver-label">Số điện thoại:</span>
                    <span class="receiver-value"><%=receiverPhone%></span>
                </div>
                <div class="receiver-row">
                    <span class="receiver-label">Email:</span>
                    <span class="receiver-value"><%=receiverEmail%></span>
                </div>
                <div class="receiver-row">
                    <span class="receiver-label">Địa chỉ:</span>
                    <span class="receiver-value"><%=receiverAddress%></span>
                </div>
            </div>

            <%If note <> "" And Not IsNull(note) Then%>
            <div class="note-section">
                <div class="note-label">Ghi chú đơn hàng:</div>
                <div class="note-content"><%=note%></div>
            </div>
            <%End If%>
        </div>

        <!-- Products List -->
        <div class="products-section">
            <h2 class="section-title">
                <i class="fas fa-box"></i>
                Sản phẩm đã đặt
            </h2>

            <%
            If rsDetails.EOF Then
            %>
                <div class="empty-products">
                    <i class="fas fa-box-open" style="font-size: 3rem; margin-bottom: 10px; color: #ddd;"></i>
                    <p>Không có sản phẩm trong đơn hàng này</p>
                </div>
            <%
            Else
                Do While Not rsDetails.EOF
                    Dim productName, imageURL, quantity, price, color, size, detailTotal
                    productName = rsDetails("ProductName")
                    
                    ' Xử lý ảnh - kiểm tra null
                    If IsNull(rsDetails("ImageURL")) Or rsDetails("ImageURL") = "" Then
                        imageURL = ""
                    Else
                        imageURL = rsDetails("ImageURL")
                    End If
                    
                    quantity = rsDetails("Quantity")
                    price = rsDetails("Price")
                    
                    ' Xử lý Color và Size - kiểm tra null
                    If IsNull(rsDetails("Color")) Then
                        color = ""
                    Else
                        color = rsDetails("Color")
                    End If
                    
                    If IsNull(rsDetails("Size")) Then
                        size = ""
                    Else
                        size = rsDetails("Size")
                    End If
                    
                    detailTotal = quantity * price
            %>
            <div class="product-item">
                <div class="product-image">
                    <%If imageURL <> "" Then%>
                    <img src="<%=imageURL%>" alt="<% Call WriteUTF8(productName)%>">
                    <%Else%>
                    <img src="/assets/images/no-image.jpg" alt="No image">
                    <%End If%>
                </div>

                <div class="product-info">
                    <div class="product-name"><% Call WriteUTF8(productName)%></div>
                    <%If color <> "" Or size <> "" Then%>
                    <div class="product-variant">
                        <%If color <> "" Then%>
                        <span><strong>Màu:</strong> <%=color%></span>
                        <%End If%>
                        <%If size <> "" Then%>
                        <span><strong>Size:</strong> <%=size%></span>
                        <%End If%>
                    </div>
                    <%End If%>
                    <div class="product-quantity">Số lượng: <%=quantity%></div>
                </div>

                <div class="product-price">
                    <div class="unit-price"><%=FormatNumber(price, 0)%>₫</div>
                    <div class="total-price"><%=FormatNumber(detailTotal, 0)%>₫</div>
                </div>
            </div>
            <%
                    rsDetails.MoveNext
                Loop
            End If
            rsDetails.Close
            %>
        </div>

        <!-- Payment Summary -->
        <div class="payment-section">
            <h2 class="section-title">
                <i class="fas fa-file-invoice-dollar"></i>
                Thanh toán
            </h2>

            <div class="payment-summary">
                <div class="summary-row">
                    <span class="summary-label">Tổng tiền hàng:</span>
                    <span class="summary-value"><%=FormatNumber(totalAmount, 0)%>₫</span>
                </div>
                <div class="summary-row">
                    <span class="summary-label">Phí vận chuyển:</span>
                    <span class="summary-value"><%=FormatNumber(shippingFee, 0)%>₫</span>
                </div>
                <div class="summary-row total">
                    <span class="summary-label">Tổng thanh toán:</span>
                    <span class="summary-value"><%=FormatNumber(finalAmount, 0)%>₫</span>
                </div>

                <div class="payment-method-info">
                    <i class="fas fa-wallet"></i>
                    <span>Phương thức: <strong><%=paymentMethod%></strong></span>
                </div>
            </div>
        </div>
    </div>

    <!-- Cancel Order Modal -->
    <div id="cancelModal" class="modal">
        <div class="modal-content">
            <div class="modal-header">
                <h2>Xác nhận hủy đơn hàng</h2>
                <span class="close" onclick="closeCancelModal()">&times;</span>
            </div>
            <form method="POST" action="order-detail.asp?id=<%=orderId%>&action=cancel">
                <div class="modal-body">
                    <div class="form-group">
                        <label for="cancelReason">Lý do hủy đơn hàng: <span style="color: #d32f2f;">*</span></label>
                        <textarea 
                            id="cancelReason" 
                            name="cancelReason" 
                            placeholder="Vui lòng nhập lý do hủy đơn hàng (ví dụ: Đặt nhầm sản phẩm, Muốn đổi địa chỉ giao hàng...)"
                            required></textarea>
                    </div>
                    <p style="color: #666; font-size: 1.3rem; margin-top: 10px;">
                        <i class="fas fa-info-circle"></i> 
                        Đơn hàng đã hủy sẽ không thể khôi phục lại.
                    </p>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" onclick="closeCancelModal()">
                        Đóng
                    </button>
                    <button type="submit" class="btn btn-danger">
                        <i class="fas fa-check"></i> Xác nhận hủy
                    </button>
                </div>
            </form>
        </div>
    </div>

    <div id="footer"></div>

    <script>
        // Load header/footer
        async function loadComponent(id, file) {
            try {
                let res = await fetch(file);
                if(res.ok) document.getElementById(id).innerHTML = await res.text();
            } catch(e) { console.error(e); }
        }
        loadComponent("header", "../../FE/customer/component/header.asp");
        loadComponent("footer", "../../FE/customer/component/footer.html");

        // Modal functions
        function openCancelModal() {
            document.getElementById('cancelModal').style.display = 'block';
            document.body.style.overflow = 'hidden'; // Prevent body scroll
        }

        function closeCancelModal() {
            document.getElementById('cancelModal').style.display = 'none';
            document.body.style.overflow = 'auto'; // Re-enable body scroll
            document.getElementById('cancelReason').value = ''; // Clear textarea
        }

        // Close modal when clicking outside
        window.onclick = function(event) {
            const modal = document.getElementById('cancelModal');
            if (event.target == modal) {
                closeCancelModal();
            }
        }

        // Confirm before submit
        document.querySelector('#cancelModal form').addEventListener('submit', function(e) {
            const reason = document.getElementById('cancelReason').value.trim();
            if (reason.length < 10) {
                e.preventDefault();
                alert('Vui lòng nhập lý do hủy đơn ít nhất 10 ký tự!');
                return false;
            }
            
            const confirmed = confirm('Bạn có chắc chắn muốn hủy đơn hàng này? Hành động này không thể hoàn tác!');
            if (!confirmed) {
                e.preventDefault();
                return false;
            }
        });

        // Auto hide success message after 5 seconds
        window.addEventListener('DOMContentLoaded', function() {
            const successMsg = document.querySelector('.success-message');
            if (successMsg) {
                setTimeout(function() {
                    successMsg.style.animation = 'fadeOut 0.5s';
                    setTimeout(function() {
                        successMsg.style.display = 'none';
                    }, 500);
                }, 5000);
            }
        });
    </script>
    <script src="../../FE/js/header-footer.js"></script>