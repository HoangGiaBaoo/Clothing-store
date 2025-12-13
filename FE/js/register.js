const form = document.getElementById("registerForm");
if (form) {
    form.addEventListener("submit", function (e) {
    e.preventDefault();

    const formData = new URLSearchParams(new FormData(form)).toString();

    fetch("/BE/api/account_register.asp", {
        method: "POST",
        headers: {
            "Content-Type": "application/x-www-form-urlencoded"
        },
        body: formData
    })
    .then(res => res.json())
    .then(data => {
        if (data.status === "success") {
            alert("Đăng ký thành công!");
            window.location.href = "login.html";
        } else {
            alert("Lỗi: " + data.message);
        }
    })
    .catch(err => console.error(err));
});
}
