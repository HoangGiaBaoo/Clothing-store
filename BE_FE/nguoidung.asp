<!--#include file="../BE/db/connect.asp" -->
<%@ Language="VBScript" Codepage=65001 %>
<%
'==============================
' Cấu hình UTF-8 toàn cục
'==============================
Response.Buffer = True
Response.Charset = "UTF-8"
Session.CodePage = 65001

activePage = "nguoidung"

'==============================
' Hàm xuất UTF-8 cho các trường khác
'==============================
Sub WriteUTF8(text)
    If IsNull(text) Or text = "" Then 
        Response.Write ""
        Exit Sub
    End If
    Dim st
    Set st = Server.CreateObject("ADODB.Stream")
    st.Open
    st.Type = 2 
    st.Charset = "UTF-8"
    st.WriteText text
    st.Position = 0
    st.Type = 1 
    If st.Size > 3 Then
        st.Position = 3
        Response.BinaryWrite st.Read
    End If
    st.Close
    Set st = Nothing
End Sub

'--- Đọc Action và ID ---
Dim action, userId
action = Request.QueryString("action")
userId = Request.QueryString("id")

'--- XỬ LÝ LOGIC ---

' 1. Lưu Edit
If Request.Form("doSave") = "1" Then
    Session.CodePage = 65001
    Dim fName, lName, email, phone, addr, gender, role, status
    fName  = Replace(Request.Form("first_name"), "'", "''")
    lName  = Replace(Request.Form("last_name"), "'", "''")
    email  = Replace(Request.Form("email"), "'", "''")
    phone  = Replace(Request.Form("phone_number"), "'", "''")
    addr   = Replace(Request.Form("address"), "'", "''")
    gender = Replace(Request.Form("gender"), "'", "''")
    status = Request.Form("status")
    
    conn.Execute("UPDATE Users SET first_name=N'"& fName &"', last_name=N'"& lName &"', email='"& email &"', " & _
                 "phone_number='"& phone &"', address=N'"& addr &"', gender=N'"& gender &"', " & _
                 " status="& status &" WHERE id=" & userId)
    Response.Redirect "nguoidung.asp"

' 2. Xóa đơn lẻ
ElseIf action = "delete" And IsNumeric(userId) Then
    conn.Execute("DELETE FROM SupportMessages WHERE SenderID = " & userId & " OR ReceiverID =" & userId)
    conn.Execute("Update Users Set status = 0 WHERE id= " & userId)
    Response.Redirect "nguoidung.asp"

' 3. Xóa nhiều
ElseIf Request.Form("doDeleteMulti") = "1" Then
    Dim multiIds
    multiIds = Request.Form("selected_ids")
    If multiIds <> "" Then
        conn.Execute("DELETE FROM Users WHERE id IN (" & multiIds & ")")
        Response.Redirect "nguoidung.asp"
    End If
End If
%>

<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <title>Quản lý người dùng</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.1/font/bootstrap-icons.css" rel="stylesheet">
    <link rel="stylesheet" href="css/admin.css">
    <style>
        .form-label { font-weight: 500; color: #666; font-size: 0.9rem; }
        .card-edit { border-top: 4px solid #9b0025; }
        .btn-apply { background-color: #007bff; border: none; padding: 10px 30px; color: white; }
        .btn-apply:hover { background-color: #0056b3; }
        .header { border-bottom: 2px solid #9b0025; margin-bottom: 20px; padding-bottom: 10px; }
        .form-check-input:checked { background-color: #9b0025; border-color: #9b0025; }
        .table th { background-color: #f8f9fa; }
    </style>
</head>
<body>
    <!-- #include file="sidebar.asp" -->
    <div class="main">
    <% Select Case action
        Case "edit"
            Dim rsEdit
            Set rsEdit = conn.Execute("SELECT * FROM Users WHERE id = " & userId)
            If Not rsEdit.EOF Then
    %>
                <div class="header d-flex justify-content-between align-items-center">
                    <h4>Chi tiết người dùng</h4>
                    <a href="nguoidung.asp" class="btn btn-outline-secondary btn-sm"><i class="bi bi-arrow-left"></i> Quay lại</a>
                </div>
                <div class="card shadow-sm p-4 card-edit">
                    <form method="POST" action="?action=edit&id=<%=userId%>" accept-charset="UTF-8">
                        <input type="hidden" name="doSave" value="1">
                        <div class="row g-4">
                            <div class="col-md-6">
                                <label class="form-label">* Họ (Last Name):</label>
                                <input type="text" class="form-control" name="last_name" value="<%=rsEdit("last_name")%>" required>
                            </div>
                            <div class="col-md-6">
                                <label class="form-label">* Tên (First Name):</label>
                                <input type="text" class="form-control" name="first_name" value="<%=rsEdit("first_name")%>" required>
                            </div>
                            <div class="col-md-12">
                                <label class="form-label">* Email:</label>
                                <input type="email" class="form-control" name="email" value="<%=rsEdit("email")%>" required>
                            </div>
                            <div class="col-md-6">
                                <label class="form-label">Số điện thoại:</label>
                                <input type="text" class="form-control" name="phone_number" value="<%=rsEdit("phone_number")%>">
                            </div>
                            <div class="col-md-6">
                                <label class="form-label">Giới tính:</label>
                                <select class="form-select" name="gender">
                                    <option value="Nam" <%If rsEdit("gender")="Nam" Then Response.Write "selected"%>>Nam</option>
                                    <option value="Nữ" <%If rsEdit("gender")="Nữ" Then Response.Write "selected"%>>Nữ</option>
                                </select>
                            </div>
                            <div class="col-md-12">
                                <label class="form-label">Địa chỉ:</label>
                                <input type="text" class="form-control" name="address" value="<% =rsEdit("address") %>">
                            </div>
                            
                            <div class="col-md-6">
                                <label class="form-label">Trạng thái:</label>
                                <select class="form-select" name="status">
                                    <option value="1" <%If rsEdit("status")=1 Then Response.Write "selected"%>>Hoạt động</option>
                                    <option value="0" <%If rsEdit("status")=0 Then Response.Write "selected"%>>Khóa</option>
                                </select>
                            </div>
                        </div>
                        <div class="mt-5 text-end"><button type="submit" class="btn btn-apply">Lưu</button></div>
                    </form>
                </div>
    <% End If : rsEdit.Close : Set rsEdit = Nothing
        Case Else
            Dim rs
            Set rs = conn.Execute("SELECT id, last_name, first_name, email, address, phone_number, role, status FROM Users ORDER BY id DESC")
    %>
            <div class="header"><h4>Quản lý người dùng</h4></div>

            <div class="d-flex justify-content-between align-items-center mb-3">
                <div class="d-flex gap-2" style="max-width:620px;">
                    <input type="text" id="searchInput" class="form-control" placeholder="Tìm tên, email hoặc SĐT...">
                    <select id="roleFilter" class="form-select" style="width:200px;">
                        <option value="">Tất cả vai trò</option>
                        <option value="admin">Admin</option>
                        <option value="customer">Customer</option>
                    </select>
                </div>
                
                <div id="bulkDeleteArea" style="visibility: hidden;">
                    <button type="button" class="btn btn-danger btn-sm" onclick="confirmDeleteMulti()">
                        <i class="bi bi-trash"></i> Xóa đã chọn
                    </button>
                </div>
            </div>

            <div class="card shadow-sm">
                <form id="bulkDeleteForm" method="POST" action="nguoidung.asp">
                    <input type="hidden" name="doDeleteMulti" value="1">
                    <input type="hidden" name="selected_ids" id="selected_ids_input">
                    
                    <table class="table table-hover align-middle mb-0 text-center">
                        <thead>
                            <tr>
                                <th style="width: 40px;"><input type="checkbox" id="selectAll" class="form-check-input"></th>
                                <th class="text-start">Họ tên</th>
                                <th>Email</th>
                                <th>Địa chỉ</th>
                                <th>Số điện thoại</th>
                                <th>Vai trò</th>
                                <th>Trạng thái</th>
                                <th>Hành động</th>
                            </tr>
                        </thead>
                        <tbody id="userTable">
                            <% Do While Not rs.EOF %>
                            <tr>
                                <td><input type="checkbox" name="user_check" value="<%=rs("id")%>" class="form-check-input user-checkbox"></td>
                                <td class="text-start"><%=rs("last_name") & " " & rs("first_name")%></td>
                                <td><%=rs("email")%></td>
                                <td><% =rs("address") %></td>
                                <td><%=rs("phone_number")%></td>
                                <td><span class="badge bg-secondary"><%=rs("role")%></span></td>
                                <td>
                                    <% If rs("status") = 1 Then %>
                                        <span class="badge bg-success">Hoạt động</span>
                                    <% Else %>
                                        <span class="badge bg-danger">Khóa</span>
                                    <% End If %>
                                </td>
                                <td>
                                    <a href="?action=edit&id=<%=rs("id")%>" class="btn btn-sm btn-outline-dark"><i class="bi bi-pencil"></i></a>
                                    <a href="?action=delete&id=<%=rs("id")%>" class="btn btn-sm btn-outline-danger" onclick="return confirm('Xóa người dùng này?');"><i class="bi bi-trash"></i></a>
                                </td>
                            </tr>
                            <% rs.MoveNext : Loop %>
                        </tbody>
                    </table>
                </form>
            </div>
    <% rs.Close : Set rs = Nothing : End Select %>
    </div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js"></script>
<script>
const searchInput = document.getElementById("searchInput");
const roleFilter = document.getElementById("roleFilter");
const userTable = document.getElementById("userTable");

function filterUsers(){
    const txt = searchInput.value.toLowerCase().trim();
    const roleVal = roleFilter.value.toLowerCase().trim();
    Array.from(userTable.rows).forEach(r => {
        const fullName = r.cells[1].textContent.toLowerCase();
        const email = r.cells[2].textContent.toLowerCase();
        const phone = r.cells[4].textContent.toLowerCase();
        const role = r.cells[5].textContent.toLowerCase();
        const matchText = fullName.includes(txt) || email.includes(txt) || phone.includes(txt);
        const matchRole = (roleVal === "" || role.includes(roleVal));
        r.style.display = (matchText && matchRole) ? "" : "none";
        if (r.style.display === "none") r.cells[0].querySelector('input').checked = false;
    });
    toggleBulkDeleteButton();
}
if(searchInput) searchInput.oninput = filterUsers;
if(roleFilter) roleFilter.onchange = filterUsers;

const selectAll = document.getElementById("selectAll");
const userCheckboxes = document.querySelectorAll(".user-checkbox");
const bulkDeleteArea = document.getElementById("bulkDeleteArea");
const selectedIdsInput = document.getElementById("selected_ids_input");
const bulkDeleteForm = document.getElementById("bulkDeleteForm");

function toggleBulkDeleteButton() {
    const checkedBoxes = document.querySelectorAll(".user-checkbox:checked");
    bulkDeleteArea.style.visibility = checkedBoxes.length > 0 ? "visible" : "hidden";
}

if (selectAll) {
    selectAll.addEventListener("change", function() {
        userCheckboxes.forEach(cb => {
            if (cb.closest('tr').style.display !== 'none') {
                cb.checked = this.checked;
            }
        });
        toggleBulkDeleteButton();
    });
}

userCheckboxes.forEach(cb => {
    cb.addEventListener("change", toggleBulkDeleteButton);
});

function confirmDeleteMulti() {
    const checkedBoxes = document.querySelectorAll(".user-checkbox:checked");
    const ids = Array.from(checkedBoxes).map(cb => cb.value);
    if (confirm("Xóa " + ids.length + " người dùng đã chọn?")) {
        selectedIdsInput.value = ids.join(",");
        bulkDeleteForm.submit();
    }
}
</script>
</body>
</html>
<% conn.Close : Set conn = Nothing %>