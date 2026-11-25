# Bitwarden-backed secrets -> environment.
#
# Inputs (set by templates/env.sh.j2 from variables*.yml):
#   BW_SESSION      session key from `bw unlock --raw`. Empty = skip, no-op.
#   BW_SECRETS      assoc array: ENV_VAR_NAME -> Bitwarden item name/id
#
# Load runs on shell start only when BW_SESSION is non-empty and `bw` exists.
# Each secret = one `bw get password` call; keep the map small.
# Manual refresh: `secrets_load`. Unlock: `export BW_SESSION=$(bw unlock --raw)`.

typeset -gA BW_SECRETS

secrets_load() {
  [[ -n "${BW_SESSION:-}" ]] || { echo "secrets: BW_SESSION empty, skipping" >&2; return 0; }
  command -v bw >/dev/null 2>&1 || { echo "secrets: bw not installed" >&2; return 1; }
  local var item value
  for var item in "${(@kv)BW_SECRETS}"; do
    value=$(bw get password "$item" --session "$BW_SESSION" 2>/dev/null) \
      || { echo "secrets: failed to read '$item' for $var" >&2; continue; }
    export "$var=$value"
  done
}

[[ -n "${BW_SESSION:-}" && ${#BW_SECRETS} -gt 0 ]] && secrets_load
