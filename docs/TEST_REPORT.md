# 测试报告：医生数据 API 与问诊用户登录

## 1. 基本信息

| 项目 | 内容 |
| --- | --- |
| 测试对象 | `qa-service-user`（医生 API、患者登录 API） |
| 被测分支 | `feature-interview-task` |
| 测试类型 | 接口功能测试、鉴权测试、参数校验、CORS 联调 |
| 测试工具 | curl 8.10.1；Python 3.12.10（仅解析 JSON） |
| 测试脚本 | `tests/api-test.sh` |
| 测试依据 | `docs/API_TEST.md`、`docs/PRD-patient-login.md` |
| 执行时间 | 2026-10-29 23:13:16 – 23:13:22（UTC+8） |
| 执行人 | AI 协作 + 人工复核 |

### 1.1 测试环境

| 组件 | 版本 / 配置 |
| --- | --- |
| 操作系统 | Windows 11 Home China 10.0.26200 |
| 服务地址 | `http://localhost:8080` |
| 后端 | Spring Boot 3.5.7，Maven 3.9.11，Java 运行环境 25.0.2（源码/编译目标 Java 17） |
| 数据库 | MySQL 8.0.46（Docker，容器 `mysql_doctor`，库 `doctor_db`） |
| 数据库管理 | phpMyAdmin（Docker，`http://localhost:8081`） |
| 前端 | Vue 3.5.10 + TypeScript 5.5 + Vite 5.4.8，Node v22.23.2，npm 10.9.8 |
| 浏览器（UI E2E） | Microsoft Edge 156.0.4314.50（headless + Chrome DevTools Protocol） |
| 后端单测 | `mvn test`：2 个测试类（Spring 上下文 + JWT 单测），全部通过 |
| 前端构建 | `npm run build`（`vue-tsc -b && vite build`）通过 |

### 1.2 测试数据

- 医生：`doc001`–`doc005`，其中 4 位在线、1 位离线；
- 患者：`zhaoming / Patient@123`、`sunli / Patient@123`；
- 动态注册账号：`autotest_<timestamp>_<random>`，测试后已清理。

---

## 2. 测试范围

### 2.1 范围内

- 医生列表、仅在线医生、医生详情、医生不存在；
- 医生登录（正确凭证、错误密码、缺少参数）；
- 患者注册（成功、重复用户名、密码过短、UTF-8 中文请求体）；
- 患者登录（成功、错误密码、不存在的用户）；
- 患者会话 `GET /api/patients/me`（有效 token、无 token、非法 token）；
- 浏览器跨域预检（CORS）；
- 敏感字段检查：响应不得包含 `password`。

### 2.2 范围外

- 前端页面视觉与交互（另行手工验收，`npm run build` 已通过）；
- 性能压测、并发、限流；
- 生产 HTTPS、WAF、短信/OAuth 等未实现能力。

---

## 3. 执行结果汇总

| 指标 | 数值 |
| --- | --- |
| 接口断言数 | 51 |
| 接口通过 | 51 |
| 接口失败 | 0 |
| 接口通过率 | 100% |
| UI 端到端检查 | 6 |
| UI 通过 | 6 |
| 阻塞缺陷 | 0 |
| 脚本退出码 | 0 |

**结论：本轮接口测试与 UI 端到端检查全部通过，满足需求 1 / 2 / 3 的验收条件。**

### 3.1 分模块统计

| 模块 | 断言数 | 通过 | 失败 |
| --- | --- | --- | --- |
| 医生列表 API | 15 | 15 | 0 |
| 医生登录 API | 7 | 7 | 0 |
| 患者注册 API | 12 | 12 | 0 |
| 患者登录 API | 7 | 7 | 0 |
| 患者会话 API | 8 | 8 | 0 |
| CORS | 2 | 2 | 0 |
| **合计** | **51** | **51** | **0** |

---

## 4. 用例明细

### 4.1 医生列表 API（需求 2）

| 用例 | 请求 | 预期 | 实际 | 结果 |
| --- | --- | --- | --- | --- |
| D-01a | `GET /api/doctors` | HTTP 200 | 200 | ✅ |
| D-01b | 同上 | code 0 | 0 | ✅ |
| D-01c | 同上 | 5 位医生 | 5 | ✅ |
| D-01d | 同上 | 首位 id=doc001 | doc001 | ✅ |
| D-01e | 同上 | 首位姓名=张伟医生 | 张伟医生 | ✅ |
| D-01f | 同上 | isActive=true | true | ✅ |
| D-01g | 同上 | 擅长领域 3 个 | 3 | ✅ |
| D-01h | 同上 | 不返回 password | 空 | ✅ |
| D-02a | `GET /api/doctors?activeOnly=true` | HTTP 200 | 200 | ✅ |
| D-02b | 同上 | 4 位在线医生 | 4 | ✅ |
| D-03a | `GET /api/doctors/doc002` | HTTP 200 | 200 | ✅ |
| D-03b | 同上 | code 0 | 0 | ✅ |
| D-03c | 同上 | id=doc002 | doc002 | ✅ |
| D-04a | `GET /api/doctors/doc999` | HTTP 404 | 404 | ✅ |
| D-04b | 同上 | code 40401 | 40401 | ✅ |

### 4.2 医生登录 API（需求 2）

| 用例 | 请求 | 预期 | 实际 | 结果 |
| --- | --- | --- | --- | --- |
| D-05a | 正确账号密码 | HTTP 200 | 200 | ✅ |
| D-05b | 同上 | code 0 | 0 | ✅ |
| D-05c | 同上 | 返回 doc001 | doc001 | ✅ |
| D-06a | 错误密码 | HTTP 401 | 401 | ✅ |
| D-06b | 错误密码 | code 40101 | 40101 | ✅ |
| D-07a | 缺少 password | HTTP 400 | 400 | ✅ |
| D-07b | 缺少 password | code 40001 | 40001 | ✅ |

### 4.3 患者注册 API（需求 3）

| 用例 | 请求 | 预期 | 实际 | 结果 |
| --- | --- | --- | --- | --- |
| P-01a | 合法注册 | HTTP 201 | 201 | ✅ |
| P-01b | 同上 | code 0 | 0 | ✅ |
| P-01c | 同上 | 返回 JWT | 有 | ✅ |
| P-01d | 同上 | 回显用户名 | 一致 | ✅ |
| P-01e | 同上 | 不返回密码哈希 | 空 | ✅ |
| P-02a | 重复用户名 | HTTP 409 | 409 | ✅ |
| P-02b | 重复用户名 | code 40901 | 40901 | ✅ |
| P-03a | 密码 123 | HTTP 400 | 400 | ✅ |
| P-03b | 密码 123 | code 40001 | 40001 | ✅ |
| P-10a | UTF-8 中文请求体 | HTTP 201 | 201 | ✅ |
| P-10b | 同上 | 姓名=测试用户 | 测试用户 | ✅ |
| P-10c | 同上 | 性别=男 | 男 | ✅ |

### 4.4 患者登录 API（需求 3）

| 用例 | 请求 | 预期 | 实际 | 结果 |
| --- | --- | --- | --- | --- |
| P-04a | zhaoming 正确密码 | HTTP 200 | 200 | ✅ |
| P-04b | 同上 | code 0 | 0 | ✅ |
| P-04c | 同上 | username=zhaoming | zhaoming | ✅ |
| P-04d | 同上 | 返回 JWT | 有 | ✅ |
| P-05a | 错误密码 | HTTP 401 | 401 | ✅ |
| P-05b | 错误密码 | code 40101 | 40101 | ✅ |
| P-06 | 不存在的用户 | HTTP 401 | 401 | ✅ |

### 4.5 患者会话 API（需求 3）

| 用例 | 请求 | 预期 | 实际 | 结果 |
| --- | --- | --- | --- | --- |
| P-07a | 有效 token `/me` | HTTP 200 | 200 | ✅ |
| P-07b | 同上 | code 0 | 0 | ✅ |
| P-07c | 同上 | username=zhaoming | zhaoming | ✅ |
| P-07d | 同上 | name=赵明 | 赵明 | ✅ |
| P-08a | 无 Authorization | HTTP 401 | 401 | ✅ |
| P-08b | 无 Authorization | code 40101 | 40101 | ✅ |
| P-09a | 非法 token | HTTP 401 | 401 | ✅ |
| P-09b | 非法 token | code 40101 | 40101 | ✅ |

### 4.6 CORS（前后端联调）

| 用例 | 请求 | 预期 | 实际 | 结果 |
| --- | --- | --- | --- | --- |
| C-01a | `OPTIONS /api/doctors`（Origin: 5173） | HTTP 200 | 200 | ✅ |
| C-01b | 同上 | 存在 Access-Control-Allow-Origin | 存在 | ✅ |

### 4.7 前端 UI 端到端（无头 Edge + CDP）

| 用例 | 操作 | 预期 | 实际 | 结果 |
| --- | --- | --- | --- | --- |
| UI-01 | 打开 `/`（浏览器语言 zh-CN） | 显示“专业在线医疗问诊平台”“开放诊室”，医生卡片来自 API | 一致，张伟医生等 4 位在线医生渲染 | ✅ |
| UI-02 | 以 `--lang=en-US` 打开 `/` | 首页显示英文 Hero、Open Consultation Rooms、Enter Room | 一致 | ✅ |
| UI-03 | 打开 `/doctors` | 5 位医生，离线医生按钮为“暂未开放” | 一致 | ✅ |
| UI-04 | 在 `/consultation` 输入 `zhaoming / Patient@123` 并登录 | 进入“赵明 的问诊”门户，localStorage 写入 JWT | 一致，JWT 长度 155 | ✅ |
| UI-05 | 刷新页面后点击“切换用户” | 刷新后仍为已登录；退出后回到登录表单且 token 清空 | 一致 | ✅ |
| UI-06 | 首页右上角语言下拉：中文 → English → 中文 | 页面文案即时切换，localStorage 记录 `qa-locale` | 一致，英文/中文内容与存储均正确 | ✅ |

---

## 5. 失败与问题记录

### 5.1 本轮失败

无。

### 5.2 开发过程中发现并修复的问题

| 编号 | 问题 | 根因 | 修复 | 验证 |
| --- | --- | --- | --- | --- |
| I-01 | 首次执行时注册接口返回 400，且医生/患者中文显示为乱码（如 `å¼ ä¼ŸåŒ»ç”Ÿ`） | 初始化 SQL 通过默认字符集为 latin1 的 mysql 客户端执行，UTF-8 文本被当作 latin1 转换后入库，造成双重编码 | 在 `01-schema.sql`、`02-seed.sql` 顶部加入 `SET NAMES utf8mb4;`；使用 `--default-character-set=utf8mb4` 重新灌入种子数据 | 数据库 `HEX(name)` 为 `E5BCA0...`；接口返回中文正常；51 条断言全绿 |
| I-02 | 测试脚本对中文响应断言失败 | Windows 下 Python stdout 默认 GBK，无法编码中文 | 脚本设置 `PYTHONIOENCODING=utf-8` | 中文断言通过 |
| I-03 | 含中文字段的注册请求在 Git Bash 下返回 400 | Windows 命令行参数转码导致 JSON 非 UTF-8 | 注册用例改用 ASCII 参数；另用 UTF-8 文件 + `--data-binary` 增加中文用例 | P-01、P-10 均通过 |

上述问题均已在提交前修复，修复后完整重跑通过。

---

## 6. 覆盖矩阵

| PRD 需求 | 接口 | 测试用例 | 覆盖 |
| --- | --- | --- | --- |
| 医生列表展示（需求 2） | `GET /api/doctors` | D-01 | ✅ |
| 在线医生筛选（需求 2） | `GET /api/doctors?activeOnly=true` | D-02 | ✅ |
| 医生详情（需求 2） | `GET /api/doctors/{id}` | D-03、D-04 | ✅ |
| 医生登录（需求 2） | `POST /api/doctors/login` | D-05、D-06、D-07 | ✅ |
| FR-01 用户注册 | `POST /api/patients/register` | P-01、P-02、P-03、P-10 | ✅ |
| FR-02 用户登录 | `POST /api/patients/login` | P-04、P-05、P-06 | ✅ |
| FR-03 会话校验 | `GET /api/patients/me` | P-07、P-08、P-09 | ✅ |
| NFR-01 密码不泄露 | 全部响应 | D-01h、P-01e | ✅ |
| NFR-04 统一响应 | 全部接口 | 所有 code 断言 | ✅ |
| 前后端联调 CORS | `OPTIONS` | C-01 | ✅ |
| FR-04 退出 | 前端 store + localStorage | UI-05 | ✅ |
| FR-05 刷新恢复 | 前端 store + `/me` | UI-04、UI-05 | ✅ |
| 需求 1 首页 i18n | 前端 locales + 语言下拉 | UI-01、UI-02、UI-06 | ✅ |

> FR-04 / FR-05 属于前端行为，`tests/api-test.sh` 不覆盖；已使用无头 Edge + CDP 实际执行登录、刷新、退出，结果见 4.7。UI 检查脚本为一次性验证脚本，未纳入仓库（避免引入浏览器自动化依赖）。

---

## 7. 风险与后续建议

1. **未做登录频率限制**：当前无验证码/锁定策略，生产需在网关或应用层补齐；
2. **JWT 存于 localStorage**：存在 XSS 读取风险，生产建议改为 HttpOnly Cookie + CSRF 防护；
3. **默认 JWT 密钥**：本地默认值仅供开发，部署必须注入 `JWT_SECRET`；
4. **无自动化 UI 测试**：建议后续引入 Playwright，覆盖语言切换与登录—刷新—退出；
5. **性能未测**：医生列表数据量小，后续增加分页/缓存与压测；
6. **测试账号清理**：脚本每次生成 `autotest_*` 账号，CI 中建议执行清理 SQL 或使用事务回滚。

---

## 8. 附录：原始执行输出

```text
API test suite
  base url : http://localhost:8080
  started  : 2026-10-29 23:13:16
  test user: autotest_1793286796_5089

== Doctor list API ==
  [PASS] GET /api/doctors -> HTTP 200                               200
  [PASS] GET /api/doctors -> code 0                                 0
  [PASS] GET /api/doctors -> 5 seeded doctors                       5
  [PASS] GET /api/doctors -> first id is doc001                     doc001
  [PASS] GET /api/doctors -> first name is 张伟医生             张伟医生
  [PASS] GET /api/doctors -> first doctor is active                 true
  [PASS] GET /api/doctors -> 3 specialties for doc001               3
  [PASS] GET /api/doctors -> password is never exposed
  [PASS] GET /api/doctors?activeOnly=true -> HTTP 200               200
  [PASS] GET /api/doctors?activeOnly=true -> 4 active doctors       4
  [PASS] GET /api/doctors/doc002 -> HTTP 200                        200
  [PASS] GET /api/doctors/doc002 -> code 0                          0
  [PASS] GET /api/doctors/doc002 -> id doc002                       doc002
  [PASS] GET /api/doctors/doc999 (not found) -> HTTP 404            404
  [PASS] GET /api/doctors/doc999 (not found) -> code 40401          40401

== Doctor login API ==
  [PASS] POST /api/doctors/login (correct) -> HTTP 200              200
  [PASS] POST /api/doctors/login (correct) -> code 0                0
  [PASS] POST /api/doctors/login (correct) -> doctor doc001         doc001
  [PASS] POST /api/doctors/login (wrong password) -> HTTP 401       401
  [PASS] POST /api/doctors/login (wrong password) -> code 40101     40101
  [PASS] POST /api/doctors/login (missing password) -> HTTP 400     400
  [PASS] POST /api/doctors/login (missing password) -> code 40001   40001

== Patient registration API ==
  [PASS] POST /api/patients/register -> HTTP 201                    201
  [PASS] POST /api/patients/register -> code 0                      0
  [PASS] POST /api/patients/register -> returns JWT                 yes
  [PASS] POST /api/patients/register -> username echoed             autotest_1793286796_5089
  [PASS] POST /api/patients/register -> no password hash exposed
  [PASS] POST /api/patients/register (duplicate) -> HTTP 409        409
  [PASS] POST /api/patients/register (duplicate) -> code 40901      40901
  [PASS] POST /api/patients/register (short password) -> HTTP 400   400
  [PASS] POST /api/patients/register (short password) -> code 40001 40001
  [PASS] POST /api/patients/register (UTF-8 Chinese body) -> HTTP 201 201
  [PASS] POST /api/patients/register (UTF-8 Chinese body) -> name 测试用户 测试用户
  [PASS] POST /api/patients/register (UTF-8 Chinese body) -> gender 男 男

== Patient login API ==
  [PASS] POST /api/patients/login (seeded user) -> HTTP 200         200
  [PASS] POST /api/patients/login (seeded user) -> code 0           0
  [PASS] POST /api/patients/login (seeded user) -> username zhaoming zhaoming
  [PASS] POST /api/patients/login -> returns JWT                    yes
  [PASS] POST /api/patients/login (wrong password) -> HTTP 401      401
  [PASS] POST /api/patients/login (wrong password) -> code 40101    40101
  [PASS] POST /api/patients/login (unknown user) -> HTTP 401        401

== Patient session API ==
  [PASS] GET /api/patients/me (valid token) -> HTTP 200             200
  [PASS] GET /api/patients/me (valid token) -> code 0               0
  [PASS] GET /api/patients/me (valid token) -> username zhaoming    zhaoming
  [PASS] GET /api/patients/me (valid token) -> name 赵明          赵明
  [PASS] GET /api/patients/me (no token) -> HTTP 401                401
  [PASS] GET /api/patients/me (no token) -> code 40101              40101
  [PASS] GET /api/patients/me (invalid token) -> HTTP 401           401
  [PASS] GET /api/patients/me (invalid token) -> code 40101         40101

== CORS ==
  [PASS] OPTIONS /api/doctors -> HTTP 200                           200
  [PASS] OPTIONS /api/doctors -> Access-Control-Allow-Origin present yes

---------------------------------------------
Total: 51    Passed: 51    Failed: 0
Suite started: 2026-10-29 23:13:16
Finished     : 2026-10-29 23:13:22
Test account created: autotest_1793286796_5089
```

---

## 9. 结论

- 需求 2 的医生列表/详情/登录接口全部通过，数据来自 MySQL，中文与 JSON 字段正确；
- 需求 3 的注册、登录、会话校验、鉴权失败场景全部通过，密码未泄露；
- 前后端跨域预检通过，前端生产构建通过；
- 未发现阻塞缺陷。建议生产部署前落实 JWT 密钥注入、HTTPS 与登录限流。
