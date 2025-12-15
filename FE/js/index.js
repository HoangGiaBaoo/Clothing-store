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



document.addEventListener("DOMContentLoaded", () => {
    const overlay = document.querySelector(".sidebar-search");
    const openBtn = document.querySelector(".nav-search");
    const closeBtn = document.querySelector(".btn-close-search");

    if (!overlay || !openBtn) return;

    openBtn.addEventListener("click", () => {
        overlay.classList.add("show");
        document.body.classList.add("search-open");

        const input = overlay.querySelector(".input-search");
        if (input) setTimeout(() => input.focus(), 200);
    });

    closeBtn.addEventListener("click", close);
    overlay.addEventListener("click", e => {
        if (e.target === overlay) close();
    });

    function close() {
        overlay.classList.remove("show");
        document.body.classList.remove("search-open");
    }
});
