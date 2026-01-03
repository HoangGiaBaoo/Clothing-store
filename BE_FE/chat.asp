<!-- #include file="/BE/db/connect.asp" -->
<%
    ' --- LOGIC SERVER-SIDE ---
    Dim action, currentUserID, adminID, targetID, guestID
    action = Request.QueryString("action")
    currentUserID = Session("UserID")
    adminID = 2 ' ID của Admin

    ' 1. XỬ LÝ GỬI TIN
    If action = "send" Then
        If currentUserID = "" Then
            Response.Write "LOGIN_REQUIRED": Response.End
        End If

        Dim msgText: msgText = Request.Form("message")
        ' Lấy targetID từ form (Admin gửi), nếu không có thì mặc định gửi tới Admin (Khách gửi)
        targetID = Request.Form("targetID")
        If targetID = "" Then targetID = adminID

        If msgText <> "" Then
            msgText = Replace(msgText, "'", "''")
            On Error Resume Next
            Dim sqlInsert
            sqlInsert = "INSERT INTO SupportMessages (SenderID, ReceiverID, MessageText, IsRead, CreatedDate) " & _
                        "VALUES (" & currentUserID & ", " & targetID & ", N'" & msgText & "', 0, GETDATE())"
            conn.Execute(sqlInsert)
            If Err.Number <> 0 Then
                Response.Write "LỖI SQL: " & Err.Description
            Else
                Response.Write "SENT"
            End If
            On Error GoTo 0
        End If
        Response.End
    End If

    ' 2. XỬ LÝ LẤY TIN
    If action = "get" Then
        If currentUserID = "" Then
            Response.Write "<div style='padding:10px;text-align:center;'>Vui lòng <a href='login.asp'>Đăng nhập</a></div>": Response.End
        End If

        ' Nếu Admin xem, họ truyền guestID. Nếu khách xem, lấy currentUserID
        guestID = Request.QueryString("guestID")
        Dim viewID: If guestID <> "" Then viewID = guestID Else viewID = currentUserID

        Dim rs, sqlGet
        ' Lấy hội thoại giữa Admin và viewID
        sqlGet = "SELECT * FROM SupportMessages WHERE (SenderID = " & viewID & " AND ReceiverID = " & adminID & ") OR (SenderID = " & adminID & " AND ReceiverID = " & viewID & ") ORDER BY CreatedDate ASC"
        Set rs = conn.Execute(sqlGet)
        
        Do While Not rs.EOF
            Dim cls: cls = "msg-admin"
            ' Nếu SenderID trùng với người đang đăng nhập hiện tại thì hiện bên phải
            If CStr(rs("SenderID")) = CStr(currentUserID) Then cls = "msg-customer"
            
            Response.Write "<div class='item " & cls & "'>"
            Response.Write "  <span>" & rs("MessageText") & "</span>"
            Response.Write "  <small style='display:block; font-size:9px; opacity:0.6; margin-top:4px;'>" & Hour(rs("CreatedDate")) & ":" & Minute(rs("CreatedDate")) & "</small>"
            Response.Write "</div>"
            rs.MoveNext
        Loop
        Response.End
    End If
%>  
<style>
    /* 1. Container chính - Giữ cố định lề */
    #chat-wrapper { 
        position: fixed; 
        bottom: 25px; 
        right: 25px; 
        z-index: 1001; 
        display: flex;
        flex-direction: column;
        align-items: flex-end;
        pointer-events: none;
    }

    /* 2. Nút bấm Chat - Hiệu ứng Glow */
    #chat-btn { 
        width: 60px; 
        height: 60px; 
        background: linear-gradient(135deg, #ff4757 0%, #ff6b81 100%); 
        border-radius: 50%; 
        display: flex; 
        align-items: center; 
        justify-content: center; 
        color: #fff; 
        cursor: pointer; 
        box-shadow: 0 8px 25px rgba(255, 71, 87, 0.4); 
        font-size: 26px; 
        transition: all 0.4s cubic-bezier(0.175, 0.885, 0.32, 1.275);
        pointer-events: auto;
    }
    
    #chat-btn:hover { 
        transform: scale(1.1) rotate(5deg);
        box-shadow: 0 12px 30px rgba(255, 71, 87, 0.5);
    }

    /* 3. Panel Chat - Bo góc lớn và Border mờ */
    #chat-panel { 
        width: 350px; 
        height: 400px; 
        background: #fff; 
        border-radius: 24px; 
        box-shadow: 0 15px 50px rgba(0,0,0,0.12); 
        margin-bottom: 20px;
        display: flex;
        flex-direction: column;
        overflow: hidden;
        pointer-events: auto;
        border: 1px solid rgba(0,0,0,0.05);

        /* Animation */
        opacity: 0;
        visibility: hidden;
        transform: translateY(40px) scale(0.8);
        transition: all 0.5s cubic-bezier(0.165, 0.84, 0.44, 1);
        transform-origin: bottom right;
    }

    #chat-panel.active {
        opacity: 1;
        visibility: visible;
        transform: translateY(0) scale(1);
    }

    /* 4. Header - Gradient sang trọng */
    #chat-header { 
        background: linear-gradient(100deg, #ff4757 0%, #ff6b81 100%); 
        color: #fff; 
        padding: 20px; 
        font-weight: 700; 
        text-align: center;
        text-transform: uppercase;
        font-size: 13px;
        letter-spacing: 1.5px;
        box-shadow: 0 2px 10px rgba(0,0,0,0.05);
    }

    /* 5. Vùng tin nhắn - Padding rộng hơn */
    #chat-logs { 
        flex: 1; 
        overflow-y: auto; 
        padding: 25px 20px; 
        background: #ffffff; 
        display: flex; 
        flex-direction: column; 
        gap: 15px;
        scroll-behavior: smooth;
    }

    #chat-logs::-webkit-scrollbar { width: 4px; }
    #chat-logs::-webkit-scrollbar-thumb { background: #eee; border-radius: 10px; }

    /* 6. Bong bóng chat - Đổ bóng nhẹ (Soft Shadow) */
    .item { 
        padding: 12px 16px; 
        max-width: 80%; 
        font-size: 14px; 
        line-height: 1.6; 
        position: relative;
        transition: all 0.3s ease;
    }

    .msg-customer { 
        background: #ff4757; 
        color: #fff; 
        align-self: flex-end; 
        border-radius: 20px 20px 4px 20px; 
        box-shadow: 0 4px 12px rgba(255, 71, 87, 0.15);
    }

    .msg-admin { 
        background: #f8f9fa; 
        color: #2d3436; 
        align-self: flex-start; 
        border-radius: 20px 20px 20px 4px;
        border: 1px solid #f1f2f6;
    }

    /* Thời gian dưới tin nhắn */
    .item small {
        display: block;
        font-size: 10px;
        margin-top: 5px;
        opacity: 0.7;
    }
    .msg-customer small { text-align: right; }

    /* 7. Ô nhập liệu - Thiết kế tràn viền */
    #chat-input-box { 
        padding: 15px 20px; 
        border-top: 1px solid rgba(0,0,0,0.03);
        display: flex;
        align-items: center;
        background: #fff;
    }

    #chat-input-box input { 
        flex: 1; 
        border: 1px solid #f1f2f6; 
        padding: 12px 18px; 
        border-radius: 30px; 
        outline: none; 
        background: #f8f9fa;
        font-size: 14px;
        transition: all 0.3s ease;
    }
    #chat-input-box input:focus { 
        background: #fff;
        border-color: #ff4757;
        box-shadow: 0 0 0 3px rgba(255, 71, 87, 0.1);
    }

    #chat-input-box button { 
        background: none; 
        border: none; 
        color: #ff4757; 
        cursor: pointer; 
        margin-left: 12px; 
        display: flex;
        align-items: center;
        justify-content: center;
        transition: all 0.3s ease;
        padding: 8px;
    }

    #chat-input-box button:hover { 
        transform: scale(1.2) translateX(3px); 
        color: #ff6b81;
    }

    #chat-input-box button svg {
        filter: drop-shadow(0 2px 4px rgba(255, 71, 87, 0.2));
    }
</style>

<div id="chat-wrapper">
    <div id="chat-panel">
        <div id="chat-header">TORANO SUPPORT</div>
        <div id="chat-logs"></div>
        <div id="chat-input-box">
            <input type="text" id="userMsg" placeholder="Hỏi về sản phẩm..." onkeypress="if(event.keyCode==13) sendChat()">
            <button onclick="sendChat()" id="btnSend">
    <svg viewBox="0 0 24 24" width="24" height="24" fill="currentColor">
        <path d="M3.4,20.2c0,0.3,0.2,0.6,0.5,0.7c0.1,0,0.2,0.1,0.3,0.1c0.2,0,0.4-0.1,0.5-0.2l18-9c0.4-0.2,0.5-0.6,0.4-0.9 c0-0.1-0.1-0.2-0.2-0.3l-18-9c-0.3-0.2-0.7-0.1-0.9,0.2c-0.1,0.1-0.2,0.3-0.2,0.5l1.5,8.2l11.9,0.1c0.3,0,0.5,0.2,0.5,0.5 s-0.2,0.5-0.5,0.5l-11.9,0.1L3.4,20.2z"></path>
    </svg>
</button>
        </div>
    </div>
    <div id="chat-btn" onclick="toggleChat()">💬</div>
</div>

<script>
    function toggleChat() {
        const panel = document.getElementById('chat-panel');
        panel.classList.toggle('active'); // Thêm hoặc xóa class active
        
        if(panel.classList.contains('active')) {
            loadChat();
            // Focus vào ô nhập sau khi panel hiện lên
            setTimeout(() => {
                document.getElementById('userMsg').focus();
            }, 300);
        }
    }

    function loadChat() {
        fetch('chat.asp?action=get&t=' + new Date().getTime())
        .then(res => res.text())
        .then(html => {
            const logs = document.getElementById('chat-logs');
            logs.innerHTML = html;
            // Cuộn xuống mượt mà
            logs.scrollTop = logs.scrollHeight;
        });
    }

    function sendChat() {
        const input = document.getElementById('userMsg');
        const msg = input.value.trim();
        if (!msg) return;

        const params = new URLSearchParams();
        params.append('message', msg);

        fetch('chat.asp?action=send', {
            method: 'POST',
            headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
            body: params
        })
        .then(res => res.text())
        .then(data => {
            if (data.trim() === "SENT") {
                input.value = '';
                loadChat();
            } else if (data.trim() === "LOGIN_REQUIRED") {
                alert("Vui lòng đăng nhập để gửi tin nhắn!");
            }
        });
    }
    
    // Tự động cập nhật nếu panel đang mở
    setInterval(() => {
        if(document.getElementById('chat-panel').classList.contains('active')) loadChat();
    }, 4000);
</script>