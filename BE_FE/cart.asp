<%@LANGUAGE="VBSCRIPT" CODEPAGE="65001"%>
<%
' --- 0. CẤU HÌNH & CHỐNG CACHE (QUAN TRỌNG ĐỂ TRÁNH LỖI LOOP) ---
Response.Buffer = True
%>
<!-- #include file="/BE/db/connect.asp" -->
<%
' Xóa Cache trình duyệt (Bắt buộc trình duyệt phải hỏi Server mỗi lần vào giỏ)
Response.Expires = -1
Response.ExpiresAbsolute = Now() - 1
Response.AddHeader "pragma", "no-cache"
Response.AddHeader "cache-control", "private"
Response.CacheControl = "no-cache"

' --- 1. HÀM HỖ TRỢ HIỂN THỊ TIẾNG VIỆT ---
Sub WriteUTF8(text)
    If IsNull(text) Or text = "" Then Exit Sub
    Dim stream
    Set stream = Server.CreateObject("ADODB.Stream")
    stream.Open
    stream.Type = 2
    stream.Charset = "UTF-8"
    stream.WriteText text
    stream.Position = 0
    stream.Type = 1
    If stream.Size > 3 Then
        stream.Position = 3
        Dim binaryData
        binaryData = stream.Read
        Response.BinaryWrite binaryData
    End If
    stream.Close
    Set stream = Nothing
End Sub

' --- 2. CẤU HÌNH & KHỞI TẠO ---

' [LOGIC MỚI] A. KIỂM TRA ĐĂNG NHẬP (CHẶN KHÁCH VÃNG LAI)
If IsEmpty(Session("UserID")) Or Session("UserID") = "" Then
    ' Chưa đăng nhập -> Chuyển hướng sang Login
    ' Kèm ?ret=cart.asp để đăng nhập xong quay lại đây
    Response.Redirect "login.asp?msg=view_cart_login&ret=cart.asp"
End If

' [LOGIC MỚI] B. LẤY ID NGƯỜI DÙNG
Dim currentSessionID
currentSessionID = Session("UserID")

Dim shippingThreshold
shippingThreshold = 500000

Dim totalAmount, cartCount, shippingPercent
totalAmount = 0
cartCount = 0
shippingPercent = 0

' --- 3. TRUY VẤN DỮ LIỆU GIỎ HÀNG ---
Dim sqlCart, rsCart
sqlCart = "SELECT c.CartID, c.ProductID, c.Quantity, c.ColorName, c.SizeName, " & _
          "p.ProductName, p.ProductCode, p.SalePrice, p.OriginalPrice, " & _
          "(SELECT TOP 1 ImageURL FROM ProductImages WHERE ProductID = p.ProductID AND IsMainImage = 1) AS MainImage " & _
          "FROM Cart c " & _
          "INNER JOIN Products p ON c.ProductID = p.ProductID " & _
          "WHERE c.SessionID = '" & currentSessionID & "' " & _
          "ORDER BY c.AddedDate DESC"

Set rsCart = Server.CreateObject("ADODB.Recordset")
rsCart.Open sqlCart, conn

' --- 4. TÍNH TỔNG TIỀN & SỐ LƯỢNG ---
Dim sqlSum
sqlSum = "SELECT " & _
         "ISNULL(SUM(CAST(c.Quantity AS DECIMAL(18,2)) * p.SalePrice), 0) as GrandTotal, " & _
         "ISNULL(SUM(c.Quantity), 0) as TotalCount " & _
         "FROM Cart c INNER JOIN Products p ON c.ProductID = p.ProductID " & _
         "WHERE c.SessionID = '" & currentSessionID & "'"

Dim rsSum
Set rsSum = conn.Execute(sqlSum)

If Not rsSum.EOF Then
    totalAmount = CDbl(rsSum("GrandTotal"))
    cartCount = CInt(rsSum("TotalCount"))
End If
rsSum.Close
Set rsSum = Nothing

' Cập nhật Session đếm giỏ hàng
Session("CartCount") = cartCount

' Tính % thanh Free Ship
If totalAmount >= shippingThreshold Then
    shippingPercent = 100
Else
    If shippingThreshold > 0 Then
        shippingPercent = Int((totalAmount / shippingThreshold) * 100)
    End If
End If
%>

<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Giỏ hàng - TORANO</title>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/normalize/8.0.1/normalize.min.css">
    <link rel="stylesheet" href="../../assets/css/base.css">
    <link rel="stylesheet" href="../../assets/css/main.css">
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link rel="stylesheet" href="/assets/fonts/fontawesome-free-6.7.2-web/css/all.min.css">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <link rel="stylesheet" href="../../assets/css/chiTietSanPham.css">
    <link rel="stylesheet" href="../../assets/css/cart.css">
    <link rel="stylesheet" href="../../assets/css/header-footer.css">
    
    <style>
        .cart-icon-wrap {
            position: relative;
            display: inline-block;
            text-decoration: none;
            color: inherit;
        }
        .cart-badge {
            position: absolute;
            top: -8px;
            right: -10px;
            background-color: #d0021b;
            color: white;
            font-size: 10px;
            font-weight: bold;
            padding: 2px 5px;
            border-radius: 10px;
            border: 1px solid #fff;
            min-width: 15px;
            text-align: center;
        }
    </style>
</head>
<body>
    <div id="header">
        <header>
    <div class="header-top">
        <div class="grid">
            <div class="header-top-info">
                <div class="header-top-item">
                    <p class="header-top-hotline header-top-item--separate">Hotline mua hàng: <span>0964942121</span>
                        (8:30-21:30, Tất cả các ngày trong tuần)</p>
                    <a href="" class="header-top-contact">Liên hệ</a>
                </div>
                <div class="header-top-item">
                    <a href="" class="header-top-link">
                        <i class="fa-solid fa-bell"></i>
                        Thông báo của tôi
                    </a>
                </div>
            </div>
        </div>
    </div>
    <div class="grid">
        <div class="navbar">
            <div class="navbar__logo">
                <a href="index.asp"><img class="logo-img" src="../assets/img/logo.png" alt="logo"></a>
            </div>
            <ul class="menu">
                <li><a href="#">Sản phẩm mới</a></li>
                <li><a href="#">Danh mục sale</a></li>

                <li class="has-dropdown">
                    <a href="#">
                        Áo nam
                        <i class="dropdown-icon fa-solid fa-angle-down"></i>
                    </a>
                    <ul class="dropdown">
                        <li><a href="#">Áo Khoác</a></li>
                        <li><a href="#">Áo - Quần Nỉ</a></li>
                        <li><a href="#">Áo Polo</a></li>
                        <li><a href="#">Áo Sơ Mi</a></li>
                        <li><a href="#">Áo Thun</a></li>
                        <li><a href="#">Áo Blazer</a></li>
                        <li><a href="#">Áo Len</a></li>
                    </ul>
                </li>

                <li class="has-dropdown">
                    <a href="#">
                        Quần nam
                        <i class="dropdown-icon fa-solid fa-angle-down"></i>
                    </a>
                    <ul class="dropdown">
                        <li><a href="#">Quần Dài Kaki</a></li>
                        <li><a href="#">Quần Âu</a></li>
                        <li><a href="#">Quần Gió</a></li>
                        <li><a href="#">Quần Jeans</a></li>
                        <li><a href="#">Quần Short</a></li>
                    </ul>
                </li>

                <li class="has-dropdown">
                    <a href="#">
                        Phụ kiện
                        <i class="dropdown-icon fa-solid fa-angle-down"></i>
                    </a>
                    <ul class="dropdown">
                        <li><a href="#">Thắt Lưng</a></li>
                    </ul>
                </li>

                <li><a href="#">Hệ thống cửa hàng</a></li>
            </ul>
            <ul class="icon-list">
                <li class="icon-list-item nav-search">
                    <i class="icon-list-icon fa-solid fa-magnifying-glass"></i>
                </li>
                <% If isLoggedIn Then %>
                    <!-- ĐÃ ĐĂNG NHẬP -->
                    <li class="icon-list-item icon-user">
                        <i class="icon-list-icon fa-regular fa-user"></i>
                        <div class="icon-wrap">
                            <div class="icon-wrap-header">
                                <p class="icon-txt">THÔNG TIN TÀI KHOẢN</p>
                            </div>
                            <ul class="icon-info">
                                <li class="icon-info-name"><span><%=Session("FullName")%></span></li>
                                <a href="account.asp" class="icon-info-link"><li class="icon-info-item">Tài khoản của tôi</li></a>
                                <a href="logout.asp" class="icon-info-link"><li class="icon-info-item">Đăng xuất</li></a>
                            </ul>
                        </div>
                    </li>
                <% Else %>
                    <!-- CHƯA ĐĂNG NHẬP -->
                    <li class="icon-list-item icon-user">
                        <i class="icon-list-icon fa-regular fa-user"></i>
                        <div class="icon-wrap icon-wrap-login">
                            <div class="icon-wrap-header">
                                <p class="icon-txt">ĐĂNG NHẬP TÀI KHOẢN</p>
                            </div>
                            <p class="login-subtitle">Nhập email và mật khẩu của bạn:</p>
                            
                            <!-- Div hiển thị lỗi (được điều khiển bằng JavaScript) -->
                            <div id="loginErrorMsg" class="login-error-msg" style="display: none;"></div>
                            
                            <form action="login-process.asp" method="POST" class="login-form-dropdown">
                                <div class="login-form-group">
                                    <input type="email" name="email" class="login-input" placeholder="Email" required>
                                </div>
                                <div class="login-form-group">
                                    <input type="password" name="password" class="login-input" placeholder="Mật khẩu" required>
                                </div>
                                <p class="recaptcha-notice">
                                    This site is protected by reCAPTCHA and the Google 
                                    <a href="https://policies.google.com/privacy" target="_blank">Privacy Policy</a> and 
                                    <a href="https://policies.google.com/terms" target="_blank">Terms of Service</a> apply.
                                </p>
                                <button type="submit" class="btn-login-dropdown">ĐĂNG NHẬP</button>
                                
                                <div class="login-links">
                                    <p>Khách hàng mới? <a href="register.asp" class="login-link">Tạo tài khoản</a></p>
                                    <p>Quên mật khẩu? <a href="forgot-password.asp" class="login-link">Khôi phục mật khẩu</a></p>
                                </div>
                            </form>
                        </div>
                    </li>
                <% End If %>
                <li class="icon-list-item">
                    <a href="cart.asp" class="cart-icon-wrap">
                        <i class="icon-list-icon fa-solid fa-cart-shopping"></i>
                        
                        <% If headerCartCount > 0 Then %>
                            <span class="cart-badge"><%=headerCartCount%></span>
                        <% End If %>
                    </a>
                </li>
            </ul>
        </div>
    </div>
</header>
    </div>
    
    <div class="container cart-container">
        
        <% If cartCount = 0 Then %>
            <div style="width: 100%; text-align: center; padding: 50px;">
                <img src="https://bizweb.dktcdn.net/100/320/202/themes/714916/assets/empty-cart.png" alt="Empty Cart" style="width: 200px; margin-bottom: 20px;">
                <h3>Giỏ hàng của bạn đang trống</h3>
                <p>Hãy chọn thêm sản phẩm để mua sắm nhé!</p>
                <a href="index.asp" class="btn-checkout" style="display: inline-block; width: auto; margin-top: 20px; text-decoration: none;">Tiếp tục mua sắm</a>
            </div>
        <% Else %>
            
            <div class="cart-left">
                <div class="cart-heading">
                    <h2>Giỏ hàng của bạn</h2>
                    <span class="cart-summary-text">Bạn đang có <strong><%=cartCount%> sản phẩm</strong> trong giỏ hàng</span>
                </div>

                <div class="shipping-progress-box">
                    <% If totalAmount >= shippingThreshold Then %>
                        <p>Bạn đã được <strong>MIỄN PHÍ VẬN CHUYỂN</strong></p>
                    <% Else %>
                        <p>Mua thêm <strong><%=FormatNumber(shippingThreshold - totalAmount, 0)%>₫</strong> để được <strong>MIỄN PHÍ VẬN CHUYỂN</strong></p>
                    <% End If %>
                    <div class="progress-bar-bg">
                        <div class="progress-bar-fill" style="width: <%=shippingPercent%>%;">
                            <i class="fas fa-truck truck-icon"></i>
                        </div>
                    </div>
                </div>

                <div class="cart-items">
                    <% 
                    Do While Not rsCart.EOF 
                        Dim pName, pImage, pPrice, pColor, pSize, pQty, cartID, prodID
                        
                        pName = rsCart("ProductName")
                        pColor = rsCart("ColorName")
                        pSize = rsCart("SizeName")
                        
                        If IsNull(rsCart("MainImage")) Or rsCart("MainImage") = "" Then
                            pImage = "images/no-image.jpg"
                        Else
                            pImage = rsCart("MainImage")
                        End If
                        
                        pPrice = rsCart("SalePrice")
                        pQty = rsCart("Quantity")
                        cartID = rsCart("CartID")
                        prodID = rsCart("ProductID")
                    %>
                    <div class="cart-item" id="item-<%=cartID%>">
                        <div class="item-remove">
                            <button title="Xóa sản phẩm" onclick="removeItem(<%=cartID%>)"><i class="fas fa-times"></i></button>
                        </div>
                        <div class="item-image">
                            <a href="product-detail.asp?id=<%=prodID%>">
                                <img src="<%=pImage%>" alt="Product Image">
                            </a>
                        </div>
                        <div class="item-info">
                            <h3><a href="product-detail.asp?id=<%=prodID%>"><% WriteUTF8(pName) %></a></h3>
                            
                            <div class="item-variant">
                                <% If pColor <> "" Then %>
                                    <% =pColor %> / 
                                <% End If %> 
                                <% WriteUTF8(pSize) %>
                            </div>
                            
                            <div class="item-price-mobile"><%=FormatNumber(pPrice, 0)%>₫</div>
                        </div>
                        <div class="item-price">
                            <div class="price-current"><%=FormatNumber(pPrice, 0)%>₫</div>
                        </div>
                        <div class="item-qty">
                            <div class="qty-controls">
                                <button class="qty-btn" onclick="updateCartQty(<%=cartID%>, -1)">-</button>
                                <input type="number" class="qty-input" value="<%=pQty%>" min="1" readonly>
                                <button class="qty-btn" onclick="updateCartQty(<%=cartID%>, 1)">+</button>
                            </div>
                        </div>
                    </div>
                    <% 
                        rsCart.MoveNext
                    Loop 
                    %>
                </div>

                <div class="cart-note">
                    <label for="orderNote">Ghi chú đơn hàng</label>
                    <textarea id="orderNote" name="orderNote" placeholder="Ghi chú thêm về đơn hàng (ví dụ: giao giờ hành chính)..."></textarea>
                </div>
            </div>

            <div class="cart-right">
                <div class="order-summary">
                    <h3>Thông tin đơn hàng</h3>
                    <div class="summary-line total">
                        <span>Tổng tiền:</span>
                        <span class="total-price"><%=FormatNumber(totalAmount, 0)%>₫</span>
                    </div>
                    
                    <ul class="summary-notes">
                        <li>Phí vận chuyển sẽ được tính ở trang thanh toán.</li>
                        <li>Bạn cũng có thể nhập mã giảm giá ở trang thanh toán.</li>
                    </ul>

                    <button class="btn-checkout" onclick="proceedToCheckout()">THANH TOÁN</button>

                    <div class="policy-box">
                        <h4>Chính sách mua hàng:</h4>
                        <p>Hiện chúng tôi chỉ áp dụng thanh toán với đơn hàng có giá trị tối thiểu <strong>0₫</strong> trở lên.</p>
                    </div>

                    <div class="promo-box">
                        <h4>Khuyến mãi dành cho bạn</h4>
                        <p style="color:#777; font-size:13px;">(Chưa có mã khuyến mãi nào)</p>
                    </div>
                </div>
            </div>

        <% End If %>
    </div>

    <div id="footer">
    </div>

    <script>
        function updateCartQty(cartId, change) {
            var url = "update-cart-action.asp?action=update&id=" + cartId + "&change=" + change;
            window.location.href = url;
        }

        function removeItem(cartId) {
            if(confirm("Bạn có chắc muốn xóa sản phẩm này khỏi giỏ hàng?")) {
                var url = "update-cart-action.asp?action=delete&id=" + cartId;
                window.location.href = url;
            }
        }

        function proceedToCheckout() {
            var note = document.getElementById('orderNote').value;
            window.location.href = "checkout.asp?note=" + encodeURIComponent(note);
        }
        async function loadComponent(id, file) {
      try {
          let res = await fetch(file);
          if(res.ok) document.getElementById(id).innerHTML = await res.text();
      } catch(e) { console.error(e); }
    }
    // Load Header & Footer
    loadComponent("header", "../../FE/customer/component/header.asp");
    loadComponent("footer", "../../FE/customer/component/footer.html");
    </script>
    <script src="../../FE/js/header-footer.js"></script>
</body>
</html>
<%
rsCart.Close
Set rsCart = Nothing
conn.Close
Set conn = Nothing
%>