<%@ Language="VBScript" %>
<!-- #include file="/BE/db/connect.asp" -->
<%
Response.Buffer  = True
Response.Charset = "UTF-8"

'==============================
' ACTIVE PAGE (CHỈ SET – KHÔNG DIM)
'==============================
activePage = "dashboard"
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
Dim rs, sql
Set rs = Server.CreateObject("ADODB.Recordset")
Dim adminName
adminName = "Admin"

If Not IsEmpty(Session("userid")) Then
    Dim rsUser
    Set rsUser = Server.CreateObject("ADODB.Recordset")

    sql = "SELECT first_name, last_name FROM Users WHERE id=" & CLng(Session("userid"))
    rsUser.Open sql, conn

    If Not rsUser.EOF Then
        adminName = rsUser("first_name") & " " & rsUser("last_name")
    End If

    rsUser.Close
    Set rsUser = Nothing
End If

'==============================
' SUMMARY DATA
'==============================
Dim revenue, totalOrders, totalProducts, totalCustomers

sql = "SELECT ISNULL(SUM(TotalAmount),0) AS Revenue FROM Orders WHERE status = 3"
rs.Open sql, conn
revenue = rs("Revenue")
rs.Close

sql = "SELECT COUNT(*) AS TotalOrders FROM Orders"
rs.Open sql, conn
totalOrders = rs("TotalOrders")
rs.Close

sql = "SELECT COUNT(*) AS TotalProducts FROM Products"
rs.Open sql, conn
totalProducts = rs("TotalProducts")
rs.Close

sql = "SELECT COUNT(*) AS TotalCustomers FROM Users where role ='customer'"
rs.Open sql, conn
totalCustomers = rs("TotalCustomers")
rs.Close

'==============================
' CHART DATA
'==============================
Dim labels, data
labels = ""
data   = ""

sql = "SELECT MONTH(OrderDate) AS m, Year(OrderDate), SUM(TotalAmount) AS total " & _
      "FROM Orders " & _
        "WHERE YEAR(OrderDate) = YEAR(GETDATE()) and status = 3" & _
      "GROUP BY MONTH(OrderDate), Year(OrderDate) " & _
      "ORDER BY Year(OrderDate)"

rs.Open sql, conn
Do While Not rs.EOF
    labels = labels & "'Th" & rs("m") & "',"
    If IsNull(rs("total")) Then
    data = data & "0,"
Else
    data = data & CLng(CDbl(rs("total")) / 1000000) & ","
End If

    rs.MoveNext
Loop
rs.Close
Set rs = Nothing
If labels = "" Then
    labels = "'Th1','Th2','Th3','Th4','Th5','Th6','Th7','Th8','Th9','Th10','Th11','Th12'"
    data   = "0,0,0,0,0,0,0,0,0,0,0,0"
End If
%>

<!DOCTYPE html>
<html lang="vi">
<head>
<meta charset="UTF-8">


<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
<link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.1/font/bootstrap-icons.css" rel="stylesheet">
<script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
</head>

<body>

<!-- SIDEBAR (CHỈ INCLUDE 1 LẦN) -->
<!--#include file="/BE_FE/sidebar.asp"-->

<div class="main">

    <div class="header">
        <h3 class="mb-0">Dashboard</h3>
       <span>Xin chào, <strong><%=adminName %></strong></span>
    </div>

    <!-- SUMMARY -->
    <div class="row g-3 mb-3">
        <div class="col-md-3">
            <div class="card shadow-sm">
                <div class="card-body d-flex justify-content-between">
                    <div>
                        <small class="text-muted">Doanh thu</small>
                        <h5><%=FormatNumber(revenue,0)%>đ</h5>
                    </div>
                    <i class="bi bi-cash-coin fs-2 text-danger"></i>
                </div>
            </div>
        </div>

        <div class="col-md-3">
            <div class="card shadow-sm">
                <div class="card-body d-flex justify-content-between">
                    <div>
                        <small class="text-muted">Đơn hàng</small>
                        <h5><%=totalOrders%></h5>
                    </div>
                    <i class="bi bi-receipt fs-2 text-danger"></i>
                </div>
            </div>
        </div>

        <div class="col-md-3">
            <div class="card shadow-sm">
                <div class="card-body d-flex justify-content-between">
                    <div>
                        <small class="text-muted">Sản phẩm</small>
                        <h5><%=totalProducts%></h5>
                    </div>
                    <i class="bi bi-tshirt fs-2 text-danger"></i>
                </div>
            </div>
        </div>

        <div class="col-md-3">
            <div class="card shadow-sm">
                <div class="card-body d-flex justify-content-between">
                    <div>
                        <small class="text-muted">Khách hàng</small>
                        <h5><%=totalCustomers%></h5>
                    </div>
                    <i class="bi bi-people fs-2 text-danger"></i>
                </div>
            </div>
        </div>
    </div>

 
   <!-- CHART -->
<div class="card shadow-sm">
    <div class="card-body">
        <div class="d-flex justify-content-between align-items-center mb-3">
            <h6 class="mb-0 fw-semibold">Doanh thu theo tháng</h6>
            <small class="text-muted">Đơn vị: triệu đồng</small>
        </div>

        <div class="chart-wrapper">
            <canvas id="revenueChart"></canvas>
        </div>
    </div>
</div>


</div>

<script>
new Chart(document.getElementById('revenueChart'), {
    type: 'bar',
    data: {
        labels: [<%=labels%>],
        datasets: [{
            data: [<%=data%>],
            backgroundColor: '#9b0025',
            borderRadius: 6,
            barThickness: 28
        }]
    },
    options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
            legend: { display: false },
            tooltip: {
                callbacks: {
                    label: ctx => ctx.raw + ' triệu đồng'
                }
            }
        },
        scales: {
            y: {
                beginAtZero: true,
                max: 100,          // 👈 FIX TRẦN 250 TRIỆU
                ticks: {
                    stepSize: 20,  // 👈 mỗi vạch 50tr
                    callback: v => v + ' tr'
                },
                grid: {
                    color: '#eee'
                }
            },
            x: {
                grid: {
                    display: false
                }
            }
        }
    }
});
</script>


</body>
</html>
