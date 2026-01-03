<%@LANGUAGE="VBSCRIPT" CODEPAGE="65001"%>
<!--#include file="/BE/db/connect.asp" -->
<%
Session.CodePage = 65001
Response.Charset = "UTF-8"
On Error Resume Next

If Not IsObject(conn) Then
    Response.Write "<h3>❌ Lỗi kết nối database</h3>"
    Response.End
End If

' ==================================================================
' HÀM HỖ TRỢ
' ==================================================================
Function SqlStr(str)
    If IsNull(str) Or Trim(str) = "" Then
        SqlStr = "NULL"
    Else
        SqlStr = "N'" & Replace(Trim(str), "'", "''") & "'"
    End If
End Function

Function SafeNumber(val, defaultVal)
    If IsNumeric(val) And val <> "" Then
        SafeNumber = CDbl(val)
    Else
        SafeNumber = defaultVal
    End If
End Function

Function SafeInt(val, defaultVal)
    If IsNumeric(val) And val <> "" Then
        SafeInt = CInt(val)
    Else
        SafeInt = defaultVal
    End If
End Function

' ==================================================================
' NHẬN DỮ LIỆU
' ==================================================================
Dim productID, pName, pCat, pBrand, pOriginPrice, pSalePrice
Dim pMat, pOrigin, pShort, pDetail

productID    = Request.Form("ProductID")
pName        = Trim(Request.Form("ProductName"))
pCat         = Trim(Request.Form("CategoryID"))
pBrand       = Trim(Request.Form("BrandID"))
pOriginPrice = SafeNumber(Request.Form("OriginalPrice"), 0)
pSalePrice   = SafeNumber(Request.Form("SalePrice"), 0)
pMat         = Trim(Request.Form("Material"))
pOrigin      = Trim(Request.Form("Origin"))
pShort       = Trim(Request.Form("ShortDescription"))
pDetail      = Trim(Request.Form("DetailDescription"))

If pCat = "" Then pCat = "NULL"
If pBrand = "" Then pBrand = "NULL"

If productID = "" Or pName = "" Then
    Response.Write "<script>alert('Dữ liệu không hợp lệ!'); history.back();</script>"
    Response.End
End If

' ==================================================================
' BẮT ĐẦU TRANSACTION
' ==================================================================
conn.BeginTrans

' ==================================================================
' 1. CẬP NHẬT THÔNG TIN SẢN PHẨM
' ==================================================================
Dim sqlUpdate
sqlUpdate = "UPDATE Products SET " & _
            "ProductName = " & SqlStr(pName) & ", " & _
            "CategoryID = " & pCat & ", " & _
            "BrandID = " & pBrand & ", " & _
            "OriginalPrice = " & pOriginPrice & ", " & _
            "SalePrice = " & pSalePrice & ", " & _
            "Material = " & SqlStr(pMat) & ", " & _
            "Origin = " & SqlStr(pOrigin) & ", " & _
            "ShortDescription = " & SqlStr(pShort) & ", " & _
            "DetailDescription = " & SqlStr(pDetail) & ", " & _
            "ModifiedDate = GETDATE() " & _
            "WHERE ProductID = " & productID

conn.Execute(sqlUpdate)

If Err.Number <> 0 Then
    conn.RollbackTrans
    Response.Write "<meta charset='UTF-8'><h3 style='color:red;'>❌ Lỗi cập nhật sản phẩm: " & Err.Description & "</h3>"
    Response.End
End If

' ==================================================================
' 2. XỬ LÝ HÌNH ẢNH
' ==================================================================
' Xóa tất cả ảnh cũ
conn.Execute "DELETE FROM ProductImages WHERE ProductID = " & productID

' Thêm ảnh mới
Dim mainImageIndex, imageCount, imgUrl, isMain
mainImageIndex = SafeInt(Request.Form("MainImageSelect"), 1)
imageCount = 0

For i = 1 To 5
    imgUrl = Trim(Request.Form("Image" & i))
    isMain = 0
    
    If i = mainImageIndex Then isMain = 1
    
    If imgUrl <> "" Then
        imageCount = imageCount + 1
        
        Dim sqlImg
        sqlImg = "INSERT INTO ProductImages(ProductID, ImageURL, IsMainImage, DisplayOrder, CreatedDate) " & _
                 "VALUES (" & productID & ", " & SqlStr(imgUrl) & ", " & isMain & ", " & (i) & ", GETDATE())"
        
        conn.Execute(sqlImg)
        
        If Err.Number <> 0 Then
            conn.RollbackTrans
            Response.Write "<meta charset='UTF-8'><h3 style='color:red;'>❌ Lỗi cập nhật ảnh: " & Err.Description & "</h3>"
            Response.End
        End If
    End If
Next

' ==================================================================
' 3. XỬ LÝ VARIANTS HIỆN CÓ
' ==================================================================
Dim existingIDs, existingCount, variantCount, totalStock
existingCount = 0
variantCount = 0
totalStock = 0

On Error Resume Next
existingCount = Request.Form("ExistingVariantID").Count
If Err.Number <> 0 Then existingCount = 0
On Error Goto 0

If existingCount > 0 Then
    For i = 1 To existingCount
        Dim varID, varColor, varSize, varAddPrice, varStock, varAddStock, varDeleteFlag
        
        varID         = Request.Form("ExistingVariantID")(i)
        varColor      = Trim(Request.Form("ExistingColor")(i))
        varSize       = Trim(Request.Form("ExistingSize")(i))
        varAddPrice   = SafeNumber(Request.Form("ExistingAddPrice")(i), 0)
        varStock      = SafeInt(Request.Form("ExistingStock")(i), 0)
        varAddStock   = SafeInt(Request.Form("ExistingAddStock")(i), 0)
        varDeleteFlag = Request.Form("ExistingDeleteFlag")(i)
        
        If varDeleteFlag = "1" Then
            ' XÓA VARIANT
            conn.Execute "DELETE FROM ProductVariants WHERE VariantID = " & varID
        Else
            ' CẬP NHẬT VARIANT
            Dim newStock
            newStock = varStock + varAddStock
            
            Dim sizeOrder
            Select Case UCase(varSize)
                Case "S"   : sizeOrder = 1
                Case "M"   : sizeOrder = 2
                Case "L"   : sizeOrder = 3
                Case "XL"  : sizeOrder = 4
                Case "XXL" : sizeOrder = 5
                Case Else  : sizeOrder = 0
            End Select
            
            Dim sqlUpdateVar
            sqlUpdateVar = "UPDATE ProductVariants SET " & _
                          "ColorName = " & SqlStr(varColor) & ", " & _
                          "SizeName = " & SqlStr(varSize) & ", " & _
                          "SizeOrder = " & sizeOrder & ", " & _
                          "AdditionalPrice = " & varAddPrice & ", " & _
                          "StockQuantity = " & newStock & " " & _
                          "WHERE VariantID = " & varID
            
            conn.Execute(sqlUpdateVar)
            
            totalStock = totalStock + newStock
            variantCount = variantCount + 1
        End If
        
        If Err.Number <> 0 Then
            conn.RollbackTrans
            Response.Write "<meta charset='UTF-8'><h3 style='color:red;'>❌ Lỗi xử lý variant: " & Err.Description & "</h3>"
            Response.End
        End If
    Next
End If

' ==================================================================
' 4. THÊM VARIANTS MỚI
' ==================================================================
Dim newColorCount
On Error Resume Next
newColorCount = Request.Form("NewColor").Count
If Err.Number <> 0 Then newColorCount = 0
On Error Goto 0

If newColorCount > 0 Then
    ' Lấy ProductCode để tạo SKU
    Dim rsCode
    Set rsCode = conn.Execute("SELECT ProductCode FROM Products WHERE ProductID = " & productID)
    Dim pCode
    If Not rsCode.EOF Then pCode = rsCode("ProductCode")
    rsCode.Close
    
    For i = 1 To newColorCount
        Dim nSKU, nColor, nSize, nAddPrice, nStock, nSizeOrder
        
        nSKU      = Trim(Request.Form("NewSKU")(i))
        nColor    = Trim(Request.Form("NewColor")(i))
        nSize     = Trim(Request.Form("NewSize")(i))
        nAddPrice = SafeNumber(Request.Form("NewAddPrice")(i), 0)
        nStock    = SafeInt(Request.Form("NewStock")(i), 0)
        
        ' Chỉ thêm nếu có màu
        If nColor <> "" Then
            ' Auto SKU nếu trống
            If nSKU = "" Then nSKU = pCode & "-" & Left(nColor, 3) & "-" & nSize
            
            Select Case UCase(nSize)
                Case "S"   : nSizeOrder = 1
                Case "M"   : nSizeOrder = 2
                Case "L"   : nSizeOrder = 3
                Case "XL"  : nSizeOrder = 4
                Case "XXL" : nSizeOrder = 5
                Case Else  : nSizeOrder = 0
            End Select
            
            Dim sqlNewVar
            sqlNewVar = "INSERT INTO ProductVariants(ProductID, SKU, ColorName, SizeName, SizeOrder, " & _
                       "AdditionalPrice, StockQuantity, IsActive) VALUES (" & _
                       productID & ", " & SqlStr(nSKU) & ", " & SqlStr(nColor) & ", " & _
                       SqlStr(nSize) & ", " & nSizeOrder & ", " & nAddPrice & ", " & nStock & ", 1)"
            
            conn.Execute(sqlNewVar)
            
            totalStock = totalStock + nStock
            variantCount = variantCount + 1
            
            If Err.Number <> 0 Then
                conn.RollbackTrans
                Response.Write "<meta charset='UTF-8'><h3 style='color:red;'>❌ Lỗi thêm variant mới: " & Err.Description & "</h3>"
                Response.End
            End If
        End If
    Next
End If

' ==================================================================
' 5. CẬP NHẬT TỔNG TỒN KHO
' ==================================================================
conn.Execute "UPDATE Products SET StockQuantity = " & totalStock & " WHERE ProductID = " & productID

' ==================================================================
' 6. COMMIT VÀ CHUYỂN HƯỚNG
' ==================================================================
If Err.Number = 0 Then
    conn.CommitTrans
    
    Session("SuccessMessage") = "Cập nhật sản phẩm thành công!"
    Session("ProductCode") = pCode
    Session("ProductName") = pName
    Session("VariantCount") = variantCount
    Session("ImageCount") = imageCount
    Session("TotalStock") = totalStock
    
    Response.Redirect "qlsp.asp"
Else
    conn.RollbackTrans
    Response.Write "<meta charset='UTF-8'><h3 style='color:red;'>❌ Lỗi: " & Err.Description & "</h3>"
End If
%>