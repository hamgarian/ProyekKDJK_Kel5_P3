#!/usr/bin/env bash
# validate.sh - pemeriksaan konfigurasi & dokumentasi repo KDJK GitLab CE.
#
# Skrip ini TIDAK men-deploy, TIDAK menarik image, dan TIDAK menyentuh server.
# Yang diperiksa:
#   1. docker-compose.yml valid secara sintaks (jika `docker compose` tersedia)
#   2. tag image yang di-pin benar-benar punya manifest untuk arsitektur host
#   3. README.md memuat semua bagian wajib laporan
#   4. tidak ada rahasia / file .env yang ter-commit
#   5. klaim screenshot di README konsisten dengan file yang benar-benar ada
#   6. tidak ada karakter em dash pada berkas dokumentasi/konfigurasi
#
# Pakai:  ./scripts/validate.sh
# Keluar dengan status 1 bila ada pemeriksaan yang GAGAL.

set -u

cd "$(dirname "$0")/.." || exit 1

PASS=0
FAIL=0
SKIP=0

ok()   { printf '  \033[32mOK\033[0m    %s\n' "$1"; PASS=$((PASS + 1)); }
bad()  { printf '  \033[31mGAGAL\033[0m %s\n' "$1"; FAIL=$((FAIL + 1)); }
skip() { printf '  \033[33mLEWAT\033[0m %s\n' "$1"; SKIP=$((SKIP + 1)); }

IMAGE_REF=$(grep -oE '^\s*image:\s*gitlab/gitlab-ce:[A-Za-z0-9._-]+' docker-compose.yml |
	head -1 | sed 's|.*gitlab/gitlab-ce:||')

