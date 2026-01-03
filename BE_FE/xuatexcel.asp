<%@ Language="VBScript" %>
<!-- #include file="/BE/db/connect.asp" -->
<%
Response.Buffer = True
Response.Charset = "UTF-8"
Session.CodePage = 65001

' --- Sub ghi UTF-8 cho Excel ---
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
    If st.Size > 0 Then
        Response.BinaryWrite st.Read
    End If
    st.Close
    Set st = Nothing
End Sub

' --- Ghi BOM UTF-8 để Excel nhận dạng ---
Dim bom
bom = Chr(&HEF) & Chr(&HBB) & Chr(&HBF)
Response.Write bom

Dim fromDate, toDate
Dim sFrom, sTo
Dim rsSummary, totalOrders, totalRevenue
Dim rsQty, totalQty
Dim rsTop, rsDetail

fromDate = Request("fromDate")
toDate = Request("toDate")

If fromDate = "" Then fromDate = FormatDateTime(DateAdd("m",-1,Date), 2)
If toDate = "" Then toDate = FormatDateTime(Date, 2)

Function SQLDate(d)
    SQLDate = Year(d) & "-" & Right("0" & Month(d),2) & "-" & Right("0" & Day(d),2)
End Function

sFrom = SQLDate(CDate(fromDate))
sTo   = SQLDate(DateAdd("d",1,CDate(toDate)))

' ================== TỔNG DOANH THU / ĐƠN ==================
Set rsSummary = conn.Execute("SELECT COUNT(*) AS TotalOrders, SUM(FinalAmount) AS TotalRevenue FROM Orders WHERE OrderDate >= '" & sFrom & "' AND OrderDate < '" & sTo & "'")
If Not rsSummary.EOF Then
    totalOrders = rsSummary("TotalOrders")
    totalRevenue = rsSummary("TotalRevenue")
    If IsNull(totalRevenue) Then totalRevenue = 0
Else
    totalOrders = 0
    totalRevenue = 0
End If
rsSummary.Close
Set rsSummary = Nothing

' ================== TỔNG SẢN PHẨM ==================
Set rsQty = conn.Execute("SELECT SUM(Quantity) AS TotalQty FROM OrderDetails od JOIN Orders o ON od.OrderID=o.OrderID WHERE o.OrderDate >= '" & sFrom & "' AND o.OrderDate < '" & sTo & "'")
If Not rsQty.EOF Then
    totalQty = rsQty("TotalQty")
    If IsNull(totalQty) Then totalQty = 0
Else
    totalQty = 0
End If
rsQty.Close
Set rsQty = Nothing

' ================== TOP 5 SẢN PHẨM ==================
Set rsTop = conn.Execute("SELECT TOP 5 p.ProductName, SUM(od.Quantity) AS Qty FROM OrderDetails od JOIN Orders o ON od.OrderID=o.OrderID JOIN Products p ON od.ProductID=p.ProductID WHERE o.OrderDate >= '" & sFrom & "' AND o.OrderDate < '" & sTo & "' GROUP BY p.ProductName ORDER BY Qty DESC")

' ================== CHI TIẾT SẢN PHẨM ==================
Set rsDetail = conn.Execute("SELECT p.ProductName, SUM(od.Quantity) AS Qty, SUM(od.Quantity*od.Price) AS Amount FROM OrderDetails od JOIN Orders o ON od.OrderID=o.OrderID JOIN Products p ON od.ProductID=p.ProductID WHERE o.OrderDate >= '" & sFrom & "' AND o.OrderDate < '" & sTo & "' GROUP BY p.ProductName")

' ================== HEADER EXCEL ==================
Response.ContentType = "application/vnd.ms-excel"
Response.AddHeader "Content-Disposition", "attachment; filename=ThongKe_" & fromDate & "_den_" & toDate & ".xls"

' ================== NỘI DUNG EXCEL ==================
Response.Write "<table border='1' style='font-family:Times New Roman; font-size:12pt;'>"
Response.Write "<tr><th colspan='2'>BÁO CÁO THỐNG KÊ BÁN HÀNG</th></tr>"
Response.Write "<tr><td>Từ ngày</td><td>" & fromDate & "</td></tr>"
Response.Write "<tr><td>Đến ngày</td><td>" & toDate & "</td></tr>"
Response.Write "<tr><td>Tổng đơn hàng</td><td>" & totalOrders & "</td></tr>"
Response.Write "<tr><td>Tổng sản phẩm bán được</td><td>" & totalQty & "</td></tr>"
Response.Write "<tr><td>Tổng doanh thu</td><td>" & FormatNumber(totalRevenue,0) & "</td></tr>"
Response.Write "</table><br>"

' ================== TOP 5 SẢN PHẨM ==================
Response.Write "<table border='1' style='font-family:Times New Roman; font-size:12pt;'>"
Response.Write "<tr><th colspan='2'>Top 5 sản phẩm bán chạy</th></tr>"
Response.Write "<tr><th>Sản phẩm</th><th>Số lượng</th></tr>"
Do While Not rsTop.EOF
    Response.Write "<tr><td>"
    WriteUTF8 rsTop("ProductName")
    Response.Write "</td><td>" & rsTop("Qty") & "</td></tr>"
    rsTop.MoveNext
Loop
rsTop.Close
Set rsTop = Nothing
Response.Write "</table><br>"

' ================== CHI TIẾT SẢN PHẨM ==================
Response.Write "<table border='1' style='font-family:Times New Roman; font-size:12pt;'>"
Response.Write "<tr><th>Sản phẩm</th><th>Số lượng</th><th>Thành tiền</th></tr>"
Do While Not rsDetail.EOF
    Response.Write "<tr><td>"
    WriteUTF8 rsDetail("ProductName")
    Response.Write "</td><td>" & rsDetail("Qty") & "</td><td>" & FormatNumber(rsDetail("Amount"),0) & "</td></tr>"
    rsDetail.MoveNext
Loop
rsDetail.Close
Set rsDetail = Nothing
Response.Write "</table>"
%>
