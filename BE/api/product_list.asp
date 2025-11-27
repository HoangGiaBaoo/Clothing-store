<!--#include file="/BE/db/connect.asp"-->
<%
Response.ContentType = "application/json"
Response.Charset = "UTF-8"

cate = Request("categoryID")

If cate <> "" Then
    sql = "SELECT * FROM Products WHERE CategoryID=" & cate
Else
    sql = "SELECT TOP 20 * FROM Products ORDER BY ProductID DESC"
End If

Set rs = conn.Execute(sql)

json = "["

Do While Not rs.EOF
    json = json & "{"
    json = json & """ProductID"":" & rs("ProductID") & ","
    json = json & """CategoryID"":" & rs("CategoryID") & ","
    json = json & """ProductName"":""" & Replace(rs("ProductName"), """", "\""") & ""","
    json = json & """Description"":""" & Replace(rs("Description"), """", "\""") & ""","
    json = json & """Price"":" & rs("Price") & ","
    json = json & """Stock"":" & rs("Stock") & ","
    json = json & """ImageURL"":""" & rs("ImageURL") & """"
    json = json & "}"

    rs.MoveNext
    If Not rs.EOF Then json = json & ","
Loop

json = json & "]"
Response.binarywrite Utf8Encode(json)

rs.Close : conn.Close
Set rs = Nothing : Set conn = Nothing
%>
