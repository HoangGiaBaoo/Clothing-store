<%@LANGUAGE="VBSCRIPT" CODEPAGE="65001"%>
<% Response.CharSet = "UTF-8" %>
<!-- #include file="/BE/db/connect.asp" -->
<%
' --- HÀM XỬ LÝ HIỂN THỊ TIẾNG VIỆT (BẤT CHẤP SERVER) ---
' Hàm này chuyển chuỗi thành Binary UTF-8 và ghi trực tiếp ra luồng
Sub WriteUTF8(text)
    If IsNull(text) Or text = "" Then Exit Sub
    
    Dim stream
    Set stream = Server.CreateObject("ADODB.Stream")
    stream.Open
    stream.Type = 2 ' adTypeText
    stream.Charset = "UTF-8"
    stream.WriteText text
    stream.Position = 0
    stream.Type = 1 ' adTypeBinary
    ' Bỏ qua 3 byte đầu (BOM) nếu có, để tránh lỗi ký tự lạ giữa trang
    If stream.Size > 3 Then
        stream.Position = 3
        Dim binaryData
        binaryData = stream.Read
        Response.BinaryWrite binaryData
    End If
    stream.Close
    Set stream = Nothing
End Sub

' ---------------------------------------------------------

' KHÔNG dùng Option Explicit
If Session("CartCount") = "" Then Session("CartCount") = 0

' Xử lý ID
Dim productId
productId = Request.QueryString("id")
If productId = "" Or Not IsNumeric(productId) Then productId = 1 Else productId = CLng(productId)

' Lấy thông tin sản phẩm
Dim sqlProduct, rsProduct
sqlProduct = "SELECT TOP 1 p.*, b.BrandName, c.CategoryName " & _
             "FROM Products p " & _
             "LEFT JOIN Brands b ON p.BrandID = b.BrandID " & _
             "LEFT JOIN Categories c ON p.CategoryID = c.CategoryID " & _
             "WHERE p.ProductID = " & productId & " AND p.IsActive = 1"

Set rsProduct = Server.CreateObject("ADODB.Recordset")
On Error Resume Next
rsProduct.Open sqlProduct, conn
If Err.Number <> 0 Then
    Response.Write "Error: " & Err.Description
    Response.End
End If
On Error GoTo 0

If rsProduct.EOF Then
    rsProduct.Close
    ' Fallback lấy sản phẩm đầu tiên
    sqlProduct = "SELECT TOP 1 p.*, b.BrandName, c.CategoryName FROM Products p LEFT JOIN Brands b ON p.BrandID = b.BrandID LEFT JOIN Categories c ON p.CategoryID = c.CategoryID WHERE p.IsActive = 1 ORDER BY p.ProductID"
    rsProduct.Open sqlProduct, conn
    If rsProduct.EOF Then Response.End
    productId = rsProduct("ProductID")
End If

' Lấy dữ liệu ra biến
Dim productName, productCode, brandName, salePrice, originalPrice, detailDescription
Dim categoryName, categoryId, material, fitType, origin

If Not rsProduct.EOF Then
    ' Lấy dữ liệu thô từ DB, chưa in ra màn hình vội
    productName = rsProduct("ProductName")
    productCode = rsProduct("ProductCode")
    brandName = rsProduct("BrandName")
    categoryName = rsProduct("CategoryName")
    categoryId = rsProduct("CategoryID")
    detailDescription = rsProduct("DetailDescription")
    material = rsProduct("Material")
    fitType = rsProduct("FitType")
    origin = rsProduct("Origin")
    
    If IsNull(salePrice) Then salePrice = 0 Else salePrice = CDbl(rsProduct("SalePrice"))
    If IsNull(originalPrice) Then originalPrice = 0 Else originalPrice = CDbl(rsProduct("OriginalPrice"))
End If

' Lấy hình ảnh
Dim sqlImages, rsImages
sqlImages = "SELECT ImageURL, IsMainImage FROM ProductImages WHERE ProductID = " & productId & " ORDER BY DisplayOrder"
Set rsImages = Server.CreateObject("ADODB.Recordset")
rsImages.Open sqlImages, conn

' Lấy màu sắc
Dim sqlColors, rsColors
sqlColors = "SELECT DISTINCT ColorName FROM ProductVariants WHERE ProductID = " & productId & " AND IsActive = 1"
Set rsColors = Server.CreateObject("ADODB.Recordset")
rsColors.Open sqlColors, conn

' Lấy kích thước
Dim sqlSizes, rsSizes
sqlSizes = "SELECT DISTINCT SizeName, SizeOrder FROM ProductVariants WHERE ProductID = " & productId & " AND IsActive = 1 ORDER BY SizeOrder"
Set rsSizes = Server.CreateObject("ADODB.Recordset")
On Error Resume Next
rsSizes.Open sqlSizes, conn
If Err.Number <> 0 Then
    sqlSizes = "SELECT DISTINCT SizeName FROM ProductVariants WHERE ProductID = " & productId & " AND IsActive = 1"
    rsSizes.Close
    rsSizes.Open sqlSizes, conn
End If
On Error GoTo 0

' Màu/Size mặc định
Dim selectedColor, selectedSize
selectedColor = "Mặc định"
selectedSize = "Mặc định"
If Not rsColors.EOF Then 
    rsColors.MoveFirst
    If Not IsNull(rsColors("ColorName")) Then selectedColor = Trim(rsColors("ColorName"))
End If
If Not rsSizes.EOF Then 
    rsSizes.MoveFirst
    If Not IsNull(rsSizes("SizeName")) Then selectedSize = Trim(rsSizes("SizeName"))
End If

' Tính giảm giá
Dim discountPercent : discountPercent = 0
If IsNumeric(originalPrice) And IsNumeric(salePrice) Then
    If originalPrice > 0 And originalPrice > salePrice Then
        discountPercent = Int((1 - salePrice/originalPrice) * 100)
    End If
End If
%>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><% WriteUTF8(productName) %> - TORANO</title>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/normalize/8.0.1/normalize.min.css">
    <link rel="stylesheet" href="../../assets/css/base.css">
    <link rel="stylesheet" href="../../assets/css/main.css">
    <link rel="stylesheet" href="../../assets/css/header-footer.css">
    <link rel="stylesheet" href="../../assets/css/register.css">
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link rel="stylesheet" href="/assets/fonts/fontawesome-free-6.7.2-web/css/all.min.css">
    <link href="https://fonts.googleapis.com/css2?family=Roboto:ital,wght@0,100..900;1,100..900&display=swap"
        rel="stylesheet">
    <link rel="stylesheet" href="../../assets/css/chiTietSanPham.css">
</head>
<body>
    <div id="header"></div>

    <div class="breadcrumb">
        <div class="breadcrumb-content">
            <a href="index.asp">Trang chủ</a>
            <span>/</span>
            <% If categoryName <> "" Then %>
                <a href="products.asp?cat=<%=categoryId%>"><% WriteUTF8(categoryName) %></a>
                <span>/</span>
            <% End If %>
            <span class="current"><% WriteUTF8(productName) %></span>
        </div>
    </div>

    <div class="container">
        <div class="product-container">
            <div class="product-images">
                <div class="main-image">
                    <%
                    Dim mainImageFound : mainImageFound = false
                    If Not rsImages.EOF Then
                        rsImages.MoveFirst
                        Do While Not rsImages.EOF
                            If rsImages("IsMainImage") = True Then
                                mainImageFound = true
                    %>
                    <img src="<%=rsImages("ImageURL")%>" alt="Product Image" id="mainImg">
                    <%
                                Exit Do
                            End If
                            rsImages.MoveNext
                        Loop
                        If Not mainImageFound Then
                            rsImages.MoveFirst
                    %>
                    <img src="<%=rsImages("ImageURL")%>" alt="Product Image" id="mainImg">
                    <%
                        End If
                    Else
                    %>
                    <img src="images/no-image.jpg" alt="No Image" id="mainImg">
                    <% End If %>
                </div>
                <div class="thumbnails" id="thumbnailContainer">
                    <%
                    If Not rsImages.EOF Then
                        rsImages.MoveFirst
                        Dim thumbCount : thumbCount = 0
                        Do While Not rsImages.EOF And thumbCount < 6
                            Dim thumbClass : If thumbCount = 0 Then thumbClass = "active" Else thumbClass = ""
                    %>
                    <div class="thumbnail <%=thumbClass%>" onclick="changeImage('<%=rsImages("ImageURL")%>', this)">
                        <img src="<%=rsImages("ImageURL")%>" alt="Thumb">
                    </div>
                    <%
                            thumbCount = thumbCount + 1
                            rsImages.MoveNext
                        Loop
                    End If
                    %>
                </div>
            </div>

            <div class="product-info">
                <h1 class="product-title"><% WriteUTF8(productName) %></h1>

                <div class="price-section">
                    <span class="current-price"><%=FormatNumber(salePrice, 0)%>₫</span>
                    <% If discountPercent > 0 Then %>
                    <span class="old-price"><%=FormatNumber(originalPrice, 0)%>₫</span>
                    <span class="discount-badge">-<%=discountPercent%>%</span>
                    <% End If %>
                </div>

                <div class="option-section">
                    <span class="option-label">Màu sắc:</span>
                    <span class="option-value" id="selectedColor"><% WriteUTF8(selectedColor) %></span>
                    <div class="option-buttons" id="colorButtons">
                        <%
                        If Not rsColors.EOF Then
                            rsColors.MoveFirst
                            Do While Not rsColors.EOF
                                Dim colorValue
                                If IsNull(rsColors("ColorName")) Then colorValue = "Mặc định" Else colorValue = Trim(rsColors("ColorName"))
                                
                                Dim isColorActive
                                If colorValue = selectedColor Then isColorActive = "active" Else isColorActive = ""
                        %>
                        <button class="option-btn <%=isColorActive%>" 
                                onclick="selectColor('<% WriteUTF8(colorValue) %>', this)">
                            <% WriteUTF8(colorValue) %>
                        </button>
                        <%
                                rsColors.MoveNext
                            Loop
                        End If
                        %>
                    </div>
                </div>

                <div class="option-section">
                    <span class="option-label">Kích thước:</span>
                    <span class="option-value" id="selectedSize"><% WriteUTF8(selectedSize) %></span>
                    <div class="option-buttons" id="sizeButtons">
                        <%
                        If Not rsSizes.EOF Then
                            rsSizes.MoveFirst
                            Do While Not rsSizes.EOF
                                Dim sizeValue
                                If IsNull(rsSizes("SizeName")) Then sizeValue = "Mặc định" Else sizeValue = Trim(rsSizes("SizeName"))
                                
                                Dim isSizeActive
                                If sizeValue = selectedSize Then isSizeActive = "active" Else isSizeActive = ""
                        %>
                        <button class="option-btn <%=isSizeActive%>" 
                                onclick="selectSize('<% WriteUTF8(sizeValue) %>', this)">
                            <% WriteUTF8(sizeValue) %>
                        </button>
                        <%
                                rsSizes.MoveNext
                            Loop
                        End If
                        %>
                    </div>
                </div>

                <div class="quantity-section">
                    <span class="option-label">Số lượng:</span>
                    <div class="quantity-controls">
                        <div class="qty-controls">
                            <button class="qty-btn" onclick="changeQty(-1)">-</button>
                            <input type="number" class="qty-input" id="quantity" value="1" min="1" max="99">
                            <button class="qty-btn" onclick="changeQty(1)">+</button>
                        </div>
                    </div>
                </div>

                <div class="action-buttons">
                    <button class="btn btn-cart" onclick="addToCart()">Thêm vào giỏ hàng</button>
                    <button class="btn btn-buy" onclick="buyNow()">Mua ngay</button>
                </div>
                
                <div class="share-section">
                    <span class="option-label">Chia sẻ:</span>
                    <div class="social-icons">
                        <button class="social-btn social-facebook" data-tooltip="Facebook"><i class="fab fa-facebook-f"></i></button>
                        <button class="social-btn social-messenger" data-tooltip="Messenger"><i class="fab fa-facebook-messenger"></i></button>
                        <button class="social-btn social-twitter" data-tooltip="Twitter"><i class="fab fa-twitter"></i></button>
                        <button class="social-btn social-pinterest" data-tooltip="Pinterest"><i class="fab fa-pinterest-p"></i></button>
                        <button class="social-btn social-link" data-tooltip="Sao chép liên kết"><i class="fas fa-link"></i></button>
                    </div>
                </div>

                <div class="features">
                    <div class="feature-item feature-shipping">
                        <div class="feature-icon">🚚</div>
                        <div class="feature-text"><div class="feature-title">Miễn phí giao hàng</div><div class="feature-desc">cho đơn hàng từ 500K</div></div>
                    </div>
                    <div class="feature-item feature-authentic">
                        <div class="feature-icon">✓</div>
                        <div class="feature-text"><div class="feature-title">Hàng phẩm chính hãng</div><div class="feature-desc">100%</div></div>
                    </div>
                    <div class="feature-item feature-hotline">
                        <div class="feature-icon">📞</div>
                        <div class="feature-text"><div class="feature-title">TỔNG ĐÀI 24/7</div><div class="feature-desc">0337420408</div></div>
                    </div>
                </div>
            </div>
        </div>

        <div class="product-details">
            <div class="detail-tabs">
                <button class="tab-btn active" onclick="showTab('description')">Mô tả sản phẩm</button>
                <button class="tab-btn" onclick="showTab('specs')">Thông số kỹ thuật</button>
            </div>
            
            <div id="description" class="tab-content active">
                <h3>Chi tiết sản phẩm</h3>
                <% If detailDescription <> "" Then %>
                    <% WriteUTF8(detailDescription) %>
                <% Else %>
                    <p style="text-align:center">Đang cập nhật...</p>
                <% End If %>
            </div>
            
            <div id="specs" class="tab-content">
                <h3>Thông số kỹ thuật</h3>
                <ul>
                    <li><strong>Mã sản phẩm:</strong> <% WriteUTF8(productCode) %></li>
                    <li><strong>Tên sản phẩm:</strong> <% WriteUTF8(productName) %></li>
                    <li><strong>Thương hiệu:</strong> <% WriteUTF8(brandName) %></li>
                    <% If categoryName <> "" Then %>
                    <li><strong>Danh mục:</strong> <% WriteUTF8(categoryName) %></li>
                    <% End If %>
                    <li><strong>Chất liệu:</strong> <% WriteUTF8(material) %></li>
                    <li><strong>Form dáng:</strong> <% WriteUTF8(fitType) %></li>
                    <li><strong>Xuất xứ:</strong> <% WriteUTF8(origin) %></li>
                </ul>
            </div>
        </div>
    </div>

    <div id="footer"></div>

    <script>
    // ... (Giữ nguyên phần Script cũ của bạn) ...
    // Javascript không ảnh hưởng đến việc hiển thị tiếng Việt của HTML
    async function loadComponent(id, file) {
            document.getElementById(id).innerHTML = await (await fetch(file)).text();
        }
        loadComponent("header", "../FE/customer/component/header.asp");
        loadComponent("footer", "../FE/customer/component/footer.html");

    // Thay đổi ảnh chính
    function changeImage(src, element) {
        document.getElementById('mainImg').src = src;
        var thumbnails = document.querySelectorAll('.thumbnail');
        thumbnails.forEach(function(thumb) { thumb.classList.remove('active'); });
        if (element) { element.classList.add('active'); }
    }
    
    function selectColor(color, button) {
        document.getElementById('selectedColor').textContent = color;
        var colorButtons = document.querySelectorAll('#colorButtons .option-btn');
        colorButtons.forEach(function(btn) { btn.classList.remove('active'); });
        button.classList.add('active');
    }
    
    function selectSize(size, button) {
        document.getElementById('selectedSize').textContent = size;
        var sizeButtons = document.querySelectorAll('#sizeButtons .option-btn');
        sizeButtons.forEach(function(btn) { btn.classList.remove('active'); });
        button.classList.add('active');
    }
    
    function changeQty(change) {
        var input = document.getElementById('quantity');
        var current = parseInt(input.value);
        var newVal = current + change;
        if (newVal < 1) newVal = 1;
        input.value = newVal;
    }
    
    function showTab(tabId) {
        var tabContents = document.querySelectorAll('.tab-content');
        tabContents.forEach(function(content) { content.classList.remove('active'); });
        var tabButtons = document.querySelectorAll('.tab-btn');
        tabButtons.forEach(function(button) { button.classList.remove('active'); });
        document.getElementById(tabId).classList.add('active');
        event.target.classList.add('active');
    }
    
   // Thêm vào giỏ hàng
function addToCart() {
    var color = document.getElementById('selectedColor').textContent;
    var size = document.getElementById('selectedSize').textContent;
    var qty = document.getElementById('quantity').value;
    
    // 1. Kiểm tra dữ liệu đầu vào
    if (color === "Mặc định" || size === "Mặc định" || color === "" || size === "") {
        alert("Vui lòng chọn màu sắc và kích thước!");
        return;
    }

    // 2. Tạo form ảo
    var form = document.createElement("form");
    
    // --- QUAN TRỌNG: ĐỔI THÀNH GET ĐỂ BACKEND ĐỌC ĐƯỢC QUERY_STRING ---
    form.method = "GET"; 
    form.action = "add-to-cart.asp";

    // 3. Tạo các input chứa dữ liệu
    // ID Sản phẩm
    var inputId = document.createElement("input");
    inputId.type = "hidden";
    inputId.name = "id";
    inputId.value = "<%=productId%>";
    form.appendChild(inputId);

    // Màu sắc (Trình duyệt sẽ tự động mã hóa URL khi submit form GET)
    var inputColor = document.createElement("input");
    inputColor.type = "hidden";
    inputColor.name = "color";
    inputColor.value = color;
    form.appendChild(inputColor);

    // Kích thước
    var inputSize = document.createElement("input");
    inputSize.type = "hidden";
    inputSize.name = "size";
    inputSize.value = size;
    form.appendChild(inputSize);

    // Số lượng
    var inputQty = document.createElement("input");
    inputQty.type = "hidden";
    inputQty.name = "qty";
    inputQty.value = qty;
    form.appendChild(inputQty);

    // 4. Gắn vào trang và gửi đi
    document.body.appendChild(form);
    form.submit();
}
    
    function buyNow() {
        // Tương tự Add to cart
        var color = document.getElementById('selectedColor').textContent;
        var size = document.getElementById('selectedSize').textContent;
        var qty = document.getElementById('quantity').value;
        var url = 'checkout.asp?id=<%=productId%>&color=' + encodeURIComponent(color) + '&size=' + encodeURIComponent(size) + '&qty=' + qty;
        window.location.href = url;
    }
    </script>
</body>
</html>
<%
If rsImages.State = 1 Then rsImages.Close
If rsColors.State = 1 Then rsColors.Close
If rsSizes.State = 1 Then rsSizes.Close
If rsProduct.State = 1 Then rsProduct.Close
%>