<%
dim diem(9)
diem(0)=CDBL(Request("NNCN")) * 2
diem(1)=CDBL(Request("CNTKWNC")) * 3
diem(2)=CDBL(Request("DOAN")) * 1
diem(3)=CDBL(Request("CSDL")) * 3
diem(4)=CDBL(Request("CNJV")) * 2
diem(5)=CDBL(Request("TKGD")) * 3
diem(6)=CDBL(Request("VXL")) * 3
diem(7)=CDBL(Request("CNXH")) * 2
diem(8)=CDBL(Request("TTHCM")) * 2
diem(9)=CDBL(Request("LSD")) * 2
tong=0
for i=0 to 9
if diem(i)=0 then
    tong=tong
else tong=tong+diem(i)  
end if
next

if diem(8) =0 and diem(9) =0 and diem(7) =0 then
        sotin=17
else if diem(8) =0 and diem(9) =0 then
        sotin=19
    else
        sotin=23
    end if
end if

tong=tong/sotin
session("diemtb")=tong

%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>tinhdiemtb</title>
</head>
<body>
    <form>
        <table align="center">
            <tr>
                <th>Môn</th>
                <th>Điểm</th>
            </tr>
            <tr>
                <td>NNCN</td>
                <td><input type="text" name="NNCN" requiered /></td>
            </tr>
            <tr>
                <td>CNTKWNC</td>
                <td><input type="text" name="CNTKWNC" required /></td>
            </tr>
            <tr>
                <td>ĐỒ ÁN CNTKWNC</td>
                <td><input type="text" name="DOAN" required /></td>
            </tr>
            <tr>
                <td>CSDL NÂNG CAO</td>
                <td><input type="text" name="CSDL" required /></td>
            </tr>
            <tr>
                <td>CN JAVA</td>
                <td><input type="text" name="CNJV" required /></td>
            </tr>
            <tr>
                <td>TK GIAO DIỆN & TT NGƯỜI MÁY</td>
                <td><input type="text" name="TKGD" required /></td>
            </tr>
            <tr>
                <td>VXL</td>
                <td><input type="text" name="VXL" required /></td>
            </tr>
            <tr>
                <td>CNXH</td>
                <td><input type="text" name="CNXH" required /></td>
            </tr>
            <tr>
                <td>TT HỒ CHÍ MINH</td>
                <td><input type="text" name="TTHCM" required /></td>
            </tr>
            <tr>
                <td>LỊCH SỬ ĐẢNG</td>
                <td><input type="text" name="LSD" required /></td>
            </tr>
            <tr>
                <td colspan="1" align="right">
                    <button type="submit" style="margin-top:12px; padding: 12px 12px;"><a href="tinhdiem.asp" style="text-decoration: none; color:black;">Nhập lại</a></button>
                </td>
                <td colspan="2" align="right">
                    <input type="submit" value="Tính điểm TB" style="margin-top:12px; padding: 12px 12px" />
                </td>
            </tr>
        </table>
    </form>
    <div align="center" style="margin:12px 0px;"><h4 style="display: inline; color:red; text-decoration: underline;">* Chú ý: </h4><i>Môn nào không có điểm thì nhập 0.</i></div>
    <h4 align="center">Điểm trung bình kì này của bạn là: <%=session("diemtb")%></h4>
    <%if session("diemtb")<>"" then
    session("diemtb")=""
    end if %>
</body>
</html>