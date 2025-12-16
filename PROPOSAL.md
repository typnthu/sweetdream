# Đề Xuất Dự Án - Nền Tảng Thương Mại Điện Tử SweetDream

## Tóm Tắt Tổng Quan

**SweetDream** là nền tảng thương mại điện tử sẵn sàng cho môi trường production, được xây dựng với kiến trúc microservices trên AWS. Dự án thể hiện các phương pháp DevOps hiện đại, triển khai tự động và phân tích hành vi khách hàng toàn diện.

**Điểm Nổi Bật:**
- Pipeline CI/CD hoàn toàn tự động
- Kiến trúc microservices với 4 dịch vụ độc lập
- Phân tích hành vi khách hàng theo thời gian thực
- Triển khai không downtime
- Infrastructure as Code (Terraform)
- Hạ tầng AWS tối ưu chi phí (~$120-220/tháng)

---

## Mục Tiêu Dự Án

### Mục Tiêu Chính
1. **Xây dựng nền tảng thương mại điện tử có khả năng mở rộng** sử dụng kiến trúc microservices
2. **Triển khai pipeline DevOps tự động** cho continuous deployment
3. **Theo dõi hành vi khách hàng** với phân tích thời gian thực
4. **Thể hiện các phương pháp hay nhất về cloud-native** trên AWS

### Chỉ Số Thành Công
- Uptime 99.9% với auto-scaling
- Thời gian tải trang dưới 2 giây
- Thời gian triển khai dưới 10 phút
- Xuất dữ liệu phân tích tự động hàng ngày
- Triển khai không downtime

---

## Kiến Trúc Kỹ Thuật

### Thiết Kế Microservices

| Dịch Vụ | Công Nghệ | Mục Đích |
|---------|-----------|----------|
| **Frontend** | Next.js 14 | Ứng dụng web cho khách hàng |
| **Backend** | Express.js + Prisma | Danh mục sản phẩm & giỏ hàng |
| **User Service** | Express.js + Prisma | Xác thực & quản lý người dùng |
| **Order Service** | Express.js + Prisma | Xử lý đơn hàng |

### Hạ Tầng AWS

**Dịch Vụ Cốt Lõi:**
- **ECS Fargate**: Điều phối container serverless
- **RDS PostgreSQL**: Cơ sở dữ liệu được quản lý (Multi-AZ)
- **Application Load Balancer**: Phân phối traffic
- **CloudWatch**: Logging & monitoring
- **S3**: Lưu trữ dữ liệu phân tích
- **Lambda**: Xuất dữ liệu phân tích theo lịch
- **ECR**: Container registry
- **AWS Cloud Map**: Service discovery

**Tính Năng Chính:**
- Triển khai Multi-AZ cho high availability
- Auto-scaling dựa trên CPU/memory
- Chiến lược triển khai blue-green
- Backup và recovery tự động

---

## Tính Năng Cốt Lõi

### Tính Năng Khách Hàng
- Danh mục sản phẩm với tìm kiếm & lọc
- Quản lý giỏ hàng
- Đăng ký & xác thực người dùng
- Đặt hàng & theo dõi
- Lịch sử đơn hàng
- Thiết kế responsive cho mobile

### Tính Năng Quản Trị
- Dashboard quản lý đơn hàng
- Cập nhật trạng thái đơn hàng
- Thông tin phân tích khách hàng
- Quản lý vai trò người dùng
- Giám sát thời gian thực

### Tính Năng Kỹ Thuật
- **CI/CD Thông Minh**: Chỉ rebuild các service thay đổi
- **Xuất Dữ Liệu Phân Tích**: Tự động hàng ngày lên S3
- **Ngăn Chặn Trùng Lặp**: An toàn khi chạy nhiều lần
- **Service Discovery**: Giao tiếp động giữa các service
- **Health Checks**: Tự động phục hồi
- **Quản Lý Secrets**: AWS Secrets Manager

---

## Hệ Thống Phân Tích

### Sự Kiện Được Theo Dõi
- Xem sản phẩm
- Tìm kiếm sản phẩm
- Thêm vào giỏ hàng
- Bắt đầu thanh toán
- Hoàn thành đơn hàng

### Quy Trình Dữ Liệu
1. **Thu Thập**: CloudWatch Logs ghi lại tất cả sự kiện
2. **Xử Lý**: Lambda function lọc & chuyển đổi
3. **Lưu Trữ**: Xuất sang S3 theo cấu trúc phân vùng
4. **Phân Tích**: CloudWatch Insights queries

### Lịch Xuất Dữ Liệu
- **Tự Động**: Hàng ngày lúc 10 giờ sáng giờ Việt Nam
- **Thủ Công**: Theo yêu cầu qua Lambda invocation
- **Định Dạng**: JSON với ngăn chặn trùng lặp
- **Lưu Trữ**: `s3://bucket/user-actions/YYYY/MM/DD/`

---

## Chiến Lược Triển Khai

### Pipeline CI/CD (GitHub Actions)

**Quy Trình:**
1. **Phát Hiện Thay Đổi**: Phân tích git diff
2. **Build Song Song**: Chỉ build các service thay đổi
3. **Push ECR**: Upload Docker images
4. **Deploy ECS**: Rolling update với health checks
5. **Xác Minh**: Giám sát trạng thái triển khai

**Thời Gian Triển Khai:**
- Một service: 5-8 phút
- Tất cả services: 10-15 phút

**Trigger Triển Khai:**
- Branch `main` → Production
- Branch `dev` → Development
- Pull requests → Chỉ chạy tests

---

## Phân Tích Chi Phí

### Chi Phí AWS Hàng Tháng (Ước Tính)

| Dịch Vụ | Chi Phí |
|---------|---------|
| ECS Fargate (4 services) | $50-100 |
| RDS PostgreSQL (db.t3.micro) | $30-50 |
| Application Load Balancer | $20-30 |
| S3 Storage | $1-5 |
| CloudWatch Logs | $5-10 |
| Data Transfer | $10-20 |
| Lambda (Analytics) | < $1 |
| **Tổng Cộng** | **$120-220/tháng** |

**Tối Ưu Chi Phí:**
- Fargate Spot cho các task không quan trọng
- S3 Lifecycle policies (Glacier sau 90 ngày)
- CloudWatch log retention (7 ngày)
- Auto-scaling theo nhu cầu

---

## Triển Khai Bảo Mật

### Bảo Mật Mạng
- VPC với public/private subnets
- Security groups với least privilege
- NAT Gateway cho outbound traffic
- HTTPS/TLS qua ALB

### Bảo Mật Ứng Dụng
- Xác thực dựa trên JWT
- Mã hóa mật khẩu (bcrypt)
- Kiểm soát truy cập dựa trên vai trò (RBAC)
- Validation & sanitization đầu vào
- Ngăn chặn SQL injection (Prisma ORM)

### Bảo Mật AWS
- IAM roles với least privilege
- Secrets Manager cho credentials
- Mã hóa S3 buckets (AES-256)
- Mã hóa RDS storage
- CloudWatch audit logs

---

## Khả Năng Mở Rộng & Hiệu Suất

### Cấu Hình Auto-Scaling
- **Target CPU**: 70%
- **Target Memory**: 80%
- **Min Tasks**: 1 mỗi service
- **Max Tasks**: 4 mỗi service

### Mục Tiêu Hiệu Suất
- Tải trang: < 2 giây
- API response: < 500ms
- Database queries: < 100ms
- Tải hình ảnh: < 1 giây

### High Availability
- Triển khai Multi-AZ
- RDS automatic failover
- ECS task auto-recovery
- ALB health checks

---

## Quy Trình Phát Triển

### Phát Triển Local
```bash
docker-compose up -d
# Tất cả services có sẵn tại localhost
```

### Database Migrations
```bash
npx prisma migrate dev
npx prisma generate
npm run seed
```

### Testing
```bash
npm test          # Unit tests
npm run lint      # Chất lượng code
npm run type-check # TypeScript
```
---

## Công Cụ & Công Nghệ
- **Ngôn Ngữ**: TypeScript, JavaScript, Python
- **Frameworks**: Next.js, Express.js, Prisma
- **Cloud**: AWS (ECS, RDS, Lambda, S3)
- **DevOps**: Docker, Terraform, GitHub Actions
- **Monitoring**: CloudWatch, CloudWatch Insights

---
## Kết Luận

SweetDream thể hiện một nền tảng thương mại điện tử cloud-native sẵn sàng cho production với:
- Kiến trúc microservices hiện đại
- Pipeline CI/CD hoàn toàn tự động
- Hệ thống phân tích toàn diện
- Hạ tầng AWS tối ưu chi phí
- Phương pháp hay nhất về bảo mật
- Codebase có khả năng mở rộng & bảo trì

Nền tảng này phục vụ như một triển khai tham khảo để xây dựng các ứng dụng cloud-native có khả năng mở rộng trên AWS với các phương pháp DevOps hiện đại.