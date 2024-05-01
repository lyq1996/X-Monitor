#!/bin/sh

#check argv
#signature -g output_dir
#signature -s -k private_key.pem macho_file
#signature -w -k public_key.pem source_file.m

#check otool version

#check mach-o fat header

#remove codesign

#for each mach-o
# 1. dump __TEXT,__text section
# 2. calcuate sha256 hash
# 3. encrypt sha256 using private key, get signature
# 4. store signature into mach-o __X_CUSTOM, __signature section

# codesign with adhoc

