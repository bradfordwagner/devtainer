#!/usr/bin/env bash
# Verifies the wl-paste shim makes Claude Code's WSL image-paste work.
pass(){ printf '  \033[32m✓\033[0m %s\n' "$1"; }
fail(){ printf '  \033[31m✗\033[0m %s\n' "$1"; FAILED=1; }

echo
echo "1. shim on PATH"
w=$(command -v wl-paste)
case "$w" in
  *wsl-shims*) pass "wl-paste -> $w" ;;
  *) fail "wl-paste -> ${w:-not found} (expected wsl-shims; open a NEW shell)"; echo; exit 1 ;;
esac

echo "2. clipboard holds an image"
if wl-paste --list-types 2>/dev/null | grep -q '^image/'; then
  pass "clipboard has $(wl-paste --list-types 2>/dev/null | tr '\n' ' ')"
else
  fail "no image on clipboard — press win+shift+s and grab something, then rerun"; echo; exit 1
fi

echo "3. shim blocks image reads (so PowerShell branch is reached)"
wl-paste --type image/bmp >/dev/null 2>&1 && fail "image read succeeded — shim not active" || pass "image/bmp read refused (exit 1)"

echo "4. Claude's real fallback chain yields a PNG"
i=$(mktemp /tmp/cliptest-XXXX.png)
PS="$(command -v powershell.exe 2>/dev/null || echo /mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe)"
xclip -selection clipboard -t image/png -o > "$i" 2>/dev/null \
  || wl-paste --type image/png > "$i" 2>/dev/null \
  || xclip -selection clipboard -t image/bmp -o > "$i" 2>/dev/null \
  || wl-paste --type image/bmp > "$i" 2>/dev/null \
  || "$PS" -NoProfile -NonInteractive -Sta -Command 'Add-Type -AssemblyName System.Windows.Forms; $i = [System.Windows.Forms.Clipboard]::GetImage(); if ($null -eq $i) { exit 1 }; $ms = New-Object System.IO.MemoryStream; $i.Save($ms, [System.Drawing.Imaging.ImageFormat]::Png); [Convert]::ToBase64String($ms.ToArray())' 2>/dev/null | tr -d '\r' | base64 -d > "$i"
t=$(file -b "$i")
case "$t" in
  PNG*) pass "chain produced: $t" ;;
  *bitmap*|*BMP*) fail "still BMP: $t  (this is the bug — shim not taking effect)" ;;
  *) fail "unexpected: $t" ;;
esac
rm -f "$i"
echo "5. text clipboard still works (pbpaste / screenshot.sh)"
if echo probe-$$ | wl-copy 2>/dev/null && [ "$(wl-paste 2>/dev/null)" = "probe-$$" ]; then
  pass "wl-copy/wl-paste text roundtrip intact (clipboard image consumed)"
else
  fail "text roundtrip broken"
fi


echo
[ -n "$FAILED" ] && { echo "  Some checks failed."; exit 1; }
echo "  All checks passed — restart Claude Code, then press ctrl+v."
echo
