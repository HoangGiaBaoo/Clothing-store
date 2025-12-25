<%

If IsEmpty(activePage) Then activePage = ""

Dim dashActive, spActive, dhActive, khActive, bcActive
dashActive = ""
spActive   = ""
dhActive   = ""
khActive   = ""
bcActive   = ""

Select Case activePage
    Case "dashboard": dashActive = "active"
    Case "sanpham":   spActive   = "active"
    Case "donhang":   dhActive   = "active"
    Case "khachhang": khActive   = "active"
    Case "thongke":    bcActive   = "active"
End Select
%>

<div class="sidebar">
    <div style="padding:20px;text-align:center;border-bottom:1px solid #333;">
        <img src="../assets/img/logo.png"
             alt="Torano" style="max-width:150px;">
    </div>

    <a href="dashboard.asp" class="<%= dashActive %>">
        <i class="bi bi-speedometer2 me-2"></i>Dashboard
    </a>

    <a href="qlsp.asp" class="<%= spActive %>">
        <i class="bi bi-tshirt me-2"></i>Sản phẩm
    </a>

    <a href="donhang.asp" class="<%= dhActive %>">
        <i class="bi bi-bag-check me-2"></i>Đơn hàng
    </a>

    <a href="khachhang.asp" class="<%= khActive %>">
        <i class="bi bi-people me-2"></i>Khách hàng
    </a>

    <a href="thongke.asp" class="<%= bcActive %>">
        <i class="bi bi-bar-chart me-2"></i>Thống kê
    </a>

    <a href="login.asp">
        <i class="bi bi-box-arrow-right me-2"></i>Đăng xuất
    </a>
</div>
<style>
body {
    margin: 0;
    background: #f5f5f5;
}

:root {
    --torano-red: #9b0025;
}

/* SIDEBAR */
.sidebar {
    width: 250px;
    height: 100vh;
    position: fixed;
    left: 0;
    top: 0;
    background: #111;
}

.sidebar-logo {
    padding: 20px;
    text-align: center;
    border-bottom: 1px solid #333;
}

.sidebar-logo img {
    max-width: 150px;
}

.sidebar a {
    color: #ccc;
    padding: 14px 20px;
    display: block;
    text-decoration: none;
}

.sidebar a.active,
.sidebar a:hover {
    background: var(--torano-red);
    color: #fff;
}

/* MAIN */
.main {
    margin-left: 250px;
    padding: 20px 25px;
    height: 100vh;
    overflow-y: auto;
}

.header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    border-bottom: 2px solid var(--torano-red);
    padding-bottom: 10px;
    margin-bottom: 20px;
}

table th {
    background: #111;
    color: #fff;
    text-align: center;
}
.chart-wrapper {
    height: 320px;        /* chiều cao vừa đẹp */
    padding: 10px 5px;
}

</style>
