<%@LANGUAGE="VBSCRIPT" CODEPAGE="65001"%>

<!-- #include file="/BE/db/connect.asp" -->
<%
' --- HÀM ÉP HIỂN THỊ TIẾNG VIỆT (ĐÃ FIX LỖI 3 KÍ TỰ LẠ) ---
Sub WriteUTF8(text)
    If IsNull(text) Or text = "" Then Exit Sub
    Dim stream
    Set stream = Server.CreateObject("ADODB.Stream")
    stream.Open
    stream.Type = 2 ' adTypeText
    stream.Charset = "UTF-8"
    stream.WriteText text
    
    ' Chuyển sang chế độ Binary để xử lý Byte
    stream.Position = 0
    stream.Type = 1 ' adTypeBinary
    
    ' KIỂM TRA VÀ BỎ QUA 3 BYTE BOM (ï»¿)
    If stream.Size > 3 Then
        stream.Position = 3 ' <--- QUAN TRỌNG: Nhảy qua 3 ký tự đầu
        Dim binaryData
        binaryData = stream.Read ' Chỉ đọc phần nội dung phía sau
        Response.BinaryWrite binaryData
    End If
    
    stream.Close
    Set stream = Nothing
End Sub

' --- 2. CẤU HÌNH & KHỞI TẠO ---
Dim currentSessionID
currentSessionID = Session.SessionID

Dim shippingThreshold
shippingThreshold = 500000

Dim totalAmount, cartCount, shippingPercent
totalAmount = 0
cartCount = 0
shippingPercent = 0

' --- 3. TRUY VẤN DỮ LIỆU GIỎ HÀNG (ĐỂ HIỂN THỊ) ---
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

' --- 4. TÍNH TỔNG TIỀN (SỬA LẠI ĐOẠN NÀY) ---
Dim sqlSum
' SỬ DỤNG ISNULL TRONG SQL ĐỂ ĐẢM BẢO KHÔNG BỊ TRẢ VỀ NULL
sqlSum = "SELECT " & _
         "ISNULL(SUM(CAST(c.Quantity AS DECIMAL(18,2)) * p.SalePrice), 0) as GrandTotal, " & _
         "ISNULL(SUM(c.Quantity), 0) as TotalCount " & _
         "FROM Cart c INNER JOIN Products p ON c.ProductID = p.ProductID " & _
         "WHERE c.SessionID = '" & currentSessionID & "'"

Dim rsSum
Set rsSum = conn.Execute(sqlSum)

If Not rsSum.EOF Then
    ' Lấy giá trị trực tiếp vì SQL đã xử lý ISNULL rồi, không sợ lỗi nữa
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
    <link rel="stylesheet" href="../../assets/css/header-footer.css">
    <link rel="stylesheet" href="../../assets/css/register.css">
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link rel="stylesheet" href="/assets/fonts/fontawesome-free-6.7.2-web/css/all.min.css">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <link rel="stylesheet" href="../../assets/css/chiTietSanPham.css">
    <link rel="stylesheet" href="../../assets/css/cart.css">
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
                <li class="icon-list-item icon-user">
                    <i class="icon-list-icon fa-regular fa-user"></i>
                    <div class="icon-wrap">
                        <div class="icon-wrap-header">
                            <p class="icon-txt">THÔNG TIN TÀI KHOẢN</p>
                        </div>
                        <ul class="icon-info">
                        <li class="icon-info-name"><span>HOANG GIA BAO</span></li>
                        <a href="" class="icon-info-link"><li class="icon-info-item">Tài khoản của tôi</li></a>
                        <a href="" class="icon-info-link"><li class="icon-info-item">Danh sách địa chỉ</li></a>
                        <a href="" class="icon-info-link"><li class="icon-info-item">Đăng xuất</li></a>
                    </ul>
                    </div>
                </li>
                <li class="icon-list-item">
                    <i class="icon-list-icon fa-solid fa-cart-shopping"></i>
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
                        
                        ' --- LẤY DỮ LIỆU ---
                        pName = rsCart("ProductName") ' Chuỗi tiếng Việt cần xử lý
                        pColor = rsCart("ColorName")  ' Chuỗi tiếng Việt cần xử lý
                        pSize = rsCart("SizeName")    ' Chuỗi tiếng Việt cần xử lý
                        
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
                                    <% WriteUTF8(pColor) %> / 
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
        <footer>
  <div class="footer-main">
    <div class="footer-column">
      <h4>Thời trang nam Lavab</h4>
      <p>Hệ thống thời trang cho phái mạnh hàng đầu Việt Nam, hướng tới phong cách nam tính, lịch lãm và trẻ trung.</p>
      <div class="social-icons">
        <a href="#" aria-label="Facebook" title="Facebook">&#xF09A;</a>
        <a href="#" aria-label="Twitter" title="Twitter">&#xF099;</a>
        <a href="#" aria-label="Instagram" title="Instagram">&#xF16D;</a>
        <a href="#" aria-label="TikTok" title="TikTok">🎵</a>
        <a href="#" aria-label="Youtube" title="Youtube">&#xF167;</a>
      </div>
      <h5>Phương thức thanh toán</h5>
      <div class="payment-icons">
        <img src="/assets/img/vnpay.png" alt="VNPay" />
        <img src="/assets/img/zalopay.png" alt="ZaloPay" />
        <img src="/assets/img/moca.png" alt="Moca" />
        <img src="/assets/img/kredio.png" alt="Kredivo" />
        <img src="/assets/img/napas.png" alt="Napas" />
        <img src="/assets/img/visa.png" alt="Visa" />
      </div>
    </div>
    <div class="footer-column">
      <h4>Thông tin liên hệ</h4>
      <p><b>Địa chỉ:</b>55 Đ. Giải Phóng, Đồng Tâm, Hai Bà Trưng, Hà Nội</p>
      <p><b>Điện thoại:</b> 0964942121</p>
      <p><b>Fax:</b> 0904636356</p>
      <p><b>Email:</b> cskh@lavab.vn</p>
      <h5>Phương thức vận chuyển</h5>
      <div class="shipping-icons">
        <img src="/assets/img/GHN.png" alt="GHN Express" />
        <img src="/assets/img/ninja.png" alt="Ninja Van" />
        <img src="/assets/img/ahamove.png" alt="Ahamove" />
        <img src="/assets/img/jt.png" alt="JT Express" />
      </div>
    </div>
    <div class="footer-column">
      <h4>Nhóm liên kết</h4>
      <ul>
        <li>Tìm kiếm</li>
        <li>Giới thiệu</li>
        <li>Chính sách đổi trả</li>
        <li>Chính sách bảo mật</li>
        <li>Tuyển dụng</li>
        <li>Liên hệ</li>
      </ul>
    </div>
    <div class="footer-column newsletter">
      <h4>Đăng ký nhận tin</h4>
      <p>Để cập nhật những sản phẩm mới, nhận thông tin ưu đãi đặc biệt và thông tin giảm giá khác.</p>
      <form>
        <input type="email" placeholder="Nhập email của bạn" required>
        <button type="submit">ĐĂNG KÝ</button>
      </form>
      <img src="../assets/img/bocongthuong.png"
        alt="Đã thông báo Bộ Công Thương" class="cert" />
    </div>
  </div>
  <div class="footer-bottom">
    <p>Copyright © 2025 Lavab. Powered by Nhom1</p>
  </div>
</footer>
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