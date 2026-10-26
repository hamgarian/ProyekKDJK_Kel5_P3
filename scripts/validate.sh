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

echo
echo "== 1. Sintaks docker-compose.yml =="
if [ ! -f docker-compose.yml ]; then
	bad "docker-compose.yml tidak ditemukan"
elif command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
	# Pakai .env.example sebagai sumber variabel agar tidak butuh .env asli.
	if out=$(docker compose --env-file .env.example config 2>&1 >/dev/null); then
		ok "docker compose config berhasil mem-parse (env dari .env.example)"
	else
		bad "docker compose config menolak file:"
		printf '%s\n' "$out" | sed 's/^/        /'
	fi
else
	skip "docker compose tidak tersedia, sintaks tidak diperiksa"
fi

if command -v python3 >/dev/null 2>&1; then
	for f in docker-compose.yml compose.coolify.yaml; do
		if python3 -I -c 'import yaml,sys; yaml.safe_load(open(sys.argv[1]))' "$f" 2>/dev/null; then
			ok "$f adalah YAML yang valid"
		else
			skip "PyYAML tidak ada atau $f tidak terbaca, validasi YAML dilewati"
		fi
	done
fi

# Tag image pada kedua berkas Compose harus sama agar dokumentasi konsisten.
COOLIFY_REF=$(grep -oE '^\s*image:\s*gitlab/gitlab-ce:[A-Za-z0-9._-]+' compose.coolify.yaml 2>/dev/null |
	head -1 | sed 's|.*gitlab/gitlab-ce:||')
if [ -n "${COOLIFY_REF:-}" ] && [ -n "${IMAGE_REF:-}" ]; then
	if [ "$COOLIFY_REF" = "$IMAGE_REF" ]; then
		ok "tag image sama di docker-compose.yml dan compose.coolify.yaml ($IMAGE_REF)"
	else
		bad "tag image berbeda: docker-compose.yml=$IMAGE_REF, compose.coolify.yaml=$COOLIFY_REF"
	fi
fi

echo
echo "== 2. Dukungan arsitektur image =="
HOST_ARCH=$(uname -m)
case "$HOST_ARCH" in
aarch64 | arm64) WANT_ARCH=arm64 ;;
x86_64 | amd64) WANT_ARCH=amd64 ;;
*) WANT_ARCH="$HOST_ARCH" ;;
esac
echo "  host: $HOST_ARCH  ->  arsitektur image yang dibutuhkan: $WANT_ARCH"
echo "  tag yang di-pin di docker-compose.yml: ${IMAGE_REF:-<tidak terbaca>}"

