alias ih='reattach-to-user-namespace idea .'

function mac_toggle_menubar() {
  osascript <<END
tell application "System Events"
	tell dock preferences to set autohide menu bar to not autohide menu bar
end tell
END
}

function mac_trust_certificate() {
  certificate_file=${1}

  if [ ! -f "$certificate_file" ]; then
    echo "Error: Certificate file not found: $certificate_file" >&2
    return 1
  fi

  # Create temp directory for splitting certificates
  TMP_DIR=$(mktemp -d /tmp/mac_trust_certs.XXXXXX)

  # Split certificate file into individual certificates
  awk -v tmpdir="$TMP_DIR" '
    /BEGIN CERTIFICATE/ {
      cert_count++
      outfile = tmpdir "/cert_" cert_count ".pem"
    }
    {
      if (cert_count > 0) {
        print > outfile
      }
    }
  ' "$certificate_file"

  # Trust each certificate
  cert_num=0
  for cert in "$TMP_DIR"/cert_*.pem; do
    if [ -f "$cert" ]; then
      cert_num=$((cert_num + 1))
      echo "Trusting certificate #${cert_num}..."
      sudo security add-trusted-cert \
        -d \
        -r trustRoot \
        -k /Library/Keychains/System.keychain \
        "$cert"
    fi
  done

  # Cleanup
  rm -rf "$TMP_DIR"

  echo "Successfully trusted ${cert_num} certificate(s)"
}
