<!--#include file="/BE/db/connect.asp"-->
<%
Response.ContentType = "application/json"
Response.Charset = "UTF-8"

sql = "SELECT * FROM categories ORDER BY id ASC"
Set rs = conn.Execute(sql)

json = "["

Do While Not rs.EOF
    json = json & "{"
    json = json & """id"":" & rs("id") & ","
    json = json & """name"":""" & Replace(rs("name"), """", "\""") & ""","
    json = json & """image_url"":""" & rs("image_url") & """"
    json = json & "}"

    rs.MoveNext
    If Not rs.EOF Then json = json & ","
Loop

json = json & "]"
Response.BinaryWrite Utf8Encode(json)

rs.Close : conn.Close
Set rs = Nothing : Set conn = Nothing
%>
