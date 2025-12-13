let categories = [];
let currentIndex = 0; 
const showCount = 4;

function loadCategories() {
    fetch("../../BE/api/category_list.asp")
        .then(res => res.json())
        .then(data => {
            categories = data;
            renderCategorySlider();
            updateButtons();
        })
        .catch(err => console.error("Category Error:", err));
}

function renderCategorySlider() {
    const slider = document.getElementById("category-slider");
    slider.innerHTML = "";

    categories.forEach(c => {
        slider.innerHTML += `
            <div class="category-card">
                <a href="" class="cate-link"><img src="/assets/img/${c.image_url}">
                <div class="cate-info">
                    <span>${c.name}</span>
                    <span>→</span>
                </div></a>
            </div>
        `;
    });

    slider.style.width = `${categories.length * 25}%`;
}

function updateButtons() {
    document.getElementById("prevCate").disabled = (currentIndex === 0);
    document.getElementById("nextCate").disabled = (currentIndex >= categories.length - showCount);
}

document.getElementById("nextCate").addEventListener("click", () => {
    if (currentIndex < categories.length - showCount) {
        currentIndex++;
        moveCategorySlider();
    }
});

document.getElementById("prevCate").addEventListener("click", () => {
    if (currentIndex > 0) {
        currentIndex--;
        moveCategorySlider();
    }
});

function moveCategorySlider() {
    const slider = document.getElementById("category-slider");
    const item = slider.querySelector(".category-card");

    if (item) {
        const itemStyle = getComputedStyle(item);
        const itemWidth = item.offsetWidth 
                        + parseFloat(itemStyle.marginRight); // lấy đúng gap thực tế

        slider.style.transform = `translateX(-${currentIndex * itemWidth}px)`;
    }

    updateButtons();
}

// Load lần đầu
loadCategories();
