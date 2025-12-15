<!-- #include file="../../../BE/db/connect.asp" -->
<%
' --- LOGIC ĐẾM GIỎ HÀNG CHO HEADER ---
Dim headerCartCount
headerCartCount = 0

' 1. Nếu Session đã có số lượng (do trang khác tính rồi) thì dùng luôn cho nhanh
If Not IsEmpty(Session("CartCount")) Then
    headerCartCount = CInt(Session("CartCount"))
Else
    ' 2. Nếu Session trống (mới vào web), phải query Database để đếm
    Dim h_sessID
    If Not IsEmpty(Session("UserID")) And Session("UserID") <> "" Then
        h_sessID = Session("UserID")
    Else
        h_sessID = Session.SessionID
    End If
    
    ' Chỉ chạy query nếu đã có kết nối CSDL (conn)
    ' Lưu ý: Đảm bảo trang cha (index.asp, products.asp...) đã include file connect.asp
    If IsObject(conn) Then
        Dim rsCount
        Set rsCount = conn.Execute("SELECT ISNULL(SUM(Quantity), 0) AS Total FROM Cart WHERE SessionID = '" & h_sessID & "'")
        If Not rsCount.EOF Then
            headerCartCount = CInt(rsCount("Total"))
        End If
        rsCount.Close
        Set rsCount = Nothing
        
        ' Lưu lại vào Session để lần sau đỡ phải query lại
        Session("CartCount") = headerCartCount
    End If
End If
%>
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