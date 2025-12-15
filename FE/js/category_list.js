const wrapper = document.getElementById('categoriesWrapper');
const prevBtn = document.getElementById('prevBtn-cate');
const nextBtn = document.getElementById('nextBtn-cate');

let currentIndex = 0;
const totalCategories = 8;
const categoriesToShow = 4; // Số danh mục hiển thị cùng lúc
const maxIndex = totalCategories - categoriesToShow;

function updateButtons() {
    // Disable prev button khi ở đầu
    if (currentIndex === 0) {
        prevBtn.disabled = true;
    } else {
        prevBtn.disabled = false;
    }

    // Disable next button khi ở cuối
    if (currentIndex >= maxIndex) {
        nextBtn.disabled = true;
    } else {
        nextBtn.disabled = false;
    }
}

function slideCategories() {
    const cardWidth = wrapper.querySelector('.category-card').offsetWidth;
    const gap = 20;
    const translateX = -(currentIndex * (cardWidth + gap));
    wrapper.style.transform = `translateX(${translateX}px)`;
    updateButtons();
}

nextBtn.addEventListener('click', () => {
    if (currentIndex < maxIndex) {
        currentIndex++;
        slideCategories();
    }
});

prevBtn.addEventListener('click', () => {
    if (currentIndex > 0) {
        currentIndex--;
        slideCategories();
    }
});

// Cập nhật khi resize window
window.addEventListener('resize', () => {
    slideCategories();
});

// Khởi tạo trạng thái buttons
updateButtons();