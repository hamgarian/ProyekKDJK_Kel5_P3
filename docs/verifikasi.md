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

Butir 12 sekaligus membuktikan DNS teresolusi dan reverse proxy Traefik
meneruskan permintaan sampai ke NGINX internal container.

---

## 2. Belum Diuji

Daftar ini bukan penghalang pemakaian, melainkan pekerjaan verifikasi yang
memang belum dijalankan. Statusnya ditulis apa adanya.

| # | Hal | Cara verifikasi nanti |
|---|---|---|
| 1 | Login administratif dan sesi di dalam aplikasi | login root di peramban, lihat dashboard |
| 2 | Pengisian konten demo (grup, 4 akun anggota, projek, issue, wiki, pipeline) | ikuti bagian "Cara Pemakaian" pada README |
| 3 | `git clone` dan `git push` via HTTPS maupun SSH port 2222 | jalankan dari klien, lihat tabel Pengujian |
| 4 | Screenshot tampilan aplikasi | ambil sesuai daftar di `docs/screenshots/README.md`, sensor data sensitif |
| 5 | Siklus backup dan latihan restore | `gitlab-backup create`, lalu restore ke host uji, lalu `gitlab-rake gitlab:check SANITIZE=true` |
| 6 | Integritas aplikasi menyeluruh | `gitlab-rake gitlab:check SANITIZE=true` |
| 7 | Pengukuran pemakaian memori setelah tuning | `docker stats --no-stream` pada container GitLab |
| 8 | Endpoint `/-/readiness` dan `/-/liveness` | `curl -sSI` ke kedua endpoint |

---

## 3. Risiko yang Diketahui

### R1. CPU di bawah angka acuan resmi
Dokumentasi memory-constrained meminta **4 core** ARM7/ARM64; host hanya punya
**2**. Instance tetap boot sampai seluruh service `run:`, tetapi boot pertama
dan latensi request lebih lambat daripada angka acuan.
**Mitigasi:** `start_period: 15m` pada health check kedua berkas Compose, agar
container tidak dibunuh sebelum siap.

