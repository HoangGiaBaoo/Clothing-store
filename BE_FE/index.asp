<%@LANGUAGE="VBSCRIPT" CODEPAGE="65001"%>
<!-- #include file="/BE/db/connect.asp" -->
<%
' 1. Cấu hình Tiếng Việt và bộ đệm
Response.Buffer = True
%>

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

        <div class="product-category-section">
            <div class="section-header">
                <h2 class="section-title">DANH MỤC SẢN PHẨM</h2>
                <div class="navigation-arrows">
                    <button class="nav-arrow" id="prevBtn-cate" disabled>
                        <i class="fas fa-chevron-left"></i>
                    </button>
                    <button class="nav-arrow" id="nextBtn-cate">
                        <i class="fas fa-chevron-right"></i>
                    </button>
                </div>
            </div>

            <div class="categories-container">
                <div class="categories-wrapper" id="categoriesWrapper">
                    <!-- Category 1 -->
                    <a href="product_list.asp?cate=4" class="category-card">
                        <div class="category-image-wrapper">
                            <img src="../assets/img/home_category_1_img.jpg" alt="Áo Khoác" class="category-image">
                            <div class="category-info">
                                <span class="category-name">Áo Khoác</span>
                                <div class="category-arrow">
                                    <i class="fas fa-arrow-right"></i>
                                </div>
                            </div>
                        </div>
                    </a>

                    <!-- Category 2 -->
                    <a href="product_list.asp?cate=5" class="category-card">
                        <div class="category-image-wrapper">
                            <img src="../assets/img/home_category_2_img.jpg" alt="Bộ Thu Đông" class="category-image">
                            <div class="category-info">
                                <span class="category-name">Bộ Thu Đông</span>
                                <div class="category-arrow">
                                    <i class="fas fa-arrow-right"></i>
                                </div>
                            </div>
                        </div>
                    </a>

                    <!-- Category 3 -->
                    <a href="product_list.asp?cate=11" class="category-card">
                        <div class="category-image-wrapper">
                            <img src="../assets/img/home_category_3_img.jpg" alt="Quần Kaki" class="category-image">
                            <div class="category-info">
                                <span class="category-name">Quần Kaki</span>
                                <div class="category-arrow">
                                    <i class="fas fa-arrow-right"></i>
                                </div>
                            </div>
                        </div>
                    </a>

                    <!-- Category 4 -->
                    <a href="product_list.asp?cate=14" class="category-card">
                        <div class="category-image-wrapper">
                            <img src="../assets/img/home_category_4_img.jpg" alt="Quần Jeans" class="category-image">
                            <div class="category-info">
                                <span class="category-name">Quần Jeans</span>
                                <div class="category-arrow">
                                    <i class="fas fa-arrow-right"></i>
                                </div>
                            </div>
                        </div>
                    </a>

                    <!-- Category 5 -->
                    <a href="product_list.asp?cate=6" class="category-card">
                        <div class="category-image-wrapper">
                            <img src="../assets/img/home_category_5_img.jpg" alt="Polo" class="category-image">
                            <div class="category-info">
                                <span class="category-name">Polo</span>
                                <div class="category-arrow">
                                    <i class="fas fa-arrow-right"></i>
                                </div>
                            </div>
                        </div>
                    </a>

                    <!-- Category 6 -->
                    <a href="product_list.asp?cate=12" class="category-card">
                        <div class="category-image-wrapper">
                            <img src="../assets/img/home_category_6_img.jpg" alt="Quần Âu" class="category-image">
                            <div class="category-info">
                                <span class="category-name">Quần Âu</span>
                                <div class="category-arrow">
                                    <i class="fas fa-arrow-right"></i>
                                </div>
                            </div>
                        </div>
                    </a>

                    <!-- Category 7 -->
                    <a href="product_list.asp?cate=7" class="category-card">
                        <div class="category-image-wrapper">
                            <img src="../assets/img/home_category_7_img.jpg" alt="Áo Sơ Mi" class="category-image">
                            <div class="category-info">
                                <span class="category-name">Áo Sơ Mi</span>
                                <div class="category-arrow">
                                    <i class="fas fa-arrow-right"></i>
                                </div>
                            </div>
                        </div>
                    </a>

                    <!-- Category 8 -->
                    <a href="product_list.asp?cate=8" class="category-card">
                        <div class="category-image-wrapper">
                            <img src="../assets/img/home_category_8_img.jpg" alt="Áo Thun" class="category-image">
                            <div class="category-info">
                                <span class="category-name">Áo Thun</span>
                                <div class="category-arrow">
                                    <i class="fas fa-arrow-right"></i>
                                </div>
                            </div>
                        </div>
                    </a>
                </div>
            </div>
        </div>

        <div class="promo-section">
            <div class="grid">
                <div class="section-header-promo">
                <h2 class="section-title-promo">Sản phẩm khuyến mãi</h2>
                <div class="nav-arrows-promo">
                    <button class="nav-arrow-promo" id="scrollLeft">←</button>
                    <button class="nav-arrow-promo" id="scrollRight">→</button>
                </div>
            </div>

            <div class="products-container" id="productsContainer">
                <div class="products-grid" id="productsGrid">
                    <div class="loading">Đang tải sản phẩm...</div>
            </div>
            </div>
        </div>

        <button class="view-all-btn">Xem tất cả sản phẩm khuyến mãi</button>
    </div>

    </div>
    <div class="a1-wrap">
        <img src="../assets/img/a1.png" alt="" class="a1-img">
    </div>
    <div class="featured-category-wrapper">
        <div class="grid">
            <!-- Category Navigation -->
        <nav class="featured-cat-nav">
            <button class="featured-cat-tab-btn is-active" data-category-id="1">
                Đồ Thu Đông
            </button>
            <button class="featured-cat-tab-btn" data-category-id="2">
                Đồ Công Sở
            </button>
            <button class="featured-cat-tab-btn" data-category-id="3">
                Đồ Thể Thao
            </button>
        </nav>

        <!-- Products Grid -->
        <div class="featured-products-grid" id="featuredProductsGrid">
            <div class="featured-loading-state">Đang tải sản phẩm...</div>
        </div>

        <!-- View All Button -->
        <button class="featured-view-all-cta" id="featuredViewAllBtn">
            Xem tất cả Đồ Thu Đông
        </button>
        </div>
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
  <script src="../../FE/js/header-footer.js"></script>
  <script src="../../FE/js/category_list.js"></script>
</body>
</html>
<%
' Đóng kết nối DB cuối cùng
conn.Close
Set conn = Nothing
%>