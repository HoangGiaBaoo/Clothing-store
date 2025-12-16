<!--#include file="/BE/db/connect.asp"-->
<%
Response.ContentType = "application/json"
Response.Charset = "UTF-8"

categoryId = Request("categoryId")

' Kiểm tra categoryId hợp lệ
If categoryId = "" Or Not IsNumeric(categoryId) Then
    Response.Write "[]"
    Response.End
End If

' Xác định điều kiện WHERE dựa trên categoryId
Dim whereCondition
Select Case CInt(categoryId)
    Case 1 ' Đồ Thu Đông
        whereCondition = "p.CategoryID = 8 AND p.IsActive = 1"
        
    Case 2 ' Đồ Công Sở
        whereCondition = "p.CategoryID = 9 AND p.IsActive = 1"
        
    Case 3 ' Đồ Thể Thao
        whereCondition = "p.CategoryID = 10 AND p.IsActive = 1"
        
    Case Else ' Trường hợp không hợp lệ
        Response.Write "[]"
        Response.End
End Select

' Lấy TOP 10 sản phẩm theo danh mục
sql = "SELECT TOP 10 p.ProductID, p.ProductCode, p.ProductName, " & _
      "p.OriginalPrice, p.SalePrice, " & _
      "(SELECT TOP 1 ImageURL FROM ProductImages WHERE ProductID = p.ProductID AND IsMainImage = 1 ORDER BY DisplayOrder) as MainImage, " & _
      "(SELECT COUNT(DISTINCT ColorName) FROM ProductVariants WHERE ProductID = p.ProductID AND IsActive = 1) as ColorCount, " & _
      "(SELECT COUNT(DISTINCT SizeName) FROM ProductVariants WHERE ProductID = p.ProductID AND IsActive = 1) as SizeCount " & _
      "FROM Products p " & _
      "WHERE " & whereCondition & " " & _
      "ORDER BY p.CreatedDate DESC"

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