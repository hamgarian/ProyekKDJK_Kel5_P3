# Status Verifikasi

Diperbarui: 26 Oktober 2026.

Lampiran ini memisahkan tegas apa yang sudah diperiksa langsung dari apa yang
belum, agar tidak ada klaim keliru di [README.md](../README.md).

---

## 1. Sudah Diverifikasi

| # | Hal | Bukti |
|---|---|---|
| 1 | Arsitektur host adalah ARM64 | `uname -m` menghasilkan `aarch64` |
| 2 | Host: 2 vCPU, RAM 11 GiB, swap 4 GiB, Docker 29.0.1 | `nproc`, `free -h`, `docker version` |
| 3 | Image resmi `gitlab/gitlab-ce` menyediakan `linux/arm64` | manifest list / OCI index dari `registry-1.docker.io` |
| 4 | Dukungan arm64 mulai dari tag `18.1.0-ce.0` | `18.0.0-ce.0` dan `17.11.0-ce.0` hanya manifest tunggal amd64 |
| 5 | Tag `19.5.1-ce.0` punya child `linux/arm64` | `sha256:a8adb207a2caeb0bc28d43b3fdfc4963584e8b166dfbc941d0aa9b098e95efe8` |
| 6 | `19.5.1-ce.0` adalah rilis stabil terbaru saat pemeriksaan | digest anaknya identik dengan tag `latest` |
| 7 | Dokumentasi GitLab menyatakan ARM didukung | "ARM-based processors are supported" pada halaman requirements resmi |
| 8 | Kedua berkas Compose valid secara sintaks | `docker compose config`, lihat `scripts/validate.sh` |
| 9 | Service berjalan sebagai service Docker Compose langsung di Coolify | definisi yang dipakai tersalin di `compose.coolify.yaml`; bukan deployment yang tertaut repositori GitHub |
| 10 | Container berjalan dengan varian arm64 dari `gitlab/gitlab-ce:19.5.1-ce.0` | container aktif di host `aarch64` |
| 11 | Seluruh 10 service di dalam container berstatus `run:` | keluaran `gitlab-ctl status` |
| 12 | `https://gitlab.ilhem.eu.org/users/sign_in` menjawab `HTTP 200` lewat TLS yang valid, berisi form login GitLab | permintaan HTTPS pada 26 Oktober 2026 |
| 13 | Container Compose yang berjalan bernama `gitlab-hdhjhzyiwqgmyagbtwqepae1` dan berstatus `healthy` | Compose yang dibangkitkan Coolify di `/data/coolify/services/hdhjhzyiwqgmyagbtwqepae1` |
| 14 | Readiness lulus dari dalam container | `GET http://localhost/-/readiness?all=1` menjawab `HTTP 200`, `status: ok`, seluruh pemeriksaan database, Redis, dan Gitaly lulus |
| 15 | Login root menghasilkan sesi, dan dashboard admin terbuka | cookie sesi dari login via HTTP, lalu `/admin` dibuka di peramban nyata dan judul dashboard admin terlihat |
| 16 | `gitlab-rake gitlab:check SANITIZE=true` keluar dengan status 0 tanpa kegagalan | `integrity.log`; integrasi yang dimatikan tercatat `skipped` |
| 17 | Clone anonim via HTTPS berhasil | clone dari klien terpisah |
| 18 | Push via HTTPS terautentikasi (password) sebagai `kelompok5` berhasil | push dari klien terpisah |
| 19 | SSH port 2222 hidup: `Welcome to GitLab, @kelompok5!`, lalu clone dan push via SSH berhasil | `ssh -T -p 2222 git@gitlab.ilhem.eu.org` dan operasi Git berikutnya |
| 20 | Pipeline CI berjalan sampai selesai | `kelompok5/demo-kdjk` commit `34342ce`, pipeline #1 `passed`; `kelompok5/web-porto-rapit-sigma` pipeline #2, #3, #4 `success` |
| 21 | Siklus kerja penuh di projek contoh berbahasa Indonesia | `https://gitlab.ilhem.eu.org/kelompok5/web-porto-rapit-sigma`: branch `fitur/penyemangat` commit `f4c6566`, issue #1 berlabel `peningkatan` dengan milestone #1 dan komentar, MR #1 di-merge dan otomatis menutup issue #1 |
| 22 | Pipeline projek contoh menjalankan 32 test pustaka standar, semuanya lulus | keluaran job; selain itu klik kutipan pada JS diperiksa manual dan pada lebar 390 px tidak ada overflow |
| 23 | Artefak job dapat diunduh | `index.html`, 11.088 byte |
| 24 | Backup selesai | `backup.log`: `Backup 1793000747_2026_10_26_19.5.1 is done.`, keluar dengan status 0 |
| 25 | Restore selesai di container terisolasi versi sama | `restore.log`: `Restore task is done.` pada `kdjk-gitlab-restore-test` dengan `--network none` dan salinan `gitlab-secrets.json` yang cocok |
| 26 | Data pulih setelah restore | user `root` dan `kelompok5` aktif di basis data, projek `demo-kdjk` ada, dan ref Git persis `34342ce8019d3b903359e72cb811e5c58ddebac3`, identik dengan sumber backup |
| 27 | Pemakaian memori terukur | `docker stats`: 2,735 GiB saat idle, 2,838 GiB pada pengukuran berikutnya, dari `mem_limit` 4 GiB |

Butir 12 sekaligus membuktikan DNS teresolusi dan reverse proxy Traefik
meneruskan permintaan sampai ke NGINX internal container.

Berkas log sumber untuk butir 16, 24, 25, dan 26 ada di luar repositori, di
`/root/.hermes/cache/scratch/gitlab-verification/`: `integrity.log`,
`backup.log`, `restore.log`, dan `restore-integrity.log`.

---

## 2. Diverifikasi dengan Catatan

Ketiga butir berikut dijalankan dan menghasilkan sesuatu, tetapi hasilnya tidak
sama dengan yang diharapkan tabel Pengujian. Keduanya ditulis apa adanya, bukan
dibulatkan menjadi "lulus".

| # | Hal | Hasil sebenarnya |
|---|---|---|
| 1 | `/-/readiness` dari internet | `HTTP 404`, karena endpoint monitoring dibatasi `gitlab_rails['monitoring_whitelist']` ke localhost. Perilaku ini diinginkan dan **tidak** dilonggarkan demi tabel uji. Jalur internal lulus, lihat butir 14 di atas. |
| 2 | Redirect HTTP ke HTTPS | Redirect berjalan, tetapi kodenya `307` dengan `Location: https://gitlab.ilhem.eu.org/`, bukan `301`. |
| 3 | Target hemat memori 2 GB | **Tidak tercapai.** Angka terukur 2,735 GiB sampai 2,838 GiB. Yang diklaim hanya angka terukurnya. |

Catatan tambahan atas butir yang sudah diverifikasi:

- `gitlab:check` pada butir 16 dijalankan **sebelum** projek demo dibuat.
  Karena itu keluarannya memuat `Projects have namespace: ... can't check, you
  have no projects` dan `Active users: ... 2`. Projek demo lahir setelah
  pemeriksaan itu, jadi baris tersebut bukan tanda projek hilang.
- Log restore memuat `ERROR: must be owner of extension pg_trgm`,
  `btree_gist`, dan `amcheck`. Pesan ini muncul karena extension sudah ada dan
  bukan milik user aplikasi; restore tetap berjalan sampai selesai dan
  pemeriksaan data pada butir 26 tetap lulus.
- Snapshot backup dibuat sebelum projek `web-porto-rapit-sigma` ada, sehingga
  projek itu memang tidak muncul di hasil restore. Ini bukan kehilangan data.
- `restore-integrity.log` masih kosong: `gitlab:check` pasca-restore belum
  selesai saat catatan ini ditulis.

---

## 3. Belum Diuji

Daftar ini bukan penghalang pemakaian, melainkan pekerjaan verifikasi yang
memang belum dijalankan. Statusnya ditulis apa adanya.

| # | Hal | Cara verifikasi nanti |
|---|---|---|
| 1 | Persistensi data setelah recreate container | `docker compose up -d --force-recreate gitlab` sudah dijalankan dan selesai, tetapi container masih menjawab `HTTP 502` selama boot ulang, sehingga bukti ujung ke ujung belum ada. Ulangi setelah boot tuntas, lalu periksa user, projek, dan ref Git. |
| 2 | `gitlab-rake gitlab:check SANITIZE=true` pada instance hasil restore | jalankan di container `kdjk-gitlab-restore-test`, keluarannya masuk ke `restore-integrity.log` |
| 3 | Screenshot tampilan aplikasi | ambil sesuai daftar di `docs/screenshots/README.md`, sensor data sensitif. Belum ada satu pun gambar, dan tidak ada gambar yang ditanamkan di README. |
| 4 | Pengisian konten demo lengkap sesuai rencana README (grup `kdjk-p3-kelompok5`, 4 akun anggota, wiki, 5 issue) | ikuti bagian "Cara Pemakaian" pada README. Yang sudah ada baru dua projek dan akun `kelompok5`, bukan susunan lengkap itu. |
| 5 | Endpoint `/-/liveness` | `curl -sSI` dari dalam container, sama seperti readiness |

---

## 4. Risiko yang Diketahui

### R1. CPU di bawah angka acuan resmi
Dokumentasi memory-constrained meminta **4 core** ARM7/ARM64; host hanya punya
**2**. Instance tetap boot sampai seluruh service `run:`, tetapi boot pertama
dan latensi request lebih lambat daripada angka acuan.
**Mitigasi:** `start_period: 15m` pada health check kedua berkas Compose, agar
container tidak dibunuh sebelum siap.

### R2. Swap terpakai 100 % saat pengukuran
`free -h` menunjukkan swap 4,0 GiB terpakai seluruhnya dan RAM bebas 146 MiB,
karena host menanggung beban lain. RAM *available* 6,1 GiB masih cukup.
**Mitigasi:** `vm.swappiness=10`, `mem_limit: 4g` pada service Coolify, dan
seluruh setting hemat memori di bagian Konfigurasi README.

### R3. Bentrokan port dengan Traefik milik Coolify
Coolify memakai port 80/443 host. Definisi Compose yang dipakai tidak meminta
kedua port itu, dan jalur CLI mem-bind HTTP hanya ke `127.0.0.1:8929`.
**Mitigasi:** jangan mengaktifkan `letsencrypt['enable']` atau
`nginx['listen_https']` di dalam container selama proxy eksternal dipakai.

### R4. Port SSH 2222 perlu dibuka manual
Coolify tidak mengurus port non-HTTP. Tanpa `ufw allow 2222/tcp`, clone via SSH
gagal meski antarmuka web berfungsi.

### R5. Tidak ada MTA di dalam image
Dokumentasi resmi menyatakan image GitLab tidak memuat MTA. Reset password dan
notifikasi tidak terkirim sampai SMTP eksternal dikonfigurasi.

### R6. Password root awal
Pada jalur CLI, password dibuat di `/etc/gitlab/initial_root_password` dan hanya
berlaku 24 jam. Pada jalur Coolify, password berasal dari variabel
`SERVICE_PASSWORD_GITLABROOT` yang dibangkitkan panel. Keduanya harus diganti
setelah login pertama dan **tidak boleh** disalin ke repositori.

### R7. `gitlab-secrets.json` tidak termasuk dalam backup
Tanpa berkas ini, dump basis data tidak dapat didekripsi. Harus dibackup
terpisah ke lokasi di luar server, dan tidak boleh masuk Git (sudah ada di
`.gitignore` dan diperiksa `scripts/validate.sh`).

### R8. Upgrade tidak boleh melompati versi
Ada upgrade path resmi; lompat beberapa versi minor dapat menggagalkan migrasi
basis data. Ganti tag image secara bertahap, jangan langsung ke `latest`.

---

## 5. Catatan Riwayat Git

Riwayat commit repositori ini disusun ulang per topik dari deliverable akhir,
sehingga cap waktu commit adalah waktu penyusunan ulang, bukan bukti kronologis
urutan pengerjaan. Penjelasan lengkap ada di bagian "Catatan tentang Riwayat
Git" pada README.
