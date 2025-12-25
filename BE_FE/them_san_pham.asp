<!--#include file="/BE/db/connect.asp" -->
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <title>Thêm Sản Phẩm Mới</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <style>
        .section-title { 
            padding-left: 10px; 
            font-weight: bold; 
            color: #0a0a0a; 
        }
        .debug-info {
            background: #f8f9fa;
            border: 1px solid #dee2e6;
            padding: 10px;
            border-radius: 5px;
            font-family: monospace;
            font-size: 12px;
        }
    </style>
</head>
<body class="bg-light">
    <div class="container mt-4 mb-5">
        <h3 class="text-center fw-bold text-uppercase mb-4">🛒 Thêm Sản Phẩm Vào Kho</h3>
        
        <form action="xuly_them_san_pham.asp" method="POST" onsubmit="return validateForm()">
            
            <!-- PHẦN 1: THÔNG TIN SẢN PHẨM -->
            <div class="card p-4 mb-4 shadow-sm">
                <h5 class="section-title mb-3">1. Thông tin sản phẩm</h5>
                <div class="row g-3">
                    <div class="col-md-3">
                        <label class="form-label fw-bold">Mã SP (ProductCode): <span class="text-danger">*</span></label>
                        <input type="text" name="ProductCode" class="form-control" required placeholder="VD: SP001">
                    </div>
                    <div class="col-md-9">
                        <label class="form-label fw-bold">Tên sản phẩm: <span class="text-danger">*</span></label>
                        <input type="text" name="ProductName" class="form-control" required placeholder="VD: Áo Polo Nam Cao Cấp">
                    </div>

                    <div class="col-md-3">
                        <label class="form-label fw-bold">Giá Gốc (OriginalPrice):</label>
                        <input type="number" name="OriginalPrice" class="form-control" value="0" min="0">
                    </div>
                    <div class="col-md-3">
                        <label class="form-label fw-bold text-success">Giá Bán (SalePrice): <span class="text-danger">*</span></label>
                        <input type="number" name="SalePrice" class="form-control" required value="0" min="0">
                    </div>
                    <div class="col-md-3">
                        <label class="form-label">Chất liệu:</label>
                        <input type="text" name="Material" class="form-control" placeholder="VD: Cotton 100%">
                    </div>
                    <div class="col-md-3">
                        <label class="form-label">Xuất xứ:</label>
                        <select name="Origin" class="form-select">
                            <option value="Việt Nam">Việt Nam</option>
                        </select>
                    </div>

                    <div class="col-md-6">
                        <label class="form-label fw-bold">Danh mục:</label>
                        <select name="CategoryID" class="form-select">
                            <option value="">-- Chọn danh mục --</option>
                            <optgroup label="THỜI TRANG NAM (ÁO)">
                                <option value="4">Áo Khoác</option>
                                <option value="5">Áo - Quần Nỉ</option>
                                <option value="6">Áo Polo</option>
                                <option value="7">Áo Sơ Mi</option>
                                <option value="8">Áo Thun</option>
                                <option value="9">Áo Blazer</option>
                                <option value="10">Áo Len</option>
                            </optgroup>
                            <optgroup label="THỜI TRANG NAM (QUẦN)">
                                <option value="11">Quần Dài Kaki</option>
                                <option value="12">Quần Âu</option>
                                <option value="13">Quần Gió</option>
                                <option value="14">Quần Jeans</option>
                                <option value="15">Quần Short</option>
                            </optgroup>
                            <optgroup label="PHỤ KIỆN">
                                <option value="16">Thắt Lưng</option>
                            </optgroup>
                        </select>
                    </div>
                    <div class="col-md-6">
                        <label class="form-label">Thương hiệu:</label>
                        <select name="BrandID" class="form-select">
                            <option value="1">Torano</option>
                        </select>
                    </div>

                    <div class="col-12">
                        <label class="form-label">Mô tả ngắn:</label>
                        <textarea name="ShortDescription" class="form-control" rows="2" placeholder="Mô tả ngắn gọn về sản phẩm..."></textarea>
                    </div>
                    <div class="col-12">
                        <label class="form-label">Mô tả chi tiết:</label>
                        <textarea name="DetailDescription" class="form-control" rows="4" placeholder="Mô tả đầy đủ về sản phẩm, chất liệu, thiết kế..."></textarea>
                    </div>
                </div>
            </div>

            <!-- PHẦN 2: HÌNH ẢNH -->
            <div class="card p-4 mb-4 shadow-sm">
                <div class="d-flex justify-content-between align-items-center mb-3">
                    <h5 class="section-title m-0">2. Hình ảnh sản phẩm</h5>
                    <small class="text-muted">Chọn radio để đánh dấu ảnh chính</small>
                </div>
                <div id="image-container">
                    <!-- ẢNH 1 -->
                    <div class="input-group mb-2">
                        <span class="input-group-text">🖼️ Ảnh 1</span>
                        <input type="text" name="Image1" class="form-control" placeholder="https://example.com/image1.jpg">
                        <div class="input-group-text">
                            <input class="form-check-input mt-0" type="radio" name="MainImageSelect" value="1" checked> 
                            <span class="ms-2">Ảnh chính</span>
                        </div>
                    </div>
                    
                    <!-- ẢNH 2 -->
                    <div class="input-group mb-2">
                        <span class="input-group-text">🖼️ Ảnh 2</span>
                        <input type="text" name="Image2" class="form-control" placeholder="https://example.com/image2.jpg">
                        <div class="input-group-text">
                            <input class="form-check-input mt-0" type="radio" name="MainImageSelect" value="2"> 
                            <span class="ms-2">Ảnh chính</span>
                        </div>
                    </div>
                    
                    <!-- ẢNH 3 -->
                    <div class="input-group mb-2">
                        <span class="input-group-text">🖼️ Ảnh 3</span>
                        <input type="text" name="Image3" class="form-control" placeholder="https://example.com/image3.jpg">
                        <div class="input-group-text">
                            <input class="form-check-input mt-0" type="radio" name="MainImageSelect" value="3"> 
                            <span class="ms-2">Ảnh chính</span>
                        </div>
                    </div>
                    
                    <!-- ẢNH 4 -->
                    <div class="input-group mb-2">
                        <span class="input-group-text">🖼️ Ảnh 4</span>
                        <input type="text" name="Image4" class="form-control" placeholder="https://example.com/image4.jpg">
                        <div class="input-group-text">
                            <input class="form-check-input mt-0" type="radio" name="MainImageSelect" value="4"> 
                            <span class="ms-2">Ảnh chính</span>
                        </div>
                    </div>
                    
                    <!-- ẢNH 5 -->
                    <div class="input-group mb-2">
                        <span class="input-group-text">🖼️ Ảnh 5</span>
                        <input type="text" name="Image5" class="form-control" placeholder="https://example.com/image5.jpg">
                        <div class="input-group-text">
                            <input class="form-check-input mt-0" type="radio" name="MainImageSelect" value="5"> 
                            <span class="ms-2">Ảnh chính</span>
                        </div>
                    </div>
                </div>
                <small class="text-muted">💡 Ảnh 1 sẽ là ảnh chính mặc định. Nhập ít nhất 1 ảnh.</small>
            </div>

            <!-- PHẦN 3: BIẾN THỂ (MÀU/SIZE) -->
            <div class="card p-4 mb-4 shadow-sm">
                <div class="d-flex justify-content-between align-items-center mb-3">
                    <h5 class="section-title m-0">3. Phân loại (Màu/Size/SKU)</h5>
                    <button type="button" class="btn btn-success btn-sm fw-bold" onclick="showNextVariantRow()">
                        <strong>+</strong> Thêm biến thể
                    </button>
                </div>
                
                <div class="table-responsive">
                    <table class="table table-bordered text-center align-middle">
                        <thead class="table-light">
                            <tr>
                                <th style="width: 20%;">Mã SKU</th>
                                <th style="width: 20%;">Màu sắc <span class="text-danger">*</span></th>
                                <th style="width: 15%;">Size</th>
                                <th style="width: 20%;">Giá thêm (+VND)</th>
                                <th style="width: 15%;">Tồn kho</th>
                                <th style="width: 10%;">Xóa</th>
                            </tr>
                        </thead>
                        <tbody id="variant-container">
                            <!-- TẠO SẴN 15 DÒNG - ẨN 14 DÒNG -->
                            <tr class="variant-row" data-index="1">
                                <td><input type="text" name="vSKU" class="form-control form-control-sm" placeholder="Auto"></td>
                                <td><input type="text" name="vColor" class="form-control form-control-sm" placeholder="VD: Đỏ"></td>
                                <td>
                                    <select name="vSize" class="form-select form-select-sm">
                                        <option value="S">S</option>
                                        <option value="M" selected>M</option>
                                        <option value="L">L</option>
                                        <option value="XL">XL</option>
                                        <option value="XXL">XXL</option>
                                    </select>
                                </td>
                                <td><input type="number" name="vAddPrice" class="form-control form-control-sm" value="0" min="0"></td>
                                <td><input type="number" name="vStock" class="form-control form-control-sm" value="0" min="0"></td>
                                <td><button type="button" class="btn btn-danger btn-sm" onclick="hideVariantRow(this)">✖</button></td>
                            </tr>
                            <tr class="variant-row" data-index="2" style="display:none;">
                                <td><input type="text" name="vSKU" class="form-control form-control-sm" placeholder="Auto"></td>
                                <td><input type="text" name="vColor" class="form-control form-control-sm" placeholder="VD: Xanh"></td>
                                <td>
                                    <select name="vSize" class="form-select form-select-sm">
                                        <option value="S">S</option>
                                        <option value="M">M</option>
                                        <option value="L" selected>L</option>
                                        <option value="XL">XL</option>
                                        <option value="XXL">XXL</option>
                                    </select>
                                </td>
                                <td><input type="number" name="vAddPrice" class="form-control form-control-sm" value="0" min="0"></td>
                                <td><input type="number" name="vStock" class="form-control form-control-sm" value="0" min="0"></td>
                                <td><button type="button" class="btn btn-danger btn-sm" onclick="hideVariantRow(this)">✖</button></td>
                            </tr>
                            <tr class="variant-row" data-index="3" style="display:none;">
                                <td><input type="text" name="vSKU" class="form-control form-control-sm" placeholder="Auto"></td>
                                <td><input type="text" name="vColor" class="form-control form-control-sm" placeholder="VD: Đen"></td>
                                <td>
                                    <select name="vSize" class="form-select form-select-sm">
                                        <option value="S">S</option>
                                        <option value="M">M</option>
                                        <option value="L">L</option>
                                        <option value="XL" selected>XL</option>
                                        <option value="XXL">XXL</option>
                                    </select>
                                </td>
                                <td><input type="number" name="vAddPrice" class="form-control form-control-sm" value="0" min="0"></td>
                                <td><input type="number" name="vStock" class="form-control form-control-sm" value="0" min="0"></td>
                                <td><button type="button" class="btn btn-danger btn-sm" onclick="hideVariantRow(this)">✖</button></td>
                            </tr>
                            <tr class="variant-row" data-index="4" style="display:none;">
                                <td><input type="text" name="vSKU" class="form-control form-control-sm"></td>
                                <td><input type="text" name="vColor" class="form-control form-control-sm"></td>
                                <td>
                                    <select name="vSize" class="form-select form-select-sm">
                                        <option value="S">S</option>
                                        <option value="M">M</option>
                                        <option value="L">L</option>
                                        <option value="XL">XL</option>
                                        <option value="XXL">XXL</option>
                                    </select>
                                </td>
                                <td><input type="number" name="vAddPrice" class="form-control form-control-sm" value="0"></td>
                                <td><input type="number" name="vStock" class="form-control form-control-sm" value="0"></td>
                                <td><button type="button" class="btn btn-danger btn-sm" onclick="hideVariantRow(this)">✖</button></td>
                            </tr>
                            <tr class="variant-row" data-index="5" style="display:none;">
                                <td><input type="text" name="vSKU" class="form-control form-control-sm"></td>
                                <td><input type="text" name="vColor" class="form-control form-control-sm"></td>
                                <td>
                                    <select name="vSize" class="form-select form-select-sm">
                                        <option value="S">S</option>
                                        <option value="M">M</option>
                                        <option value="L">L</option>
                                        <option value="XL">XL</option>
                                        <option value="XXL">XXL</option>
                                    </select>
                                </td>
                                <td><input type="number" name="vAddPrice" class="form-control form-control-sm" value="0"></td>
                                <td><input type="number" name="vStock" class="form-control form-control-sm" value="0"></td>
                                <td><button type="button" class="btn btn-danger btn-sm" onclick="hideVariantRow(this)">✖</button></td>
                            </tr>
                            <tr class="variant-row" data-index="6" style="display:none;">
                                <td><input type="text" name="vSKU" class="form-control form-control-sm"></td>
                                <td><input type="text" name="vColor" class="form-control form-control-sm"></td>
                                <td>
                                    <select name="vSize" class="form-select form-select-sm">
                                        <option value="S">S</option>
                                        <option value="M">M</option>
                                        <option value="L">L</option>
                                        <option value="XL">XL</option>
                                        <option value="XXL">XXL</option>
                                    </select>
                                </td>
                                <td><input type="number" name="vAddPrice" class="form-control form-control-sm" value="0"></td>
                                <td><input type="number" name="vStock" class="form-control form-control-sm" value="0"></td>
                                <td><button type="button" class="btn btn-danger btn-sm" onclick="hideVariantRow(this)">✖</button></td>
                            </tr>
                            <tr class="variant-row" data-index="7" style="display:none;">
                                <td><input type="text" name="vSKU" class="form-control form-control-sm"></td>
                                <td><input type="text" name="vColor" class="form-control form-control-sm"></td>
                                <td>
                                    <select name="vSize" class="form-select form-select-sm">
                                        <option value="S">S</option>
                                        <option value="M">M</option>
                                        <option value="L">L</option>
                                        <option value="XL">XL</option>
                                        <option value="XXL">XXL</option>
                                    </select>
                                </td>
                                <td><input type="number" name="vAddPrice" class="form-control form-control-sm" value="0"></td>
                                <td><input type="number" name="vStock" class="form-control form-control-sm" value="0"></td>
                                <td><button type="button" class="btn btn-danger btn-sm" onclick="hideVariantRow(this)">✖</button></td>
                            </tr>
                            <tr class="variant-row" data-index="8" style="display:none;">
                                <td><input type="text" name="vSKU" class="form-control form-control-sm"></td>
                                <td><input type="text" name="vColor" class="form-control form-control-sm"></td>
                                <td>
                                    <select name="vSize" class="form-select form-select-sm">
                                        <option value="S">S</option>
                                        <option value="M">M</option>
                                        <option value="L">L</option>
                                        <option value="XL">XL</option>
                                        <option value="XXL">XXL</option>
                                    </select>
                                </td>
                                <td><input type="number" name="vAddPrice" class="form-control form-control-sm" value="0"></td>
                                <td><input type="number" name="vStock" class="form-control form-control-sm" value="0"></td>
                                <td><button type="button" class="btn btn-danger btn-sm" onclick="hideVariantRow(this)">✖</button></td>
                            </tr>
                            <tr class="variant-row" data-index="9" style="display:none;">
                                <td><input type="text" name="vSKU" class="form-control form-control-sm"></td>
                                <td><input type="text" name="vColor" class="form-control form-control-sm"></td>
                                <td>
                                    <select name="vSize" class="form-select form-select-sm">
                                        <option value="S">S</option>
                                        <option value="M">M</option>
                                        <option value="L">L</option>
                                        <option value="XL">XL</option>
                                        <option value="XXL">XXL</option>
                                    </select>
                                </td>
                                <td><input type="number" name="vAddPrice" class="form-control form-control-sm" value="0"></td>
                                <td><input type="number" name="vStock" class="form-control form-control-sm" value="0"></td>
                                <td><button type="button" class="btn btn-danger btn-sm" onclick="hideVariantRow(this)">✖</button></td>
                            </tr>
                            <tr class="variant-row" data-index="10" style="display:none;">
                                <td><input type="text" name="vSKU" class="form-control form-control-sm"></td>
                                <td><input type="text" name="vColor" class="form-control form-control-sm"></td>
                                <td>
                                    <select name="vSize" class="form-select form-select-sm">
                                        <option value="S">S</option>
                                        <option value="M">M</option>
                                        <option value="L">L</option>
                                        <option value="XL">XL</option>
                                        <option value="XXL">XXL</option>
                                    </select>
                                </td>
                                <td><input type="number" name="vAddPrice" class="form-control form-control-sm" value="0"></td>
                                <td><input type="number" name="vStock" class="form-control form-control-sm" value="0"></td>
                                <td><button type="button" class="btn btn-danger btn-sm" onclick="hideVariantRow(this)">✖</button></td>
                            </tr>
                        </tbody>
                    </table>
                </div>
                <small class="text-muted">💡 Màu sắc bắt buộc nhập. SKU để trống sẽ tự động tạo.</small>
            </div>

            <!-- SUBMIT BUTTONS -->
            <div class="text-center pb-5">
                <button type="submit" class="btn btn-primary btn-lg px-5 fw-bold">
                    💾 THÊM SẢN PHẨM
                </button>
                <a href="qlsp.asp" class="btn btn-secondary btn-lg px-4">
                    ❌ Hủy
                </a>
            </div>
        </form>
    </div>

    <script>
        let currentVariantIndex = 1;

        // ============================================
        // HIỆN DÒNG BIẾN THỂ TIẾP THEO
        // ============================================
        function showNextVariantRow() {
            const rows = document.querySelectorAll('.variant-row');
            
            for (let i = 0; i < rows.length; i++) {
                if (rows[i].style.display === 'none') {
                    rows[i].style.display = '';
                    currentVariantIndex++;
                    
                    // Focus vào ô màu sắc
                    const colorInput = rows[i].querySelector('input[name="vColor"]');
                    if (colorInput) {
                        colorInput.focus();
                    }
                    return;
                }
            }
            
            alert('⚠️ Đã đạt giới hạn 10 biến thể!');
        }

        // ============================================
        // ẨN DÒNG BIẾN THỂ (KHÔNG XÓA)
        // ============================================
        function hideVariantRow(btn) {
            const row = btn.closest('tr');
            const index = row.getAttribute('data-index');
            
            // Không cho ẩn dòng đầu tiên
            if (index === '1') {
                alert('⚠️ Không thể xóa dòng đầu tiên!');
                return;
            }
            
            // Xóa dữ liệu và ẩn
            row.querySelectorAll('input, select').forEach(input => {
                if (input.type === 'number') {
                    input.value = '0';
                } else {
                    input.value = '';
                }
            });
            
            row.style.display = 'none';
            currentVariantIndex--;
        }

        // ============================================
        // VALIDATE
        // ============================================
        function validateForm() {
            // Kiểm tra ít nhất 1 ảnh
            const images = [
                document.querySelector('input[name="Image1"]'),
                document.querySelector('input[name="Image2"]'),
                document.querySelector('input[name="Image3"]'),
                document.querySelector('input[name="Image4"]'),
                document.querySelector('input[name="Image5"]')
            ];
            
            let hasImage = false;
            images.forEach(img => {
                if (img && img.value.trim() !== '') hasImage = true;
            });
            
            if (!hasImage) {
                alert('❌ Vui lòng thêm ít nhất 1 hình ảnh!');
                return false;
            }

            // Kiểm tra ít nhất 1 màu
            const colors = document.querySelectorAll('input[name="vColor"]');
            let hasColor = false;
            colors.forEach(color => {
                const row = color.closest('tr');
                if (row.style.display !== 'none' && color.value.trim() !== '') {
                    hasColor = true;
                }
            });
            
            if (!hasColor) {
                alert('❌ Vui lòng nhập ít nhất 1 màu sắc!');
                return false;
            }

            return true;
        }

        // ============================================
        // TỰ ĐỘNG TẠO SKU
        // ============================================
        document.addEventListener('input', function(e) {
            if (e.target.matches('input[name="ProductCode"]') || 
                e.target.matches('input[name="vColor"]') || 
                e.target.matches('select[name="vSize"]')) {
                
                const row = e.target.closest('tr');
                if (row && row.style.display !== 'none') {
                    const productCode = document.querySelector('input[name="ProductCode"]').value.toUpperCase();
                    const colorInput = row.querySelector('input[name="vColor"]');
                    const sizeSelect = row.querySelector('select[name="vSize"]');
                    const skuInput = row.querySelector('input[name="vSKU"]');
                    
                    if (productCode && colorInput.value && skuInput.value === '') {
                        const colorCode = colorInput.value.substring(0, 3).toUpperCase();
                        const size = sizeSelect.value;
                        skuInput.value = `${productCode}-${colorCode}-${size}`;
                    }
                }
            }
        });
    </script>
</body>
</html>