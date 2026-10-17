#!/usr/bin/env bash
# Superintel drop style check. Every HTML page in the folder must:
#  - load fonts from the site itself (fonts/fonts.css or @font-face with a local url), never from Google;
#  - name Antonio, Archivo and IBM Plex Mono (directly or through kit.css / an inline <style>);
#  - never use Inter.
# Usage: scripts/style_check.sh [folder]
root="${1:-.}"; fail=0
# Next.js sites (superintel-crimson): fonts come from next/font in app/layout.tsx, which self-hosts at build time.
if [ -f "$root/app/layout.tsx" ]; then
  l="$root/app/layout.tsx"
  for fam in Antonio Archivo IBM_Plex_Mono; do grep -q "$fam" "$l" || { echo "FAIL style $l: next/font $fam missing"; fail=1; }; done
  grep -q 'next/font' "$l" || { echo "FAIL style $l: load fonts with next/font (self-hosted)"; fail=1; }
  if grep -rEq --include='*.tsx' --include='*.ts' --include='*.css' "(^|[^A-Za-z])Inter([^A-Za-z]|$)" "$root/app" "$root/components" 2>/dev/null; then echo "FAIL style: Inter found in app/ or components/"; fail=1; fi
  [ $fail -eq 0 ] && echo "style ok (next): $root"; exit $fail
fi
pages=$(find "$root" -name '*.html' -not -path '*/node_modules/*' -not -path '*/.git/*')
[ -z "$pages" ] && { echo "style: no html pages in $root"; exit 0; }
css=$(find "$root" -name '*.css' -not -path '*/node_modules/*' -exec cat {} + 2>/dev/null)
for p in $pages; do
  all="$(cat "$p")
$css"
  for fam in Antonio Archivo "IBM Plex Mono"; do
    grep -q "$fam" <<<"$all" || { echo "FAIL style $p: font '$fam' missing (use kit.css from the drop kit)"; fail=1; }
  done
  if grep -Eq "(^|[^A-Za-z])Inter([^A-Za-z]|$)" "$p"; then echo "FAIL style $p: uses Inter. Use Archivo (body) and Antonio (display)."; fail=1; fi
  if ! grep -Eq 'fonts/fonts\.css|@font-face' <<<"$all"; then echo "FAIL style $p: no self-hosted fonts (link fonts/fonts.css)"; fail=1; fi
done
[ $fail -eq 0 ] && echo "style ok: $root"; exit $fail
