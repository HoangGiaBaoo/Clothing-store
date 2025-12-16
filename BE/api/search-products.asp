<!--#include file="/BE/db/connect.asp"-->
<%
Response.ContentType = "application/json"
Response.Charset = "UTF-8"

' Lấy từ khóa tìm kiếm
Dim keyword : keyword = Trim(Request("q"))

' Kiểm tra từ khóa hợp lệ
If keyword = "" Then
    Response.Write "{""products"":[],""total"":0}"
    Response.End
End If

' Làm sạch từ khóa để tránh SQL injection
keyword = Replace(keyword, "'", "''")

' Đếm tổng số sản phẩm tìm thấy
Dim countSql : countSql = "SELECT COUNT(*) as Total FROM Products p " & _
                          "WHERE (p.ProductName LIKE N'%" & keyword & "%' " & _
                          "OR p.ProductCode LIKE N'%" & keyword & "%') " & _
                          "AND p.IsActive = 1"

Set rsCount = conn.Execute(countSql)
Dim totalProducts : totalProducts = 0
If Not rsCount.EOF Then
    totalProducts = rsCount("Total")
End If
rsCount.Close
Set rsCount = Nothing

' Lấy TOP 4 sản phẩm
Dim sql : sql = "SELECT TOP 4 p.ProductID, p.ProductCode, p.ProductName, " & _
                "p.OriginalPrice, p.SalePrice, " & _
                "(SELECT TOP 1 ImageURL FROM ProductImages WHERE ProductID = p.ProductID AND IsMainImage = 1 ORDER BY DisplayOrder) as MainImage " & _
                "FROM Products p " & _
                "WHERE (p.ProductName LIKE N'%" & keyword & "%' " & _
                "OR p.ProductCode LIKE N'%" & keyword & "%') " & _
                "AND p.IsActive = 1 " & _
                "ORDER BY p.CreatedDate DESC"

Set rs = conn.Execute(sql)

json = "{""products"":["

Do While Not rs.EOF
    json = json & "{"
    json = json & """productId"":" & rs("ProductID") & ","
    json = json & """productCode"":""" & rs("ProductCode") & ""","
    json = json & """productName"":""" & Replace(rs("ProductName"), """", "\""") & ""","
    json = json & """price"":" & rs("SalePrice") & ","
    
    ' Xử lý hình ảnh
    Dim imageURL : imageURL = ""
    If Not IsNull(rs("MainImage")) Then
        imageURL = rs("MainImage")
    End If
    json = json & """imageUrl"":""" & imageURL & """"
    json = json & "}"

    rs.MoveNext
    If Not rs.EOF Then json = json & ","
Loop

json = json & "],""total"":" & totalProducts & "}"

Response.BinaryWrite Utf8Encode(json)

rs.Close : conn.Close
Set rs = Nothing : Set conn = Nothing
%>