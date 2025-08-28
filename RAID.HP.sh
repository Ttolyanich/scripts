# 1) sudoers для zabbix (как у тебя)
cat << 'EOF' | sudo tee /etc/sudoers.d/zabbix_mdadm
zabbix ALL=(ALL) NOPASSWD: /usr/sbin/ssacli
EOF

# 2) Юзерпараметр для Zabbix Agent 2 (как у тебя)
sudo install -d -m 0755 -o root -g root /etc/zabbix/zabbix_agent2.d
cat << 'EOF' | sudo tee /etc/zabbix/zabbix_agent2.d/mdadm.conf
UserParameter=mdadm.status,echo $(sudo /usr/sbin/ssacli ctrl slot=0 ld all show status | grep logicaldrive | grep -c -v OK)
EOF

# 3) Инструменты
sudo apt update
sudo apt install -y curl gpg

# 4) Ключи HPE: складываем в общий keyring и используем signed-by
#    (HPE рекомендует установить все три ключа для старых и новых пакетов)
sudo mkdir -p /usr/share/keyrings
curl -fsSL https://downloads.linux.hpe.com/SDR/hpPublicKey2048_key1.pub  | gpg --dearmor | sudo tee -a /usr/share/keyrings/hpePublicKey.gpg >/dev/null
curl -fsSL https://downloads.linux.hpe.com/SDR/hpePublicKey2048_key1.pub | gpg --dearmor | sudo tee -a /usr/share/keyrings/hpePublicKey.gpg >/dev/null
curl -fsSL https://downloads.linux.hpe.com/SDR/hpePublicKey2048_key2.pub | gpg --dearmor | sudo tee -a /usr/share/keyrings/hpePublicKey.gpg >/dev/null
sudo chmod 0644 /usr/share/keyrings/hpePublicKey.gpg

# 5) Репозиторий HPE SDR MCP (для Debian) — используем ветку bookworm/current
#    т.к. на момент 2025-08-27 директории trixie у HPE нет
echo "deb [signed-by=/usr/share/keyrings/hpePublicKey.gpg] https://downloads.linux.hpe.com/SDR/repo/mcp bookworm/current non-free" | sudo tee /etc/apt/sources.list.d/hp-mcp.list >/dev/null

# 6) Установка ssacli
sudo apt update
sudo apt install -y ssacli

# (опционально) перезапуск агента Zabbix, если нужно:
# sudo systemctl restart zabbix-agent2
