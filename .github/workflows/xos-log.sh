#!/bin/bash
# xos-log.sh — CI hata loglarını issue yorumuna taşır.
# Log blob indirilemediğinde (sandbox kısıtı) tek okunabilir kanal budur;
# yorum api.github.com üzerindedir.
xos_post_log() {
    local title="$1" file="$2"
    local repo="${XOS_REPO:-}" token="${GH_TOKEN:-}"
    [ -n "$repo" ] && [ -n "$token" ] && [ -f "$file" ] || return 0

    local num
    num=$(curl -fsS -H "Authorization: Bearer $token" \
        -H "Accept: application/vnd.github+json" \
        "https://api.github.com/search/issues?q=repo:${repo}+in:title+%22CI+logs%22" \
        | jq -r '.items[0].number // empty' 2>/dev/null || true)
    if [ -z "$num" ]; then
        num=$(curl -fsS -H "Authorization: Bearer $token" \
            -H "Accept: application/vnd.github+json" \
            -X POST "https://api.github.com/repos/${repo}/issues" \
            -d '{"title":"CI logs","body":"Otomatik CI hata logları buraya yorumlanır."}' \
            | jq -r '.number // empty' 2>/dev/null || true)
    fi
    [ -n "$num" ] || return 0

    local body
    body=$(jq -n --arg t "$title" --rawfile f "$file" \
        '("### " + $t + "\n\n```\n" + ($f | .[0:60000]) + "\n```")')
    curl -fsS -H "Authorization: Bearer $token" \
        -H "Accept: application/vnd.github+json" \
        -X POST "https://api.github.com/repos/${repo}/issues/${num}/comments" \
        -d "$(jq -n --argjson b "$body" '{body: $b}')" > /dev/null 2>&1 || true
}
