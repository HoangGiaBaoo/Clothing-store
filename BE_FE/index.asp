<%@LANGUAGE="VBSCRIPT" CODEPAGE="65001"%>
<!-- #include file="/BE/db/connect.asp" -->
<%
' 1. Cấu hình Tiếng Việt và bộ đệm
Response.Buffer = True
%>
<!-- #include file="/BE/db/connect.asp" -->

<%
' --- A. LẤY DANH MỤC SẢN PHẨM (Sắp xếp theo thứ tự hiển thị) ---
Dim rsCat, sqlCat
sqlCat = "SELECT CategoryID, CategoryName FROM Categories ORDER BY DisplayOrder ASC"
Set rsCat = conn.Execute(sqlCat)

' --- B. LẤY TOP 8 SẢN PHẨM MỚI NHẤT ---
' Logic: Lấy sản phẩm đang kích hoạt (IsActive=1), sắp xếp ngày tạo mới nhất
Dim rsNew, sqlNew
sqlNew = "SELECT TOP 8 p.ProductID, p.ProductName, p.SalePrice, p.OriginalPrice, " & _
         "(SELECT TOP 1 ImageURL FROM ProductImages WHERE ProductID = p.ProductID AND IsMainImage = 1) AS MainImage " & _
         "FROM Products p " & _
         "WHERE p.IsActive = 1 " & _
         "ORDER BY p.CreatedDate DESC"
Set rsNew = conn.Execute(sqlNew)
%>

<!DOCTYPE html>
<html lang="vi">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Trang chủ - TORANO</title>
  <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/normalize/8.0.1/normalize.min.css">
  
  <link rel="stylesheet" href="../../assets/css/base.css">
  <link rel="stylesheet" href="../../assets/css/main.css">
  <link rel="stylesheet" href="../../assets/css/header-footer.css">
  <link rel="stylesheet" href="../../assets/css/product_list.css">
  
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link rel="stylesheet" href="/assets/fonts/fontawesome-free-6.7.2-web/css/all.min.css">
  <link href="https://fonts.googleapis.com/css2?family=Roboto:ital,wght@0,100..900;1,100..900&display=swap" rel="stylesheet">
  
  <style>
      /* --- CSS FIX LỖI MÉO ẢNH & CĂN CHỈNH SẢN PHẨM --- */
      
      /* Tiêu đề section */
      .section-header { text-align: center; margin: 40px 0 30px 0; }
      .section-header h2 { font-size: 28px; font-weight: 700; text-transform: uppercase; letter-spacing: 1px; margin-bottom: 10px; }
      
      /* Lưới sản phẩm */
      .home-product-grid {
          display: grid;
          grid-template-columns: repeat(4, 1fr); /* 4 cột */
          gap: 20px;
          padding-bottom: 50px;
      }
      
      /* Thẻ sản phẩm */
      .product-item {
          background: #fff;
          transition: transform 0.3s ease, box-shadow 0.3s ease;
          border: 1px solid #eee;
          display: flex;
          flex-direction: column;
      }
      .product-item:hover {
          transform: translateY(-5px);
          box-shadow: 0 5px 15px rgba(0,0,0,0.1);
      }
      
      /* Khung ảnh (Quan trọng: Giữ tỉ lệ 3:4) */
      .product-img {
          position: relative;
          width: 100%;
          aspect-ratio: 3 / 4; 
          overflow: hidden;
          background: #f1f1f1;
      }
      
      /* Ảnh bên trong (Quan trọng: object-fit cover) */
      .product-img img {
          width: 100%;
          height: 100%;
          object-fit: cover; /* Cắt ảnh dư thừa, KHÔNG làm méo */
          object-position: center;
          display: block;
          transition: transform 0.5s ease;
      }
      .product-item:hover .product-img img { transform: scale(1.05); }
      
      /* Nhãn giảm giá */
      .badge-sale {
          position: absolute;
          top: 10px; right: 10px;
          background: #d0021b; color: #fff;
          padding: 3px 8px; font-size: 12px; font-weight: bold;
          border-radius: 2px; z-index: 2;
      }
      
      /* Thông tin sản phẩm */
      .product-info { padding: 12px; text-align: left; }
      .product-info h3 {
          font-size: 15px; margin: 0 0 8px 0; line-height: 1.4;
          height: 42px; /* Giới hạn 2 dòng */
          overflow: hidden; display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical;
      }
      .product-info h3 a { text-decoration: none; color: #333; transition: 0.2s; }
      .product-info h3 a:hover { color: #000; }
      
      .price-box { display: flex; align-items: center; gap: 10px; }
      
      /* Responsive */
      @media (max-width: 992px) { .home-product-grid { grid-template-columns: repeat(3, 1fr); } }
      @media (max-width: 768px) { .home-product-grid { grid-template-columns: repeat(2, 1fr); gap: 10px; } }

      /* Style cho danh mục (Slider ngang) */
      .cat-item-card {
          flex: 0 0 auto; /* Không co giãn */
          padding: 10px 20px;
          background: #f5f5f5;
          border-radius: 20px;
          border: 1px solid #ddd;
          white-space: nowrap;
      }
      .cat-item-card:hover { background: #000; }
      .cat-item-card a { text-decoration: none; color: #333; font-weight: 500; font-size: 14px; display: block; }
      .cat-item-card:hover a { color: #fff; }
  </style>
</head>

<body>
  <div class="app">
    <div id="header"></div>
    
    <div class="body">
      <div class="banner-slider">
        <div class="slides">
          <img src="/assets/img/slide_1_img.jpg" class="slide active">
          <img src="/assets/img/slide_2_img.jpg" class="slide">
          <img src="/assets/img/slide_3_img.jpg" class="slide">
          <img src="/assets/img/slide_4_img.jpg" class="slide">
        </div>
        <div class="arrow left" id="prevBtn">&#10094;</div>
        <div class="arrow right" id="nextBtn">&#10095;</div>
        <div class="dots">
          <span class="dot active"></span><span class="dot"></span><span class="dot"></span><span class="dot"></span>
        </div>
      </div>

      <section class="category-section">
        <div class="grid">
          <h1 class="cate-header">DANH MỤC SẢN PHẨM</h1>
          <div class="category-container">
            <div class="category-slider" id="category-slider" style="display: flex; overflow-x: auto; gap: 15px; padding: 10px 0; scrollbar-width: none;">
                <% 
                If Not rsCat.EOF Then
                    Do While Not rsCat.EOF 
                %>
                    <div class="cat-item-card">
                        <a href="products.asp?cat=<%=rsCat("CategoryID")%>">
                            <%=rsCat("CategoryName")%>
                        </a>
                    </div>
                <% 
                        rsCat.MoveNext
                    Loop
                End If
                rsCat.Close
                Set rsCat = Nothing
                %>
            </div>
          </div>
        </div>
      </section>

      <section class="new-arrival-section">
          <div class="grid">
              <div class="section-header">
                  <h2>Sản phẩm mới về</h2>
                  <img src="https://torano.vn/wp-content/uploads/2019/07/title-line.png" alt="line" style="width:100px;">
              </div>
              
              <div class="home-product-grid">
                  <% 
                  If Not rsNew.EOF Then
                      Do While Not rsNew.EOF
                          Dim pID, pName, pPrice, pOldPrice, pImg
                          pID = rsNew("ProductID")
                          pName = rsNew("ProductName")
                          pPrice = rsNew("SalePrice")
                          pOldPrice = rsNew("OriginalPrice")
                          
                          ' Xử lý ảnh null
                          If IsNull(rsNew("MainImage")) Or rsNew("MainImage") = "" Then
                              pImg = "images/no-image.jpg"
                          Else
                              pImg = rsNew("MainImage")
                          End If
                  %>
                      <div class="product-item">
                          <div class="product-img">
                              <a href="product-detail.asp?id=<%=pID%>">
                                  <img src="<%=pImg%>" alt="<%=pName%>">
                              </a>
                              <% If pOldPrice > pPrice Then %>
                                  <span class="badge-sale">-<%=Int((pOldPrice - pPrice)/pOldPrice * 100)%>%</span>
                              <% End If %>
                          </div>
                          
                          <div class="product-info">
                              <h3>
                                  <a href="product-detail.asp?id=<%=pID%>" title="<%=pName%>"><%=pName%></a>
                              </h3>
                              <div class="price-box">
                                  <span style="font-weight: bold; color: #d0021b; font-size: 16px;"><%=FormatNumber(pPrice, 0)%>₫</span>
                                  <% If pOldPrice > pPrice Then %>
                                      <span style="text-decoration: line-through; color: #999; font-size: 13px;"><%=FormatNumber(pOldPrice, 0)%>₫</span>
                                  <% End If %>
                              </div>
                          </div>
                      </div>
                  <%
                          rsNew.MoveNext
                      Loop
                  End If
                  rsNew.Close
                  Set rsNew = Nothing
                  %>
              </div>
              
              <div style="text-align: center; margin-bottom: 40px;">
                  <a href="products.asp" class="btn-view-all" style="padding: 12px 40px; border: 1px solid #000; text-decoration: none; color: #000; font-weight: bold; transition: 0.3s; background: #fff;">XEM TẤT CẢ</a>
              </div>
          </div>
      </section>

    </div>
    
    <div class="footer-top">
      <div class="footer-item">
        <div class="icon"><i class="fa-solid fa-truck-fast" style="font-size: 24px;"></i></div>
        <div class="text"><h3>Miễn phí vận chuyển</h3><p>Áp dụng cho mọi đơn hàng từ 500k</p></div>
      </div>
      <div class="footer-item">
        <div class="icon"><i class="fa-solid fa-rotate" style="font-size: 24px;"></i></div>
        <div class="text"><h3>Đổi hàng dễ dàng</h3><p>7 ngày đổi hàng vì bất kì lí do gì</p></div>
      </div>
      <div class="footer-item">
        <div class="icon"><i class="fa-solid fa-phone-volume" style="font-size: 24px;"></i></div>
        <div class="text"><h3>Hỗ trợ nhanh chóng</h3><p>HOTLINE 24/7 : 0964942121</p></div>
      </div>
      <div class="footer-item">
        <div class="icon"><i class="fa-regular fa-credit-card" style="font-size: 24px;"></i></div>
        <div class="text"><h3>Thanh toán đa dạng</h3><p>Thanh toán khi nhận hàng, Napas, Visa...</p></div>
      </div>
    </div>
    
    <div id="footer"></div>

  </div>
  
  <script>
    async function loadComponent(id, file) {
      try {
          let res = await fetch(file);
          if(res.ok) document.getElementById(id).innerHTML = await res.text();
      } catch(e) { console.error(e); }
    }
    // Load Header & Footer
    loadComponent("header", "../../FE/customer/component/header.asp");
    loadComponent("footer", "../../FE/customer/component/footer.html");
  </script>
  
  <script src="../../FE/js/index.js"></script>
</body>
</html>
<%
' Đóng kết nối DB cuối cùng
conn.Close
Set conn = Nothing
%>