<%
Function Utf8Encode(text)
    Dim stream, bytes
    Set stream = Server.CreateObject("ADODB.Stream")
    stream.Type = 2 'Text
    stream.Mode = 3
    stream.Open
    stream.Charset = "utf-8"
    stream.WriteText text
    stream.Position = 0
    stream.Type = 1 'Binary
    bytes = stream.Read
    stream.Close
    Set stream = Nothing

    ' Loại bỏ BOM nếu có (3 byte đầu EF BB BF)
    If LenB(bytes) >= 3 Then
        If AscB(MidB(bytes, 1, 1)) = &HEF And _
           AscB(MidB(bytes, 2, 1)) = &HBB And _
           AscB(MidB(bytes, 3, 1)) = &HBF Then
            bytes = MidB(bytes, 4)
        End If
    End If

    Utf8Encode = bytes
End Function

%>
<%
    
    set conn = Server.CreateObject("ADODB.Connection")
    strconn = "Provider=SQLOLEDB;Data Source=DESKTOP-RDPV4HN\GBAO;Initial Catalog=ShopQuanAo;User Id=sa;Password=Giabao2005@;"
    set rs = Server.CreateObject("ADODB.Recordset")
    conn.open strconn
%>