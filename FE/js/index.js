const slides = document.querySelector(".slides");
const dots = document.querySelectorAll(".dot");

let index = 0;
let autoSlide;
const totalSlides = dots.length;

// Cập nhật vị trí slide
function updateSlide(i) {
    slides.style.transform = `translateX(-${i * 100}%)`;

    dots.forEach(dot => dot.classList.remove("active"));
    dots[i].classList.add("active");

    index = i;
}

function nextSlide() {
    index = (index + 1) % totalSlides;
    updateSlide(index);
}

function prevSlide() {
    index = (index - 1 + totalSlides) % totalSlides;
    updateSlide(index);
}

function startAutoSlide() {
    autoSlide = setInterval(nextSlide, 4000);
}

function stopAutoSlide() {
    clearInterval(autoSlide);
}

document.getElementById("nextBtn").addEventListener("click", () => {
    nextSlide();
    stopAutoSlide();
    startAutoSlide();
});

document.getElementById("prevBtn").addEventListener("click", () => {
    prevSlide();
    stopAutoSlide();
    startAutoSlide();
});

dots.forEach((dot, i) => {
    dot.addEventListener("click", () => {
        updateSlide(i);
        stopAutoSlide();
        startAutoSlide();
    });
});

startAutoSlide();


// Format tiền VND
function formatPrice(price) {
    return new Intl.NumberFormat('vi-VN').format(price) + 'đ';
}

// Render sản phẩm
function renderProducts(products) {
    const grid = document.getElementById('productsGrid');

    if (!products || products.length === 0) {
        grid.innerHTML = '<div class="loading">Không có sản phẩm khuyến mãi</div>';
        return;
    }

    grid.innerHTML = products.map(product => `
                <div class="product-card" onclick="viewProduct(${product.productId})">
                    <div class="product-image-wrapper">
                        <img src="${product.imageUrl || '/images/no-image.jpg'}" 
                             alt="${product.productName}" 
                             class="product-image"
                             onerror="this.src='/images/no-image.jpg'">
                        <span class="discount-badge-promo">-${product.discount}%</span>
                    </div>
                    <div class="product-info">
                        <div class="product-variants">
                            ${product.colorCount > 0 ? `<span>+${product.colorCount} Màu sắc</span>` : ''}
                            ${product.sizeCount > 0 ? `<span>+${product.sizeCount} Kích thước</span>` : ''}
                        </div>
                        <div class="product-name">${product.productName}</div>
                        <div class="product-prices">
                            <span class="sale-price">${formatPrice(product.salePrice)}</span>
                            <span class="original-price">${formatPrice(product.originalPrice)}</span>
                        </div>
                    </div>
                </div>
            `).join('');
}

// Xem chi tiết sản phẩm
function viewProduct(productId) {
    window.location.href = `/BE_FE/product-detail.asp?id=${productId}`;
}

// Scroll navigation
const container = document.getElementById('productsContainer');
const scrollAmount = 250;

document.getElementById('scrollLeft').addEventListener('click', () => {
    container.scrollBy({ left: -scrollAmount, behavior: 'smooth' });
});

document.getElementById('scrollRight').addEventListener('click', () => {
    container.scrollBy({ left: scrollAmount, behavior: 'smooth' });
});

// Xem tất cả
document.querySelector('.view-all-btn').addEventListener('click', () => {
    window.location.href = '/promotions.asp';
});

// Load sản phẩm từ API
async function loadProducts() {
    try {
        const response = await fetch('/BE/api/get-promotions.asp');
        if (!response.ok) throw new Error('Không thể tải dữ liệu');

        const products = await response.json();
        renderProducts(products);
    } catch (error) {
        console.error('Error loading products:', error);
        document.getElementById('productsGrid').innerHTML =
            '<div class="loading">Không thể tải sản phẩm. Vui lòng thử lại sau.</div>';
    }
}

// Load khi trang tải xong
loadProducts();

// Cấu hình danh mục
const CATEGORY_CONFIG = {
    1: { name: 'Đồ Thu Đông', slug: 'thu-dong' },
    2: { name: 'Đồ Công Sở', slug: 'cong-so' },
    3: { name: 'Đồ Thể Thao', slug: 'the-thao' }
};

let currentCategoryId = 1;

// Format giá tiền VND
function formatVndPrice(price) {
    return new Intl.NumberFormat('vi-VN').format(price) + 'đ';
}

// Render danh sách sản phẩm
function renderFeaturedProducts(products) {
    const grid = document.getElementById('featuredProductsGrid');

    if (!products || products.length === 0) {
        grid.innerHTML = '<div class="featured-loading-state">Không có sản phẩm trong danh mục này</div>';
        return;
    }

    grid.innerHTML = products.map(product => {
        const hasDiscount = product.discount > 0;
        const hasGift = product.discount >= 25; // Có quà nếu giảm >= 25%

        return `
                    <div class="featured-product-item" onclick="goToProductDetail(${product.productId})">
                        <div class="featured-product-img-container">
                            <img src="${product.imageUrl || '/images/no-image.jpg'}" 
                                 alt="${product.productName}" 
                                 class="featured-product-img"
                                 onerror="this.src='/images/no-image.jpg'">
                            ${hasDiscount ? `<span class="featured-discount-label">-${product.discount}%</span>` : ''}
                            ${hasGift ? '<div class="featured-gift-badge">🎁</div>' : ''}
                        </div>
                        <div class="featured-product-details">
                            <div class="featured-product-variants">
                                ${product.colorCount > 0 ? `<span>+${product.colorCount} Màu sắc</span>` : ''}
                                ${product.sizeCount > 0 ? `<span>+${product.sizeCount} Kích thước</span>` : ''}
                            </div>
                            <div class="featured-product-title">${product.productName}</div>
                            <div class="featured-product-pricing">
                                ${hasDiscount
                ? `<span class="featured-price-sale">${formatVndPrice(product.salePrice)}</span>
                                       <span class="featured-price-original">${formatVndPrice(product.originalPrice)}</span>`
                : `<span class="featured-price-regular">${formatVndPrice(product.salePrice)}</span>`
            }
                            </div>
                        </div>
                    </div>
                `;
    }).join('');
}

// Chuyển đến trang chi tiết sản phẩm
function goToProductDetail(productId) {
    window.location.href = `/BE_FE/product-detail.asp?id=${productId}`;
}

// Load sản phẩm theo danh mục
async function loadCategoryProducts(categoryId) {
    const grid = document.getElementById('featuredProductsGrid');
    grid.innerHTML = '<div class="featured-loading-state">Đang tải sản phẩm...</div>';

    try {
        const response = await fetch(`/BE/api/get-cate-product.asp?categoryId=${categoryId}`);
        if (!response.ok) throw new Error('Không thể tải dữ liệu');

        const products = await response.json();
        renderFeaturedProducts(products);
    } catch (error) {
        console.error('Error loading products:', error);
        grid.innerHTML = '<div class="featured-loading-state">Không thể tải sản phẩm. Vui lòng thử lại sau.</div>';
    }
}

// Xử lý click tab danh mục
function handleCategoryTabClick(event) {
    const clickedTab = event.currentTarget;
    const categoryId = parseInt(clickedTab.dataset.categoryId);

    if (categoryId === currentCategoryId) return;

    // Cập nhật trạng thái active
    document.querySelectorAll('.featured-cat-tab-btn').forEach(tab => {
        tab.classList.remove('is-active');
    });
    clickedTab.classList.add('is-active');

    // Cập nhật nút "Xem tất cả"
    const categoryName = CATEGORY_CONFIG[categoryId].name;
    document.getElementById('featuredViewAllBtn').textContent = `Xem tất cả ${categoryName}`;

    // Load sản phẩm mới
    currentCategoryId = categoryId;
    loadCategoryProducts(categoryId);
}

// Xử lý click nút "Xem tất cả"
function handleViewAllClick() {
    const categorySlug = CATEGORY_CONFIG[currentCategoryId].slug;
    window.location.href = `/category.asp?slug=${categorySlug}`;
}

// Khởi tạo
function initFeaturedCategories() {
    // Gán sự kiện cho các tab
    document.querySelectorAll('.featured-cat-tab-btn').forEach(tab => {
        tab.addEventListener('click', handleCategoryTabClick);
    });

    // Gán sự kiện cho nút "Xem tất cả"
    document.getElementById('featuredViewAllBtn').addEventListener('click', handleViewAllClick);

    // Load sản phẩm danh mục đầu tiên
    loadCategoryProducts(currentCategoryId);
}

// Chạy khi trang load xong
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initFeaturedCategories);
} else {
    initFeaturedCategories();
}

