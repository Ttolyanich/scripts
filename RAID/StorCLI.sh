cat << 'EOF' > /etc/sudoers.d/zabbix_mdadm
zabbix ALL=(ALL) NOPASSWD: /usr/sbin/storcli, /etc/zabbix/scripts/mdadm.status.sh
EOF
cat << 'EOF' > /etc/zabbix/zabbix_agent2.d/mdadm.conf
UserParameter=mdadm.status,sudo /etc/zabbix/scripts/mdadm.status.sh
EOF
mkdir -p /etc/zabbix/scripts
cat << 'EOF' > /etc/zabbix/scripts/mdadm.status.sh
#!/usr/bin/bash
echo $(storcli /c0 /vall show | grep RAID | grep -v Optl | wc -l)
EOF
chown zabbix:zabbix /etc/zabbix/scripts/mdadm.status.sh
chmod u+x /etc/zabbix/scripts/mdadm.status.sh
wget https://downloads.linux.hpe.com/SDR/repo/mcp/debian/pool/non-free/storcli-007.3210.0000.0000-1_amd64.deb 
dpkg -i storcli-007.3210.0000.0000-1_amd64.deb
ln -s /opt/MegaRAID/storcli/storcli64 /usr/sbin/storcli
