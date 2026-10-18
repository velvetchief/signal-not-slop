#!/usr/bin/env bash
# Superintel drop style check. Every HTML page in the folder must:
#  - load fonts from the site itself (fonts/fonts.css or @font-face with a local url), never from a font CDN;
#  - name Antonio, Archivo and IBM Plex Mono (directly or through kit.css / an inline <style>);
#  - never use Inter;
#  - have the three-column layout (a grid with three tracks, as in kit.css .row);
#  - carry no X links (x.com, twitter.com) and no "Assumption" tags (C-20261016-02, -03).
# It warns (does not fail) on red colours: Superintel is white, black and grey (C-0000-12).
# Usage: scripts/style_check.sh [folder]
root="${1:-.}"; fail=0
FONT_CDN='fonts\.(googleapis|gstatic)\.com|fonts\.bunny\.net|use\.typekit\.net|p\.typekit\.net|fonts\.cdnfonts\.com|rsms\.me/inter|fast\.fonts\.net|cdn\.jsdelivr\.net/(npm|gh)/@?fontsource|api\.fontshare\.com|fonts\.adobe\.com'
warn_red(){ # $1 = text, $2 = where. Warn on hex colours where red clearly dominates.
  local hits; hits=$(grep -oE '#[0-9a-fA-F]{6}\b' <<<"$1" | sort -u | while read -r h; do
    r=$((16#${h:1:2})); g=$((16#${h:3:2})); b=$((16#${h:5:2})); [ $r -ge 150 ] && [ $g -le 90 ] && [ $b -le 90 ] && printf '%s ' "$h"; done)
  [ -n "$hits" ] && echo "WARN style $2: red colour(s) $hits(Superintel is white, black and grey)"; return 0; }
# Next.js sites (superintel-crimson): fonts come from next/font in app/layout.tsx, which self-hosts at build time.
if [ -f "$root/app/layout.tsx" ]; then
  l="$root/app/layout.tsx"
  for fam in Antonio Archivo IBM_Plex_Mono; do grep -q "$fam" "$l" || { echo "FAIL style $l: next/font $fam missing"; fail=1; }; done
  grep -q 'next/font' "$l" || { echo "FAIL style $l: load fonts with next/font (self-hosted)"; fail=1; }
  if grep -rEq --include='*.tsx' --include='*.ts' --include='*.css' "(^|[^A-Za-z])Inter([^A-Za-z]|$)" "$root/app" "$root/components" 2>/dev/null; then echo "FAIL style: Inter found in app/ or components/"; fail=1; fi
  warn_red "$(cat "$root"/app/*.css "$root"/app/**/*.css 2>/dev/null)" "$root/app"
  [ $fail -eq 0 ] && echo "style ok (next): $root"; exit $fail
fi
pages=$(find "$root" -name '*.html' -not -path '*/node_modules/*' -not -path '*/.git/*')
[ -z "$pages" ] && { echo "style: no html pages in $root"; exit 0; }
css=$(find "$root" -name '*.css' -not -path '*/node_modules/*' -not -path '*/.git/*' -exec cat {} + 2>/dev/null)
for p in $pages; do
  all="$(cat "$p")
$css"
  for fam in Antonio Archivo "IBM Plex Mono"; do
    grep -q "$fam" <<<"$all" || { echo "FAIL style $p: font '$fam' missing (use kit.css from the drop kit)"; fail=1; }
  done
  if grep -Eq "(^|[^A-Za-z])Inter([^A-Za-z]|$)" "$p"; then echo "FAIL style $p: uses Inter. Use Archivo (body) and Antonio (display)."; fail=1; fi
  if ! grep -Eq 'fonts/fonts\.css|@font-face' <<<"$all"; then echo "FAIL style $p: no self-hosted fonts (link fonts/fonts.css)"; fail=1; fi
  if grep -Eq "$FONT_CDN" <<<"$all"; then echo "FAIL style $p: font loaded from a font CDN. Self-host it (drop kit fonts/)."; fail=1; fi
  if grep -Eiq "url\([[:space:]]*['\"]?(https?:)?//[^)]*\.(woff2?|ttf|otf|eot)" <<<"$all"; then echo "FAIL style $p: @font-face loads a font file from another host. Self-host it."; fail=1; fi
  if ! grep -Eq 'grid-template-columns:[[:space:]]*[^[:space:];}]+[[:space:]]+[^[:space:];}]+[[:space:]]+[^[:space:];}]+[[:space:]]*[;}"]' <<<"$all"; then
    echo "FAIL style $p: no three-column grid (use kit.css .row, 140px / 1fr / 1.2fr)"; fail=1; fi
  if grep -Eq '(https?:)?//(www\.|mobile\.)?(x|twitter)\.com/' "$p"; then echo "FAIL style $p: X link (x.com or twitter.com). Drop pages carry no X links."; fail=1; fi
  if grep -q 'Assumption' "$p"; then echo "FAIL style $p: 'Assumption' tag. It belongs in work files only."; fail=1; fi
  warn_red "$all" "$p"
done
[ $fail -eq 0 ] && echo "style ok: $root"; exit $fail
