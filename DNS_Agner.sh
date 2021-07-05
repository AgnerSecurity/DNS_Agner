#!/bin/bash

echo -ne '
  ___  _  _ ___     _   ___ _  _ ___ ___          
 |   \| \| / __|   /_\ / __| \| | __| _ \         
 | |) | .` \__ \  / _ \ (_ | .` | _||   /         
 |___/|_|\_|___/_/_/ \_\___|_|\_|___|_|_\ ___ ___ 
  / _ \| _ \ __| \| / __|/ _ \| | | | _ \/ __| __|
 | (_) |  _/ _|| .` \__ \ (_) | |_| |   / (__| _| 
  \___/|_| |___|_|\_|___/\___/ \___/|_|_\\___|___|
                                                  
'
sleep 5
echo -ne '
   __        _       ___                      _______            
  / /  __ __(_)__   / _ |___ ____  ___ ____  / ___/ /__ ________ 
 / /__/ // / (_-<  / __ / _ `/ _ \/ -_) __/ / /__/ / _ `/ __/ _ \
/____/\_,_/_/___/ /_/ |_\_, /_//_/\__/_/    \___/_/\_,_/_/  \___/
'

sleep 2

echo -ne '#   Iniciando configuração, esse processo pode demorar um pouco (1%)\r'
sleep 2
clear
echo -ne '#   Aplicando dns público 8.8.8.8 para baixar pacotes (2%)\r'
echo 'nameserver 8.8.8.8' > /etc/resolv.conf
clear
echo -ne '##   Atualizando sistema (5%)\r'
sleep 2
clear
yum -y update
clear
echo -ne '#####  Instalando pacotes necessarios(18%)\r'
sleep 2
clear
yum install -y ntp unbound vim bind-utils whois
clear
echo -ne '#####  Ativando NetworkManager(22%)\r'
sleep 2
clear
service NetworkManager stop 
chkconfig NetworkManager off
clear
echo -ne '#####  Manipulando Firewall(25%)\r'
sleep 2
clear
chkconfig firewalld off
service firewalld stop 
cat <<EOF > /etc/selinux/config #Desabilita Selinux
SELINUX=disabled
SELINUXTYPE=targeted
EOF
clear
echo -ne '######  Configurando NTP(30%)\r'
sleep 2
clear


chkconfig ntpd on
cat  <<EOF > /etc/ntp.conf
driftfile /var/lib/ntp/drift
restrict 127.0.0.1
restrict ::1
server 0.centos.pool.ntp.org iburst
server 1.centos.pool.ntp.org iburst
server 2.centos.pool.ntp.org iburst
server 3.centos.pool.ntp.org iburst
server 200.20.186.75
server 200.160.0.8
server 200.189.40.8
server 200.192.232.8
includefile /etc/ntp/crypto/pw
keys /etc/ntp/keys
disable monitor
restrict default kod notrap nomodify nopeer noquery
restrict -6 default kod notrap nomodify nopeer noquery
EOF

rm -rf /etc/localtime
ln -s /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime
ntpdate -u 200.20.186.75
service ntpd restart


clear
echo -ne '########  Configurando DNSlocaldomain(40%)\r'
sleep 2
clear

   
echo "recursivo"1"."site.com > /etc/hostname



ncore=`grep -c cpu[0-9] /proc/stat`
let "nmemo=($ncore*2)"


echo "" > /etc/unbound/root.key
unbound-anchor -a /etc/unbound/root.key
unbound-control-setup -d /etc/unbound
chown -R unbound:unbound /etc/unbound

cat <<EOF > /etc/unbound/unbound.conf

server:
	interface: 0.0.0.0
	interface: ::0
	port: 53
	access-control: 0.0.0.0/0 refuse 
	access-control: ::0/0 refuse
	access-control: 192.168.0.0/16 allow
        access-control: 172.16.0.0/12 allow
        access-control: 10.0.0.0/8 allow
	access-control: 100.64.0.0/10 allow
EOF


while read line
do
        echo "        access-control: $line allow" >> /etc/unbound/unbound.conf
done < prefixos.txt

cat <<EOF >> /etc/unbound/unbound.conf
	verbosity: 1
	do-ip4: "yes" 
	do-ip6: "yes" 
	do-udp: "yes" 
	do-tcp: "yes" 
	root-hints: "/etc/unbound/named.cache" 
	logfile: /etc/unbound/unbound.log 	
	auto-trust-anchor-file: "root.key" 
	harden-dnssec-stripped: "yes" 

#Cache	
	cache-min-ttl: 600
	cache-max-ttl: 86400
	prefetch: "yes" 
	num-threads: $ncore
	msg-cache-slabs: $nmemo
	rrset-cache-slabs: $nmemo
	infra-cache-slabs: $nmemo
	key-cache-slabs: $nmemo
	rrset-cache-size: 256m
	msg-cache-size: 128m
remote-control:
	control-enable: "yes" 
	control-interface: 127.0.0.1
	control-interface: ::1
	server-key-file: "/etc/unbound/unbound_server.key" 
	server-cert-file: "/etc/unbound/unbound_server.pem" 
	control-key-file: "/etc/unbound/unbound_control.key" 
	control-cert-file: "/etc/unbound/unbound_control.pem" 
EOF


cat <<EOF > /etc/unbound/named.cache
.                        3600000      NS    A.ROOT-SERVERS.NET. 
A.ROOT-SERVERS.NET.      3600000      A     198.41.0.4 
A.ROOT-SERVERS.NET.      3600000      AAAA  2001:503:ba3e::2:30 
.                        3600000      NS    B.ROOT-SERVERS.NET. 
B.ROOT-SERVERS.NET.      3600000      A     192.228.79.201 
B.ROOT-SERVERS.NET.      3600000      AAAA  2001:500:84::b 
.                        3600000      NS    C.ROOT-SERVERS.NET. 
C.ROOT-SERVERS.NET.      3600000      A     192.33.4.12 
C.ROOT-SERVERS.NET.      3600000      AAAA  2001:500:2::c 
.                        3600000      NS    D.ROOT-SERVERS.NET. 
D.ROOT-SERVERS.NET.      3600000      A     199.7.91.13 
D.ROOT-SERVERS.NET.      3600000      AAAA  2001:500:2d::d 
.                        3600000      NS    E.ROOT-SERVERS.NET. 
E.ROOT-SERVERS.NET.      3600000      A     192.203.230.10 
.                        3600000      NS    F.ROOT-SERVERS.NET. 
F.ROOT-SERVERS.NET.      3600000      A     192.5.5.241 
F.ROOT-SERVERS.NET.      3600000      AAAA  2001:500:2f::f 
.                        3600000      NS    G.ROOT-SERVERS.NET. 
G.ROOT-SERVERS.NET.      3600000      A     192.112.36.4 
.                        3600000      NS    H.ROOT-SERVERS.NET. 
H.ROOT-SERVERS.NET.      3600000      A     198.97.190.53 
H.ROOT-SERVERS.NET.      3600000      AAAA  2001:500:1::53 
.                        3600000      NS    I.ROOT-SERVERS.NET. 
I.ROOT-SERVERS.NET.      3600000      A     192.36.148.17 
I.ROOT-SERVERS.NET.      3600000      AAAA  2001:7fe::53 
.                        3600000      NS    J.ROOT-SERVERS.NET. 
J.ROOT-SERVERS.NET.      3600000      A     192.58.128.30 
J.ROOT-SERVERS.NET.      3600000      AAAA  2001:503:c27::2:30 
.                        3600000      NS    K.ROOT-SERVERS.NET. 
K.ROOT-SERVERS.NET.      3600000      A     193.0.14.129 
K.ROOT-SERVERS.NET.      3600000      AAAA  2001:7fd::1 
.                        3600000      NS    L.ROOT-SERVERS.NET. 
L.ROOT-SERVERS.NET.      3600000      A     199.7.83.42 
L.ROOT-SERVERS.NET.      3600000      AAAA  2001:500:3::42 
.                        3600000      NS    M.ROOT-SERVERS.NET. 
M.ROOT-SERVERS.NET.      3600000      A     202.12.27.33 
M.ROOT-SERVERS.NET.      3600000      AAAA  2001:dc3::35
EOF


rm prefixos.txt


chown unbound:unbound /etc/unbound/named.cache
service unbound restart
chkconfig unbound on 

echo "nameserver 127.0.0.1" > /etc/resolv.conf



