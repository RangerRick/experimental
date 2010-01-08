#!/bin/sh

for FILE in \
	common/crypto/finkinfo/boo.* \
	common/crypto/finkinfo/*-sharp* \
	common/crypto/finkinfo/gtk* \
	common/crypto/finkinfo/libgdiplus.* \
	common/crypto/finkinfo/mono* \
	common/main/finkinfo/devel/nant.* \
	common/main/finkinfo/languages/mono.* \
	common/main/finkinfo/languages/ikvm.* \
	common/main/finkinfo/libs/*-sharp* \
	common/main/finkinfo/utils/mono* \
	common/main/finkinfo/web/mono* \
; do
	./tounstable.pl --prefix=/pc "$FILE"
done
