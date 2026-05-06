<%@ Language="VBScript" %>
<!-- #include file="/BE/db/connect.asp" -->
<%
Response.Buffer = True
Response.Charset = "UTF-8"
Session.CodePage = 65001
activePage = "thongke"
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
' CHECK SUBMIT
'==============================
Dim fromDate, toDate, isSubmit
fromDate = Trim(Request("fromDate"))
toDate   = Trim(Request("toDate"))
isSubmit = False

If fromDate <> "" And toDate <> "" Then
    isSubmit = True
End If

'==============================
' FORMAT DATE FOR SQL
'==============================
Function SQLDate(d)
    SQLDate = Year(d) & "-" & Right("0"&Month(d),2) & "-" & Right("0"&Day(d),2)
End Function

Dim sFrom, sTo
If isSubmit Then
    sFrom = SQLDate(CDate(fromDate))
    sTo   = SQLDate(DateAdd("d",1,CDate(toDate)))
End If

'==============================
' INIT VARIABLES
'==============================
Dim totalOrders, totalRevenue, totalQty
totalOrders  = 0
totalRevenue = 0
totalQty     = 0

Dim rsSummary, rsQty, rsTop, rsDetail

'==============================
' RUN QUERY ONLY WHEN SUBMIT
'==============================
If isSubmit Then

    ' ======= SUMMARY =======
    Set rsSummary = conn.Execute( _
        "SELECT COUNT(*) AS TotalOrders, SUM(FinalAmount) AS TotalRevenue " & _
        "FROM Orders " & _
        "WHERE OrderDate >= '" & sFrom & "' AND OrderDate < '" & sTo & "'And status = 3")

    If Not rsSummary.EOF Then
        totalOrders = rsSummary("TotalOrders")
        totalRevenue = rsSummary("TotalRevenue")
        If IsNull(totalRevenue) Then totalRevenue = 0
    End If
    rsSummary.Close
    Set rsSummary = Nothing

    ' ======= TOTAL QTY =======
    Set rsQty = conn.Execute( _
        "SELECT SUM(Quantity) AS TotalQty " & _
        "FROM OrderDetails od " & _
        "JOIN Orders o ON od.OrderID=o.OrderID " & _
        "WHERE o.OrderDate >= '" & sFrom & "' AND o.OrderDate < '" & sTo & "' And status = 3")

    If Not rsQty.EOF Then
        totalQty = rsQty("TotalQty")
        If IsNull(totalQty) Then totalQty = 0
    End If
    rsQty.Close
    Set rsQty = Nothing

    ' ======= TOP PRODUCTS =======
    Set rsTop = conn.Execute( _
        "SELECT TOP 5 p.ProductName, SUM(od.Quantity) AS Qty " & _
        "FROM OrderDetails od " & _
        "JOIN Orders o ON od.OrderID=o.OrderID " & _
        "JOIN Products p ON od.ProductID=p.ProductID " & _
        "WHERE o.OrderDate >= '" & sFrom & "' AND o.OrderDate < '" & sTo & "' And status = 3" & _
        "GROUP BY p.ProductName ORDER BY Qty DESC")

    ' ======= DETAIL TABLE =======
    Set rsDetail = conn.Execute( _
        "SELECT p.ProductName, SUM(od.Quantity) AS Qty, " & _
        "SUM(od.Quantity*od.Price) AS Amount " & _
        "FROM OrderDetails od " & _
        "JOIN Orders o ON od.OrderID=o.OrderID " & _
        "JOIN Products p ON od.ProductID=p.ProductID " & _
        "WHERE o.OrderDate >= '" & sFrom & "' AND o.OrderDate < '" & sTo & "' and status =3" & _
        "GROUP BY p.ProductName")

End If
%>

<!DOCTYPE html>
<html lang="vi">
<head>
<meta charset="UTF-8">
<title>Báo cáo - Thống kê</title>
<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
<link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.1/font/bootstrap-icons.css" rel="stylesheet">
<style>
body{background:#f4f4f4}
:root{--torano-red:#9b0025}
.main{margin-left:250px;padding:20px}
.card-title{color:var(--torano-red);font-weight:600}
.stat-box{background:#fff;padding:15px;border-radius:8px;display:flex;justify-content:space-between;align-items:center}
.stat-box i{font-size:28px;color:var(--torano-red)}
.bar{height:14px;background:#ddd;border-radius:6px;overflow:hidden}
.bar span{height:100%;display:block;background:var(--torano-red)}
</style>
</head>
<body>

<!-- SIDEBAR -->
<!--#include file="sidebar.asp"-->

<div class="main">

<h4 class="mb-4">📊 Thống kê bán hàng</h4>

<!-- FORM -->
<form method="get" class="card shadow-sm mb-4">
<div class="card-body">
<h5 class="card-title">Thống kê theo khoảng ngày</h5>
<div class="row g-3 align-items-end">
    <div class="col-md-4">
        <label>Từ ngày</label>
        <input type="date" name="fromDate" value="<%=fromDate%>" class="form-control">
    </div>
    <div class="col-md-4">
        <label>Đến ngày</label>
        <input type="date" name="toDate" value="<%=toDate%>" class="form-control">
    </div>
    <div class="col-md-4">
        <button class="btn btn-danger w-100">
            <i class="bi bi-search"></i> Xem thống kê
        </button>
    </div>
</div>
</div>
</form>

<% If Not isSubmit Then %>

<div class="alert alert-info">
📅 Vui lòng chọn <strong>Từ ngày</strong> và <strong>Đến ngày</strong> rồi nhấn
<strong>Xem thống kê</strong> để hiển thị dữ liệu.
</div>

<% Else %>

<!-- SUMMARY -->
<div class="row g-3 mb-4">
<div class="col-md-4">
<div class="stat-box">
<div><small>Doanh thu</small><h6><%=FormatNumber(totalRevenue,0)%>đ</h6></div>
<i class="bi bi-cash-coin"></i>
</div>
</div>

<div class="col-md-4">
<div class="stat-box">
<div><small>Tổng đơn hàng</small><h6><%=totalOrders%></h6></div>
<i class="bi bi-receipt"></i>
</div>
</div>

<div class="col-md-4">
<div class="stat-box">
<div><small>Sản phẩm bán được</small><h6><%=totalQty%></h6></div>
<i class="bi bi-box-seam"></i>
</div>
</div>
</div>

<!-- TOP PRODUCTS -->
<div class="card shadow-sm mb-4">
<div class="card-body">
<h5 class="card-title">🔥 Top sản phẩm bán chạy</h5>

<%
Do While Not rsTop.EOF
%>
<div class="mb-3">
    <strong><% WriteUTF8 rsTop("ProductName") %></strong>
    <div class="bar">
        <span style="width:<%=rsTop("Qty")*5%>%"></span>
    </div>
    <small><%=rsTop("Qty")%> sản phẩm</small>
</div>
<%
    rsTop.MoveNext
Loop
rsTop.Close
Set rsTop = Nothing
%>

</div>
</div>

<!-- DETAIL TABLE -->
<div class="card shadow-sm">
<div class="card-body">
<h5 class="card-title">📄 Danh sách chi tiết</h5>

<table class="table table-bordered text-center">
<thead class="table-dark">
<tr>
<th>Sản phẩm</th>
<th>Số lượng</th>
<th>Thành tiền</th>
</tr>
</thead>
<tbody>

<%
Do While Not rsDetail.EOF
%>
<tr>
<td><% WriteUTF8 rsDetail("ProductName") %></td>
<td><%=rsDetail("Qty")%></td>
<td><%=FormatNumber(rsDetail("Amount"),0)%> đ</td>
</tr>
<%
rsDetail.MoveNext
Loop
rsDetail.Close
Set rsDetail = Nothing
%>

</tbody>
</table>
<div class="text-end mt-3">
    <a href="xuatexcel.asp?fromDate=<%=fromDate%>&toDate=<%=toDate%>" class="btn btn-success">
        <i class="bi bi-file-earmark-excel"></i> Xuất Excel
    </a>
</div>

</div>
</div>

<% End If %>

</div>
</body>
</html>
