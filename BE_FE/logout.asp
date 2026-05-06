<%@ LANGUAGE="VBScript" CODEPAGE="65001" %>
<%
' Hủy toàn bộ session
Session.Abandon

' Chuyển về trang đăng nhập hoặc trang chủ
Response.Redirect("login.asp")
%>