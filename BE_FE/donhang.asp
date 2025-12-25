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
' UPDATE STATUS
'==============================
If Request("action") = "updatestatus" Then
    If IsNumeric(Request("orderid")) And IsNumeric(Request("status")) Then
        conn.Execute "UPDATE Orders SET Status=" & CLng(Request("status")) & _
                     " WHERE OrderID=" & CLng(Request("orderid"))
    End If
End If

'==============================
' SEARCH + FILTER
'==============================
Dim keyword, status, sql
keyword = Trim(Request("keyword"))
status  = Trim(Request("status"))

sql = "SELECT OrderID, ReceiverName, ReceiverPhone, OrderDate, FinalAmount, Status " & _
      "FROM Orders WHERE 1=1 "

If keyword <> "" Then
    sql = sql & " AND (" & _
          "CAST(OrderID AS VARCHAR) LIKE '%" & Replace(keyword,"'","''") & "%' " & _
          "OR ReceiverName LIKE N'%" & Replace(keyword,"'","''") & "%' " & _
          "OR ReceiverPhone LIKE '%" & Replace(keyword,"'","''") & "%') "
End If

If status <> "" And IsNumeric(status) Then
    sql = sql & " AND Status=" & CLng(status)
End If

sql = sql & " ORDER BY OrderDate DESC"

Dim rs
Set rs = Server.CreateObject("ADODB.Recordset")
rs.Open sql, conn
%>

<!DOCTYPE html>
<html lang="vi">
<head>
<meta charset="UTF-8">
<title>Quản lý đơn hàng</title>

<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
<link href="https://cdn.jsdelivr.net/npm/bootstrap-icons/font/bootstrap-icons.css" rel="stylesheet">
</head>

<body>

<!-- SIDEBAR -->
<!-- #include file="sidebar.asp" -->

<!-- MAIN CONTENT -->
<div class="main">

    <div class="header">
        <h4>📦 Quản lý đơn hàng</h4>
    </div>

    <!-- SEARCH + FILTER -->
    <form method="get" class="row g-2 mb-3">
        <div class="col-md-5">
            <input type="text" name="keyword" class="form-control"
                   placeholder="Tìm mã đơn, người nhận, SĐT"
                   value="<%=keyword%>">
        </div>

        <div class="col-md-3">
            <select name="status" class="form-select">
                <option value="">-- Tất cả trạng thái --</option>
                <option value="1" <%If status="1" Then Response.Write("selected")%>>Chờ xác nhận</option>
                <option value="2" <%If status="2" Then Response.Write("selected")%>>Đang giao</option>
                <option value="3" <%If status="3" Then Response.Write("selected")%>>Hoàn thành</option>
                <option value="0" <%If status="0" Then Response.Write("selected")%>>Đã hủy</option>
            </select>
        </div>

        <div class="col-md-2">
            <button class="btn btn-dark w-100">
                <i class="bi bi-search"></i> Tìm
            </button>
        </div>

        <div class="col-md-2">
            <a href="donhang.asp" class="btn btn-secondary w-100">Reset</a>
        </div>
    </form>

    <!-- TABLE -->
    <table class="table table-bordered align-middle">
        <thead>
            <tr>
                <th>Mã ĐH</th>
                <th>Người nhận</th>
                <th>SĐT</th>
                <th>Ngày đặt</th>
                <th>Thanh toán</th>
                <th>Trạng thái</th>
                <th>Chi tiết</th>
            </tr>
        </thead>
        <tbody>

<%
If rs.EOF Then
%>
            <tr>
                <td colspan="7" class="text-center">Không có đơn hàng</td>
            </tr>
<%
Else
Do While Not rs.EOF

Dim stt, color, textStatus
stt = rs("Status")

Select Case stt
    Case 0: textStatus = "Đã hủy": color = "danger"
    Case 1: textStatus = "Chờ xác nhận": color = "warning"
    Case 2: textStatus = "Đang giao": color = "primary"
    Case 3: textStatus = "Hoàn thành": color = "success"
End Select
%>

            <tr>
                <td>#<%=rs("OrderID")%></td>
                <td><% =rs("ReceiverName") %></td>
                <td><%=rs("ReceiverPhone")%></td>
                <td>
                    <%=Day(rs("OrderDate"))%>/<%=Month(rs("OrderDate"))%>/<%=Year(rs("OrderDate"))%>
                </td>
                <td><%=FormatNumber(rs("FinalAmount"),0)%>đ</td>

                <td>
                <% If stt = 0 Or stt = 3 Then %>
                    <span class="badge bg-<%=color%>"><%=textStatus%></span>
                <% Else %>
                    <form method="post" class="d-inline">
                        <input type="hidden" name="action" value="updatestatus">
                        <input type="hidden" name="orderid" value="<%=rs("OrderID")%>">
                        <select name="status" class="form-select form-select-sm"
                                onchange="this.form.submit()">
                            <option value="1" <%If stt=1 Then Response.Write("selected")%>>Chờ xác nhận</option>
                            <option value="2" <%If stt=2 Then Response.Write("selected")%>>Đang giao</option>
                            <option value="3">Hoàn thành</option>
                            <option value="0">Hủy đơn</option>
                        </select>
                    </form>
                <% End If %>
                </td>

                <td class="text-center">
                    <a class="btn btn-sm btn-outline-secondary"
                       href="donhang_chitiet.asp?orderid=<%=rs("OrderID")%>">
                       <i class="bi bi-eye"></i>
                    </a>
                </td>
            </tr>

<%
rs.MoveNext
Loop
End If

rs.Close
Set rs = Nothing
%>

        </tbody>
    </table>

</div> <!-- end main -->

</body>
</html>
