#!/usr/bin/env bash
#
# QA Live Healthcare - API regression suite (curl only).
# Covers every endpoint used by requirements #2 and #3:
#   - doctor list / detail / login       (MySQL-backed doctor page)
#   - patient register / login / profile (username + password login)
#
# Usage:
#   bash tests/api-test.sh
#   BASE_URL=http://localhost:8080 bash tests/api-test.sh
#
# Exit code: 0 when every assertion passes, 1 otherwise.

set -u

# Make Python emit UTF-8 on Windows consoles (default is GBK/CP936).
export PYTHONIOENCODING=utf-8

BASE_URL="${BASE_URL:-http://localhost:8080}"
API="${BASE_URL}/api"
TMP_DIR="$(mktemp -d)"
BODY="${TMP_DIR}/body.json"
HEADERS="${TMP_DIR}/headers.txt"

PASS=0
FAIL=0
SUITE_START="${SUITE_START:-$(date '+%Y-%m-%d %H:%M:%S')}"
RUN_ID="$(date +%s)_${RANDOM}"
TEST_USERNAME="autotest_${RUN_ID}"

if command -v tput >/dev/null 2>&1 && [ -t 1 ]; then
  GREEN="$(tput setaf 2)"
  RED="$(tput setaf 1)"
  YELLOW="$(tput setaf 3)"
  RESET="$(tput sgr0)"
else
  GREEN=""; RED=""; YELLOW=""; RESET=""
fi

json_get() {
  # json_get <file> <dotted.path>
  python - "$1" "$2" <<'PY'
import json, sys

try:
    with open(sys.argv[1], encoding='utf-8') as fh:
        value = json.load(fh)
    for part in sys.argv[2].split('.'):
        if part.lstrip('-').isdigit():
            value = value[int(part)]
        else:
            value = value[part]
except (KeyError, IndexError, TypeError, ValueError, OSError):
    value = None
if value is None:
    print('')
elif isinstance(value, bool):
    print('true' if value else 'false')
else:
    print(value)
PY
}

json_len() {
  # json_len <file> <dotted.path>
  python - "$1" "$2" <<'PY'
import json, sys

try:
    with open(sys.argv[1], encoding='utf-8') as fh:
        value = json.load(fh)
    for part in sys.argv[2].split('.'):
        if part.lstrip('-').isdigit():
            value = value[int(part)]
        else:
            value = value[part]
    print(len(value))
except (KeyError, IndexError, TypeError, ValueError, OSError):
    print('')
PY
}

check() {
  # check <description> <expected> <actual>
  local description="$1" expected="$2" actual="$3"
  if [ "$expected" = "$actual" ]; then
    PASS=$((PASS + 1))
    printf '  %s[PASS]%s %-58s %s\n' "$GREEN" "$RESET" "$description" "$actual"
  else
    FAIL=$((FAIL + 1))
    printf '  %s[FAIL]%s %-58s expected=%s actual=%s\n' "$RED" "$RESET" "$description" "$expected" "$actual"
  fi
}

call() {
  # call <METHOD> <path> [json-body] [bearer-token]
  local method="$1" path="$2" body="${3:-}" token="${4:-}"
  local args=(-s -o "$BODY" -w '%{http_code}' -X "$method" "${API}${path}")
  if [ -n "$body" ]; then
    args+=(-H 'Content-Type: application/json' -d "$body")
  fi
  if [ -n "$token" ]; then
    args+=(-H "Authorization: Bearer ${token}")
  fi
  STATUS="$(curl "${args[@]}")"
}

section() {
  printf '\n%s== %s ==%s\n' "$YELLOW" "$1" "$RESET"
}

printf 'API test suite\n'
printf '  base url : %s\n' "$BASE_URL"
printf '  started  : %s\n' "$SUITE_START"
printf '  test user: %s\n' "$TEST_USERNAME"

# ---------------------------------------------------------------------------
# 1. Doctor APIs (requirement #2)
# ---------------------------------------------------------------------------
section 'Doctor list API'

call GET '/doctors'
check 'GET /api/doctors -> HTTP 200' '200' "$STATUS"
check 'GET /api/doctors -> code 0' '0' "$(json_get "$BODY" code)"
check 'GET /api/doctors -> 5 seeded doctors' '5' "$(json_len "$BODY" data)"
check 'GET /api/doctors -> first id is doc001' 'doc001' "$(json_get "$BODY" data.0.id)"
check 'GET /api/doctors -> first name is 张伟医生' '张伟医生' "$(json_get "$BODY" data.0.name)"
check 'GET /api/doctors -> first doctor is active' 'true' "$(json_get "$BODY" data.0.isActive)"
check 'GET /api/doctors -> 3 specialties for doc001' '3' "$(json_len "$BODY" data.0.specialties)"
check 'GET /api/doctors -> password is never exposed' '' "$(json_get "$BODY" data.0.password)"

call GET '/doctors?activeOnly=true'
check 'GET /api/doctors?activeOnly=true -> HTTP 200' '200' "$STATUS"
check 'GET /api/doctors?activeOnly=true -> 4 active doctors' '4' "$(json_len "$BODY" data)"

call GET '/doctors/doc002'
check 'GET /api/doctors/doc002 -> HTTP 200' '200' "$STATUS"
check 'GET /api/doctors/doc002 -> code 0' '0' "$(json_get "$BODY" code)"
check 'GET /api/doctors/doc002 -> id doc002' 'doc002' "$(json_get "$BODY" data.id)"

call GET '/doctors/doc999'
check 'GET /api/doctors/doc999 (not found) -> HTTP 404' '404' "$STATUS"
check 'GET /api/doctors/doc999 (not found) -> code 40401' '40401' "$(json_get "$BODY" code)"

section 'Doctor login API'

call POST '/doctors/login' '{"username":"dr-zhang-wei","password":"123456"}'
check 'POST /api/doctors/login (correct) -> HTTP 200' '200' "$STATUS"
check 'POST /api/doctors/login (correct) -> code 0' '0' "$(json_get "$BODY" code)"
check 'POST /api/doctors/login (correct) -> doctor doc001' 'doc001' "$(json_get "$BODY" data.id)"

call POST '/doctors/login' '{"username":"dr-zhang-wei","password":"wrong-password"}'
check 'POST /api/doctors/login (wrong password) -> HTTP 401' '401' "$STATUS"
check 'POST /api/doctors/login (wrong password) -> code 40101' '40101' "$(json_get "$BODY" code)"

call POST '/doctors/login' '{"username":"dr-zhang-wei"}'
check 'POST /api/doctors/login (missing password) -> HTTP 400' '400' "$STATUS"
check 'POST /api/doctors/login (missing password) -> code 40001' '40001' "$(json_get "$BODY" code)"

# ---------------------------------------------------------------------------
# 2. Patient login APIs (requirement #3)
# ---------------------------------------------------------------------------
section 'Patient registration API'

# ASCII-only body: on Windows/Git Bash non-ASCII command-line arguments may be
# transcoded to the system code page and rejected as invalid UTF-8 JSON.
# Chinese payload coverage is added separately below via a UTF-8 file.
REGISTER_BODY="{\"username\":\"${TEST_USERNAME}\",\"password\":\"Patient@123\",\"name\":\"Auto Test\",\"birthday\":\"1992-05-20\",\"phone\":\"13800009999\",\"gender\":\"male\"}"
call POST '/patients/register' "$REGISTER_BODY"
check 'POST /api/patients/register -> HTTP 201' '201' "$STATUS"
check 'POST /api/patients/register -> code 0' '0' "$(json_get "$BODY" code)"
check 'POST /api/patients/register -> returns JWT' 'yes' "$([ -n "$(json_get "$BODY" data.token)" ] && echo yes || echo no)"
check 'POST /api/patients/register -> username echoed' "$TEST_USERNAME" "$(json_get "$BODY" data.patient.username)"
check 'POST /api/patients/register -> no password hash exposed' '' "$(json_get "$BODY" data.patient.password)"

call POST '/patients/register' "$REGISTER_BODY"
check 'POST /api/patients/register (duplicate) -> HTTP 409' '409' "$STATUS"
check 'POST /api/patients/register (duplicate) -> code 40901' '40901' "$(json_get "$BODY" code)"

call POST '/patients/register' "{\"username\":\"${TEST_USERNAME}_x\",\"password\":\"123\",\"name\":\"Auto Test\"}"
check 'POST /api/patients/register (short password) -> HTTP 400' '400' "$STATUS"
check 'POST /api/patients/register (short password) -> code 40001' '40001' "$(json_get "$BODY" code)"

# UTF-8 body from a file (Chinese name + Chinese gender), immune to argv transcoding.
printf '%s' "{\"username\":\"${TEST_USERNAME}_zh\",\"password\":\"Patient@123\",\"name\":\"测试用户\",\"gender\":\"男\"}" \
  > "${TMP_DIR}/register_zh.json"
ZH_STATUS="$(curl -s -o "$BODY" -w '%{http_code}' -X POST "${API}/patients/register" \
  -H 'Content-Type: application/json' --data-binary "@${TMP_DIR}/register_zh.json")"
check 'POST /api/patients/register (UTF-8 Chinese body) -> HTTP 201' '201' "$ZH_STATUS"
check 'POST /api/patients/register (UTF-8 Chinese body) -> name 测试用户' '测试用户' "$(json_get "$BODY" data.patient.name)"
check 'POST /api/patients/register (UTF-8 Chinese body) -> gender 男' '男' "$(json_get "$BODY" data.patient.gender)"

section 'Patient login API'

call POST '/patients/login' '{"username":"zhaoming","password":"Patient@123"}'
check 'POST /api/patients/login (seeded user) -> HTTP 200' '200' "$STATUS"
check 'POST /api/patients/login (seeded user) -> code 0' '0' "$(json_get "$BODY" code)"
check 'POST /api/patients/login (seeded user) -> username zhaoming' 'zhaoming' "$(json_get "$BODY" data.patient.username)"
PATIENT_TOKEN="$(json_get "$BODY" data.token)"
check 'POST /api/patients/login -> returns JWT' 'yes' "$([ -n "$PATIENT_TOKEN" ] && echo yes || echo no)"

call POST '/patients/login' '{"username":"zhaoming","password":"wrong-password"}'
check 'POST /api/patients/login (wrong password) -> HTTP 401' '401' "$STATUS"
check 'POST /api/patients/login (wrong password) -> code 40101' '40101' "$(json_get "$BODY" code)"

call POST '/patients/login' '{"username":"no-such-user","password":"Patient@123"}'
check 'POST /api/patients/login (unknown user) -> HTTP 401' '401' "$STATUS"

section 'Patient session API'

call GET '/patients/me' '' "$PATIENT_TOKEN"
check 'GET /api/patients/me (valid token) -> HTTP 200' '200' "$STATUS"
check 'GET /api/patients/me (valid token) -> code 0' '0' "$(json_get "$BODY" code)"
check 'GET /api/patients/me (valid token) -> username zhaoming' 'zhaoming' "$(json_get "$BODY" data.username)"
check 'GET /api/patients/me (valid token) -> name 赵明' '赵明' "$(json_get "$BODY" data.name)"

call GET '/patients/me'
check 'GET /api/patients/me (no token) -> HTTP 401' '401' "$STATUS"
check 'GET /api/patients/me (no token) -> code 40101' '40101' "$(json_get "$BODY" code)"

call GET '/patients/me' '' 'not.a.valid.jwt'
check 'GET /api/patients/me (invalid token) -> HTTP 401' '401' "$STATUS"
check 'GET /api/patients/me (invalid token) -> code 40101' '40101' "$(json_get "$BODY" code)"

# ---------------------------------------------------------------------------
# 3. CORS preflight used by the Vite dev server
# ---------------------------------------------------------------------------
section 'CORS'

CORS_STATUS="$(curl -s -o /dev/null -D "$HEADERS" -w '%{http_code}' -X OPTIONS "${API}/doctors" \
  -H 'Origin: http://localhost:5173' \
  -H 'Access-Control-Request-Method: GET' \
  -H 'Access-Control-Request-Headers: content-type')"
check 'OPTIONS /api/doctors -> HTTP 200' '200' "$CORS_STATUS"
check 'OPTIONS /api/doctors -> Access-Control-Allow-Origin present' 'yes' \
  "$(grep -qi 'access-control-allow-origin' "$HEADERS" && echo yes || echo no)"

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
TOTAL=$((PASS + FAIL))
printf '\n%s---------------------------------------------%s\n' "$YELLOW" "$RESET"
printf 'Total: %d    Passed: %s%d%s    Failed: %s%d%s\n' \
  "$TOTAL" "$GREEN" "$PASS" "$RESET" "$RED" "$FAIL" "$RESET"
printf 'Suite started: %s\n' "$SUITE_START"
printf 'Finished     : %s\n' "$(date '+%Y-%m-%d %H:%M:%S')"
printf 'Test account created: %s\n' "$TEST_USERNAME"
printf 'Cleanup (optional):\n'
printf "  docker exec -i mysql_doctor mysql -uroot -proot doctor_db -e \"DELETE FROM patient WHERE username LIKE 'autotest_%%';\"\n"

rm -rf "$TMP_DIR"

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
exit 0
