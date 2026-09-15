#!/usr/bin/env bash
# ghpush.sh — HTTPS + fine-grained PAT push helper for GitHub.
# Design: the token is entered ONCE by a human (hidden), stored in git's
# credential store, and never appears in URLs, config, logs, shell history
# or this script. Day-to-day push works from stored credentials only.
#
# Usage:
#   scripts/ghpush.sh --setup-token            # human, once: hidden token entry
#   scripts/ghpush.sh --check                  # credential present + read-only probe
#   scripts/ghpush.sh [--tag v3.3] [--tag v4]  # push current branch + optional tags
#
# Env / files:
#   GIT_BIN=<path>                force a specific git (e.g. an openssl-build one)
#   ./.ghpushrc                   optional local file: GIT_BIN=/path/to/git (gitignored)
#   GH_ALLOW_ANY_TOKEN=1          skip token format checks
set -euo pipefail

cd "$(dirname "$0")/.."
REMOTE="${GHPUSH_REMOTE:-origin}"

if [ -f .ghpushrc ]; then # shellcheck disable=SC1091
  . ./.ghpushrc
fi
GIT_BIN="${GIT_BIN:-$(command -v git)}"

G=( -c credential.helper= -c credential.helper=store -c http.version=HTTP/1.1
    -c credential.interactive=false )
git_() { "$GIT_BIN" "${G[@]}" "$@"; }

die() { echo "[ghpush] ERROR: $*" >&2; exit 1; }

need_remote() {
  url="$(git remote get-url "$REMOTE" 2>/dev/null)" || die "no remote '$REMOTE'"
  case "$url" in
    https://github.com/*) : ;;
    *) die "expected clean https://github.com/OWNER/REPO(.git) remote, got: $url" ;;
  esac
  case "$url" in
    *://[^/@]*@*) die "remote URL embeds credentials; clean it: git remote set-url $REMOTE https://github.com/OWNER/REPO.git" ;;
  esac
  OWNER="$(sed -E 's#https://github\.com/([^/]+)/.*#\1#' <<<"$url")"
  URL="$url"
}

setup_token() {
  need_remote
  local T n
  read -rs -p "Paste GitHub PAT (github_pat_... / ghp_...; input hidden): " T; echo
  T="${T//$'\r'/}"; T="${T//$'\n'/}"
  T="$(printf '%s' "$T" | sed -E "s/^[\"' ]+//; s/[\"' ]+$//")"
  [ -n "$T" ] || die "empty input"
  n="$(grep -oE 'gh[pousr]?_|github_pat_' <<<"$T" | wc -l)"
  [ "$n" -le 1 ] || die "疑似重复粘贴（检测到 $n 个 token 前缀），请清空后只粘贴一次"
  if [ "${GH_ALLOW_ANY_TOKEN:-0}" != "1" ]; then
    case "$T" in
      github_pat_*) [ "${#T}" -ge 82 ] || die "fine-grained token 长度异常 (${#T})" ;;
      gh[pousr]_*)  [ "${#T}" -eq 40 ]  || die "classic token 长度异常 (${#T}, 应为 40)" ;;
      *) die "未识别 token 前缀（或设 GH_ALLOW_ANY_TOKEN=1 放行）" ;;
    esac
  fi
  local body
  # 先无密码 reject：删掉该 host+username 的全部旧条目（含损坏的空密码条目）
  printf 'protocol=https\nhost=github.com\nusername=%s\n\n' "$OWNER" | git_ credential reject 2>/dev/null || true
  body="$(printf 'protocol=https\nhost=github.com\nusername=%s\npassword=%s\n\n' "$OWNER" "$T")"
  printf '%s' "$body" | git_ credential approve
  [ -f "$HOME/.git-credentials" ] && chmod 600 "$HOME/.git-credentials"
  unset T body
  local chk
  chk="$(printf 'protocol=https\nhost=github.com\nusername=%s\n\n' "$OWNER" \
        | GIT_TERMINAL_PROMPT=0 "$GIT_BIN" "${G[@]}" credential fill | sed -n 's/^password=//p')"
  [ "${#chk}" -ge 40 ] || die "落盘校验失败（读回长度 ${#chk}），请重跑 --setup-token 并只粘贴一次"
  echo "[ghpush] 校验通过：${chk:0:5}…${chk: -4} (len=${#chk})"
  unset chk
  echo "[ghpush] 已保存：${OWNER} @ github.com（掩码预览略）。现在起直接：scripts/ghpush.sh"
  check || die "保存后连通性检查失败，见上"
}

check() {
  need_remote
  GIT_TERMINAL_PROMPT=0 credential-fill-check || die "凭据库中无 github.com/$OWNER 凭据，请先 --setup-token"
  git_ ls-remote --heads "$URL" >/dev/null 2>&1 || die "ls-remote 失败（网络/权限）：$URL"
  echo "[ghpush] check OK（$OWNER @ $URL 可达）"
}

# hidden helper: ask credential store without echoing the secret
credential-fill-check() {
  printf 'protocol=https\nhost=github.com\nusername=%s\n\n' "$OWNER" \
    | GIT_TERMINAL_PROMPT=0 "$GIT_BIN" "${G[@]}" credential fill >/dev/null 2>&1
}

push_with_retry() {
  local try=0 max="${GHPUSH_RETRIES:-5}"
  until GIT_TERMINAL_PROMPT=0 git_ "$@"; do
    try=$((try+1)); [ "$try" -ge "$max" ] && die "push 失败（重试 $max 次）：git $*"
    echo "[ghpush] 第 $try 次失败，2s 后重试..."; sleep 2
  done
}

usage() { grep '^# ' "$0" | sed 's/^# \{0,1\}//'; }

[ $# -gt 0 ] || { usage; exit 1; }
TAGS=(); ACTION=push
for a in "$@"; do
  case "$a" in
    --setup-token) ACTION=setup ;;
    --check)       ACTION=check ;;
    --tag=*)       TAGS+=("${a#--tag=}") ;;
    --tag|--tags)  : ;;  # value consumed below
    -h|--help)     usage; exit 0 ;;
    *) case "${prev:-}" in --tag|--tags) TAGS+=("$a");; *) die "unknown arg: $a";; esac ;;
  esac
  prev="$a"
done

case "$ACTION" in
  setup) setup_token; exit 0 ;;
  check) check; exit 0 ;;
esac

need_remote
BR="$(git symbolic-ref --short HEAD)"
git_ ls-remote --heads "$URL" >/dev/null 2>&1 || die "预检失败（凭据/网络）"
echo "[ghpush] 预检 OK，推送 $BR -> $REMOTE"
push_with_retry push -u "$REMOTE" "$BR"
if [ "${#TAGS[@]}" -gt 0 ]; then
  push_with_retry push "$REMOTE" "${TAGS[@]}"
fi
echo "[ghpush] 完成：branch $BR${TAGS:+, tags ${TAGS[*]}}"
