#!/usr/bin/env bash
# Pre-launch legal check, automatic part (checks 1, 2 and the email footer part of 4).
# Fails on: Google-hosted fonts, known session-replay scripts, marketing email templates without an unsubscribe link.
# Checks 3 (children), 5 (auto-renewal) and 6 (DMCA) stay judgment: see the pre-launch-legal-check skill.
# Usage: scripts/legal_check.sh [folder]   (plain grep, no extra tools)
root="${1:-.}"; fail=0
EX=(--exclude-dir=node_modules --exclude-dir=.next --exclude-dir=.git --exclude-dir=.github)
hits=$(grep -rInE "${EX[@]}" --include='*.html' --include='*.htm' --include='*.css' --include='*.js' --include='*.jsx' --include='*.ts' --include='*.tsx' --include='*.mjs' 'fonts\.(googleapis|gstatic)\.com' "$root")
[ -n "$hits" ] && { echo "FAIL fonts: Google-hosted font. Use next/font, or self-host the files (drop kit fonts/fonts.css)."; echo "$hits" | head -5; fail=1; }
hits=$(grep -rIniE "${EX[@]}" --include='*.html' --include='*.js' --include='*.jsx' --include='*.ts' --include='*.tsx' --include='*.mjs' --include='package.json' 'hotjar|fullstory|clarity\.ms|logrocket|mouseflow|smartlook|inspectlet|disable_session_recording:[[:space:]]*false' "$root")
[ -n "$hits" ] && { echo "FAIL session replay: script found. Remove it, or add consent and input masking."; echo "$hits" | head -5; fail=1; }
while IFS= read -r f; do
  grep -qi 'unsubscribe' "$f" || { echo "FAIL email template $f: no unsubscribe link"; fail=1; }
  grep -qiE 'P\.?O\.? Box|[0-9]+ [A-Za-z]+ (St|Street|Ave|Avenue|Rd|Road|Blvd|Suite)' "$f" || { echo "FAIL email template $f: no postal address"; fail=1; }
done < <(find "$root" \( -path '*/node_modules' -o -path '*/.git' \) -prune -o -type f \( -iname '*newsletter*' -o -iname '*email-template*' -o -path '*/emails/*' \) \( -name '*.html' -o -name '*.tsx' -o -name '*.mjml' -o -name '*.md' \) -print)
[ $fail -eq 0 ] && echo "legal ok: $root"; exit $fail
