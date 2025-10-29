<html>
	<head>
			<meta charset=utf-8>
	</head>
	<body>
				<h1 align=center>Đăng nhập vào hệ thống</h1> 
				<center><font color=red><%= session("login_error") %></font></center>
				<form method=POST action="login_action.asp">
				<table align=center width=350 cellspacing=5 cellpadding=5 border=0>
						<tr>
							<td>Tên đăng nhập:</td>
							<td><input type=text name=txtTenDangNhap></td>
						</tr>
						<tr>
							<td>Mật khẩu: </td>
							<td><input type=password name=txtMatKhau></td>
						</tr>
						<tr>
							<td align=right><input type=checkbox value=1 name=ckNhoMatKhau></td>
							<td>Nhớ mật khẩu</td>
						</tr> 
						<tr>
							<td align=right><input type=submit value="Đăng nhập"></td>
							<td><input type=reset value="Hủy bỏ"></td>
						</tr>
				</table>
				</form>
	</body>
</html>
	
