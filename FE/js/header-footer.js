document.addEventListener("DOMContentLoaded", () => {
    const userIcon = document.querySelector(".icon-user");

    userIcon.addEventListener("click", (e) => {
        e.stopPropagation(); // tránh đóng ngay
        userIcon.classList.toggle("active");
    });

    // Click ra ngoài thì đóng
    document.addEventListener("click", () => {
        userIcon.classList.remove("active");
    });

    // Click bên trong dropdown không bị đóng
    const iconWrap = document.querySelector(".icon-wrap");
    iconWrap.addEventListener("click", (e) => {
        e.stopPropagation();
    });
});