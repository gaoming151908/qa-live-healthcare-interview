# QA Live Healthcare

在线医疗问诊平台（Vue 3 + Spring Boot 3 + MySQL 8）。本仓库完成了面试任务中的三个需求：首页中英文切换、医生数据迁移至 MySQL 并提供 API、问诊用户用户名密码登录。

> 原始需求见 [`项目要求.md`](./项目要求.md)。

---

## 功能概览

| 需求 | 实现 |
| --- | --- |
| 首页中英文切换 | `vue-i18n`，语言资源位于 `web/qa-web/src/locales`，右上角下拉菜单，选择持久化到 localStorage |
| 医生数据 MySQL 化 | `docker-compose.yml` 启动 MySQL 8 + phpMyAdmin，`doctor` 表存储医生，`GET /api/doctors` 供前端列表使用 |
| 问诊用户登录 | 注册 / 用户名密码登录，BCrypt 密码哈希，JWT 会话（24h），`GET /api/patients/me` 校验会话 |
| 测试 | 仅用 curl 的 51 条断言，见 `tests/api-test.sh` 与 `docs/API_TEST.md` |
| 文档 | PRD 模版、特性 PRD、设计文档、测试报告、提示词记录，见 [`docs/`](./docs) |

---

## 技术栈

- **前端**：Vue 3.5、TypeScript、Vite 5、Ant Design Vue 4、vue-i18n 9
- **后端**：Spring Boot 3.5、Spring Data JPA、Bean Validation、JJWT 0.12、BCrypt
- **数据库**：MySQL 8（Docker），phpMyAdmin 管理界面
- **测试**：curl + Python（仅解析 JSON）、JUnit 5、H2（单测）

---

## 目录结构

```
.
├── docker-compose.yml            # MySQL + phpMyAdmin
├── docker/mysql/init/
│   ├── 01-schema.sql             # 建库、doctor/patient 表、qa_user 授权
│   └── 02-seed.sql               # 医生与患者种子数据
├── server/qa-service-user/       # Spring Boot 后端
│   └── src/main/java/com/leansofx/qaserviceuser/
│       ├── controller/           # DoctorController、PatientAuthController
│       ├── service/              # DoctorService、PatientService、JwtService
│       ├── entity/ repository/   # JPA
│       ├── dto/ common/ config/  # 契约、异常、BCrypt、CORS
│       └── ...
├── web/qa-web/                   # Vue 前端
│   └── src/
│       ├── locales/              # zh-CN.ts、en-US.ts、index.ts
│       ├── api/                  # http.ts、doctor.ts、patient.ts
│       ├── store/                # 全局状态与会话持久化
│       └── views/                # Home、Doctors、DoctorLogin、Consultation...
├── tests/api-test.sh             # curl 接口回归套件
└── docs/                         # PRD、设计、测试、提示词
```

---

## 快速开始

### 0. 环境要求

- Docker Desktop（含 Docker Compose）
- JDK 17+（`java -version`）
- Node.js 18+ / npm
- curl、Python 3（仅自动化测试使用）

### 1. 启动数据库

```bash
docker compose up -d
docker compose ps          # 等待 mysql 变为 healthy
```

- MySQL：`localhost:3306`，库 `doctor_db`
  - 应用账号：`qa_user / Qa@123456`
  - root：`root / root`
- phpMyAdmin：<http://localhost:8081>（登录 `root / root` 或 `qa_user / Qa@123456`）

首次启动会自动执行 `docker/mysql/init/` 下的建表与种子脚本。若使用已存在的数据卷导致脚本未执行，可手动执行：

```bash
docker exec -i mysql_doctor mysql -uroot -proot --default-character-set=utf8mb4 < docker/mysql/init/01-schema.sql
docker exec -i mysql_doctor mysql -uroot -proot --default-character-set=utf8mb4 < docker/mysql/init/02-seed.sql
```

> 注意：`01-schema.sql` 会重建 `doctor` / `patient` 表，本地演示数据会重置。

### 2. 启动后端

```bash
cd server/qa-service-user
./mvnw spring-boot:run
# 或先打包：./mvnw -DskipTests package && java -jar target/qa-service-user-0.0.1-SNAPSHOT.jar
```

- 地址：<http://localhost:8080>
- 健康检查：<http://localhost:8080/actuator/health>
- 可选环境变量：`DB_HOST`、`DB_PORT`、`DB_NAME`、`DB_USER`、`DB_PASSWORD`、`JWT_SECRET`、`SERVER_PORT`

### 3. 启动前端

```bash
cd web/qa-web
npm install
npm run dev
```

- 地址：<http://localhost:5173>
- 后端地址可通过 `VITE_API_BASE_URL` 覆盖（默认 `http://localhost:8080`）：

```bash
VITE_API_BASE_URL=http://localhost:8080 npm run dev
```

### 4. 运行测试

```bash
# 后端单测（H2，不依赖 Docker）
cd server/qa-service-user && ./mvnw test

# 前端类型检查 + 构建
cd web/qa-web && npm run build

# curl 接口回归（需后端与 MySQL 已启动）
bash tests/api-test.sh
```

---

## 演示账号

| 角色 | 用户名 | 密码 | 说明 |
| --- | --- | --- | --- |
| 医生 | `dr-zhang-wei` | `123456` | 心内科，在线 |
| 医生 | `dr-li-na` | `123456` | 儿科，在线 |
| 医生 | `dr-liu-min` | `123456` | 妇产科，离线（按钮禁用） |
| 患者 | `zhaoming` | `Patient@123` | 赵明 |
| 患者 | `sunli` | `Patient@123` | 孙丽 |

患者也可在问诊页“注册”Tab 自行创建账号。

---

## API 一览

统一响应：`{ "code": 0, "message": "success", "data": ... }`

| 方法 | 路径 | 鉴权 | 说明 |
| --- | --- | --- | --- |
| GET | `/api/doctors` | 无 | 医生列表；`?activeOnly=true` 仅在线 |
| GET | `/api/doctors/{id}` | 无 | 医生详情 |
| POST | `/api/doctors/login` | 无 | 医生登录 |
| POST | `/api/patients/register` | 无 | 患者注册（自动登录） |
| POST | `/api/patients/login` | 无 | 患者登录，返回 JWT |
| GET | `/api/patients/me` | `Bearer <JWT>` | 当前患者信息 |

错误码：`40001` 参数错误、`40101` 未认证/凭证错误、`40401` 不存在、`40901` 冲突、`50001` 服务器错误。

详细契约：`docs/PRD-patient-login.md`、`docs/DESIGN.md`；测试示例：`docs/API_TEST.md`。

---

## 文档

| 文档 | 说明 |
| --- | --- |
| [`docs/PRD_TEMPLATE.md`](docs/PRD_TEMPLATE.md) | 规范 PRD 模版 |
| [`docs/PRD-patient-login.md`](docs/PRD-patient-login.md) | 问诊用户登录 PRD（含拆分步骤） |
| [`docs/DESIGN.md`](docs/DESIGN.md) | 架构、数据模型、接口、关键取舍 |
| [`docs/API_TEST.md`](docs/API_TEST.md) | curl 测试流程与用例定义 |
| [`docs/TEST_REPORT.md`](docs/TEST_REPORT.md) | 实际测试报告（51/51 通过） |
| [`docs/prompts.md`](docs/prompts.md) | 全流程 AI Coding 提示词记录 |

---

## 已知限制

- 本地默认 JWT 密钥仅供开发，生产必须通过 `JWT_SECRET` 注入；
- 未实现短信验证码、找回密码、登录限流、刷新令牌；
- 患者会话存于 localStorage，生产建议改为 HttpOnly Cookie；
- 问诊问题数据仍保存在前端 JSON/内存中，不在本次需求范围内。

---

## 分支与交付

- 特性分支：`feature-interview-task`
- 提交按需求拆分为 i18n、数据库与医生 API、患者登录、测试与文档；
- PR 目标分支：`main`。
