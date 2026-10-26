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

if [ -z "$IMAGE_REF" ]; then
	bad "tidak bisa membaca tag image dari docker-compose.yml"
elif ! command -v curl >/dev/null 2>&1; then
	skip "curl tidak tersedia, manifest registry tidak diperiksa"
else
	TOKEN=$(curl -sS --max-time 30 \
		"https://auth.docker.io/token?service=registry.docker.io&scope=repository:gitlab/gitlab-ce:pull" |
		sed -n 's/.*"token":"\([^"]*\)".*/\1/p')
	if [ -z "$TOKEN" ]; then
		skip "tidak bisa mengambil token Docker Hub (offline?)"
	else
		MANIFEST=$(curl -sS --max-time 30 -H "Authorization: Bearer $TOKEN" \
			-H "Accept: application/vnd.docker.distribution.manifest.list.v2+json" \
			-H "Accept: application/vnd.oci.image.index.v1+json" \
			-H "Accept: application/vnd.docker.distribution.manifest.v2+json" \
			"https://registry-1.docker.io/v2/gitlab/gitlab-ce/manifests/$IMAGE_REF")
		ARCHES=$(printf '%s' "$MANIFEST" |
			grep -oE '"architecture"[[:space:]]*:[[:space:]]*"[a-z0-9]+"' |
			sed 's/.*"\([a-z0-9]*\)"$/\1/' | sort -u | tr '\n' ' ')
		if [ -z "$ARCHES" ]; then
			bad "tag $IMAGE_REF bukan manifest multi-arch (hanya amd64) -> TIDAK jalan di $HOST_ARCH"
		else
			echo "  arsitektur tersedia pada tag: $ARCHES"
			if printf '%s' "$ARCHES" | grep -qw "$WANT_ARCH"; then
				ok "tag $IMAGE_REF menyediakan linux/$WANT_ARCH"
			else
				bad "tag $IMAGE_REF TIDAK menyediakan linux/$WANT_ARCH"
			fi
		fi
	fi
fi

echo
echo "== 3. Bagian wajib README.md =="
REQUIRED_HEADINGS="Sekilas Tentang|Spesifikasi dan Arsitektur|Prasyarat|Instalasi|Konfigurasi|Reverse Proxy|Persistensi|Backup|Restore|Cara Pemakaian|Pengujian|Pemeliharaan dan Biaya|Keamanan Berkas Repositori|Pembahasan|Referensi"
if [ ! -f README.md ]; then
	bad "README.md tidak ditemukan"
else
	old_ifs=$IFS
	IFS='|'
	for h in $REQUIRED_HEADINGS; do
		if grep -qiE "^#{1,4} .*$h" README.md; then
			ok "bagian ditemukan: $h"
		else
			bad "bagian HILANG: $h"
		fi
	done
	IFS=$old_ifs

