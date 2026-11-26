# Gnome Tavern Poll — Voting Realm on Gno.land

Realm polling untuk Gnome Tavern Hackathon | Gno.land (deadline submit
**18 Des 2026 08:00 WIB**). Proyek ke-1 dari tiga submission Gnome Tavern
(token TIP dan bounty board ada di repo terpisah).

- **Realm:** `gno.land/r/g1yyyk53j9ahtvfjp2h4nmngjxhxug3kq8rdkyek/poll`
- **Chain:** Onyx testnet (chain-id `onyx-1`)
- **Toolchain:** gno v1.8.0, `export GNOROOT=$HOME/gno`

Siapa saja bisa membuat poll, tiap alamat hanya boleh 1 suara per poll,
dan hanya pembuat poll yang bisa menutupnya.

## Fungsi

| Fungsi | Keterangan |
|---|---|
| `CreatePoll(question, options)` | Buat poll baru, return poll ID. `options` satu string dipisah `|` (mis. `"Poll|Token|Bounty"`). Validasi: pertanyaan tidak kosong (≤200 karakter), 2–10 opsi, tiap opsi tidak kosong (≤100 karakter). |
| `Vote(pollID, optionIndex)` | Beri suara. Tolak vote kedua dari alamat yang sama, opsi di luar range, dan vote di poll yang sudah ditutup. |
| `ClosePoll(pollID)` | Tutup poll — hanya pembuat poll; tolak kalau sudah ditutup. |
| `PollCount()` | Jumlah poll yang pernah dibuat. |
| `Tally(pollID)` | Salinan hitungan suara per opsi. |
| `GetPoll(pollID)` | Pertanyaan, opsi, creator, dan status poll. |
| `Render(path string)` | Daftar poll + tally sebagai Markdown; teks dari user di-escape via `gno.land/p/nt/markdown/sanitize/v0` (paket itu ADA di Onyx testnet). |

## File

- `poll.gno` — realm
- `poll_test.gno` — 8 test: buat poll, validasi, vote valid, vote ganda ditolak, opsi invalid ditolak, tutup lalu vote ditolak, render, render escape input jahat
- `gnomod.toml` — module `gno.land/r/g1yyyk53j9ahtvfjp2h4nmngjxhxug3kq8rdkyek/poll`
- `deploy.sh` — deploy ke Onyx testnet (baca password keybase dari `wallet-seed.txt` di folder induk proyek — file itu TIDAK PERNAH di-commit)

## Verifikasi lokal (26 Nov 2026, `gno` v1.8.0, `GNOROOT=$HOME/gno`)

- `gno fmt` ✅, `gno lint` ✅, `gno test` ✅ — **8/8 test lolos**.
- `gnodev` lokal ✅: Render tampil di web UI lokal ("No polls yet" →
  setelah `CreatePoll` via `gnokey maketx call`, poll tampil dengan tally
  0; setelah `Vote`, tally jadi 1; vote kedua dari alamat yang sama
  ditolak on-chain: "address has already voted in this poll").

## Deploy — BERHASIL 26 Nov 2026 (Onyx testnet)

- Tx sukses di blok **1420938**, hash
  `813e32364c6fb7d7e846b5760f4157d818b304a35d8178cd76a8417e90482bc1`,
  deliver `msg:0,success:true`, gas dipakai 16.687.902.
- Percobaan pertama GAGAL OutOfGas (gas-wanted 5.000.000, dipakai
  14.751.776); percobaan kedua dengan gas-wanted 20.000.000 + gas-fee
  30.000ugnot berhasil. `deploy.sh` sudah diperbarui ke nilai gas ini.
- `gnokey -broadcast` gagal TLS lewat egress proxy VM (klien HTTP Go),
  jadi deploy memakai jalur offline: `maketx -broadcast=false` →
  `gnokey sign` (account-number 2273, sequence 1) → `encode_tx.py`
  (encoder amino binary2 Python) → broadcast via `curl` POST
  `broadcast_tx_commit`. Catatan: untuk deploy berikutnya, broadcast
  HARUS via Python urllib (`broadcast_tx.py`) — POST curl ke RPC ini
  gagal konsisten dengan param tx kosong.
- Saldo setelah deploy: **299,965 GNOT**; sequence akun 2.
- **Status realm: SUBMITTED, belum enabled.** Onyx memakai mode `inert`:
  paket yang di-deploy masuk antrean review GPAS dan di-enable otomatis
  kalau lolos. Sampai di-enable, gnoweb menampilkan "Not Yet Enabled"
  dan `PollCount` (qeval) menjawab "package not found" — ini normal
  untuk mode inert, bukan kegagalan deploy.

Verifikasi deploy:
https://latest.testnets.gno.land/r/g1yyyk53j9ahtvfjp2h4nmngjxhxug3kq8rdkyek/poll

## Catatan teknis (temuan saat build)

- `GNOROOT=$HOME/gno` (clone gno v1.8.0) — GNOROOT bawaan binary menunjuk
  path build-time `/__w/gno/gno` yang tidak ada. Selalu export sebelum
  menjalankan `gno`/`gnokey`/`gnodev`.
- **Tidak ada paket `std` di gno v1.8.0** — jangan `import "std"`. Alamat
  pakai tipe bawaan `address`, caller di crossing function pakai
  `cur.Previous().Address()`, error pakai stdlib `errors`.
- **`testing.SetRealm` itu frame-scoped**: harus dipanggil di frame yang
  sama dengan pemanggilan `cross(cur)` — memanggilnya lewat helper
  terpisah tidak berpengaruh. Test di sini memakai helper yang melakukan
  SetRealm + cross dalam satu frame, dan `reset()` tiap test karena state
  realm dipakai bersama antar test dalam satu run `gno test`.
- **Argumen `[]string` tidak bisa dikirim lewat `gnokey maketx call`**
  (VM panic "unexpected slice type in contract arg") — karena itu
  `CreatePoll` menerima opsi sebagai satu string dipisah `|`.
- Dependensi on-chain di-vendor lokal untuk test offline:
  `gno.land/p/nt/markdown/sanitize/v0/` (disalin dari repo gnolang/gno,
  Apache-2.0) + `gnowork.toml` kosong di root proyek; tanpa ini
  `gno test`/`lint` mencoba mengunduh paket dari `rpc.gno.land` dan
  gagal TLS lewat egress proxy VM (klien HTTP Go gagal TLS, curl
  berhasil — temuan yang sama berlaku untuk `gnokey query`/`-broadcast`).
