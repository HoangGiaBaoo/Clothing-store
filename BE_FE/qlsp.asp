<!-- #include file="/BE/db/connect.asp" -->

<%@ Language="VBScript" %>

<%
'==============================
' Cấu hình UTF-8
'==============================
Response.Buffer = True
Response.Charset = "UTF-8"
Session.CodePage = 65001

activePage = "sanpham"

'==============================
' Hàm xuất UTF-8
'==============================
Sub WriteUTF8(text)
    If IsNull(text) Or text = "" Then Exit Sub
    Dim st
    Set st = Server.CreateObject("ADODB.Stream")
    st.Open
    st.Type = 2 'Text
    st.Charset = "UTF-8"
    st.WriteText text
    st.Position = 0
    st.Type = 1 'Binary
    If st.Size > 3 Then
        st.Position = 3
        Response.BinaryWrite st.Read
    End If
    st.Close
    Set st = Nothing
End Sub

'==============================
' Lấy danh sách danh mục
'==============================
Dim rsCat
Set rsCat = Server.CreateObject("ADODB.Recordset")
rsCat.Open "SELECT CategoryName FROM Categories ORDER BY CategoryName", conn

'==============================
' Lấy danh sách sản phẩm
'==============================
Dim rs, sql
Set rs = Server.CreateObject("ADODB.Recordset")
sql = "SELECT p.ProductID, p.ProductName, " & _
      "ISNULL(c.CategoryName,N'Chưa phân loại') AS CategoryName, " & _
      "p.SalePrice, p.StockQuantity " & _
      "FROM Products p LEFT JOIN Categories c ON p.CategoryID=c.CategoryID " & _
      "ORDER BY p.ProductID DESC"
rs.Open sql, conn

Dim delID
delID = Request.QueryString("del_id")

' Chỉ xóa khi delID là số và KHÔNG RỖNG
If IsNumeric(delID) And delID <> "" Then
    ' Xóa ảnh trước (bảng con)
    conn.Execute "DELETE FROM ProductImages WHERE ProductID = " & delID
    ' Xóa biến thể (bảng con)
    conn.Execute "DELETE FROM ProductVariants WHERE ProductID = " & delID
    ' Xóa sản phẩm (bảng cha)
    conn.Execute "DELETE FROM Products WHERE ProductID = " & delID
    
    ' Chuyển hướng về trang gốc (bỏ query string để tránh lặp)
    Response.Redirect "qlsp.asp"
End If
%>

<!DOCTYPE html>
<html lang="vi">
<head>
<meta charset="UTF-8">
<title>Quản lý sản phẩm</title>
<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
<link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.1/font/bootstrap-icons.css" rel="stylesheet">
<link rel="stylesheet" href="css/admin.css">
</head>

<body>
 <!-- #include file="/BE_FE/sidebar.asp" -->

<div class="main">

<div class="header">
    <h4>Quản lý sản phẩm</h4>
    <a href="them_san_pham.asp" class="btn btn-danger">+ Thêm sản phẩm</a>
</div>

<!-- Filter search + danh mục -->
<div class="d-flex gap-2 mb-3" style="max-width:620px;">
    <input type="text" id="searchInput" class="form-control" placeholder="Tìm kiếm sản phẩm...">
    <select id="categoryFilter" class="form-select" style="width:220px;">
    <option value="">Tất cả danh mục</option>
    <% Do While Not rsCat.EOF %>
        <option value="<% Call WriteUTF8(rsCat("CategoryName")) %>">
            <% Call WriteUTF8(rsCat("CategoryName")) %>
        </option>
    <% rsCat.MoveNext : Loop %>
</select>
</div>

<!-- Bảng sản phẩm -->
<div class="card shadow-sm">
<table class="table table-hover align-middle mb-0 text-center">
<thead>
<tr>
    <th>ID</th>
    <th>Tên SP</th>
    <th>Danh mục</th>
    <th>Giá</th>
    <th>SL</th>
    <th>Trạng thái</th>
    <th></th>
    <th>Hành động</th>
</tr>
</thead>

<tbody id="productTable">
<% Do While Not rs.EOF %>
<tr>
    <td><%=rs("ProductID")%></td>
    <td class="text-start"><% Call WriteUTF8(rs("ProductName")) %></td>
    <td><% Call WriteUTF8(rs("CategoryName")) %></td>

    <td><%=FormatNumber(rs("SalePrice"),0)%> đ</td>
    <td><%=rs("StockQuantity")%></td>
    <td>
        <% If rs("StockQuantity") > 0 Then %>
            <span class="badge bg-success">Đang bán</span>
        <% Else %>
            <span class="badge bg-danger">Hết hàng</span>
        <% End If %>
    </td>
    <td>
        <button class="btn btn-sm btn-outline-primary" onclick="xemChiTiet(<%=rs("ProductID")%>)">
            Chi tiết
        </button>
    </td>
    <td>
        <a href="sua_san_pham.asp?id=<%=rs("ProductID")%>" class="btn btn-sm btn-outline-dark"><i class="bi bi-pencil"></i></a>

        <a href="qlsp.asp?del_id=<%=rs("ProductID")%>" class="btn btn-sm btn-outline-danger" onclick="return confirm('Bạn chắc chắn muốn xóa SP này?');" title="Xóa">
                                    <i class="bi bi-trash"></i>
                                </a>
    </td>
</tr>
<% rs.MoveNext : Loop %>
</tbody>
</table>
</div>
</div>

<!-- MODAL CHI TIẾT -->
<div class="modal fade" id="chiTietModal">
<div class="modal-dialog modal-lg modal-dialog-centered">
<div class="modal-content">
<div class="modal-header">
<h5 class="modal-title">CHI TIẾT SẢN PHẨM</h5>
<button type="button" class="btn-close" data-bs-dismiss="modal"></button>
</div>
<div class="modal-body">
<table class="table table-bordered text-center">
<thead class="table-dark">
<tr>
<th>Màu</th>
<th>Size</th>
<th>Số lượng</th>
</tr>
</thead>
<tbody id="chiTietBody"></tbody>
</table>
</div>
</div>
</div>
</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js"></script>

<script>
// Hiển thị chi tiết sản phẩm
function xemChiTiet(id){
    fetch("sanpham_chitiet.asp?id=" + id)
        .then(res => res.text())
        .then(html => {
            document.getElementById("chiTietBody").innerHTML = html;
            new bootstrap.Modal(document.getElementById("chiTietModal")).show();
        });
}

// Filter search + danh mục
const searchInput = document.getElementById("searchInput");
const categoryFilter = document.getElementById("categoryFilter");
const productTable = document.getElementById("productTable");

function filterProducts(){
    const txt = searchInput.value.toLowerCase().trim();
    const catVal = categoryFilter.value.toLowerCase().trim();
    Array.from(productTable.rows).forEach(r => {
        const name = r.cells[1].textContent.toLowerCase().trim();
        const cat = r.cells[2].textContent.toLowerCase().trim();
        r.style.display = (name.includes(txt) && (catVal === "" || cat === catVal)) ? "" : "none";
    });
}

searchInput.oninput = filterProducts;
categoryFilter.onchange = filterProducts;
</script>

</body>
</html>

<%
'==============================
' Giải phóng bộ nhớ
'==============================
rs.Close : rsCat.Close
Set rs = Nothing : Set rsCat = Nothing
conn.Close : Set conn = Nothing
%>

