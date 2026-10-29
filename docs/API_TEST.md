# API 测试说明（curl）

本文档描述如何使用 curl 验证需求 2（医生数据 MySQL + API）与需求 3（问诊用户登录）涉及的全部接口，并指导 AI / 测试人员据此生成测试报告。

- 自动化脚本：`tests/api-test.sh`
- 测试报告：`docs/TEST_REPORT.md`
- 被测服务：`qa-service-user`（默认 `http://localhost:8080`）
- 数据来源：`docker-compose.yml` 启动的 MySQL 8（`doctor_db`）

---

## 1. 前置条件

| 依赖 | 版本 | 检查命令 |
| --- | --- | --- |
| Docker / Docker Compose | 24+ | `docker --version` |
| JDK | 17+ | `java -version` |
| Node.js（仅前端联调需要） | 18+ | `node -v` |
| curl | 7+ | `curl --version` |
| Python（脚本用于解析 JSON） | 3.8+ | `python --version` |

> 脚本只使用 `curl` 发起请求，Python 仅用于读取响应 JSON（不使用第三方库），也可替换为 `jq`。

---

## 2. 启动被测环境

```bash
# 1) 启动 MySQL + phpMyAdmin（首次启动自动执行建表/种子脚本）
docker compose up -d

# 2) 等待 MySQL healthy
docker compose ps

# 3) 启动后端
cd server/qa-service-user
./mvnw spring-boot:run

# 4) 确认健康检查
curl -s http://localhost:8080/actuator/health
# => {"status":"UP",...}
```

验证数据库（可选）：

```bash
docker exec mysql_doctor mysql -uroot -proot -e \
  "USE doctor_db; SELECT id,username,name,is_active FROM doctor; SELECT username,name FROM patient;"
```

预期：5 位医生、2 位种子患者（`zhaoming`、`sunli`）。

若使用已经初始化过的数据卷，初始化脚本不会重复执行。可手动重建（会清空 `doctor`/`patient` 表）：

```bash
docker exec -i mysql_doctor mysql -uroot -proot < docker/mysql/init/01-schema.sql
docker exec -i mysql_doctor mysql -uroot -proot < docker/mysql/init/02-seed.sql
```

---

## 3. 测试数据

| 数据 | 值 | 用途 |
| --- | --- | --- |
| 医生账号 | `dr-zhang-wei / 123456` | 医生登录成功 |
| 医生账号（错误密码） | `dr-zhang-wei / wrong-password` | 401 |
| 患者账号 | `zhaoming / Patient@123` | 患者登录成功、`/me` |
| 患者账号 | `sunli / Patient@123` | 备用 |
| 动态注册账号 | `autotest_<timestamp>_<random>` | 注册成功 / 重复注册 409 |

动态账号由脚本生成，测试结束后可清理：

```bash
docker exec -i mysql_doctor mysql -uroot -proot doctor_db -e \
  "DELETE FROM patient WHERE username LIKE 'autotest_%';"
```

---

## 4. 测试用例

### 4.1 医生接口（需求 2）

| 编号 | 方法 | 路径 | 请求体/参数 | 预期 HTTP | 预期 code | 断言要点 |
| --- | --- | --- | --- | --- | --- | --- |
| D-01 | GET | `/api/doctors` | - | 200 | 0 | 返回 5 位医生；首位 `doc001`、姓名“张伟医生”、`isActive=true`、3 个擅长领域；不返回 `password` |
| D-02 | GET | `/api/doctors?activeOnly=true` | - | 200 | 0 | 仅 4 位在线医生 |
| D-03 | GET | `/api/doctors/doc002` | - | 200 | 0 | `id=doc002` |
| D-04 | GET | `/api/doctors/doc999` | - | 404 | 40401 | 不存在的医生 |
| D-05 | POST | `/api/doctors/login` | `{"username":"dr-zhang-wei","password":"123456"}` | 200 | 0 | 返回 `doc001` |
| D-06 | POST | `/api/doctors/login` | 错误密码 | 401 | 40101 | 凭证错误 |
| D-07 | POST | `/api/doctors/login` | 缺少 password | 400 | 40001 | 参数校验 |

### 4.2 患者接口（需求 3）

| 编号 | 方法 | 路径 | 请求体/请求头 | 预期 HTTP | 预期 code | 断言要点 |
| --- | --- | --- | --- | --- | --- | --- |
| P-01 | POST | `/api/patients/register` | 唯一用户名 + `Patient@123` | 201 | 0 | 返回 JWT、患者信息；不返回密码 |
| P-02 | POST | `/api/patients/register` | 重复用户名 | 409 | 40901 | 用户名冲突 |
| P-03 | POST | `/api/patients/register` | 密码 `123` | 400 | 40001 | 长度校验 |
| P-04 | POST | `/api/patients/login` | `zhaoming / Patient@123` | 200 | 0 | 返回 JWT、`username=zhaoming` |
| P-05 | POST | `/api/patients/login` | 错误密码 | 401 | 40101 | 凭证错误 |
| P-06 | POST | `/api/patients/login` | 不存在的用户 | 401 | 40101 | 不泄露账号是否存在 |
| P-07 | GET | `/api/patients/me` | `Authorization: Bearer <有效 token>` | 200 | 0 | 返回 `zhaoming` / `赵明` |
| P-08 | GET | `/api/patients/me` | 无 Authorization | 401 | 40101 | 未认证 |
| P-09 | GET | `/api/patients/me` | 非法 token | 401 | 40101 | 签名/格式错误 |
| P-10 | POST | `/api/patients/register` | UTF-8 文件请求体（中文姓名 + 性别“男”） | 201 | 0 | UTF-8 JSON 与中文校验通过 |

### 4.3 跨域（前后端联调）

| 编号 | 方法 | 路径 | 请求头 | 预期 |
| --- | --- | --- | --- | --- |
| C-01 | OPTIONS | `/api/doctors` | `Origin: http://localhost:5173`、`Access-Control-Request-Method: GET` | HTTP 200，响应含 `Access-Control-Allow-Origin` |

---

## 5. 手工 curl 示例

以下命令可直接复制执行（Git Bash / macOS / Linux；Windows CMD 请把单引号改为双引号并转义）。

### 5.1 医生列表

```bash
curl -s http://localhost:8080/api/doctors | python -m json.tool
```

预期（节选）：

```json
{
  "code": 0,
  "message": "success",
  "data": [
    {
      "id": "doc001",
      "username": "dr-zhang-wei",
      "name": "张伟医生",
      "title": "主任医师",
      "department": "心内科",
      "avatar": "https://...",
      "experience": "15年临床经验",
      "specialties": ["高血压", "冠心病", "心律失常"],
      "isActive": true
    }
  ]
}
```

### 5.2 仅在线医生

```bash
curl -s "http://localhost:8080/api/doctors?activeOnly=true"
```

### 5.3 医生详情 / 不存在

```bash
curl -s -w '\nHTTP %{http_code}\n' http://localhost:8080/api/doctors/doc002
curl -s -w '\nHTTP %{http_code}\n' http://localhost:8080/api/doctors/doc999
```

### 5.4 医生登录

```bash
curl -s -w '\nHTTP %{http_code}\n' -X POST http://localhost:8080/api/doctors/login \
  -H 'Content-Type: application/json' \
  -d '{"username":"dr-zhang-wei","password":"123456"}'
```

### 5.5 患者注册

```bash
curl -s -w '\nHTTP %{http_code}\n' -X POST http://localhost:8080/api/patients/register \
  -H 'Content-Type: application/json' \
  -d '{"username":"demo_user_001","password":"Patient@123","name":"演示用户","birthday":"1995-01-01","phone":"13800001111","gender":"男"}'
```

### 5.6 患者登录并保存 token

```bash
TOKEN=$(curl -s -X POST http://localhost:8080/api/patients/login \
  -H 'Content-Type: application/json' \
  -d '{"username":"zhaoming","password":"Patient@123"}' \
  | python -c "import sys,json; print(json.load(sys.stdin)['data']['token'])")

echo "$TOKEN"
```

### 5.7 使用 token 获取当前患者

```bash
curl -s http://localhost:8080/api/patients/me -H "Authorization: Bearer $TOKEN" | python -m json.tool
```

### 5.8 未认证 / 非法 token

```bash
curl -s -w '\nHTTP %{http_code}\n' http://localhost:8080/api/patients/me
curl -s -w '\nHTTP %{http_code}\n' http://localhost:8080/api/patients/me \
  -H 'Authorization: Bearer not.a.valid.jwt'
```

### 5.9 CORS 预检

```bash
curl -s -o /dev/null -D - -X OPTIONS http://localhost:8080/api/doctors \
  -H 'Origin: http://localhost:5173' \
  -H 'Access-Control-Request-Method: GET'
```

---

## 6. 自动化执行

```bash
# 默认 http://localhost:8080
bash tests/api-test.sh

# 指定地址
BASE_URL=http://127.0.0.1:8080 bash tests/api-test.sh

# 保存原始输出，便于生成报告
bash tests/api-test.sh | tee /tmp/api-test.log
```

脚本行为：

1. 逐条请求并断言 HTTP 状态、业务 `code`、关键字段；
2. 实时打印 `[PASS]` / `[FAIL]`；
3. 末尾输出总数、通过数、失败数、测试账号与清理命令；
4. 全部通过退出码 `0`，存在失败退出码 `1`（可用于 CI）。

预期输出末尾：

```
Total: 51    Passed: 51    Failed: 0
```

> 断言数量随用例调整，以脚本实际输出为准。

---

## 7. 指导 AI 生成测试报告

把以下提示词与脚本输出一起交给 AI：

```text
你是测试工程师。请依据 docs/API_TEST.md 的用例定义和下面的 tests/api-test.sh 运行输出，
生成 docs/TEST_REPORT.md，必须包含：
1. 测试环境（日期、操作系统、Java/Node/Docker/MySQL 版本、服务地址）；
2. 测试范围与不在范围；
3. 汇总：执行用例数、通过数、失败数、通过率、结论；
4. 分模块明细表（用例编号、接口、预期、实际、结果）；
5. 失败项分析（若无失败写明“无”）；
6. 覆盖矩阵：PRD 需求编号 -> 接口 -> 测试用例；
7. 风险与后续建议；
8. 原始执行输出摘要（附录）。
不要编造未执行的用例；若输出缺失，请标注“未执行”。
```

---

## 8. 常见问题

| 现象 | 原因 | 处理 |
| --- | --- | --- |
| `无法连接后端服务` | 后端未启动 / 端口不是 8080 | 启动 `qa-service-user`，或用 `BASE_URL` 指定 |
| 接口 500，日志提示 `Communications link failure` | MySQL 未启动 | `docker compose up -d` |
| 医生列表为空 | 数据卷存在但未执行种子脚本 | 手动执行 `01-schema.sql` / `02-seed.sql`（见第 2 节） |
| 注册返回 409 | 用户名重复 | 使用新的 `autotest_*` 用户名或执行清理 SQL |
| `/me` 始终 401 | token 过期（默认 24h）或 JWT_SECRET 变更 | 重新登录获取 token |
| `python: command not found` | 未安装 Python / 未加入 PATH | 安装 Python 3，或将脚本中的 JSON 解析替换为 `jq` |
| CORS 失败 | 后端未启动或 Origin 不在允许范围 | 确认 `CorsConfig` 与请求 Origin |

---

## 9. 验收标准

- [ ] `tests/api-test.sh` 全部用例通过（退出码 0）；
- [ ] 响应中不出现 `password` 字段；
- [ ] 数据库密码列为 BCrypt 哈希（`$2a$` / `$2b$` / `$2y$` 开头）；
- [ ] 医生列表与 `doctor` 表数据一致；
- [ ] 前端 `npm run build` 通过，登录—刷新—退出流程可用；
- [ ] `docs/TEST_REPORT.md` 已依据真实输出生成。
