#!/bin/sh
#
#

KERNEL_V=3.2.27-ubuntu-airlink-imq
PATH_EXTR=$(pwd)
PATH_TOSRC=/usr/src

clear

echo "###############################################################"
echo "#				       			      #"
echo "#	AIRLINK 1.0.1a UBUNTU 12.04 LTS INSTALLATION SCRIPT   #"
echo "#	        UBUNTU 12.04 LTS SERVER_AMD_64 ONLY	      #"
echo "#	           +IMQ Airlink Kernel,Firewall               #"
echo "#						                    #"
echo "#  Original script & Software :   fb.com/face.myface          #"
echo "#  Developer Airlink software :   fb.com/sartonice            #"
echo "#  Kernel Firewall security   :   fb.com/Lachezis	      #"
echo "#  Miscellaneous Script	    :   fb.com/soravit.shine8    #"
echo "#							            #"
echo "#							            #"
echo "#  Have a question & Support  :   sarto@airlink.in.th        #"
echo "#							            #"
echo "#	       	    http://www.airlink.in.th	     #"
echo "#        http://fb.com/groups/airlink.hotspot	           #"
echo "#						                  #"
echo "#############################################################"

sleep 9

echo "Everthing OK.. Let's Go!!!"
sleep 3
apt-get update

if [ $KERNEL_V = $(uname -r) ]; then

	echo "########"
	echo "Install and update your system"
	echo "#######"
	service apache2 stop
	service mysql stop
	echo 'ServerName 127.0.0.1' >> /etc/apache2/httpd.conf
	echo "########"
	echo "######## Upgrade Mysql to MariaDB-5.5"
	echo "#######"

	sleep 3

	sudo apt-get install -y python-software-properties
	sudo apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xcbcb082a1bb943db
#	sudo add-apt-repository 'deb http://ftp.yz.yamagata-u.ac.jp/pub/dbms/mariadb/repo/10.0/ubuntu precise main'
	sudo add-apt-repository 'deb http://ftp.yz.yamagata-u.ac.jp/pub/dbms/mariadb/repo/5.5/ubuntu precise main'
	apt-get update
	apt-get install -y mariadb-server
	apt-get install -y fail2ban build-essential libssl-dev squid php5-gd freeradius freeradius-mysql libapache2-mod-auth-mysql ssl-cert php5-curl php5-cli iptables
	apt-get clean
	clear

fi

# Check kernel to install IMQ
tar -zxvf kernel.tar.gz
cd kernel
if [ $KERNEL_V != $(uname -r) ]; then
	clear
	echo "####### "
	echo "####### Install Kernel $KERNEL_V"
	echo "####### "
	dpkg -i linux-*.deb
	cd /boot
	update-initramfs -u -k $KERNEL_V
	update-initramfs -c -k $KERNEL_V
	#sleep 2
	#apt-get autoremove -y linux-image-$(uname -r)
	#sleep 2
	rm -Rf /boot/initrd.img-3.8*
	rm -Rf /boot/vmlinuz-3.8*
	rm -Rf /boot/System.map-3.8*
	update-grub2
	clear
	echo "########"
	echo "######## Rebooting... and please run ./install.sh again !!"
	echo "########"
	sleep 5
	reboot
	exit
fi

# Compile IPTable 1.4.15 & patch IMQ
clear
echo "########"
echo "######## Compile IPTables 1.4.15 & patch IMQ"
echo "########"
sleep 3

cd kernel
tar xvjf iptables-1.4.15.tar.bz2
cd iptables-1.4.15

patch -p1 < ../iptables-1.4.13-IMQ-test1.diff
./configure --with-ksource=$PATH_TOSRC/linux-headers-$KERNEL_V
make && make install
cd ..
cd ..

# Make HTTPS Certificate
mkdir /etc/apache2/ssl
make-ssl-cert /usr/share/ssl-cert/ssleay.cnf /etc/apache2/ssl/apache.pem

#Stop Service
service apache2 stop
service freeradius stop
service squid3 stop

clear
echo "########"
echo "######## Install CoovaChilli-1.3.0"
echo "########"
sleep 3
useradd -s /sbin/nologin chilli
tar -xvf coova-chilli-1.3.0.tar.gz
cd coova-chilli-1.3.0
./configure --host=x86_64-linux-gnu --build=x86_64-linux-gnu \
        --prefix=/usr --mandir=\${prefix}/share/man --infodir=\${prefix}/share/info \
        --sysconfdir=/etc --localstatedir=/var --enable-largelimits \
        --enable-proxyvsa --enable-miniportal --enable-chilliredir \
        --enable-chilliproxy --enable-binstatusfile --enable-chilliscript \
        --enable-chilliradsec --enable-dnslog --enable-layer3 --enable-eapol \
        --enable-uamdomainfile --enable-redirdnsreq --enable-modules \
        --enable-multiroute --with-openssl --with-poll

make && make install
depmod -a
cd ..

# สร้าง  Virtual Host สำหรับ SSL Site
a2enmod ssl
/etc/init.d/apache2 force-reload


#COPY CONFIG TO SYSTEM
tar -C / -zxvf config_install.tar.gz
chmod 0440 /etc/sudoers


# File hotspot
cat > /etc/apache2/sites-available/hotspot <<EOF
NameVirtualHost *:443
<VirtualHost *:443>
        ServerAdmin webmaster@domain.org
        DocumentRoot "/opt/hotspot"
        <Directory "/opt/hotspot/">
                Options Indexes FollowSymLinks MultiViews
                AllowOverride None
                Order allow,deny
                allow from all
        </Directory>

        Alias "/dialupadmin/" "/usr/share/freeradius-dialupadmin/htdocs/"
        <Directory "/usr/share/freeradius-dialupadmin/htdocs/">
                Options Indexes FollowSymLinks MultiViews
                AllowOverride None
                Order allow,deny
                allow from all
        </Directory>

        ScriptAlias /cgi-bin/ /opt/hotspot/cgi-bin/
        <Directory "/opt/hotspot/cgi-bin/">
                AllowOverride None
                Options ExecCGI -MultiViews +SymLinksIfOwnerMatch
                Order allow,deny
                Allow from all
        </Directory>

        ErrorLog /var/log/apache2/hotspot-error.log

        LogLevel warn

        CustomLog /var/log/apache2/hotspot-access.log combined

        ServerSignature Off
        SSLEngine on
        SSLCertificateFile /etc/apache2/ssl/apache.pem
</VirtualHost>

EOF

mkdir -p /opt/hotspot/cgi-bin/
a2ensite hotspot
/etc/init.d/apache2 reload

# File ports.conf
cat > /etc/apache2/ports.conf <<EOF
Listen *:443
Listen *:80
EOF

#Install Airlink Database
clear
read -p "Enter your mysql password : " SQL_PASS
echo 'CREATE DATABASE radius DEFAULT CHARACTER SET utf8' | mysql -uroot -p$SQL_PASS
mysql -uroot -p$SQL_PASS radius < airlink.sql
clear
squid3 -z

#Setup Wizard
clear
# โหลดไฟล์ coova_wizard.sh เพื่อตั้งค่า coova-chilli
. $PATH_EXTR/coova_wizard.sh
# โหลดไฟล์ mysql_pass.sh ตั้งค่ารหัสผ่านฐานข้อมูลให้
. $PATH_EXTR/mysql_pass.sh

update-rc.d chilli defaults
chmod +x /etc/chilli/*.sh
chown -R www-data:www-data /opt/hotspot/
chown -R www-data:www-data /etc/squid3/*.txt
chown -R www-data:www-data /etc/chilli/config
chown -R www-data:www-data /etc/freeradius/clients.conf
chown -R www-data:www-data /etc/chilli/control.sh
ln -s /opt/hotspot/admin /var/www/hotspot
chmod a+x /usr/local/bin/hotspot/mysar/bin/mysar-importer.php

cat /etc/php5/cli/conf.d/mcrypt.ini | grep -v \# > /etc/php5/cli/conf.d/mcrypt.ini

/etc/init.d/apache2 reload
/etc/init.d/freeradius restart
/etc/init.d/chilli restart

clear
echo "########"
echo "######## Install phpmyadmin proftpd vnstat"
echo "########"
sleep 3

apt-get install -y phpmyadmin proftpd vnstat zip unzip rar unrar htop mytop apachetop mc

vnstat -u -i tun0

echo "########"
echo "######## Disable Apparmor"
echo "########"
sleep 3
/etc/init.d/apparmor stop
/etc/init.d/apparmor teardown
update-rc.d -f apparmor remove

sed -i "s/ Indexes / /g" /etc/apache2/sites-available/default
sed -i "s/ Indexes / /g" /etc/apache2/sites-available/default-ssl
sed -i "s/ Indexes / /g" /etc/apache2/sites-available/hotspot
sed -i "s/ ServerTokens OS/ServerTokens Prod/g" /etc/apache2/conf.d/security

sed -i "s/*.=info;*.=notice;*.=warn;/*.=info;*.=notice;/g" /etc/rsyslog.d/50-default.conf
sed -i "s/kern.*/#kern.*/g" /etc/rsyslog.d/50-default.conf

sed -i "s/exit 0/#exit 0/g" /etc/rc.local
echo '########### Edit rc.local By : Mr.Karun ##########' >> /etc/rc.local
echo '/etc/script/clearradutmp.sh' >> /etc/rc.local
echo '#/etc/init.d/chilli restart' >> /etc/rc.local
echo '##################### End Edit ###################' >> /etc/rc.local
echo 'exit 0' >> /etc/rc.local

echo '#################################################################' >> /etc/crontab
echo '################## Edit Crontab By : Mr.Karun ###################' >> /etc/crontab
echo '#################################################################' >> /etc/crontab
echo '59 23 * * * root /etc/script/changeaccess.sh' >> /etc/crontab
echo '*/59 * * * * root /etc/script/clearram.sh' >> /etc/crontab
echo '*/39 * * * * root /etc/script/nettime.sh' >> /etc/crontab
echo '#29 3 * * 1 root /etc/script/restart.sh' >> /etc/crontab
echo '49 3 1 * * root /etc/script/clearsquid.sh' >> /etc/crontab
echo '########## Block Facebook Mon - Fri : 8.00 - 12.00 AM. ##########' >> /etc/crontab
echo '#00 8 * * 1-5 root /etc/script/faceblock.iptables' >> /etc/crontab
echo '#00 12 * * 1-5 root /etc/script/facenoblock.iptables' >> /etc/crontab
echo '########################### End Edit ############################' >> /etc/crontab
echo '#################################################################' >> /etc/crontab

mkdir /data
mkdir /data/LOG
mkdir /data/LOG/squid
mkdir /data/LOG/radius
mkdir /data/LOG/secure
mkdir /data/LOG/mysql
mkdir /data/LOG/fail2ban
mkdir /data/LOG/apache2
chmod -R 755 /data/LOG

clear
echo ""
echo "|-----------------------------------------------------------------------|"
echo "|--------------| Airlink V.1.0.1a INSTALLATION COMPLETE |---------------|"
echo "|-----------------------------------------------------------------------|"
echo ""
echo "Coova-chilli reconfig. :  $PATH_EXTR/coova_wizard.sh"
echo ""
echo "Change your MySql password in config files. : $PATH_EXTR/mysql_pass.sh"
echo ""
echo "Hotspot admin management : https://<IP-ADDRESS>/admin/index.php"
echo ""
echo " User ===> airlink     Password ===> admin "
echo ""
echo "|-----------------------------------------------------------------------|"
echo "|------------| Modify Script again By : Mr.Karun Bunkhrob |-------------|"
echo "|-----------------------------------------------------------------------|"
echo "|----------------| https://www.facebook.com/bunkhrob |------------------|"
echo "|-----------------------------------------------------------------------|"
echo ""
echo " Special thank ==>> Mr.Gu!tar and Mr.Sarto nice"
echo "  www.linuxthai.org "
echo " -: facebook.com/sartonice :-"
echo ""
echo "|=======================================================================|"
echo "|---------------| Installed finish. Go to reboot System |---------------|"
echo "|=======================================================================|"
echo ""
sleep 9
reboot

#Ending script
