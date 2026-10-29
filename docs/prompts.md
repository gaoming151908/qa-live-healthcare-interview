# AI Coding 提示词记录

本文档记录本次面试任务从需求理解到代码、测试、文档交付过程中使用的主要提示词。所有代码与文档均通过 AI Coding 方式生成，人工仅做必要的校验、纠错与调整。

- AI 工具：Claude Code（终端内的 AI Coding Agent）
- 交互方式：在项目根目录启动，按阶段给出提示词，AI 读取仓库后直接修改文件并运行构建/测试
- 人工调整说明：每次 AI 产出后由人工审查 diff、运行验证命令，发现问题再以“纠错提示词”继续对话

---

## P0. 任务启动与仓库理解

> 实际发送给 AI 的第一条提示词（已隐去账户密码）：

```text
在本项目目录下有一个.md文件,文件名为"项目要求",请根据他的要求完成任务,我的github账户账户名是:gaoming151908,项目文档已经初步建立,就在本目录,请以最高水准完成此项任务
```

AI 的动作：

1. 读取 `项目要求.md`、`README.md`、`server/`、`web/qa-web/` 目录结构；
2. 识别出上一轮遗留的无关代码（聊天 UI 的 `App.vue`、Flask `app.py`、占位的 locales），决定清理/覆盖；
3. 输出三需求 + 测试 + 文档 + GitHub 交付的执行计划。

> 安全说明：GitHub 密码不应出现在提示词或仓库中。后续推送使用本机已缓存的 Git 凭证，仓库内不保存任何账号密码。

---

## P1. 需求 1：首页中英文切换

```text
请为 web/qa-web 的首页实现中英文切换：
1. 语言资源文件放在 web/qa-web/src/locales，zh-CN.ts / en-US.ts / index.ts，使用 vue-i18n（已安装 9.x）；
2. 在页面右上角添加语言下拉菜单，选项为“中文 / English”，切换后首页内容立即变化；
3. 记住用户选择（localStorage），刷新后保持；首次访问按浏览器语言判断；
4. 只处理首页本身及其可见的导航/页脚，其他页面正文不做国际化；
5. 覆盖所有静态文案、按钮、统计标签、空/加载/错误状态和图片 alt；
6. 完成后运行 npm run build 验证。

先阅读 Home.vue、AppHeader.vue、AppFooter.vue，再给出改动方案并实施。
```

AI 产出：`locales/index.ts`、`zh-CN.ts`、`en-US.ts`，改写 `Home.vue`、`AppHeader.vue`、`AppFooter.vue`、`vite-env.d.ts`。

人工校验：确认下拉菜单位于右上角、仅在首页展示；`npm run build` 通过。

---

## P2. 需求 2：MySQL 与 docker-compose

```text
请把医生数据从 web/qa-web/src/data/doctor-user-list.json 迁移到 MySQL：
1. 重写项目根目录的 docker-compose.yml，使用 mysql:8.0 + phpmyadmin；
   - 数据库 doctor_db，字符集 utf8mb4；
   - 应用账号 qa_user / Qa@123456，root 密码 root；
   - phpmyadmin 映射 8081；
   - 增加 healthcheck 和初始化脚本挂载 ./docker/mysql/init；
2. 在 docker/mysql/init 下提供 01-schema.sql（doctor、patient 表与授权）和 02-seed.sql；
3. doctor 表字段必须与前端 Doctor 类型完全对应（id 用 doc001 这类业务 ID，specialties 用 JSON）；
4. 密码用 BCrypt 哈希，不要存明文；
5. 提供可重复执行的说明（已有数据卷时如何手动执行脚本）。
先检查当前容器与数据卷状态，避免破坏其他正在运行的服务。
```

AI 产出：`docker-compose.yml`、`docker/mysql/init/01-schema.sql`、`02-seed.sql`，并对当前运行中的 MySQL 执行了建表与种子数据。

---

## P3. 需求 2：qa-service-user 医生列表 API

```text
在 server/qa-service-user（Spring Boot 3.5 / Java 17）中实现医生 API：
1. 增加依赖：spring-boot-starter-data-jpa、validation、mysql-connector-j、spring-security-crypto、jjwt；
2. 实体 Doctor（id/username/password/name/title/department/avatar/experience/specialties/is_active/created_at），specialties 用 AttributeConverter 映射 List<String> 与 JSON；
3. GET /api/doctors（支持 activeOnly=true）、GET /api/doctors/{id}、POST /api/doctors/login；
4. 统一响应 {code,message,data}；异常用 @RestControllerAdvice 转成 400/401/404/409/500；
5. 响应 DTO 绝不能包含密码；
6. 测试环境用 H2，保证 mvn test 不依赖 Docker；
7. 构建并启动验证，用 curl 检查三个接口。
```

AI 产出：`common/`、`entity/`、`repository/`、`dto/`、`service/`、`controller/` 及配置。

人工校验：`mvn package`、启动后 curl 验证医生列表与登录。

---

## P4. 需求 2：前端接入医生 API

```text
把 web/qa-web 的医生数据源从前端 JSON 改为 qa-service-user：
1. 新增 src/api/http.ts、doctor.ts，统一 base URL（VITE_API_BASE_URL，默认 http://localhost:8080），解析 {code,message,data}，业务错误抛 ApiError；
2. 改造 store：doctors 初始为空，loadDoctors() 异步加载；App.vue 挂载时调用；
3. Doctors.vue 使用 API 数据并补充 loading / error+重试 / empty 状态；
4. Home.vue 的“开放诊室”和统计同样使用 store 中的医生数据；
5. DoctorLogin.vue 改为调用 POST /api/doctors/login；
6. 补充 vite-env.d.ts 的环境变量类型；完成后 npm run build。
```

AI 产出：`src/api/*`、`store/index.ts`、`Doctors.vue`、`Home.vue`、`DoctorLogin.vue`。

---

## P5. 需求 3：编写 PRD 模版

```text
请先在 /docs 目录编写一份规范的 PRD 文档模版 PRD_TEMPLATE.md，要求：
1. 覆盖文档信息、背景目标、用户场景、范围（In/Out）、术语、功能需求（FR 编号 + Given/When/Then 验收标准）、非功能需求、交互与文案、数据与接口契约、拆分步骤、风险依赖、测试要点、发布回滚、附录；
2. 每节带填写说明与示例占位；
3. 需求编号可被后续开发与测试逐条引用；
4. 拆分步骤要能指导 AI 按增量实现。
```

AI 产出：`docs/PRD_TEMPLATE.md`。

---

## P6. 需求 3：按模版编写 PRD

```text
请严格使用 docs/PRD_TEMPLATE.md，为“为问诊用户提供用户名密码登录方式”编写 docs/PRD-patient-login.md：
- 现状问题：Consultation.vue 目前用姓名+生日验证，任意输入都能通过、刷新丢失；
- 范围：注册、登录、JWT 会话、/me 校验、前端登录/注册、退出与刷新恢复；明确排除短信、OAuth、找回密码、验证码、限流；
- 功能需求至少覆盖：注册、登录、会话校验、退出、登录态恢复、表单体验；
- 数据模型给出 patient 表 DDL；接口给出 register/login/me 的请求响应与错误码；
- 在 PRD 中提供 5 步拆分（数据库 → 后端基础 → 接口 → 前端 → 测试文档），每步写交付物与验证方式；
- 逻辑必须与现有技术栈（Vue3 + Spring Boot3 + MySQL8）一致。
```

AI 产出：`docs/PRD-patient-login.md`。

---

## P7. 需求 3：按 PRD 完成特性开发

```text
请依据 docs/PRD-patient-login.md 的 FR/NFR 与拆分步骤实现该特性，按 SP-1 ~ SP-5 逐项落地：
1. patient 表已在 01-schema.sql 中，补齐种子账号；
2. 后端：Patient 实体、Repository、BCrypt、JWT（HS256，24h，密钥可通过 JWT_SECRET 覆盖）、注册/登录/me 接口、参数校验与统一错误码；
3. 前端：api/patient.ts、store 的患者会话持久化与 restorePatientSession、Consultation.vue 登录/注册 Tabs（替换姓名+生日）；
4. 每完成一步运行对应验证命令；
5. 实现过程中若发现 PRD 与现状冲突，先更新 PRD 再改代码，并在变更记录中说明。
```

AI 产出：患者登录完整前后端实现，`Consultation.vue` 登录/注册 UI，token 持久化与恢复。

人工校验：用种子账号与动态注册账号手工走通登录、刷新、退出。

---

## P8. 测试：curl 套件与 API_TEST.md

```text
请完成测试交付：
1. 创建 tests/api-test.sh，仅用 curl（Python 只用于解析 JSON，不引第三方库），覆盖需求 2/3 的所有接口：
   - 医生列表、activeOnly、详情、404、医生登录成功/密码错误/缺参；
   - 患者注册成功/重复/密码过短、登录成功/密码错误/用户不存在、/me 有效/无 token/非法 token；
   - CORS 预检；
2. 每个断言同时校验 HTTP 状态、业务 code 和关键字段；
3. 脚本输出 PASS/FAIL、汇总、退出码；支持 BASE_URL 覆盖；
4. 编写 docs/API_TEST.md：前置条件、启动步骤、测试数据、用例表、手工 curl 示例、自动化执行、指导 AI 生成报告的提示词、常见问题、验收标准；
5. 实际启动服务并运行脚本，确保全绿。
```

AI 产出：`tests/api-test.sh`、`docs/API_TEST.md`、运行结果。

---

## P9. 生成测试报告

```text
请根据 docs/API_TEST.md 与刚才 tests/api-test.sh 的真实输出，生成 docs/TEST_REPORT.md：
包含环境信息、范围、汇总（用例数/通过/失败/通过率/结论）、分模块明细表、失败分析（无失败则写“无”）、
PRD 需求 → 接口 → 用例覆盖矩阵、风险建议、附录原始输出摘要。
不要编造未执行的用例；数据必须与脚本输出一致。
```

AI 产出：`docs/TEST_REPORT.md`。

---

## P10. 设计文档与 README

```text
请补充 docs/DESIGN.md 和根目录 README 的运行说明：
- 设计文档覆盖三需求的架构图、数据模型、接口、JWT/BCrypt、i18n 方案、错误模型、关键取舍与文件清单；
- README 给出从零启动的完整步骤：docker compose → 后端 → 前端 → 测试，以及测试账号；
- 保持与现有代码一致，不写未实现的能力。
```

AI 产出：`docs/DESIGN.md`、`README.md` 更新。

---

## P11. 自查与纠错（多轮）

> 以下是实际发生在实现过程中的纠错提示词示例，用于说明 AI 产出并非一次成型。

```text
前端构建报错 / 类型不匹配：Doctor.id 原来是 string，患者 id 变成 number，请统一 store 与视图中的类型，
并删除已废弃的 verifyPatient，确保 npm run build 通过。
```

```text
后端启动失败：请读取异常日志定位原因；注意 Spring Boot 3 使用 jakarta.* 而不是 javax.*，
JPA 实体字段与 SQL 表结构必须一一对应。
```

```text
api-test.sh 中 json_get 遇到不存在的 password 字段会抛 KeyError，请改为容错返回空字符串，
并把布尔值统一输出 true/false，保证断言可比较。
```

```text
请检查所有响应是否可能泄露 password；检查 JWT 密钥长度校验；检查 CORS 预检是否通过。
```

---

## P12. Git 提交与 PR

```text
请整理分支 feature-interview-task：
1. 确认没有把 node_modules、target、日志、无关文件（app.py 等历史遗留）提交；
2. 用规范的提交信息分阶段提交（i18n、MySQL/医生 API、患者登录、测试与文档）；
3. 推送分支到 origin，并基于该分支向 main 创建 PR，PR 描述包含需求对照、验证命令、截图/视频说明与测试结果。
```

AI 产出：提交记录与 PR（推送/PR 创建受 GitHub 凭证与网络条件影响，详见交付说明）。

---

## 提示词使用原则（复盘）

1. **先读后写**：每条提示词都要求 AI 先阅读相关文件，避免凭空生成与项目风格不一致的代码。
2. **范围显式化**：用 In Scope / Out of Scope 约束 AI，避免过度设计。
3. **可验证**：要求每步给出验证命令（build / curl / mvn test），不验收“看起来对”的代码。
4. **契约先行**：先写 PRD 与接口契约，再实现前后端，减少联调返工。
5. **错误驱动迭代**：构建/测试失败后，把真实错误日志作为下一轮提示词输入，而不是让 AI 猜。
6. **安全默认值**：密码哈希、密钥环境变量、响应脱敏、错误信息不泄露账号存在性，均写入提示词约束。
