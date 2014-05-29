#!/bin/sh

COOVA_CONFIG=/etc/chilli/config
SQUID_CONFIG=/etc/squid3/localnet.txt
APACHE_CONFIG=/etc/apache2/apache2.conf
RADIUS_CLIENT=/etc/freeradius/clients.conf
HOTSPOT_CONF=/opt/hotspot/admin/system/air/config/hotspot.php
clear
. $COOVA_CONFIG

echo "|-------------------------------------------------------|"
echo "|---------- Coova-chilli configuration wizard ----------|"
echo "|-------------------------------------------------------|"
echo ""
read -p "Internal network interface [$HS_LANIF]? " NEW_HS_LANIF
if [ -z $NEW_HS_LANIF ]; then
	NEW_HS_LANIF=$HS_LANIF
fi

read -p "IP Address [$HS_UAMLISTEN]? " NEW_HS_UAMLISTEN
if [ -z $NEW_HS_UAMLISTEN ]; then
	NEW_HS_UAMLISTEN=$HS_UAMLISTEN
	FLG=1
fi

read -p "Netmask [$HS_NETMASK]? " NEW_HS_NETMASK

if [ -z $NEW_HS_NETMASK ]; then
	NEW_HS_NETMASK=$HS_NETMASK
fi

UAMLISTEN=`expr length $NEW_HS_UAMLISTEN`
NET_LEN=`expr "$UAMLISTEN"`
DHCPS=`echo | awk '{ print substr("'"$NEW_HS_UAMLISTEN"'",1,"'"$(($NET_LEN-1))"'") }'`"10"

if [ -z $FLG ]; then
	read -p "DHCP start form IP [$DHCPS]? " NEW_HS_DYNIP
	if [ -z $NEW_HS_DYNIP ]; then
		NEW_HS_DYNIP=$DHCPS
	fi
else
	read -p "DHCP start form IP [$HS_DYNIP]? " NEW_HS_DYNIP
	if [ -z $NEW_HS_DYNIP ]; then
		NEW_HS_DYNIP=$HS_DYNIP
	fi
fi

# DNS1
read -p "DNS1 [$HS_DNS1]? " NEW_HS_DNS1
if [ -z $NEW_HS_DNS1 ]; then
	NEW_HS_DNS1=$HS_DNS1
fi
# DNS2
read -p "DNS2 [$HS_DNS2]? " NEW_HS_DNS2
if [ -z $NEW_HS_DNS2 ]; then
	NEW_HS_DNS2=$HS_DNS2
fi
# Prelogin
read -p "Prelogin port (HS_UAMPORT) [$HS_UAMPORT]? " NEW_HS_UAMPORT
if [ -z $NEW_HS_UAMPORT ]; then
	NEW_HS_UAMPORT=$HS_UAMPORT
fi

read -p "Login page webui port (HS_UAMUIPORT) [$HS_UAMUIPORT]? " NEW_HS_UAMUIPORT
if [ -z $NEW_HS_UAMUIPORT ]; then
	NEW_HS_UAMUIPORT=$HS_UAMUIPORT
fi

read -p "Nas ID [$HS_NASID]? " NEW_HS_NASID
if [ -z $NEW_HS_NASID ]; then
	NEW_HS_NASID=$HS_NASID
fi

read -p "Radius server1 [$HS_RADIUS]? " NEW_HS_RADIUS
if [ -z $NEW_HS_RADIUS ]; then
	NEW_HS_RADIUS=$HS_RADIUS
fi

read -p "Radius server2 [$HS_RADIUS2]? " NEW_HS_RADIUS2
if [ -z $NEW_HS_RADIUS2 ]; then
	NEW_HS_RADIUS2=$HS_RADIUS2
fi

read -p "Url, Domain, or IP Allow [$HS_UAMALLOW]? " NEW_HS_UAMALLOW
if [ -z $NEW_HS_UAMALLOW ]; then
	NEW_HS_UAMALLOW=$HS_UAMALLOW
fi

read -p "Radius secret [$HS_RADSECRET]? " NEW_HS_RADSECRET
if [ -z $NEW_HS_RADSECRET ]; then
	NEW_HS_RADSECRET=$HS_RADSECRET
fi

read -p "Uamsecret [$HS_UAMSECRET]? " NEW_HS_UAMSECRET
if [ -z $NEW_HS_UAMSECRET ]; then
	NEW_HS_UAMSECRET=$HS_UAMSECRET
fi


UAMLISTEN=`expr length $NEW_HS_UAMLISTEN`
NET_LEN=`expr "$UAMLISTEN"`
NEW_HS_NETWORK=`echo | awk '{ print substr("'"$NEW_HS_UAMLISTEN"'",1,"'"$(($NET_LEN-1))"'") }'`"0"

sed -i "s/$HS_LANIF/$NEW_HS_LANIF/g" $COOVA_CONFIG
sed -i "s/$HS_UAMLISTEN/$NEW_HS_UAMLISTEN/g" $COOVA_CONFIG
sed -i "s/$HS_NETMASK/$NEW_HS_NETMASK/g" $COOVA_CONFIG
sed -i "s/$HS_NETWORK/$NEW_HS_NETWORK/g" $COOVA_CONFIG
sed -i "s/$HS_DYNIP/$NEW_HS_DYNIP/g" $COOVA_CONFIG
sed -i "s/HS_DNS1=$HS_DNS1/HS_DNS1=$NEW_HS_DNS1/g" $COOVA_CONFIG
sed -i "s/HS_DNS2=$HS_DNS2/HS_DNS2=$NEW_HS_DNS2/g" $COOVA_CONFIG
sed -i "s/$HS_UAMPORT/$NEW_HS_UAMPORT/g" $COOVA_CONFIG
sed -i "s/$HS_UAMUIPORT/$NEW_HS_UAMUIPORT/g" $COOVA_CONFIG
sed -i "s/$HS_NASID/$NEW_HS_NASID/g" $COOVA_CONFIG
sed -i "s/$HS_RADIUS/$NEW_HS_RADIUS/g" $COOVA_CONFIG
sed -i "s/$HS_RADIUS2/$NEW_HS_RADIUS2/g" $COOVA_CONFIG
sed -i "s/$HS_UAMALLOW/$NEW_HS_UAMALLOW/g" $COOVA_CONFIG
sed -i "s/$HS_RADSECRET/$NEW_HS_RADSECRET/g" $COOVA_CONFIG
sed -i "s/$HS_UAMSECRET/$NEW_HS_UAMSECRET/g" $COOVA_CONFIG

sed -i "s/$HS_RADSECRET/$NEW_HS_RADSECRET/g" $RADIUS_CLIENT
sed -i "s/$HS_RADSECRET/$NEW_HS_RADSECRET/g" $HOTSPOT_CONF
sed -i "s/$HS_UAMSECRET/$NEW_HS_UAMSECRET/g" $HOTSPOT_CONF

sed -i "s/$HS_NETWORK/$NEW_HS_NETWORK/g" $SQUID_CONFIG
sed -i "s/$HS_NETMASK/$NEW_HS_NETMASK/g" $SQUID_CONFIG

sed -i "s/ServerName $HS_UAMLISTEN/ServerName $NEW_HS_UAMLISTEN/g" $APACHE_CONFIG

echo ""
echo "Writing configuration file /etc/chilli/config"
sleep 2
echo ""
echo "Coova-chilli configuration complete..."
sleep 2
echo ""

if [ -z $PATH_TOSRC ]; then
	/etc/init.d/apache2 reload
	/etc/init.d/freeradius restart
	/etc/init.d/chilli restart
	/usr/sbin/squid3 -k reconfigure
	vnstat -u -i tun0
fi
