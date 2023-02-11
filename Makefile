
start:
	/bin/bash dev.sh TOMEKWLOD_IO_FLAG

.PHONY: build
build:
	/bin/bash build.sh

testport:
	/bin/bash testport.sh

fix:
	yarn style:fix

test:
	/bin/bash test.sh	



# preprocessor:
# 	@node lib/preprocessor.js
