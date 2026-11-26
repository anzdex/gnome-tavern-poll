#!/usr/bin/env bash
# Deploy realm/ (poll) ke Onyx testnet. Jalankan SETELAH faucet terisi.
# Kebutuhan: wallet-seed.txt (password keybase dibaca dari sana, tidak di-echo).
set -euo pipefail
cd "$(dirname "$0")"
export PATH="$HOME/.gno/bin:$PATH"

PASS=$(grep '^# keybase password: ' wallet-seed.txt | cut -d' ' -f4)
ADDR=$(grep '^# address: ' wallet-seed.txt | cut -d' ' -f3)
RPC="https://rpc.latest.testnets.gno.land:443"
PKG="gno.land/r/$ADDR/poll"

echo "Deploying $PKG to Onyx (chain-id onyx-1)..."
echo "NOTE: gnokey's Go HTTP client fails TLS through this VM's egress proxy,"
echo "so -broadcast fails at the account query. Offline flow (proven 26 Nov 2026):"
echo " 1) maketx addpkg ... -broadcast=false > tx-unsigned.json"
echo " 2) gnokey sign ... -tx-path tx-unsigned.json (in place) -account-number <N> -account-sequence <S> -chainid onyx-1"
echo " 3) python3 encode_tx.py tx-unsigned.json  # amino binary2 -> base64 in /tmp/tx-b64.txt"
echo " 4) curl POST $RPC/ broadcast_tx_commit with {\"tx\": \"<base64>\"}"
echo "Gas: addpkg of ~11.5KB needs ~16.7M gas (5M failed OOG on 26 Nov 2026)."

printf '%s\n' "$PASS" | gnokey maketx addpkg \
	-pkgpath "$PKG" \
	-pkgdir ./realm \
	-gas-fee 30000ugnot -gas-wanted 20000000 \
	-chainid onyx-1 -remote "$RPC" \
	-broadcast -simulate test gnome-tavern --insecure-password-stdin

echo "Verify at: https://latest.testnets.gno.land/r/$ADDR/poll"
