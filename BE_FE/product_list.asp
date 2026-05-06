<!--#include file="/BE/db/connect.asp"-->
<%
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
    ' Lấy tham số từ URL/Form
    cate = request("cate")
    color = request("colorname")
    size = request("sizename")
    max_price = request("max_price")
    sort = request("sort")
    q = request("q")

    ' 1. Xây dựng câu truy vấn gốc cho Products
    if cate = 17 then
        sql = "SELECT DISTINCT P.* FROM Products P WHERE P.CreatedDate >= DATEADD(DAY, -7, GETDATE()) AND P.IsActive = 1"
        displayTitle = "New products"
    elseif cate = 18 then
        sql = "SELECT DISTINCT P.* FROM Products P WHERE P.SalePrice < P.OriginalPrice and p.saleprice > 0 AND P.IsActive = 1"
        displayTitle = "Sale"
    elseif cate = 19 then
        sql = "SELECT DISTINCT P.* FROM Products P WHERE p.CategoryID = 5 OR p.CategoryID = 4 "
        displayTitle = "Autumn/Winter clothing"
    elseif cate = 20 then
        sql = "SELECT DISTINCT P.* FROM Products P WHERE p.CategoryID = 7 OR p.CategoryID = 11 "
        displayTitle = "Office Wear"
    elseif cate = 21 then
        sql = "SELECT DISTINCT P.* FROM Products P WHERE p.CategoryID = 6 OR p.CategoryID = 8 OR p.CategoryID = 15"
        displayTitle = "Sports Apparel"
    elseif cate = 22 then
        sql = "SELECT DISTINCT P.* FROM Products P WHERE (p.ProductName LIKE N'%" & q & "%' " & _
                "OR p.ProductCode LIKE N'%" & q & "%') "
        displayTitle = "Search results for '" & q & "'"
    else
        ' Kiểm tra xem Cate là danh mục cha hay con
        set rsCate = conn.execute("SELECT CategoryID FROM Categories WHERE ParentCategoryID = " & cate)
        if not rsCate.eof then
            sql = "SELECT DISTINCT P.* FROM Products P WHERE P.CategoryID IN (SELECT CategoryID FROM Categories WHERE ParentCategoryID = " & cate & ") AND P.IsActive = 1"
        else
            sql = "SELECT DISTINCT P.* FROM Products P WHERE P.CategoryID = " & cate & " AND P.IsActive = 1"
        end if
        
        sql_title = "SELECT CategoryName FROM Categories WHERE CategoryID = " & cate
        set rsTitle = conn.execute(sql_title)
        if not rsTitle.eof then
            displayTitle = rsTitle("CategoryName")
        else
            displayTitle = "Danh mục"
        end if
    end if
    
    ' Lấy danh sách Size và Màu sắc động
    if IsNumeric(cate) then
        if cate=17 then
        ' New products
        sqlSizeList = "SELECT DISTINCT V.SizeName FROM ProductVariants V INNER JOIN Products P ON V.ProductID = P.ProductID WHERE P.IsActive = 1 AND P.CreatedDate >= DATEADD(DAY, -7, GETDATE())"
        sqlColorList = "SELECT DISTINCT V.ColorName FROM ProductVariants V INNER JOIN Products P ON V.ProductID = P.ProductID WHERE P.IsActive = 1 AND P.CreatedDate >= DATEADD(DAY, -7, GETDATE())"
        set rsSizes = conn.execute(sqlSizeList & " ORDER BY V.SizeName ASC")
        set rsColors = conn.execute(sqlColorList & " ORDER BY V.ColorName ASC")
        elseif cate=18 then
        ' Sale products
        sqlSizeList = "SELECT DISTINCT V.SizeName FROM ProductVariants V INNER JOIN Products P ON V.ProductID = P.ProductID WHERE P.IsActive = 1 AND P.SalePrice < P.OriginalPrice AND P.SalePrice > 0"
        sqlColorList = "SELECT DISTINCT V.ColorName FROM ProductVariants V INNER JOIN Products P ON V.ProductID = P.ProductID WHERE P.IsActive = 1 AND P.SalePrice < P.OriginalPrice AND P.SalePrice > 0"
        set rsSizes = conn.execute(sqlSizeList & " ORDER BY V.SizeName ASC")
        set rsColors = conn.execute(sqlColorList & " ORDER BY V.ColorName ASC")
        else
        ' Size
        sqlSizeList = "SELECT DISTINCT V.SizeName FROM ProductVariants V INNER JOIN Products P ON V.ProductID = P.ProductID WHERE P.IsActive = 1 "
        if not rsCate.eof then
            sqlSizeList = sqlSizeList & " AND P.CategoryID IN (SELECT CategoryID FROM Categories WHERE ParentCategoryID = " & cate & " OR CategoryID = " & cate & ")"
        else
            sqlSizeList = sqlSizeList & " AND P.CategoryID = " & cate
        end if
        set rsSizes = conn.execute(sqlSizeList & " ORDER BY V.SizeName ASC")

        ' Màu
        sqlColorList = "SELECT DISTINCT V.ColorName FROM ProductVariants V INNER JOIN Products P ON V.ProductID = P.ProductID WHERE P.IsActive = 1 "
        if not rsCate.eof then
            sqlColorList = sqlColorList & " AND P.CategoryID IN (SELECT CategoryID FROM Categories WHERE ParentCategoryID = " & cate & " OR CategoryID = " & cate & ")"
        else
            sqlColorList = sqlColorList & " AND P.CategoryID = " & cate
        end if
        set rsColors = conn.execute(sqlColorList & " ORDER BY V.ColorName ASC")
        end if
    end if

    ' 2. Logic lọc bổ sung
    if color <> "" or size <> "" then
        sql = sql & " AND EXISTS (SELECT 1 FROM ProductVariants V WHERE V.ProductID = P.ProductID AND V.IsActive = 1"
        if color <> "" then sql = sql & " AND V.ColorName = '" & replace(color, "'", "''") & "'"
        if size <> "" then sql = sql & " AND V.SizeName = '" & replace(size, "'", "''") & "'"
        sql = sql & ")"
    end if

    if not IsNumeric(max_price) or max_price = "" then
        max_price = 3000000
    else
        max_price = CDbl(max_price)
    end if

    if max_price < 3000000 and max_price > 0 then
        sql = sql & " AND SalePrice <= " & Replace(CStr(max_price), ",", ".")
    end if

    ' 4. Sắp xếp
    select case sort
        case "price_asc":  sql = sql & " ORDER BY SalePrice ASC"
        case "price_desc": sql = sql & " ORDER BY SalePrice DESC"
        case "name_asc":   sql = sql & " ORDER BY ProductName ASC"
        case "name_desc":  sql = sql & " ORDER BY ProductName DESC"
        case "newest":     sql = sql & " ORDER BY ProductID DESC" 
        case "oldest":     sql = sql & " ORDER BY ProductID ASC"
    end select

    ' 5. Phân trang
    rs.cursorlocation = 3
    rs.pagesize = 12
    rs.open sql, conn, 0, 4
    sotrang = rs.pagecount
    p = Cint(Request("p"))
    if p < 1 then p = 1
    if p > sotrang and sotrang > 0 then p = sotrang
    if not rs.eof then rs.absolutepage = p
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>TORANO - <%WriteUTF8(displayTitle)%></title>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/normalize/8.0.1/normalize.min.css">
  
    <link rel="stylesheet" href="../../assets/css/base.css">
    <link rel="stylesheet" href="../../assets/css/main.css">
    <link rel="stylesheet" href="../../assets/css/header-footer.css">
    
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link rel="stylesheet" href="/assets/fonts/fontawesome-free-6.7.2-web/css/all.min.css">
    <link href="https://fonts.googleapis.com/css2?family=Roboto:ital,wght@0,100..900;1,100..900&display=swap" rel="stylesheet">
  
    <link rel="stylesheet" href="../../assets/css/product_list.css">
</head>
<body>
    <div id="header"></div>
    <div class="main-container">
        <aside class="left">
            <div class="filter-header-flex">
    <h2 class="filter-title">Bộ lọc</h2>
    <%
        ' Kiểm tra điều kiện để hiện nút xóa
        dim displayStyle
        displayStyle = "none"
        if (color <> "") or (size <> "") or (IsNumeric(max_price) and CDbl(max_price) < 3000000) then
            displayStyle = "block"
        end if
    %>
    <a href="javascript:void(0)" id="btnResetAll" class="reset-all-link" 
       onclick="resetFilters()" 
       style="display: <%= displayStyle %>;">
       Xóa tất cả
    </a>
</div>
            <form id="filterForm">
                <input type="hidden" name="cate" value="<%=cate%>">
                
                <section class="filter-section">
                    <details open>
                        <summary class="filter-heading">Khoảng giá <span class="toggle-icon"></span></summary>
                        <div class="filter-content">
                            <div class="price-inputs">
                                <span>0đ</span>
                                <span id="priceDisplay"><%=FormatNumber(max_price, 0)%>đ</span>
                            </div>
                        <input type="range" name="max_price" 
                        min="0" max="3000000" step="50000" 
                        value="<%=max_price%>" 
                        class="price-range-input" 
                        oninput="updatePrice(this.value)"
                        onchange="applyFilter()"> 
                        </div>
                    </details>
                </section>

                <section class="filter-section">
                    <details open>
                        <summary class="filter-heading">Màu sắc <span class="toggle-icon"></span></summary>
                        <div class="filter-content">
                            <ul class="filter-checkbox-list">
                                <% if not rsColors is nothing then 
                                    while not rsColors.eof 
                                        dim activeColor: activeColor = ""
                                        if color = rsColors("ColorName") then activeColor = "active" %>
                                    <li>
                                        <label class="filter-link <%=activeColor%>">
                                            <input type="radio" name="colorname" value="<%=rsColors("ColorName")%>" onchange="applyFilter()" <% if activeColor <> "" then response.write "checked" %> style="display:none">
                                            <%=rsColors("ColorName")%>
                                        </label>
                                    </li>
                                <% rsColors.movenext
                                wend
                                end if %>
                            </ul>
                        </div>
                    </details>
                </section>

                <section class="filter-section">
                    <details open>
                        <summary class="filter-heading">Size <span class="toggle-icon"></span></summary>
                        <div class="filter-content">
                            <div class="size-picker-grid" style="display: grid; grid-template-columns: repeat(3, 1fr); gap: 10px;">
                                <% if not rsSizes is nothing then 
                                    while not rsSizes.eof 
                                        dim activeSize: activeSize = ""
                                        if size = rsSizes("SizeName") then activeSize = "active" %>
                                    <label class="size-box <%=activeSize%>" style="border: 1px solid #ddd; padding: 10px; text-align: center; cursor: pointer; border-radius: 8px;">
                                        <input type="radio" name="sizename" value="<%=rsSizes("SizeName")%>" onchange="applyFilter()" <% if activeSize <> "" then response.write "checked" %> style="display:none">
                                        <%=rsSizes("SizeName")%>
                                    </label>
                                <% rsSizes.movenext
                                wend
                                end if %>
                            </div>
                        </div>
                    </details>
                </section>
            </form>
        </aside>

        <main class="right" id="productContainer">
            <header class="content-header">
                <div class="product-count"><%WriteUTF8(displayTitle)%> <span><%=rs.RecordCount%> sản phẩm</span></div>
                <div class="sort-options">
                    <select name="sort" onchange="applyFilter()">
                        <option value="price_asc" <%if sort="price_asc" then response.write "selected"%>>Giá: Tăng dần</option>
                        <option value="price_desc" <%if sort="price_desc" then response.write "selected"%>>Giá: Giảm dần</option>
                        <option value="name_asc" <%if sort="name_asc" then response.write "selected"%>>Tên: A-Z</option>
                        <option value="name_desc" <%if sort="name_desc" then response.write "selected"%>>Tên: Z-A</option>
                        <option value="newest" <%if sort="newest" then response.write "selected"%>>Mới nhất</option>
                        <option value="oldest" <%if sort="oldest" then response.write "selected"%>>Cũ nhất</option>
                    </select>
                </div>
            </header>

            <div class="product-grid">
                <% if not rs.eof then
                    while not rs.eof and rs.absolutepage = p 
                        ' Lấy ảnh từ bảng ProductImages
                        set rsImg = conn.execute("SELECT TOP 1 ImageURL FROM ProductImages WHERE ProductID = " & rs("ProductID") & " AND IsMainImage = 1")
                        thumb = rsImg("ImageURL")
                        rsImg.close

                        ' Ép kiểu Decimal về Double để so sánh an toàn
                        curP = CDbl(rs("SalePrice"))
                        oriP = CDbl(rs("OriginalPrice"))
                %>
                <a href="../../BE_FE/product-detail.asp?id=<%=rs("ProductID")%>" class="product-link">
                    <div class="product-item">
                        <div class="product-image-container">
                            <img src="<%=thumb%>" alt="">
                            <% if curP < oriP then %>
                                <div class="discount-tag">-<%= Round((oriP - curP) / oriP * 100) %>%</div>
                            <% end if %>
                        </div>
                        <div class="product-info">
                            <div class="product-name"><%WriteUTF8(rs("ProductName"))%></div>
                            <div class="product-price">
                                <span class="current-price"><%=FormatNumber(curP, 0)%>đ</span>
                                <% if curP < oriP then %>
                                    <span class="original-price"><%=FormatNumber(oriP, 0)%>đ</span>
                                <% end if %>
                            </div>
                        </div>
                    </div>
                </a>
                <% rs.movenext
                wend 
                else %>
                    <div class="no-products">Không tìm thấy sản phẩm.</div>
                <% end if %>
            </div>

            <div class="pagination">
                <% for i=1 to sotrang 
                    dim pgActive: pgActive = ""
                    if i = p then pgActive = "active" %>
                    <a href="javascript:void(0)" onclick="goToPage(<%=i%>)" class="page-btn <%=pgActive%>"><%=i%></a>
                <% next %>
            </div>
        </main>
    </div>
    <div id="footer"></div>
    <script>
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
    <script>
        function updatePrice(val) {
            document.getElementById('priceDisplay').innerText = Number(val).toLocaleString('vi-VN') + 'đ';
        }

        // Hàm cập nhật giao diện "đen hơn" ngay lập tức khi click
document.querySelectorAll('.filter-link').forEach(link => {
    link.addEventListener('click', function() {
        // Xóa active của tất cả các màu khác trong cùng danh sách
        this.closest('.filter-checkbox-list').querySelectorAll('.filter-link').forEach(el => el.classList.remove('active'));
        // Thêm active cho cái vừa chọn
        this.classList.add('active');
    });
});

document.querySelectorAll('.size-box').forEach(box => {
    box.addEventListener('click', function() {
        // Xóa active của tất cả các size khác
        this.closest('.size-picker-grid').querySelectorAll('.size-box').forEach(el => el.classList.remove('active'));
        // Thêm active cho cái vừa chọn
        this.classList.add('active');
    });
});

// Hàm applyFilter (giữ nguyên logic fetch cũ nhưng đảm bảo đồng bộ)
function applyFilter(page = 1) {
    const form = document.getElementById('filterForm');
    const formData = new FormData(form);
    
    // Lấy các giá trị lọc
    const colorSelected = formData.get('colorname');
    const sizeSelected = formData.get('sizename');
    const priceSelected = formData.get('max_price');
    const btnReset = document.getElementById('btnResetAll');

    // Logic ẩn hiện nút Xóa tất cả ngay lập tức
    if (colorSelected || sizeSelected || (priceSelected && priceSelected < 3000000)) {
        btnReset.style.display = 'block';
    } else {
        btnReset.style.display = 'none';
    }

    // Các phần fetch dữ liệu giữ nguyên
    formData.append('sort', document.querySelector('select[name="sort"]').value);
    formData.append('p', page);
    let params = new URLSearchParams(formData);

    document.getElementById('productContainer').style.opacity = '0.4';
    fetch('product_list.asp?' + params.toString())
        .then(r => r.text())
        .then(html => {
            const doc = new DOMParser().parseFromString(html, 'text/html');
            document.getElementById('productContainer').innerHTML = doc.getElementById('productContainer').innerHTML;
            document.getElementById('productContainer').style.opacity = '1';
            window.history.pushState({}, '', 'product_list.asp?' + params.toString());
        });
}
function resetFilters() {
    // 1. Reset radio buttons (Màu và Size)
    document.querySelectorAll('#filterForm input[type="radio"]').forEach(input => {
        input.checked = false;
    });

    // 2. Xóa class active trên giao diện
    document.querySelectorAll('.filter-link, .size-box').forEach(el => {
        el.classList.remove('active');
    });

    // 3. Reset thanh giá
    const rangeInput = document.querySelector('.price-range-input');
    if(rangeInput) {
        rangeInput.value = 3000000;
        updatePrice(3000000);
    }

    // 4. Ẩn nút reset
    document.getElementById('btnResetAll').style.display = 'none';

    // 5. Chạy lọc lại để lấy dữ liệu gốc
    applyFilter(1);
}

        function goToPage(page) { applyFilter(page); window.scrollTo({top: 0, behavior: 'smooth'}); }
        
    </script>
</body>
</html>