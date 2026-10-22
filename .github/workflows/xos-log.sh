#!/bin/bash
# xos_log_init — CI hata loglarını issue yorumuna taşır (kanal: api.github.com).
# Kullanım: adımların başında `. .github/workflows/xos-log.sh` ile yüklenir,
# hata durumunda `xos_post_log "<başlık>" <dosya>` çağrılır.
xos_post_log() {
    local title="$1" file="$2"
    local repo="${XOS_REPO:-}" token="${GH_TOKEN:-}" issue="${XOS_LOG_ISSUE:-2}"
    [ -n "$repo" ] && [ -n "$token" ] && [ -f "$file" ] || return 0

    local body
    body=$(jq -n --arg t "$title" --rawfile f "$file" \
        '("### " + $t + "\n\n```\n" + ($f | if length <= 60000 then . else .[-60000:] end) + "\n```")')
    # Arama API'si installation token ile güvenilmez; bilinen issue'ya doğrudan
    # yorum atılır (yoksa yeni issue oluşturulmaya çalışır).
    if ! curl -fsS -H "Authorization: Bearer $token" \
            -H "Accept: application/vnd.github+json" \
            -X POST "https://api.github.com/repos/${repo}/issues/${issue}/comments" \
            -d "$(jq -n --argjson b "$body" '{body: $b}')" > /dev/null 2>&1; then
        curl -fsS -H "Authorization: Bearer $token" \
            -H "Accept: application/vnd.github+json" \
            -X POST "https://api.github.com/repos/${repo}/issues" \
            -d "$(jq -n --arg t "CI logs" --argjson b "$body" '{title: $t, body: $b}')" \
            > /dev/null 2>&1 || true
    fi
}
