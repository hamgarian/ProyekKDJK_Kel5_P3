# Screenshot

Direktori ini belum memuat gambar. Instance sudah berjalan di
<https://gitlab.ilhem.eu.org>, tetapi pengambilan tangkapan layar belum
dilakukan sehingga tidak ada gambar yang ditanamkan di `README.md` utama.
Menanamkan tautan ke berkas yang belum ada hanya menghasilkan gambar rusak dan
klaim palsu; status lengkapnya ada di [docs/verifikasi.md](../verifikasi.md).

`scripts/validate.sh` bagian 5 akan **gagal** bila README menanamkan gambar
yang berkasnya tidak benar-benar ada di sini.

## Daftar Tangkapan Layar yang Dibutuhkan

Simpan berkas di direktori ini dengan nama persis seperti di bawah, lalu
tanamkan ke bagian "Cara Pemakaian" pada `README.md`.

| # | Nama berkas | Isi yang harus terlihat |
|---|---|---|
| 1 | `01-login.png` | Halaman login GitLab dengan URL `https://gitlab.ilhem.eu.org` dan ikon kunci TLS terlihat di bilah alamat |
| 2 | `02-tls-certificate.png` | Detail sertifikat di peramban: penerbit dan masa berlaku |
| 3 | `03-dashboard.png` | Dashboard setelah login, bukan halaman kosong |
| 4 | `04-grup-anggota.png` | Grup `kdjk-p3-kelompok5` dengan keempat anggota dan perannya |
| 5 | `05-projek-repositori.png` | Daftar berkas repositori dengan riwayat commit nyata |
| 6 | `06-merge-request.png` | Merge request berisi diskusi/review, bukan MR kosong |
| 7 | `07-issue-board.png` | Papan issue dengan beberapa issue berlabel |
| 8 | `08-pipeline.png` | Pipeline CI/CD yang sudah berjalan beserta statusnya |
| 9 | `09-wiki.png` | Halaman wiki yang sudah berisi teks |
| 10 | `10-admin-monitoring.png` | Admin → Settings → Metrics and profiling, memperlihatkan Prometheus Metrics nonaktif |
| 11 | `11-gitlab-ctl-status.png` | Terminal: `gitlab-ctl status` dengan seluruh service `run:` |
| 12 | `12-docker-stats.png` | Terminal: `docker stats --no-stream gitlab` sebagai bukti pemakaian memori setelah tuning |
| 13 | `13-backup-create.png` | Terminal: `gitlab-backup create` sampai baris `Creating backup archive: ... [DONE]` |
| 14 | `14-clone-ssh.png` | Terminal: `git clone` via SSH port 2222 berhasil |

## Ketentuan
