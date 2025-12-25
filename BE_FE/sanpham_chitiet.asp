<%@ Language="VBScript" %>
<!-- #include file="/BE/db/connect.asp" -->
<%
Response.Buffer = True
activePage = "sanpham"

'==============================
' UTF-8 OUTPUT
'==============================
Sub WriteUTF8(text)
    If IsNull(text) Or text = "" Then Exit Sub
    Dim st
    Set st = Server.CreateObject("ADODB.Stream")
    st.Open
    st.Type = 2
    st.Charset = "UTF-8"
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
' LOAD DATA
'==============================
Dim pid
If IsNumeric(Request("id")) Then
    pid = CLng(Request("id"))
Else
    Response.End
End If

Dim rs
Set rs = Server.CreateObject("ADODB.Recordset")

Dim sql
sql = "SELECT ColorName, SizeName, StockQuantity " & _
      "FROM ProductVariants " & _
      "WHERE ProductID=" & pid & " AND IsActive=1 " & _
      "ORDER BY SizeOrder"

rs.Open sql, conn

If Not rs.EOF Then
    Do While Not rs.EOF
%>
<tr>
    <td><% WriteUTF8 rs("ColorName") %></td>
    <td><% WriteUTF8 rs("SizeName") %></td>
    <td><% WriteUTF8 rs("StockQuantity") %></td>
</tr>
<%
        rs.MoveNext
    Loop
Else
%>
<tr>
    <td colspan="3">Không có dữ liệu</td>
</tr>
<%
End If

rs.Close
Set rs = Nothing
conn.Close
Set conn = Nothing
%>
