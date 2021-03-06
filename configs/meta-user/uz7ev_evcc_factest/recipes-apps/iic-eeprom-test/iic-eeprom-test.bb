#
# This file is the iic-eeprom-test recipe.
#

SUMMARY = "Simple iic-eeprom-test application"
SECTION = "PETALINUX/apps"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = "file://iic_eeprom_demo.c \
       file://iic_eeprom_demo.h \
       file://iic_eeprom_test.c \
       file://main.c \
       file://platform.h \
       file://types.h \
       file://zed_iic.h \
       file://zed_iic_axi.c \
	   file://Makefile \
		  "

S = "${WORKDIR}"

FILES_${PN} += "/home/root/*"

do_compile() {
	     oe_runmake
}

do_install() {
	     install -d ${D}/home/root
	     install -m 0755 iic-eeprom-test ${D}/home/root
}
