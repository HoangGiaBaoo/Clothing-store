// ===== USER ICON DROPDOWN =====
(function initUserIcon() {
    const userIcon = document.querySelector(".icon-user");
    const iconWrap = document.querySelector(".icon-wrap");

    if (!userIcon) {
        return setTimeout(initUserIcon, 50);
    }

    userIcon.addEventListener("click", (e) => {
        e.stopPropagation();
        userIcon.classList.toggle("active");
    });

    document.addEventListener("click", () => {
        userIcon.classList.remove("active");
    });

    if (iconWrap) {
        iconWrap.addEventListener("click", (e) => {
            e.stopPropagation();
        });
    }
})();

// ===== SEARCH OVERLAY =====
(function initSearchOverlay() {
    const overlay = document.querySelector(".sidebar-search");
    const openBtn = document.querySelector(".nav-search");
    const closeBtn = document.querySelector(".btn-close-search");

    if (!overlay || !openBtn) {
        return setTimeout(initSearchOverlay, 50);
    }

    openBtn.addEventListener("click", () => {
        overlay.classList.add("show");
        document.body.classList.add("search-open");

        const input = overlay.querySelector(".input-search");
        if (input) setTimeout(() => input.focus(), 200);
    });

    closeBtn?.addEventListener("click", closeOverlay);
    overlay.addEventListener("click", e => e.target === overlay && closeOverlay());

    document.addEventListener("keydown", (e) => {
        if (e.key === "Escape") closeOverlay();
    });

    function closeOverlay() {
        overlay.classList.remove("show");
        document.body.classList.remove("search-open");
    }
})();

// ===== SEARCH FUNCTIONALITY =====
(function initSearchFunctionality() {
    const searchInput = document.getElementById("inputSearchAuto");
    const searchForm = document.getElementById("searchForm");
    const resultsContainer = document.getElementById("searchResultsContent");
    const viewMoreContainer = document.getElementById("searchViewMore");
    const ajaxResults = document.getElementById("ajaxSearchResults");

    if (!searchInput || !searchForm) {
        return setTimeout(initSearchFunctionality, 50);
    }

    let searchTimeout;
    let currentKeyword = "";

    // Format giá VND
    function formatPrice(price) {
        return new Intl.NumberFormat("vi-VN").format(price) + "đ";
    }

    // Render kết quả tìm kiếm
    function renderResults(data) {
        if (!data.products || data.products.length === 0) {
            resultsContainer.innerHTML = '<div class="search-no-results">Không tìm thấy sản phẩm phù hợp</div>';
            viewMoreContainer.style.display = "none";
            ajaxResults.classList.add("show");
            return;
        }

        resultsContainer.innerHTML = data.products.map(product => `
            <a href="/BE_FE/product-detail.asp?id=${product.productId}" class="search-result-item">
                <img src="${product.imageUrl || '/images/no-image.jpg'}" 
                     alt="${product.productName}" 
                     class="search-result-img"
                     onerror="this.src='/images/no-image.jpg'">
                <div class="search-result-info">
                    <div class="search-result-name">${product.productName}</div>
                    <div class="search-result-price">${formatPrice(product.price)}</div>
                </div>
            </a>
        `).join("");

        const remaining = data.total - data.products.length;
        if (remaining > 0) {
            document.getElementById("remainingCount").textContent = remaining;
            document.getElementById("viewMoreLink").href = `/search.asp?q=${encodeURIComponent(currentKeyword)}`;
            viewMoreContainer.style.display = "block";
        } else {
            viewMoreContainer.style.display = "none";
        }

        ajaxResults.classList.add("show");
    }

    // Tìm kiếm sản phẩm
    async function searchProducts(keyword) {
        if (!keyword || keyword.trim() === "") {
            ajaxResults.classList.remove("show");
            return;
        }

        currentKeyword = keyword.trim();
        resultsContainer.innerHTML = '<div class="search-loading">Đang tìm kiếm...</div>';
        ajaxResults.classList.add("show");

        try {
            const response = await fetch(`/BE/api/search-products.asp?q=${encodeURIComponent(currentKeyword)}`);
            if (!response.ok) throw new Error("Không thể tìm kiếm");

            const data = await response.json();
            renderResults(data);
        } catch (error) {
            console.error("Error searching:", error);
            resultsContainer.innerHTML = '<div class="search-no-results">Có lỗi xảy ra. Vui lòng thử lại.</div>';
        }
    }

    // Xử lý input với debounce
    searchInput.addEventListener("input", (e) => {
        clearTimeout(searchTimeout);
        searchTimeout = setTimeout(() => {
            searchProducts(e.target.value);
        }, 500);
    });

    // Xử lý submit form
    searchForm.addEventListener("submit", (e) => {
        const keyword = searchInput.value.trim();
        if (!keyword) {
            e.preventDefault();
            return false;
        }
    });
})();