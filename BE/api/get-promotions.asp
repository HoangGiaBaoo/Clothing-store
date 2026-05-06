<!--#include file="/BE/db/connect.asp"-->
<%
Response.ContentType = "application/json"
Response.Charset = "UTF-8"

' Lấy sản phẩm có giảm giá (SalePrice > 0 và < OriginalPrice)
sql = "SELECT TOP 20 p.ProductID, p.ProductCode, p.ProductName, " & _
      "p.OriginalPrice, p.SalePrice, " & _
      "(SELECT TOP 1 ImageURL FROM ProductImages WHERE ProductID = p.ProductID AND IsMainImage = 1 ORDER BY DisplayOrder) as MainImage, " & _
      "(SELECT COUNT(DISTINCT ColorName) FROM ProductVariants WHERE ProductID = p.ProductID AND IsActive = 1) as ColorCount, " & _
      "(SELECT COUNT(DISTINCT SizeName) FROM ProductVariants WHERE ProductID = p.ProductID AND IsActive = 1) as SizeCount " & _
      "FROM Products p " & _
      "WHERE p.SalePrice > 0 AND p.SalePrice < p.OriginalPrice AND p.IsActive = 1 " & _
      "ORDER BY p.SalePrice ASC"

Set rs = conn.Execute(sql)

json = "["

Do While Not rs.EOF
    ' Tính phần trăm giảm giá
    If IsNull(salePrice) Then salePrice = 0 Else salePrice = CDbl(rs("SalePrice"))
    If IsNull(originalPrice) Then originalPrice = 0 Else originalPrice = CDbl(rs("OriginalPrice"))
    Dim discountPercent : discountPercent = 0
    
    If IsNumeric(originalPrice) And IsNumeric(salePrice) Then
        If originalPrice > 0 And originalPrice > salePrice Then
            discountPercent = Int((1 - salePrice/originalPrice) * 100)
        End If
    End If
    
    json = json & "{"
    json = json & """productId"":" & rs("ProductID") & ","
    json = json & """productCode"":""" & rs("ProductCode") & ""","
    json = json & """productName"":""" & Replace(rs("ProductName"), """", "\""") & ""","
    json = json & """originalPrice"":" & rs("OriginalPrice") & ","
    json = json & """salePrice"":" & rs("SalePrice") & ","
    json = json & """discount"":" & discountPercent & ","
    
    ' Xử lý hình ảnh
    Dim imageURL : imageURL = ""
    If Not IsNull(rs("MainImage")) Then
        imageURL = rs("MainImage")
    End If
    json = json & """imageUrl"":""" & imageURL & ""","
    
    json = json & """colorCount"":" & rs("ColorCount") & ","
    json = json & """sizeCount"":" & rs("SizeCount")
    json = json & "}"

    rs.MoveNext
    If Not rs.EOF Then json = json & ","
Loop

json = json & "]"
Response.BinaryWrite Utf8Encode(json)

rs.Close : conn.Close
Set rs = Nothing : Set conn = Nothing
%>