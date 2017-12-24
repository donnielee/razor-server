#!/bin/sh
wget --tries=0 http://boot.ipxe.org/undionly.kpxe -O /tftpboot/undionly.kpxe
cp /tmp/bootstrap.ipxe /tftpboot/bootstrap.ipxe
chmod +x /tftpboot/bootstrap.ipxe
chmod +x /tftpboot/undionly.kpxe
dnsmasq  \
	--dhcp-match=IPXEBOOT,175 \
	--enable-tftp \
	--dhcp-range=10.11.11.0,static \
	--dhcp-host=c8:60:00:de:ba:76,10.11.11.201 \
	--tftp-root=/tftpboot \
	--dhcp-boot=net:IPXEBOOT,bootstrap.ipxe \
	--dhcp-boot=undionly.kpxe \
	--log-dhcp \
	--no-daemon
#	--dhcp-range=10.11.11.201,10.11.11.202 \
#	--dhcp-range=10.11.11.1,proxy \
#	--port=0 \
#	--bind-dynamic \
