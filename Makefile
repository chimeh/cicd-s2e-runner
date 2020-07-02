all: build


.ONESHELL:
configure: clone
	cd scurl
	./buildconf
	./configure --disable-shared --enable-static --prefix=/tmp/curl --disable-ldap --disable-sspi --without-librtmp --disable-ftp --disable-file --disable-dict --disable-telnet --disable-tftp --disable-rtsp --disable-pop3 --disable-imap --disable-smtp --disable-gopher --disable-smb --without-libidn --disable-ares --disable-zlib  --disable-libcurl-option   --without-ssl

.ONESHELL:
clone:
	if [[ -d scurl ]];then
	cd scurl;git pull;
	else
	git clone --depth=1 https://github.com/curl/curl.git scurl
	fi
.PHONY: build
ubuntu: configure
	make -j $$(getconf _NPROCESSORS_CONF) -C scurl
	mkdir -p _dest
	mkdir -p _bin
	DESTDIR=$$(pwd)/_dest make install-strip -C scurl
	cp _dest/tmp/curl/bin/curl _bin/scurl


docker:
	bash ./scripts/docker.sh
