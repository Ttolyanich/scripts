# 1) Убедимся, что есть пакет с архивными ключами Debian
apt-get update
apt-get install -y debian-archive-keyring

# 2) Создаём (или правим) deb822-источник bullseye С Signed-By
cat >/etc/apt/sources.list.d/bullseye.sources <<'EOF'
Types: deb
URIs: http://deb.debian.org/debian
Suites: bullseye
Components: main
Signed-By: /usr/share/keyrings/debian-archive-bullseye-stable.gpg
EOF

# 3) Удаляем старые .list/.sources без Signed-By (если они были)
grep -RIl --exclude='bullseye.sources' 'bullseye' /etc/apt/sources.list /etc/apt/sources.list.d 2>/dev/null \
 | xargs -r sed -n '1p'  # просто показать, что нашли
# Если увидел лишние файлы с bullseye, удали их:
# rm -f /etc/apt/sources.list.d/ИМЯ-файла.list

# 4) Обновляем индексы — предупреждение должно исчезнуть
apt-get update
