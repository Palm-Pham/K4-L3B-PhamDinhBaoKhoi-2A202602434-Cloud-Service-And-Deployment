# Thông Tin Deploy — Checkpoint 5

> Điền file này sau khi deploy xong. `pytest tests/test_cp5.py` đọc file này
> để tìm địa chỉ service của bạn và gọi thử.
>
> **Chỉ ghi TÊN biến môi trường, tuyệt đối không dán giá trị API key vào đây.**
> Repo này công khai — dán khóa vào là mất khóa.

## Thông Tin Học Viên

| Mục | Nội dung |
|-----|----------|
| Họ và tên | PHAM DINH BAO KHOI |
| Mã học viên | 2A202602434 |
| Repo | https://github.com/Palm-Pham/K4-L3B-PhamDinhBaoKhoi-2A202602434-Cloud-Service-And-Deployment |

## Service

| Mục | Nội dung |
|-----|----------|
| Public URL | https://agent-production-2ea3.up.railway.app |
| Platform | Railway |
| Ngày deploy | 2026-09-29 |

## Biến Môi Trường Đã Set Trên Cloud

Ghi tên biến và **nguồn giá trị**, không ghi giá trị:

| Biến | Đã set | Ghi chú |
|------|--------|---------|
| `PORT` | ✅ | platform tự gán |
| `AGENT_API_KEY` | ✅ | đặt trong dashboard, không nằm trong repo |
| `REDIS_URL` | ✅ | Railway reference tới `${{Redis.REDIS_URL}}` |
| `RATE_LIMIT_PER_MINUTE` | ✅ | 10 |
| `MONTHLY_BUDGET_USD` | ✅ | 10.0 |
| `LOG_LEVEL` | ✅ | INFO |

## Lệnh Kiểm Tra

Các lệnh bên dưới dùng URL thật ở trên. `.env` trên máy đã có `DEPLOY_API_KEY`
để chạy test CP5; nếu chạy curl thủ công, hãy export biến này trong shell.

```bash
URL=https://agent-production-2ea3.up.railway.app

# 1. Liveness — mong đợi 200 {"status":"ok"}
curl -i "$URL/health"

# 2. Readiness — mong đợi 200 {"status":"ready"} (đã nối được Redis)
curl -i "$URL/ready"

# 3. Không có API key — mong đợi 401
curl -i -X POST "$URL/ask" \
  -H "Content-Type: application/json" \
  -d '{"question":"Hello"}'

# 4. Có API key — mong đợi 200 kèm câu trả lời
curl -i -X POST "$URL/ask" \
  -H "Content-Type: application/json" \
  -H "X-API-Key: $DEPLOY_API_KEY" \
  -H "X-User-Id: sv-test" \
  -d '{"question":"Deploy là gì?"}'

# 5. Rate limit — gọi 15 lần, những lần cuối phải trả 429
for i in $(seq 1 15); do
  curl -s -o /dev/null -w "%{http_code} " -X POST "$URL/ask" \
    -H "Content-Type: application/json" \
    -H "X-API-Key: $DEPLOY_API_KEY" \
    -H "X-User-Id: sv-test" \
    -d '{"question":"test"}'
done; echo
```

## Kết Quả Chạy Thật

Dán output của các lệnh trên vào đây:

```
GET /health → 200 {"status":"ok","service":"day12-agent","version":"1.0.0"}
GET /ready → 200 {"status":"ready","redis":true}
POST /ask không có X-API-Key → 401 {"detail":"invalid or missing API key"}
POST /ask có X-API-Key hợp lệ → 200, có answer, cost_usd, history_length, tokens, user_id
12 POST /ask cùng user trong 60 giây → 10 lần 200, 2 lần 429; Retry-After: 60
```

output:
'''
HTTP/2 200 
content-type: application/json
date: Tue, 29 Sep 2026 05:41:04 GMT
server: railway-hikari
x-railway-request-id: T0zn87I6SxC3tCgxnpoFkQ
content-length: 57
x-hikari-trace: hkg1.hn7d
x-railway-edge: hkg1

{"status":"ok","service":"day12-agent","version":"1.0.0"}HTTP/2 200 
content-type: application/json
date: Tue, 29 Sep 2026 05:41:05 GMT
server: railway-hikari
x-railway-request-id: znJoDE8qTSKhpNIlwUFZXw
content-length: 31
x-hikari-trace: hkg1.aebn
x-railway-edge: hkg1

{"status":"ready","redis":true}HTTP/2 401 
content-type: application/json
date: Tue, 29 Sep 2026 05:41:06 GMT
server: railway-hikari
x-railway-request-id: 2q7QIaNlQD-qGQUXLPU1MQ
content-length: 39
x-hikari-trace: hkg1.hn7d
x-railway-edge: hkg1

{"detail":"invalid or missing API key"}HTTP/2 401 
content-type: application/json
date: Tue, 29 Sep 2026 05:41:07 GMT
server: railway-hikari
x-railway-request-id: 0qkDL9xGQ7Sfgsp2nPRhug
content-length: 39
x-hikari-trace: hkg1.hn7d
x-railway-edge: hkg1

{"detail":"invalid or missing API key"}401 401 401 401 401 401 401 401 401 401 401 401 401 401 401 
'''


## Ảnh Chụp Màn Hình

Ảnh dashboard và `/health` có thể lưu trong `screenshots/` khi cần nộp bài.

---

## Phương Án Dự Phòng

Không sử dụng; service đang chạy trên Railway.
