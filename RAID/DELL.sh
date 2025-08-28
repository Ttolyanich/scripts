#!/usr/bin/env bash
set -Eeuo pipefail

# ---------- Конфиг ----------
SUDOERS_FILE="/etc/sudoers.d/zabbix_mdadm"
ZBX_SCRIPTS_DIR="/etc/zabbix/scripts"
ZBX_SCRIPT="${ZBX_SCRIPTS_DIR}/mdadm.status.sh"
ZBX_AGENT_D_DIR="/etc/zabbix/zabbix_agent2.d"
ZBX_USERPARAM="${ZBX_AGENT_D_DIR}/mdadm.conf"
MEGACLI_BIN="/usr/sbin/megacli"

# ---------- Проверки ----------
if [[ $EUID -ne 0 ]]; then
  echo "Запусти скрипт от root (sudo -i)"
  exit 1
fi

apt-get update -y || true
apt-get install -y curl gpg ca-certificates

# ---------- Зависимости из bullseye ----------
echo "Добавляем bullseye для libncurses5 и daemon..."
cat >/etc/apt/sources.list.d/bullseye.sources <<EOF
Types: deb
URIs: http://deb.debian.org/debian
Suites: bullseye
Components: main
EOF

cat >/etc/apt/preferences.d/zz-megacli-deps.pref <<EOF
Package: libncurses5
Pin: release n=bullseye
Pin-Priority: 501

Package: daemon
Pin: release n=bullseye
Pin-Priority: 501
EOF

apt-get update
apt-get install -y -t bullseye libncurses5 daemon

# ---------- Скачивание MegaCLI ----------
echo "Скачиваем и устанавливаем MegaCLI..."
tmpdir="$(mktemp -d)"
arch="$(dpkg --print-architecture)"

case "$arch" in
  amd64)
    url_cli="https://hwraid.le-vert.net/debian/pool-bullseye/megacli/megacli_8.07.14-3+Debian.11.bullseye_amd64.deb"
    ;;
  i386)
    url_cli="https://hwraid.le-vert.net/debian/pool-bullseye/megacli/megacli_8.07.14-3+Debian.11.bullseye_i386.deb"
    ;;
  *)
    echo "Unsupported arch: $arch"
    exit 1
    ;;
esac

url_stat="https://hwraid.le-vert.net/debian/pool-bullseye/megaclisas-status/megaclisas-status_0.18+Debian.11.bullseye_all.deb"

( cd "$tmpdir"
  curl -fLO "$url_cli"
  curl -fLO "$url_stat"
  dpkg -i ./*.deb || apt-get -f install -y
)

rm -rf "$tmpdir"

# ---------- sudoers ----------
echo "Настраиваем sudoers..."
cat >"$SUDOERS_FILE" <<EOF
zabbix ALL=(ALL) NOPASSWD: ${MEGACLI_BIN}, ${ZBX_SCRIPT}
EOF
chmod 440 "$SUDOERS_FILE"

# ---------- Zabbix-скрипт ----------
echo "Создаём скрипт для Zabbix..."
install -d -m 0755 "$ZBX_SCRIPTS_DIR"
cat >"$ZBX_SCRIPT" <<'EOF'
#!/bin/bash
sudo /usr/sbin/megacli -AdpAllInfo -aALL | grep Degraded | awk '{print $3}'
EOF
chmod +x "$ZBX_SCRIPT"

install -d -m 0755 "$ZBX_AGENT_D_DIR"
echo "UserParameter=mdadm.status,sudo $ZBX_SCRIPT" > "$ZBX_USERPARAM"

# ---------- Проверка ----------
if [[ -x "$MEGACLI_BIN" ]]; then
  echo "MegaCLI установлен: $($MEGACLI_BIN -v 2>/dev/null | head -n1)"
else
  echo "Ошибка: $MEGACLI_BIN не найден"
  exit 1
fi

echo "Готово. Zabbix UserParameter: mdadm.status"
