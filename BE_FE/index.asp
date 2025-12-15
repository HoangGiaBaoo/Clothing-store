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
  <link rel="stylesheet" href="../../assets/css/product_list.css">
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
                    <a href="products.html?category=ao-khoac" class="category-card">
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
                    <a href="products.html?category=bo-thu-dong" class="category-card">
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
                    <a href="products.html?category=quan-kaki" class="category-card">
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
                    <a href="products.html?category=quan-jeans" class="category-card">
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
                    <a href="products.html?category=ao-thun" class="category-card">
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
                    <a href="products.html?category=ao-so-mi" class="category-card">
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
                    <a href="products.html?category=phu-kien" class="category-card">
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
                    <a href="products.html?category=giay-dep" class="category-card">
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
    <!-- SEARCH OVERLAY -->
    <div class="sidebar-search">
      <div class="sitenav-search">
        <div class="container">
          <div class="row">
            <div class="col-lg-3 logo">

              <div class="wrap-logo">
                <a href="https://torano.vn" itemprop="url">
                  <img itemprop="logo" src="//theme.hstatic.net/200000690725/1001078549/14/logo.png?v=1017" alt="Torano"
                    class="img-responsive logoimg lazyload" />
                </a>
              </div>

            </div>
            <div class="col-lg-6 search-form wpo-wrapper-search">
              <form action="/search" class="searchform searchform-categoris ultimate-search">
                <div class="wpo-search-inner">
                  <input type="hidden" name="type" value="product" />
                  <input required id="inputSearchAuto" class="input-search" name="q" maxlength="40" autocomplete="off"
                    type="text" size="20" placeholder="Tìm kiếm sản phẩm...">
                </div>
                <button type="submit" class="btn-search btn" aria-label="button search">
                  <svg version="1.1" class="svg search" xmlns="http://www.w3.org/2000/svg"
                    xmlns:xlink="http://www.w3.org/1999/xlink" x="0px" y="0px" viewBox="0 0 24 27"
                    style="enable-background:new 0 0 24 27;" xml:space="preserve">
                    <path
                      d="M10,2C4.5,2,0,6.5,0,12s4.5,10,10,10s10-4.5,10-10S15.5,2,10,2z M10,19c-3.9,0-7-3.1-7-7s3.1-7,7-7s7,3.1,7,7S13.9,19,10,19z">
                    </path>
                    <rect x="17" y="17" transform="matrix(0.7071 -0.7071 0.7071 0.7071 -9.2844 19.5856)" width="4"
                      height="8"></rect>
                  </svg>
                </button>
              </form>
              <div id="ajaxSearchResults" class="smart-search-wrapper ajaxSearchResults">
                <div class="resultsContent"></div>
                <div class="search-suggest">
                  <ul>
                    <li class="item item-suggest">Polo, Short Đũi, TShirt </li>

                    <li class="item"><a href="/" title="Text 1">Text 1,</a></li>
                    <li class="item"><a href="/" title="Text 2">Text 2,</a></li>
                    <li class="item"><a href="/" title="Text 3">Text 3</a></li>

                  </ul>
                </div>
              </div>
            </div>
            <div class="col-lg-3 actions">
              <div class="btn-close-search" aria-label="close-search"></div>
            </div>
          </div>
        </div>
      </div>
    </div>
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