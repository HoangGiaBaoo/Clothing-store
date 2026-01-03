<!--#include file="../BE/db/connect.asp"-->
<%@ Language="VBScript" Codepage=65001 %>
<%
Response.Buffer = True
Response.Charset = "UTF-8"
Session.CodePage = 65001

Dim adminID: adminID = 2
activePage = "chat" 
%>

<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <title>Tin nhắn hỗ trợ - Torano Admin</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.1/font/bootstrap-icons.css" rel="stylesheet">
    <link rel="stylesheet" href="css/admin.css">
    <style>
        .chat-container { display: flex; height: calc(100vh - 120px); background: #fff; border-radius: 12px; box-shadow: 0 5px 20px rgba(0,0,0,0.05); overflow: hidden; }
        .user-sidebar { width: 320px; border-right: 1px solid #eee; display: flex; flex-direction: column; background: #f8f9fa; }
        .user-list { flex: 1; overflow-y: auto; }
        .user-item { padding: 15px; border-bottom: 1px solid #eee; cursor: pointer; transition: 0.2s; position: relative;}
        .user-item:hover { background: #fff1f2; }
        .user-item.active { background: #9b0025; color: #fff; border-left: 4px solid #333; }
        .chat-main { flex: 1; display: flex; flex-direction: column; background: #fff; }
        #chat-logs { flex: 1; overflow-y: auto; padding: 20px; display: flex; flex-direction: column; gap: 10px; background: #fdfdfd; }
        .item { padding: 10px 15px; border-radius: 18px; max-width: 75%; font-size: 13.5px; line-height: 1.4; position: relative; }
        .msg-customer { background: #9b0025; color: #fff; align-self: flex-end; border-bottom-right-radius: 2px; }
        .msg-admin { background: #e9ecef; color: #333; align-self: flex-start; border-bottom-left-radius: 2px; }
        .item small { display: block; font-size: 10px; opacity: 0.6; margin-top: 4px; }
        .chat-input-box { padding: 15px 20px; border-top: 1px solid #eee; display: flex; align-items: center; }
        .chat-input-box input { flex: 1; border: 1px solid #eee; padding: 10px 20px; border-radius: 25px; outline: none; background: #f8f9fa; }
        .chat-input-box button { background: none; border: none; color: #9b0025; margin-left: 10px; font-size: 1.5rem; }
    </style>
</head>
<body>
    <!--#include file="sidebar.asp"-->
    <div class="main">
        <div class="header">
            <h4><i class="bi bi-chat-dots me-2"></i>Hỗ trợ trực tuyến</h4>
        </div>

        <div class="chat-container">
            <div class="user-sidebar">
                <div class="p-3 fw-bold border-bottom">Hội thoại khách hàng</div>
                <div class="user-list">
                    <%
                    Dim rs, sql
                    ' Lấy danh sách khách nhắn tin, đếm tin chưa đọc, sắp xếp tin chưa đọc lên đầu
                    sql = "SELECT U.id, U.first_name, U.last_name, MAX(M.CreatedDate) as LastMsg, " & _
                          "SUM(CASE WHEN M.ReceiverID = " & adminID & " AND M.IsRead = 0 THEN 1 ELSE 0 END) as UnreadCount " & _
                          "FROM Users U " & _
                          "INNER JOIN SupportMessages M ON (U.id = M.SenderID OR U.id = M.ReceiverID) " & _
                          "WHERE U.id <> " & adminID & " " & _
                          "GROUP BY U.id, U.first_name, U.last_name " & _
                          "ORDER BY UnreadCount DESC, LastMsg DESC"
                    
                    Set rs = conn.Execute(sql)
                    If rs.EOF Then
                        Response.Write "<div class='p-3 text-muted text-center'>Chưa có tin nhắn nào.</div>"
                    Else
                        Do While Not rs.EOF
                    %>
                    <div class="user-item d-flex justify-content-between align-items-center" onclick="loadChat(<%=rs("id")%>, '<%=rs("last_name") & " " & rs("first_name")%>', this)">
                        <div>
                            <strong><%=rs("last_name") & " " & rs("first_name")%></strong>
                            <div style="font-size: 11px; opacity: 0.7;">Cập nhật: <%=FormatDateTime(rs("LastMsg"), 4)%></div>
                        </div>
                        <% If rs("UnreadCount") > 0 Then %>
                            <span class="badge rounded-pill bg-danger"><%=rs("UnreadCount")%></span>
                        <% End If %>
                    </div>
                    <% 
                        rs.MoveNext 
                        Loop 
                    End If
                    rs.Close 
                    %>
                </div>
            </div>

            <div class="chat-main" id="chatWindow" style="display:none;">
                <div class="p-3 border-bottom fw-bold" id="chatTarget">...</div>
                <div id="chat-logs"></div>
                <div class="chat-input-box">
                    <input type="text" id="adminReply" placeholder="Nhập tin nhắn trả lời..." onkeypress="if(event.keyCode==13) sendReply()">
                    <button onclick="sendReply()"><i class="bi bi-send-fill"></i></button>
                </div>
            </div>
            
            <div class="chat-main justify-content-center align-items-center" id="emptyState">
                <div class="text-center text-muted">
                    <i class="bi bi-chat-left-dots fs-1"></i>
                    <p>Chọn một khách hàng để bắt đầu trả lời</p>
                </div>
            </div>
        </div>
    </div>

    <script>
        let currentGuestID = null;

        function loadChat(id, name, el) {
            currentGuestID = id;
            document.getElementById('emptyState').style.display = 'none';
            document.getElementById('chatWindow').style.display = 'flex';
            document.getElementById('chatTarget').innerText = "Đang trả lời: " + name;

            document.querySelectorAll('.user-item').forEach(i => i.classList.remove('active'));
            el.classList.add('active');

            // Xóa badge đỏ ngay lập tức trên UI
            const badge = el.querySelector('.badge');
            if(badge) badge.remove();

            // Gọi AJAX đánh dấu đã đọc
            fetch('../BE_FE/chat.asp?action=read&guestID=' + id);

            refreshLogs();
        }

        function refreshLogs() {
            if(!currentGuestID) return;
            fetch('../BE_FE/chat.asp?action=get&guestID=' + currentGuestID)
            .then(res => res.text())
            .then(html => {
                const logs = document.getElementById('chat-logs');
                logs.innerHTML = html;
                logs.scrollTop = logs.scrollHeight;
            });
        }

        function sendReply() {
            const inp = document.getElementById('adminReply');
            const msg = inp.value.trim();
            if(!msg || !currentGuestID) return;

            const params = new URLSearchParams();
            params.append('message', msg);
            params.append('targetID', currentGuestID); 

            fetch('../BE_FE/chat.asp?action=send', {
                method: 'POST',
                headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
                body: params
            }).then(() => {
                inp.value = '';
                refreshLogs();
            });
        }

        setInterval(() => { if(currentGuestID) refreshLogs(); }, 3000);
    </script>
</body>
</html>