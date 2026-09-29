# Phiếu Phản Ánh — K4 Level 3B, Ngày 12

> **Bài làm cá nhân.** Trả lời bằng lời của chính bạn, dựa trên những gì bạn
> quan sát được khi chạy code — không sao chép đáp án của người khác.
>
> Cách trả lời: thay dòng `> *Câu trả lời của bạn*` bằng câu trả lời.
> `grade.py` đếm số câu đã trả lời (15 điểm cho 10 câu).
>
> Họ và tên: ..........................  Mã học viên: ..........................

---

### Câu 1 — Fail fast (CP1)

Trong `Settings`, `agent_api_key` không có giá trị mặc định nên app chết ngay
khi khởi động nếu thiếu biến môi trường. Hãy mô tả một tình huống cụ thể mà
việc "chết sớm" này cứu bạn, so với việc để mặc định `"changeme"`.

> Nếu deploy sang một môi trường mới mà quên đặt `AGENT_API_KEY`, app sẽ dừng ngay lúc khởi động thay vì mở API với khóa mặc định `changeme`. Nhờ vậy mình phát hiện cấu hình thiếu trước khi public traffic vào service. Nếu app dùng `changeme`, người lạ có thể đoán khóa đó và gọi API mà mình tưởng đã được bảo vệ.

---

### Câu 2 — Log cho máy đọc (CP1)

Chạy service và gọi `/ask` vài lần. Dán một dòng log JSON bạn thu được, rồi
nêu **hai** việc bạn làm được với dòng log đó mà `print("đã trả lời xong")`
không làm được.

> Một dòng log JSON mình thu được khi gọi `/ask`:

```json
{"event": "ask_completed", "level": "info", "timestamp": "2026-09-29T07:15:23.431873+00:00", "user_id": "exercise-q9", "tokens_in": 2, "tokens_out": 36, "cost_usd": 2.19e-05}
```

Mình có thể lọc các request theo `user_id` để điều tra một người dùng, và cộng `cost_usd` hoặc token theo thời gian để tìm mức sử dụng cao hay tạo cảnh báo. `print("đã trả lời xong")` không có các trường dữ liệu đó để máy lọc và tính toán.

---

### Câu 3 — Kích thước image (CP2)

Build cả hai phiên bản và ghi lại số đo thật:

```bash
docker build -f <Dockerfile-1-stage> -t agent:single .
docker build -t agent:multi .
docker images | grep agent
```

| Bản | Dung lượng |
|-----|-----------|
| 1 stage (bản đầu) | 1.73 GB |
| Multi-stage | 274 MB |

> Giải thích: chênh khoảng 1.46 GB. Bản đầu dùng image `python:3.11` đầy đủ và `COPY . .`, nên giữ cả phần lớn môi trường Python, dependency kiểm thử và tài liệu trong context. Bản multi-stage dùng `python:3.11-slim`, chỉ chép dependency cần chạy cùng `app/` và `utils/` sang image cuối; stage builder không nằm trong image cuối.


---

### Câu 4 — Thứ tự lệnh trong Dockerfile (CP2)

Sửa một ký tự trong `app/main.py` rồi build lại. Với Dockerfile của bạn, những
layer nào được dùng lại từ cache, layer nào phải chạy lại? Nếu bạn đặt
`COPY . .` lên trước `RUN pip install` thì kết quả khác thế nào?

> Trong Dockerfile hiện tại, Docker có thể dùng lại các layer base, `WORKDIR`, `COPY requirements.txt` và `RUN pip install` nếu requirements không đổi. Khi file trong `app/` đổi, layer `COPY app ./app` và các layer sau nó phải chạy lại; các layer cài dependency phía trước vẫn lấy từ cache. Nếu `COPY . .` đứng trước `RUN pip install`, mọi thay đổi trong source làm layer copy đổi, nên bước cài dependency phía sau cũng chạy lại và build lâu hơn.

---

### Câu 5 — Vì sao không chạy bằng root (CP2)

Container mặc định chạy bằng root. Mô tả chuỗi sự kiện dẫn từ "một lỗ hổng
trong code Python của bạn" tới "kẻ tấn công có quyền cao trên máy host", và
lệnh `USER` cắt đứt chuỗi đó ở chỗ nào.

> Nếu một lỗ hổng cho phép chạy lệnh tùy ý, kẻ tấn công có thể điều khiển process của app. Khi process chạy bằng root, họ có quyền root bên trong container và có nhiều khả năng đọc, sửa file hoặc khai thác cấu hình/kernel để thoát container rồi tấn công host. `USER appuser` khiến process bị chiếm trước hết chỉ có quyền user thường trong container, giảm quyền có thể dùng ở bước đầu. Nó giảm rủi ro nhưng không tự ngăn mọi kiểu container escape.

---

### Câu 6 — Cửa sổ trượt (CP3)

Rate limit của bạn dùng sliding window 60 giây. Nếu thay bằng cách đếm theo
phút đồng hồ (reset lúc giây 00), một người dùng có thể gửi tối đa bao nhiêu
request trong 2 giây liên tiếp khi hạn mức là 10/phút? Giải thích cách đạt được
con số đó.

> Có thể gửi 20 request trong 2 giây: gửi 10 request ngay trước ranh giới phút, rồi thêm 10 request ngay sau khi đồng hồ chuyển sang phút mới. Bộ đếm reset ở giây 00 nên cả hai nhóm đều được tính vào hai phút khác nhau, dù tổng cộng có 20 request trong khoảng 2 giây.

---

### Câu 7 — Rate limit và cost guard (CP3)

Hai cơ chế này khác nhau ở điểm nào? Cho một tình huống mà rate limit cho qua
nhưng cost guard phải chặn, và một tình huống ngược lại.

> Rate limit giới hạn số request trong 60 giây; cost guard giới hạn tổng tiền ước tính đã dùng trong tháng UTC. Rate limit có thể cho request qua khi user còn dưới 10 request trong cửa sổ, nhưng cost guard chặn request nếu chi phí dự kiến vượt ngân sách còn lại. Ngược lại, request thứ 11 trong một phút bị rate limit chặn dù tổng chi phí tháng vẫn còn rất thấp và cost guard vẫn cho phép.

---

### Câu 8 — /health khác /ready (CP4)

Nếu gộp hai endpoint làm một và cho nó kiểm tra Redis, chuyện gì xảy ra với cụm
3 container khi Redis mất kết nối 30 giây? Trả lời theo đúng thứ tự sự kiện.

> Nếu endpoint gộp được dùng làm liveness check, khi Redis mất kết nối cả 3 container sẽ cùng trả 503; orchestrator đánh dấu cả ba không khỏe và khởi động lại chúng. Redis vẫn đang lỗi nên các container mới khởi động cũng tiếp tục trả 503, dẫn tới restart lặp lại và service mất khả năng nhận traffic trong thời gian Redis gián đoạn. Liveness nên chỉ kiểm tra process; Redis thuộc readiness. Docker Compose cũng cần cấu hình riêng để unhealthy tự gây restart.

---

### Câu 9 — Stateless (CP4)

Chạy `docker compose up --scale agent=3` rồi gọi `/ask` nhiều lần với cùng một
`X-User-Id`. Quan sát `history_length` trong response. Nếu lịch sử được lưu
trong một dict Python thay vì Redis, bạn sẽ thấy con số đó thay đổi thế nào?

> Với Redis, lịch sử dùng chung giữa các instance nên `history_length` tiếp tục tăng theo các lượt hội thoại, dù request tới container nào. Khi thử ba request liên tiếp với cùng user trên service local, mình thấy các giá trị `0, 2, 4` (mỗi lượt thêm một message user và một message assistant). Nếu mỗi process lưu một dict riêng, mỗi instance chỉ thấy lịch sử của những request từng tới nó; khi load balancer đổi instance, con số có thể lặp lại hoặc nhảy giữa các lịch sử cục bộ thay vì tăng đều. Lệnh scale trong Compose hiện tại còn bị xung đột vì mọi replica cùng publish cổng host `8000`: container thứ ba báo `Bind for 0.0.0.0:8000 failed: port is already allocated`.

---

### Câu 10 — Deploy thật (CP5)

Ghi lại **một** lỗi bạn gặp khi deploy lên cloud (build fail, health check
timeout, sai REDIS_URL, app không đọc `$PORT`...): thông báo lỗi là gì, bạn
tìm ra nguyên nhân bằng cách nào, và sửa ra sao?

>Trong lần deploy đầu, mình gọi `/health` khi Railway vẫn đang build và nhận `404 Application not found`. Mình kiểm tra `railway deployment list --service agent --json` và thấy trạng thái `BUILDING`, rồi xem build logs để xác nhận image đang được đẩy lên. Sau khi deployment chuyển sang `SUCCESS`, gọi lại `/health` trả 200 và `/ready` trả 200 với Redis sẵn sàng. Nguyên nhân là mình kiểm tra URL trước khi deployment hoạt động; cách khắc phục là chờ Railway báo deploy thành công rồi mới kiểm tra endpoint.
