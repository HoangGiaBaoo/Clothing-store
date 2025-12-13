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

