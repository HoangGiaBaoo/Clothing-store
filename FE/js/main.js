function loadProducts(categoryID = "") {
    let url = "../../BE/api/product_list.asp"; // SỬA LẠI ĐÚNG FILE

    if (categoryID !== "") {
        url += "?categoryID=" + encodeURIComponent(categoryID);
    }

    fetch(url)
        .then(res => res.json())
        .then(data => renderProducts(data))
        .catch(err => console.error("Error:", err));
}


function renderProducts(data) {
    let box = document.getElementById("product-list");
    box.innerHTML = "";

    data.forEach(p => {
        let item = `
            <div class="product-item">
                <img src="images/${p.ImageURL}" >
                <h3>${p.ProductName}</h3>
                <p>${p.Description}</p>
                <strong>${Number(p.Price).toLocaleString()}đ</strong>
                <button class="buy-btn">Mua ngay</button>
            </div>
        `;
        box.innerHTML += item;
    });
}

// load mặc định
loadProducts();

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
