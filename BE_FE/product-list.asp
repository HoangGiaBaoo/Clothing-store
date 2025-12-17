<%@LANGUAGE="VBScript" CODEPAGE="65001"%>
<!-- #include file="/BE/db/connect.asp" -->
<%
' --- 0. HÀM XỬ LÝ TIẾNG VIỆT (Theo yêu cầu của bạn) ---
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

'========== KHAI BÁO BIẾN ==========
Dim categoryID, sortType, pageNum, pageSize
Dim filter_color, filter_size
Dim sql, countSql, rsCount
Dim totalProducts, totalPages, offset, i
Dim list_category_ids, categoryName, isSaleCategory

'========== LẤY THAM SỐ ==========
categoryID = Request.QueryString("cat")
sortType = Request.QueryString("sort")
pageNum = Request.QueryString("page")
filter_color = Request.QueryString("color")
filter_size = Request.QueryString("size")

If categoryID = "" Then categoryID = "1"
If sortType = "" Then sortType = "default"
If pageNum = "" Then pageNum = 1
pageSize = 12

pageNum = CInt(pageNum)
If pageNum < 1 Then pageNum = 1
offset = (pageNum - 1) * pageSize

'========== HÀM LẤY DANH SÁCH CON ==========
Function GetChildren(catID)
    Dim sqlChild, rsChild, childList
    sqlChild = "SELECT CategoryID FROM Categories WHERE ParentCategoryID = " & catID
    Set rsChild = conn.Execute(sqlChild)
    childList = ""
    Do While Not rsChild.EOF
        If childList <> "" Then childList = childList & ","
        childList = childList & rsChild("CategoryID")
        rsChild.MoveNext
    Loop
    rsChild.Close
    Set rsChild = Nothing
    GetChildren = childList
End Function

'========== XỬ LÝ DANH MỤC ==========
Dim sql_cat, rs_cat, parentID, childIDs
sql_cat = "SELECT CategoryName, ParentCategoryID FROM Categories WHERE CategoryID = " & categoryID
Set rs_cat = conn.Execute(sql_cat)

If Not rs_cat.EOF Then
    categoryName = rs_cat("CategoryName")
    
    ' Kiểm tra có phải danh mục Sale không
    If CInt(categoryID) = 2 Then
        isSaleCategory = True
    Else
        isSaleCategory = False
    End If
    
    If rs_cat("ParentCategoryID") = 0 OR IsNull(rs_cat("ParentCategoryID")) Then
        childIDs = GetChildren(CInt(categoryID))
        If childIDs <> "" Then 
            list_category_ids = categoryID & "," & childIDs
        Else 
            list_category_ids = categoryID
        End If
    Else
        list_category_ids = categoryID
    End If
Else
    categoryName = "Sản phẩm"
    list_category_ids = categoryID
    isSaleCategory = False
End If
rs_cat.Close
Set rs_cat = Nothing

'========== XÂY DỰNG QUERY ==========
Dim sql_where, sql_from, sql_join, sql_order

' Mặc định không JOIN với ProductVariants
sql_from = "Products p"
sql_where = " WHERE p.IsActive = 1"

'========== XỬ LÝ ĐẶC BIỆT THEO CATEGORY ==========
If CInt(categoryID) = 1 Then
    ' CAT=1: Lấy sản phẩm mới nhất từ TẤT CẢ danh mục
    sql_order = " ORDER BY p.CreatedDate DESC"
    countSql = "SELECT COUNT(*) AS Total FROM Products p WHERE p.IsActive = 1"
    
ElseIf CInt(categoryID) = 2 Then
    ' CAT=2: Lấy tất cả sản phẩm có sale từ TẤT CẢ danh mục
    sql_where = sql_where & " AND p.OriginalPrice > p.SalePrice AND p.OriginalPrice > 0"
    sql_order = " ORDER BY p.CreatedDate DESC"
    countSql = "SELECT COUNT(*) AS Total FROM Products p WHERE p.OriginalPrice > p.SalePrice AND p.OriginalPrice > 0 AND p.IsActive = 1"
    
Else
    ' Các danh mục khác
    sql_where = sql_where & " AND p.CategoryID IN (" & list_category_ids & ")"
    sql_order = " ORDER BY p.ProductID DESC"
    countSql = "SELECT COUNT(*) AS Total FROM Products p WHERE p.CategoryID IN (" & list_category_ids & ") AND p.IsActive = 1"
End If

' Nếu có lọc theo màu hoặc size
If filter_color <> "" Or filter_size <> "" Then
    sql_join = " INNER JOIN ProductVariants pv ON p.ProductID = pv.ProductID"
    sql_from = "Products p" & sql_join
    
    If filter_color <> "" Then
        sql_where = sql_where & " AND pv.ColorName = N'" & Replace(filter_color, "'", "''") & "'"
    End If
    
    If filter_size <> "" Then
        sql_where = sql_where & " AND pv.SizeName = N'" & Replace(filter_size, "'", "''") & "'"
    End If
    
    ' Điều chỉnh countSql
    If CInt(categoryID) = 1 Then
        countSql = "SELECT COUNT(DISTINCT p.ProductID) AS Total FROM Products p" & sql_join & " WHERE p.IsActive = 1"
        If filter_color <> "" Then countSql = countSql & " AND pv.ColorName = N'" & Replace(filter_color, "'", "''") & "'"
        If filter_size <> "" Then countSql = countSql & " AND pv.SizeName = N'" & Replace(filter_size, "'", "''") & "'"
    ElseIf CInt(categoryID) = 2 Then
        countSql = "SELECT COUNT(DISTINCT p.ProductID) AS Total FROM Products p" & sql_join & " WHERE p.OriginalPrice > p.SalePrice AND p.OriginalPrice > 0 AND p.IsActive = 1"
        If filter_color <> "" Then countSql = countSql & " AND pv.ColorName = N'" & Replace(filter_color, "'", "''") & "'"
        If filter_size <> "" Then countSql = countSql & " AND pv.SizeName = N'" & Replace(filter_size, "'", "''") & "'"
    Else
        countSql = "SELECT COUNT(DISTINCT p.ProductID) AS Total FROM Products p" & sql_join & " WHERE p.CategoryID IN (" & list_category_ids & ") AND p.IsActive = 1"
        If filter_color <> "" Then countSql = countSql & " AND pv.ColorName = N'" & Replace(filter_color, "'", "''") & "'"
        If filter_size <> "" Then countSql = countSql & " AND pv.SizeName = N'" & Replace(filter_size, "'", "''") & "'"
    End If
End If

'========== ĐẾM TỔNG SẢN PHẨM ==========
Set rsCount = conn.Execute(countSql)
totalProducts = rsCount("Total")
rsCount.Close
Set rsCount = Nothing

' Giới hạn 36 sp cho cat=1
If CInt(categoryID) = 1 And filter_color = "" And filter_size = "" Then
    If totalProducts > 36 Then totalProducts = 36
End If

totalPages = Int((totalProducts - 1) / pageSize) + 1
If totalPages < 1 Then totalPages = 1

'========== QUERY SẢN PHẨM ==========
sql = "SELECT p.ProductID, p.ProductName, p.SalePrice, p.OriginalPrice, p.CreatedDate, " & _
      "(SELECT TOP 1 ImageURL FROM ProductImages WHERE ProductID = p.ProductID AND IsMainImage = 1) AS ImageURL " & _
      "FROM " & sql_from & sql_where

If filter_color <> "" Or filter_size <> "" Then
    sql = sql & " GROUP BY p.ProductID, p.ProductName, p.SalePrice, p.OriginalPrice, p.CreatedDate"
End If

' Sort
If sortType <> "" And sortType <> "default" Then
    Select Case sortType
        Case "price-asc" : sql_order = " ORDER BY p.SalePrice ASC"
        Case "price-desc" : sql_order = " ORDER BY p.SalePrice DESC"
        Case "name-asc" : sql_order = " ORDER BY p.ProductName ASC"
        Case "name-desc" : sql_order = " ORDER BY p.ProductName DESC"
        Case "newest" : sql_order = " ORDER BY p.CreatedDate DESC"
        Case "oldest" : sql_order = " ORDER BY p.CreatedDate ASC"
    End Select
End If

If sql_order <> "" Then sql = sql & sql_order

' Phân trang
If CInt(categoryID) = 1 And filter_color = "" And filter_size = "" Then
    If offset = 0 Then
        sql = "SELECT TOP 36 p.ProductID, p.ProductName, p.SalePrice, p.OriginalPrice, p.CreatedDate, " & _
              "(SELECT TOP 1 ImageURL FROM ProductImages WHERE ProductID = p.ProductID AND IsMainImage = 1) AS ImageURL " & _
              "FROM Products p WHERE p.IsActive = 1 ORDER BY p.CreatedDate DESC"
    Else
        sql = "SELECT * FROM (" & _
              "SELECT TOP 36 p.ProductID, p.ProductName, p.SalePrice, p.OriginalPrice, p.CreatedDate, " & _
              "(SELECT TOP 1 ImageURL FROM ProductImages WHERE ProductID = p.ProductID AND IsMainImage = 1) AS ImageURL, " & _
              "ROW_NUMBER() OVER (ORDER BY p.CreatedDate DESC) AS RowNum " & _
              "FROM Products p WHERE p.IsActive = 1" & _
              ") AS TopProducts WHERE RowNum > " & offset & " AND RowNum <= " & (offset + pageSize) & " ORDER BY CreatedDate DESC"
    End If
Else
    sql = sql & " OFFSET " & offset & " ROWS FETCH NEXT " & pageSize & " ROWS ONLY"
End If

Set rs = conn.Execute(sql)

'========== DỮ LIỆU BỘ LỌC ==========
Dim rs_colors, rs_sizes, sql_colors, sql_sizes
sql_colors = "SELECT DISTINCT pv.ColorName FROM ProductVariants pv INNER JOIN Products p ON pv.ProductID = p.ProductID WHERE p.CategoryID IN (" & list_category_ids & ") AND pv.ColorName IS NOT NULL AND LTRIM(RTRIM(pv.ColorName)) <> '' ORDER BY pv.ColorName"
Set rs_colors = conn.Execute(sql_colors)

sql_sizes = "SELECT DISTINCT pv.SizeName, pv.SizeOrder FROM ProductVariants pv INNER JOIN Products p ON pv.ProductID = p.ProductID WHERE p.CategoryID IN (" & list_category_ids & ") AND pv.SizeName IS NOT NULL AND LTRIM(RTRIM(pv.SizeName)) <> '' ORDER BY pv.SizeOrder"
Set rs_sizes = conn.Execute(sql_sizes)

Dim rs_parents, sql_parents
sql_parents = "SELECT CategoryID, CategoryName FROM Categories WHERE ParentCategoryID IS NULL ORDER BY CategoryID"
Set rs_parents = conn.Execute(sql_parents)

Function BuildURL(cat, sort, page, color, size)
    Dim url
    url = "?cat=" & cat & "&sort=" & sort & "&page=" & page
    If color <> "" Then url = url & "&color=" & Server.URLEncode(color)
    If size <> "" Then url = url & "&size=" & Server.URLEncode(size)
    BuildURL = url
End Function
%>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>TORANO - <% Call WriteUTF8(categoryName) %></title>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/normalize/8.0.1/normalize.min.css">
    <link rel="stylesheet" href="../../assets/css/base.css">
    <link rel="stylesheet" href="../../assets/css/main.css">
    <link rel="stylesheet" href="../../assets/css/header-footer.css">
    <link rel="stylesheet" href="/assets/fonts/fontawesome-free-6.7.2-web/css/all.min.css">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <link href="https://fonts.googleapis.com/css2?family=Roboto:wght@400;500;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="../../assets/css/product_list.css">
    <style>
        .original-price { text-decoration: line-through; color: #999; font-size: 14px; margin-left: 8px; opacity: 0.7; }
        .current-price { color: #e53935; font-weight: bold; font-size: 16px; }
        .product-price { display: flex; align-items: center; margin-top: 5px; }
        .discount-tag { position: absolute; top: 10px; right: 10px; background: #e53935; color: white; padding: 3px 8px; border-radius: 12px; font-size: 12px; font-weight: bold; }
        .price-container { display: flex; flex-direction: column; gap: 2px; }
        .sale-price { color: #e53935; font-weight: bold; font-size: 16px; }
        .original-price-line { text-decoration: line-through; color: #999; font-size: 14px; opacity: 0.7; }
        .no-price { color: #666; font-style: italic; font-size: 14px; }
    </style>
</head>
<body>
    <div id="header"></div>
    <div class="main-container">
        <aside class="left">
            <h2 class="filter-title">Bộ lọc</h2>
            
            <div class="filter-section">
                <details open>
                    <summary class="filter-heading">Danh mục sản phẩm <span class="toggle-icon"></span></summary>
                    <ul class="filter-content filter-checkbox-list">
                        <% 
                        Do While Not rs_parents.EOF 
                            Dim parentID_temp, parentName
                            parentID_temp = rs_parents("CategoryID")
                            parentName = rs_parents("CategoryName")
                        %>
                        <li style="margin-bottom: 8px;">
                            <a href="<%= BuildURL(parentID_temp, sortType, 1, "", "") %>" 
                               class="category-link <% If CStr(parentID_temp) = categoryID Then Response.Write "active" %>">
                                <% Call WriteUTF8(parentName) %>
                            </a>
                            
                            <% 
                            Dim sql_children, rs_children
                            sql_children = "SELECT CategoryID, CategoryName FROM Categories WHERE ParentCategoryID = " & parentID_temp
                            Set rs_children = conn.Execute(sql_children)
                            If Not rs_children.EOF Then 
                            %>
                            <ul class="child-categories">
                                <% 
                                Do While Not rs_children.EOF 
                                   Dim childID, childName
                                   childID = rs_children("CategoryID")
                                   childName = rs_children("CategoryName")
                                %>
                                <li>
                                    <a href="<%= BuildURL(childID, sortType, 1, "", "") %>" 
                                       class="category-link <% If CStr(childID) = categoryID Then Response.Write "active" %>">
                                       <% Call WriteUTF8(childName) %>
                                    </a>
                                </li>
                                <% 
                                rs_children.MoveNext
                                Loop 
                                %>
                            </ul>
                            <% 
                            End If 
                            rs_children.Close
                            Set rs_children = Nothing
                            %>
                        </li>
                        <% 
                        rs_parents.MoveNext
                        Loop 
                        rs_parents.Close
                        Set rs_parents = Nothing
                        %>
                    </ul>
                </details>
            </div>

            <div class="filter-section">
                <details open>
                    <summary class="filter-heading">Màu sắc <span class="toggle-icon"></span></summary>
                    <ul class="filter-content filter-checkbox-list">
                        <% 
                        If rs_colors.EOF Then
                            Response.Write "<li style='color: #999;'>Không có dữ liệu</li>"
                        Else
                            Do While Not rs_colors.EOF 
                                Dim colorName, isColorActive
                                colorName = Trim(rs_colors("ColorName"))
                                isColorActive = (LCase(filter_color) = LCase(colorName))
                                Dim urlColor
                                If isColorActive Then
                                    urlColor = BuildURL(categoryID, sortType, 1, "", filter_size)
                                Else
                                    urlColor = BuildURL(categoryID, sortType, 1, colorName, filter_size)
                                End If
                        %>
                        <li>
                            <a href="<%= urlColor %>" class="filter-link <% If isColorActive Then Response.Write "active" %>">
                                <% If isColorActive Then Response.Write "✔ " %>
                                <% Call WriteUTF8(colorName) %>
                            </a>
                        </li>
                        <% 
                            rs_colors.MoveNext
                            Loop
                        End If
                        %>
                    </ul>
                </details>
            </div>

            <div class="filter-section">
                <details open>
                    <summary class="filter-heading">Size <span class="toggle-icon"></span></summary>
                    <ul class="filter-content filter-checkbox-list">
                        <% 
                        If rs_sizes.EOF Then
                            Response.Write "<li style='color: #999;'>Không có dữ liệu</li>"
                        Else
                            Do While Not rs_sizes.EOF 
                                Dim sizeName, isSizeActive
                                sizeName = Trim(rs_sizes("SizeName"))
                                isSizeActive = (LCase(filter_size) = LCase(sizeName))
                                Dim urlSize
                                If isSizeActive Then
                                    urlSize = BuildURL(categoryID, sortType, 1, filter_color, "")
                                Else
                                    urlSize = BuildURL(categoryID, sortType, 1, filter_color, sizeName)
                                End If
                        %>
                        <li>
                            <a href="<%= urlSize %>" class="filter-link <% If isSizeActive Then Response.Write "active" %>">
                                <% If isSizeActive Then Response.Write "✔ " %>
                                <% Call WriteUTF8(sizeName) %>
                            </a>
                        </li>
                        <% 
                            rs_sizes.MoveNext
                            Loop
                        End If
                        %>
                    </ul>
                </details>
            </div>

            <% If filter_color <> "" Or filter_size <> "" Then %>
            <a href="<%= BuildURL(categoryID, sortType, 1, "", "") %>" class="reset-filter-btn">Xóa tất cả bộ lọc</a>
            <% End If %>
        </aside>

        <main class="right">
            <header class="content-header">
                <h2 class="product-count">
                    <% Call WriteUTF8(categoryName) %> 
                    <span>(<%= totalProducts %> sản phẩm)</span>
                    <% If CInt(categoryID) = 1 Then %>
                    <small style="color: #1976d2; font-size: 14px; margin-left: 10px; background: #e3f2fd; padding: 3px 8px; border-radius: 12px;">
                        ⭐ sản phẩm mới nhất
                    </small>
                    <% ElseIf CInt(categoryID) = 2 Then %>
                    <small style="color: #e53935; font-size: 14px; margin-left: 10px; background: #ffebee; padding: 3px 8px; border-radius: 12px;">
                        🔥 Đang giảm giá
                    </small>
                    <% End If %>
                </h2>
                <div class="sort-options">
                    <label>Sắp xếp theo</label>
                    <select onchange="changeSort(this.value)">
                        <option value="default" <% If sortType="default" Then Response.Write "selected" %>>Mặc định</option>
                        <option value="price-asc" <% If sortType="price-asc" Then Response.Write "selected" %>>Giá: Tăng dần</option>
                        <option value="price-desc" <% If sortType="price-desc" Then Response.Write "selected" %>>Giá: Giảm dần</option>
                        <option value="name-asc" <% If sortType="name-asc" Then Response.Write "selected" %>>Tên: A-Z</option>
                        <option value="name-desc" <% If sortType="name-desc" Then Response.Write "selected" %>>Tên: Z-A</option>
                        <option value="newest" <% If sortType="newest" Then Response.Write "selected" %>>Mới nhất</option>
                        <option value="oldest" <% If sortType="oldest" Then Response.Write "selected" %>>Cũ nhất</option>
                    </select>
                </div>
            </header>

            <div class="product-grid">
                <% 
                If rs.EOF Then 
                %>
                    <p class="no-products">Không tìm thấy sản phẩm nào.</p>
                    <% If filter_color <> "" Or filter_size <> "" Then %>
                    <p style="text-align: center; color: #666; margin-top: 10px;">
                        <a href="<%= BuildURL(categoryID, sortType, 1, "", "") %>" style="color: #007bff;">
                            Bỏ bộ lọc để xem tất cả sản phẩm
                        </a>
                    </p>
                    <% End If %>
                <% 
                Else
                    Do While Not rs.EOF
                        Dim imgPath, discountPercent, formattedSalePrice, formattedOriginalPrice
                        Dim salePriceVal, originalPriceVal
                        
                        ' Xử lý ảnh
                        If IsNull(rs("ImageURL")) Or rs("ImageURL") = "" Then
                            imgPath = "https://via.placeholder.com/300x300?text=No+Image"
                        Else
                            Dim imageUrl
                            imageUrl = Trim(rs("ImageURL"))
                            If Left(imageUrl, 1) = "/" Then imageUrl = Mid(imageUrl, 2)
                            imgPath = "../../assets/img/" & imageUrl
                        End If
                        
                        ' Xử lý giá
                        salePriceVal = 0 : originalPriceVal = 0
                        If Not IsNull(rs("SalePrice")) Then salePriceVal = CDbl(rs("SalePrice"))
                        If Not IsNull(rs("OriginalPrice")) Then originalPriceVal = CDbl(rs("OriginalPrice"))
                        
                        discountPercent = 0
                        If originalPriceVal > 0 And salePriceVal > 0 And originalPriceVal > salePriceVal Then
                            discountPercent = Int((originalPriceVal - salePriceVal) / originalPriceVal * 100)
                        End If
                        
                        If salePriceVal > 0 Then formattedSalePrice = FormatNumber(salePriceVal, 0) & "₫" Else formattedSalePrice = "Liên hệ"
                        If originalPriceVal > 0 Then formattedOriginalPrice = FormatNumber(originalPriceVal, 0) & "₫"
                %>
                    <div class="product-item" onclick="window.location.href='product-detail.asp?id=<%= rs("ProductID") %>'">
                        <div class="product-image-container">
                            <img src="<%= imageUrl %>" 
                                 alt="<% Call WriteUTF8(rs("ProductName")) %>" 
                                 onerror="this.onerror=null; this.src='https://via.placeholder.com/300x300?text=Product+Image';">
                            <% If discountPercent > 0 Then %>
                                <span class="discount-tag">-<%= discountPercent %>%</span>
                            <% End If %>
                        </div>
                        <div class="product-info">
                            <p class="product-name"><% Call WriteUTF8(rs("ProductName")) %></p>
                            <div class="product-price">
                                <span class="current-price"><%= formattedSalePrice %></span>
                                <% If originalPriceVal > salePriceVal And originalPriceVal > 0 And salePriceVal > 0 Then %>
                                    <span class="original-price"><%= formattedOriginalPrice %></span>
                                <% ElseIf originalPriceVal > 0 And salePriceVal > 0 Then %>
                                    <span class="original-price" style="opacity: 0.5;"><%= formattedOriginalPrice %></span>
                                <% End If %>
                            </div>
                        </div>
                    </div>
                <% 
                        rs.MoveNext
                    Loop
                End If
                %>
            </div>

            <% If totalPages > 1 Then %>
            <div class="pagination">
                <% 
                Dim maxPages
                If CInt(categoryID) = 1 And filter_color = "" And filter_size = "" Then
                    maxPages = 3
                    If totalPages > maxPages Then totalPages = maxPages
                End If
                For i = 1 To totalPages 
                    Dim pageOffset
                    pageOffset = (i - 1) * pageSize
                    If CInt(categoryID) = 1 And filter_color = "" And filter_size = "" Then
                        If pageOffset < 36 Then
                %>
                <a href="<%= BuildURL(categoryID, sortType, i, filter_color, filter_size) %>" 
                   class="page-btn <% If i = pageNum Then Response.Write "active" %>"><%= i %></a>
                <% 
                        End If
                    Else
                %>
                <a href="<%= BuildURL(categoryID, sortType, i, filter_color, filter_size) %>" 
                   class="page-btn <% If i = pageNum Then Response.Write "active" %>"><%= i %></a>
                <% 
                    End If
                Next 
                %>
            </div>
            <% End If %>
        </main>
    </div>
    
    <script>
        async function loadComponent(id, file) {
            try { let res = await fetch(file); if(res.ok) document.getElementById(id).innerHTML = await res.text(); } catch(e) {}
        }
        loadComponent("header", "../FE/customer/component/header.asp");
        loadComponent("footer", "../FE/customer/component/footer.html");

        function changeSort(sortValue) {
            var currentUrl = window.location.href;
            currentUrl = currentUrl.replace(/&sort=[^&]*/, '').replace(/\?sort=[^&]*/, '');
            var hasParams = currentUrl.indexOf('?') !== -1;
            var newUrl;
            if (hasParams) {
                newUrl = currentUrl + '&sort=' + encodeURIComponent(sortValue);
            } else {
                newUrl = currentUrl + '?sort=' + encodeURIComponent(sortValue);
            }
            window.location.href = newUrl;
        }
    </script>
</body>
<div id="footer"></div>
</html>
<%
If IsObject(rs) Then rs.Close : Set rs = Nothing
If IsObject(rs_colors) Then rs_colors.Close : Set rs_colors = Nothing
If IsObject(rs_sizes) Then rs_sizes.Close : Set rs_sizes = Nothing
If IsObject(conn) Then conn.Close : Set conn = Nothing
%>