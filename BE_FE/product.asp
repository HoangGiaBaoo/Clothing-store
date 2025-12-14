<%@LANGUAGE="VBSCRIPT" CODEPAGE="65001"%>
<!-- #include file="/BE/db/connect.asp" -->
<%
' Cấu hình để Server hiểu tiếng Việt và không bị lỗi bộ đệm
Response.Buffer = True
Response.Clear
Session.CodePage = 65001
Response.CodePage = 65001
Response.CharSet = "UTF-8"
%>
<%
' --- 1. LẤY THAM SỐ TỪ URL ---
Dim cat, sort, page, minPrice, maxPrice
cat = Request.QueryString("cat")       ' Danh mục (new, sale, hoặc ID số)
sort = Request.QueryString("sort")     ' Kiểu sắp xếp
page = Request.QueryString("page")     ' Trang hiện tại
minPrice = Request.QueryString("min")  ' Lọc giá thấp nhất
maxPrice = Request.QueryString("max")  ' Lọc giá cao nhất

If page = "" Or Not IsNumeric(page) Then page = 1 Else page = CInt(page)

' --- 2. XÂY DỰNG CÂU SQL AN TOÀN ---
Dim sql, whereClause, orderClause

' Câu SQL gốc
sql = "SELECT p.ProductID, p.ProductName, p.SalePrice, p.OriginalPrice, " & _
      "(SELECT TOP 1 ImageURL FROM ProductImages WHERE ProductID = p.ProductID AND IsMainImage = 1) AS MainImage " & _
      "FROM Products p WHERE p.IsActive = 1 "

whereClause = ""

' 1. Xử lý Danh mục
If cat = "new" Then
    whereClause = whereClause & " AND p.CreatedDate >= DateAdd(day, -30, GetDate()) "
ElseIf cat = "sale" Then
    whereClause = whereClause & " AND p.OriginalPrice > p.SalePrice "
ElseIf IsNumeric(cat) Then
    ' Quan trọng: Chỉ cộng vào SQL nếu cat là số
    whereClause = whereClause & " AND p.CategoryID = " & cat & " "
End If

' 2. Xử lý Giá (Chỉ cộng nếu có giá trị)
If IsNumeric(minPrice) And minPrice <> "" Then 
    whereClause = whereClause & " AND p.SalePrice >= " & minPrice & " "
End If

If IsNumeric(maxPrice) And maxPrice <> "" Then 
    whereClause = whereClause & " AND p.SalePrice <= " & maxPrice & " "
End If

' 3. Xử lý Sắp xếp
If sort = "price-asc" Then
    orderClause = " ORDER BY p.SalePrice ASC"
ElseIf sort = "price-desc" Then
    orderClause = " ORDER BY p.SalePrice DESC"
ElseIf sort = "name" Then
    orderClause = " ORDER BY p.ProductName ASC"
Else
    orderClause = " ORDER BY p.CreatedDate DESC"
End If

sql = sql & whereClause & orderClause

' --- 3. THỰC THI VÀ PHÂN TRANG ---
Dim rs, pageSize, totalPage, totalRecord


Set rs = Server.CreateObject("ADODB.Recordset")
rs.CursorLocation = 3 ' adUseClient (Bắt buộc để đếm tổng số dòng)
rs.PageSize = 12      ' Hiển thị 12 sản phẩm mỗi trang
rs.Open sql, conn

totalRecord = rs.RecordCount
If totalRecord > 0 Then
    totalPage = rs.PageCount
    If page > totalPage Then page = totalPage
    If page < 1 Then page = 1
    rs.AbsolutePage = page
End If
%>

<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Danh sách sản phẩm - TORANO</title>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/normalize/8.0.1/normalize.min.css">
    <link rel="stylesheet" href="../../assets/css/base.css">
    <link rel="stylesheet" href="../../assets/css/main.css">
    <link rel="stylesheet" href="../../assets/css/header-footer.css">
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link rel="stylesheet" href="/assets/fonts/fontawesome-free-6.7.2-web/css/all.min.css">
    <link href="https://fonts.googleapis.com/css2?family=Roboto:wght@400;500;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <link href="https://fonts.googleapis.com/css2?family=Roboto:wght@400;500;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="../../assets/css/product.css">
    <style>body { font-family: 'Roboto', sans-serif; }</style>
</head>
<body>

    <div id="header"></div>

    <div class="container product-page">
        <div class="sidebar">
            <div class="filter-group">
                <h3>Danh mục sản phẩm</h3>
                <ul class="filter-list">
                    <li><a href="products.asp" class="<%=IfStr(cat="","active","")%>">Tất cả sản phẩm</a></li>
                    <li><a href="products.asp?cat=new" class="<%=IfStr(cat="new","active","")%>">Sản phẩm mới</a></li>
                    <li><a href="products.asp?cat=sale" class="<%=IfStr(cat="sale","active","")%>">Danh mục Sale</a></li>
                </ul>
            </div>

            <div class="filter-group">
                <h3>Khoảng giá</h3>
                <form action="products.asp" method="GET" class="price-filter">
                    <% If cat <> "" Then %><input type="hidden" name="cat" value="<%=cat%>"><% End If %>
                    <div class="price-inputs">
                        <input type="number" name="min" placeholder="Từ" value="<%=minPrice%>">
                        <span>-</span>
                        <input type="number" name="max" placeholder="Đến" value="<%=maxPrice%>">
                    </div>
                    <button type="submit" class="btn-filter">Áp dụng</button>
                </form>
            </div>
        </div>

        <div class="main-content">
            <div class="list-header">
                <h2>
                    <% 
                    If cat = "new" Then
                        ' Xuống dòng sau Then
                        Response.Write "Sản phẩm mới"
                    ElseIf cat = "sale" Then
                        ' Xuống dòng sau Then
                        Response.Write "Sản phẩm khuyến mãi"
                    Else
                        ' Xuống dòng sau Else
                        Response.Write "Tất cả sản phẩm"
                    End If 
                    %> 
                    <span style="font-size:14px; font-weight:normal; color:#777;">(<%=totalRecord%> sản phẩm)</span>
                </h2>
                
                <div class="sort-box">
                    <label>Sắp xếp theo:</label>
                    <select onchange="window.location.href=this.value">
                        <option value="<%=GetLink(cat, page, "default")%>">Mặc định</option>
                        <option value="<%=GetLink(cat, page, "price-asc")%>" <%=IfStr(sort="price-asc","selected","")%>>Giá tăng dần</option>
                        <option value="<%=GetLink(cat, page, "price-desc")%>" <%=IfStr(sort="price-desc","selected","")%>>Giá giảm dần</option>
                        <option value="<%=GetLink(cat, page, "name")%>" <%=IfStr(sort="name","selected","")%>>Tên A-Z</option>
                    </select>
                </div>
            </div>

            <div class="product-grid">
                <% 
                If totalRecord = 0 Then
                    Response.Write "<p class='no-result'>Chưa có sản phẩm nào trong danh mục này.</p>"
                Else
                    Dim i
                    i = 0
                    Do While Not rs.EOF And i < rs.PageSize
                        Dim pID, pName, pPrice, pOldPrice, pImg
                        pID = rs("ProductID")
                        pName = rs("ProductName")
                        pPrice = rs("SalePrice")
                        pOldPrice = rs("OriginalPrice")
                        
                        ' Xử lý ảnh (Nếu null thì hiện ảnh mặc định)
                        If IsNull(rs("MainImage")) Or rs("MainImage") = "" Then 
                            pImg = "images/no-image.jpg" 
                        Else 
                            pImg = rs("MainImage")
                        End If
                %>
                    <div class="product-card">
                        <div class="card-img">
                            <a href="product-detail.asp?id=<%=pID%>">
                                <img src="<%=pImg%>" alt="<%=pName%>">
                            </a>
                            <% If pOldPrice > pPrice Then %>
                                <span class="sale-badge">-<%=Int((pOldPrice - pPrice)/pOldPrice * 100)%>%</span>
                            <% End If %>
                        </div>
                        
                        <div class="card-info">
                            <div class="card-colors">
                                <span class="more-colors">+ Chi tiết</span>
                            </div>
                            
                            <h3 class="card-title">
                                <a href="product-detail.asp?id=<%=pID%>"><%=pName%></a>
                            </h3>
                            
                            <div class="card-price">
                                <span class="price-new"><%=FormatNumber(pPrice,0)%>₫</span>
                                <% If pOldPrice > pPrice Then %>
                                    <span class="price-old"><%=FormatNumber(pOldPrice,0)%>₫</span>
                                <% End If %>
                            </div>
                        </div>
                    </div>
                <% 
                        i = i + 1
                        rs.MoveNext
                    Loop
                End If
                %>
            </div>

            <% If totalPage > 1 Then %>
            <div class="pagination">
                <% If page > 1 Then %>
                    <a href="<%=GetLink(cat, page-1, sort)%>"><i class="fas fa-chevron-left"></i></a>
                <% End If %>

                <% Dim p %>
                <% For p = 1 To totalPage %>
                    <a href="<%=GetLink(cat, p, sort)%>" class="<%=IfStr(p=page, "active", "")%>"><%=p%></a>
                <% Next %>

                <% If page < totalPage Then %>
                    <a href="<%=GetLink(cat, page+1, sort)%>"><i class="fas fa-chevron-right"></i></a>
                <% End If %>
            </div>
            <% End If %>

        </div>
    </div>

    <div id="footer"></div>

    <script>
        async function loadComponent(id, file) {
            try {
                let res = await fetch(file);
                if(res.ok) document.getElementById(id).innerHTML = await res.text();
            } catch(e) { console.error(e); }
        }
        // Nhớ sửa đường dẫn này cho đúng với thư mục dự án của bạn
        loadComponent("header", "../FE/customer/component/header.html");
        loadComponent("footer", "../FE/customer/component/footer.html");
    </script>

</body>
</html>

<%
' --- CÁC HÀM HỖ TRỢ ---

' Hàm so sánh rút gọn (Tương tự toán tử 3 ngôi)
Function IfStr(condition, valTrue, valFalse)
    If condition Then IfStr = valTrue Else IfStr = valFalse
End Function

' Hàm tạo Link giữ lại các tham số lọc cũ
Function GetLink(c, p, s)
    Dim lnk
    lnk = "products.asp?page=" & p
    If c <> "" Then lnk = lnk & "&cat=" & c
    If s <> "" And s <> "default" Then lnk = lnk & "&sort=" & s
    
    ' Giữ lại cả giá lọc nếu có
    If Request.QueryString("min") <> "" Then lnk = lnk & "&min=" & Request.QueryString("min")
    If Request.QueryString("max") <> "" Then lnk = lnk & "&max=" & Request.QueryString("max")
    
    GetLink = lnk
End Function

rs.Close
Set rs = Nothing
conn.Close
%>