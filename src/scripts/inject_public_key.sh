#!/bin/sh
# inject_public_key.sh — Generate embedded_public_key.h from /tmp/public_key.pem

set -eu

header="${SRCROOT}/utils/embedded_public_key.h"
pem="/tmp/public_key.pem"

generate() {
    cat <<-EOF
	#ifndef embedded_public_key_h
	#define embedded_public_key_h

	#define EMBEDDED_PUBLIC_KEY "$1"

	#endif
	EOF
}

if [ ! -f "${pem}" ]; then
    generate "" > "${header}"
	echo "Unable to find ${pem}, generating empty embedded_public_key.h"
    exit 0
fi

escaped=$(sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' "${pem}" | awk '{printf "%s\\n", $0}' | sed 's/\\n$//')
generate "${escaped}" > "${header}"
