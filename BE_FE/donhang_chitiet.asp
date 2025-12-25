<!-- #include file="/BE/db/connect.asp" -->
<%@ Language="VBScript" %>

<%
'==============================
' UTF-8 CONFIG
'==============================
Response.Buffer = True
Response.Charset = "UTF-8"
Session.CodePage = 65001
activePage = "donhang"

'==============================
' UTF-8 OUTPUT
'==============================
Sub WriteUTF8(text)
    If IsNull(text) Or text = "" Then Exit Sub
    Dim st
    Set st = Server.CreateObject("ADODB.Stream")
    st.Type = 2
    st.Charset = "UTF-8"
    st.Open
    st.WriteText text
    st.Position = 0
    st.Type = 1
    If st.Size > 3 Then
        st.Position = 3
        Response.BinaryWrite st.Read
    End If
    st.Close
    Set st = Nothing
End Sub

'==============================
' CHECK ORDERID
'==============================
Dim orderid
If Not IsNumeric(Request("orderid")) Then
    Response.Redirect "donhang.asp"
End If
orderid = CLng(Request("orderid"))

'==============================
' LOAD ORDER
'==============================
Dim rsOrder, rsDetail
Set rsOrder  = Server.CreateObject("ADODB.Recordset")
Set rsDetail = Server.CreateObject("ADODB.Recordset")

rsOrder.Open _
    "SELECT * FROM Orders WHERE OrderID=" & orderid, conn

If rsOrder.EOF Then
    rsOrder.Close
    Response.Redirect "donhang.asp"
End If

rsDetail.Open _
    "SELECT d.ProductID, p.ProductName, d.Quantity, d.Price, d.Color, d.Size " & _
    "FROM OrderDetails d " & _
    "INNER JOIN Products p ON d.ProductID = p.ProductID " & _
    "WHERE d.OrderID=" & orderid, conn


Dim stt, textStatus, color
stt = rsOrder("Status")

Select Case stt
    Case 0: textStatus="Đã hủy": color="danger"
    Case 1: textStatus="Chờ xác nhận": color="warning"
    Case 2: textStatus="Đang giao": color="primary"
    Case 3: textStatus="Hoàn thành": color="success"
End Select
%>

<!DOCTYPE html>
<html lang="vi">
<head>
<meta charset="UTF-8">
<title>Chi tiết đơn hàng</title>

<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
<link href="https://cdn.jsdelivr.net/npm/bootstrap-icons/font/bootstrap-icons.css" rel="stylesheet">
</head>

<body>

<!-- SIDEBAR -->
<!-- #include file="sidebar.asp" -->

<div class="main">

    <div class="header">
        <h4>📄 Chi tiết đơn hàng #<%=orderid%></h4>
        <span class="badge bg-<%=color%>"><%=textStatus%></span>
    </div>

    <!-- THÔNG TIN KHÁCH -->
    <div class="card mb-3">
        <div class="card-body">
            <p><b>Người nhận:</b> <% =rsOrder("ReceiverName") %></p>
            <p><b>SĐT:</b> <%=rsOrder("ReceiverPhone")%></p>
            <p><b>Email:</b> <%=rsOrder("ReceiverEmail")%></p>
            <p><b>Địa chỉ:</b> <% =rsOrder("ReceiverAddress") %></p>
            <p><b>Ghi chú:</b> <% =rsOrder("Note") %></p>
        </div>
    </div>

    <!-- DANH SÁCH SẢN PHẨM -->
    <table class="table table-bordered align-middle">
        <thead class="table-light">
            <tr>
                <th>STT</th>
                <th>Tên SP</th>
                <th>Màu</th>
                <th>Size</th>
                <th>Số lượng</th>
                <th>Giá</th>
            </tr>
        </thead>
        <tbody>

<%
Dim i: i = 1
If rsDetail.EOF Then
%>
            <tr>
                <td colspan="6" class="text-center">Không có sản phẩm</td>
            </tr>
<%
Else
Do While Not rsDetail.EOF
%>
            <tr>
                <td class="text-center"><%=i%></td>
                <td><% WriteUTF8(rsDetail("ProductName")) %></td>

                <td><% WriteUTF8(rsDetail("Color")) %></td>
                <td class="text-center"><%=rsDetail("Size")%></td>
                <td class="text-center"><%=rsDetail("Quantity")%></td>
                <td class="text-end"><%=FormatNumber(rsDetail("Price"),0)%>đ</td>
            </tr>
<%
i = i + 1
rsDetail.MoveNext
Loop
End If
%>

        </tbody>
    </table>

    <!-- TỔNG TIỀN -->
    <div class="card">
        <div class="card-body text-end">
            <p>Tổng tiền: <b><%=FormatNumber(rsOrder("TotalAmount"),0)%>đ</b></p>
            <p>Phí ship: <b><%=FormatNumber(rsOrder("ShippingFee"),0)%>đ</b></p>
            <h5>Thanh toán: <span class="text-danger">
                <%=FormatNumber(rsOrder("FinalAmount"),0)%>đ
            </span></h5>

            <a href="donhang.asp" class="btn btn-secondary mt-2">
                <i class="bi bi-arrow-left"></i> Quay lại
            </a>
        </div>
    </div>

</div>

</body>
</html>

<%
rsOrder.Close
rsDetail.Close
Set rsOrder = Nothing
Set rsDetail = Nothing
%>
