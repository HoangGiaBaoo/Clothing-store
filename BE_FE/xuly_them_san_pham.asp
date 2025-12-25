<%@LANGUAGE="VBSCRIPT" CODEPAGE="65001"%>
<!--#include file="/BE/db/connect.asp" -->
<%
' ==================================================================
' CẤU HÌNH
' ==================================================================
Session.CodePage = 65001
Response.Charset = "UTF-8"
On Error Resume Next

If Not IsObject(conn) Then
    Response.Write "<meta charset='UTF-8'><h3>❌ Lỗi kết nối database</h3>"
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
' 1. NHẬN DỮ LIỆU SẢN PHẨM CHÍNH
' ==================================================================
Dim pCode, pName, pCat, pBrand, pOriginPrice, pSalePrice
Dim pMat, pOrigin, pShort, pDetail

pCode        = Trim(Request.Form("ProductCode"))
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

If pCode = "" Or pName = "" Then
    Response.Write "<script>alert('❌ Mã SP và Tên SP bắt buộc!'); history.back();</script>"
    Response.End
End If

' ==================================================================
' 2. INSERT SẢN PHẨM
' ==================================================================
conn.BeginTrans

Dim sqlPro
sqlPro = "INSERT INTO Products(" & _
         "ProductCode, ProductName, CategoryID, BrandID, " & _
         "OriginalPrice, SalePrice, Material, Origin, " & _
         "ShortDescription, DetailDescription, StockQuantity, IsActive, " & _
         "CreatedDate, ModifiedDate) " & _
         "VALUES (" & _
         SqlStr(pCode) & ", " & SqlStr(pName) & ", " & pCat & ", " & pBrand & ", " & _
         pOriginPrice & ", " & pSalePrice & ", " & SqlStr(pMat) & ", " & SqlStr(pOrigin) & ", " & _
         SqlStr(pShort) & ", " & SqlStr(pDetail) & ", 0, 1, GETDATE(), GETDATE())"

conn.Execute(sqlPro)

If Err.Number <> 0 Then
    conn.RollbackTrans
    Response.Write "<meta charset='UTF-8'><h3 style='color:red;'>❌ Lỗi INSERT: " & Err.Description & "</h3>"
    Response.Write "<pre>" & sqlPro & "</pre>"
    Response.End
End If

' --- LẤY ID ---
Dim rsID, newProID
newProID = 0

Set rsID = conn.Execute("SELECT SCOPE_IDENTITY() AS NewID")
If Not rsID.EOF Then 
    If Not IsNull(rsID("NewID")) Then newProID = CLng(rsID("NewID"))
End If
rsID.Close
Set rsID = Nothing

If newProID = 0 Then
    Set rsID = conn.Execute("SELECT TOP 1 ProductID FROM Products WHERE ProductCode = " & SqlStr(pCode) & " ORDER BY CreatedDate DESC")
    If Not rsID.EOF Then newProID = CLng(rsID("ProductID"))
    rsID.Close
    Set rsID = Nothing
End If

If newProID = 0 Then
    conn.RollbackTrans
    Response.Write "<meta charset='UTF-8'><h3 style='color:red;'>❌ Không lấy được ID</h3>"
    Response.End
End If

' ==================================================================
' 3. INSERT VARIANTS - XỬ LÝ NHIỀU INPUT CÙNG TÊN (KHÔNG CÓ [])
' ==================================================================
Dim stockTotal, variantCount, colorCount
stockTotal = 0
variantCount = 0

' ĐẾM SỐ LƯỢNG VARIANTS
On Error Resume Next
colorCount = Request.Form("vColor").Count
If Err.Number <> 0 Or IsEmpty(colorCount) Then
    colorCount = 0
    Err.Clear
End If
On Error Goto 0

If colorCount > 0 Then
    Dim i, sku, color, size, addPrice, stock, sizeOrder
    
    For i = 1 To colorCount
        sku      = Trim(Request.Form("vSKU")(i))
        color    = Trim(Request.Form("vColor")(i))
        size     = Trim(Request.Form("vSize")(i))
        addPrice = SafeNumber(Request.Form("vAddPrice")(i), 0)
        stock    = SafeInt(Request.Form("vStock")(i), 0)
        
        ' Chỉ insert nếu có màu (bỏ qua dòng trống)
        If color <> "" Then
            ' Auto SKU nếu trống
            If sku = "" Then sku = pCode & "-" & Left(color, 3) & "-" & size
            
            stockTotal = stockTotal + stock
            variantCount = variantCount + 1
            
            ' Xác định thứ tự size
            Select Case UCase(size)
                Case "S"   : sizeOrder = 1
                Case "M"   : sizeOrder = 2
                Case "L"   : sizeOrder = 3
                Case "XL"  : sizeOrder = 4
                Case "XXL" : sizeOrder = 5
                Case Else  : sizeOrder = 0
            End Select
            
            Dim sqlVar
            sqlVar = "INSERT INTO ProductVariants(" & _
                     "ProductID, SKU, ColorName, SizeName, SizeOrder, " & _
                     "AdditionalPrice, StockQuantity, IsActive) " & _
                     "VALUES (" & newProID & ", " & SqlStr(sku) & ", " & SqlStr(color) & ", " & _
                     SqlStr(size) & ", " & sizeOrder & ", " & addPrice & ", " & stock & ", 1)"
            
            conn.Execute(sqlVar)
            
            If Err.Number <> 0 Then
                conn.RollbackTrans
                Response.Write "<meta charset='UTF-8'><div style='padding:20px;'>"
                Response.Write "<h3 style='color:red;'>❌ Lỗi INSERT Variant " & i & "</h3>"
                Response.Write "<p>Màu: " & color & " | Size: " & size & "</p>"
                Response.Write "<p>" & Err.Description & "</p>"
                Response.Write "<pre>" & sqlVar & "</pre></div>"
                Response.End
            End If
        End If
    Next
End If

' Cập nhật tồn kho
conn.Execute "UPDATE Products SET StockQuantity = " & stockTotal & " WHERE ProductID = " & newProID

' ==================================================================
' 4. INSERT IMAGES - 5 ẢNH CỐ ĐỊNH
' ==================================================================
Dim imageCount, mainImageIndex
imageCount = 0
mainImageIndex = SafeInt(Request.Form("MainImageSelect"), 1)

' Duyệt qua 5 ảnh
Dim imgUrl, isMain
For i = 1 To 5
    imgUrl = Trim(Request.Form("Image" & i))
    isMain = 0
    
    ' Đánh dấu ảnh chính
    If i = mainImageIndex Then isMain = 1
    
    ' Chỉ insert nếu có URL
    If imgUrl <> "" Then
        imageCount = imageCount + 1
        
        Dim sqlImg
        sqlImg = "INSERT INTO ProductImages(" & _
                 "ProductID, ImageURL, IsMainImage, DisplayOrder, CreatedDate) " & _
                 "VALUES (" & newProID & ", " & SqlStr(imgUrl) & ", " & _
                 isMain & ", " & (i-1) & ", GETDATE())"
        
        conn.Execute(sqlImg)
        
        If Err.Number <> 0 Then
            conn.RollbackTrans
            Response.Write "<meta charset='UTF-8'><div style='padding:20px;'>"
            Response.Write "<h3 style='color:red;'>❌ Lỗi INSERT Image " & i & "</h3>"
            Response.Write "<p>URL: " & imgUrl & "</p>"
            Response.Write "<p>" & Err.Description & "</p>"
            Response.Write "<pre>" & sqlImg & "</pre></div>"
            Response.End
        End If
    End If
Next

' ==================================================================
' 5. COMMIT VÀ CHUYỂN HƯỚNG
' ==================================================================
If Err.Number = 0 Then
    conn.CommitTrans
    
    ' Lưu thông tin vào Session để hiển thị thông báo
    Session("SuccessMessage") = "Thêm sản phẩm thành công!"
    Session("ProductCode") = pCode
    Session("ProductName") = pName
    Session("VariantCount") = variantCount
    Session("ImageCount") = imageCount
    Session("TotalStock") = stockTotal
    
    ' Chuyển hướng về trang quản lý
    Response.Redirect "qlsp.asp"
Else
    conn.RollbackTrans
    Response.Write "<meta charset='UTF-8'>"
    Response.Write "<div style='padding:20px; font-family:Arial;'>"
    Response.Write "<h3 style='color:red;'>❌ Lỗi hệ thống</h3>"
    Response.Write "<p>" & Err.Description & "</p>"
    Response.Write "<button onclick='history.back()' style='padding:10px 20px; cursor:pointer;'>← Quay lại</button>"
    Response.Write "</div>"
End If
%>