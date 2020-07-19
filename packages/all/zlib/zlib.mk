################################################################################
#
# zlib
#
################################################################################

ZLIB_VERSION = 1.2.11
ZLIB_SOURCE = zlib-$(ZLIB_VERSION).tar.xz
ZLIB_SITE = http://www.zlib.net
ZLIB_LICENSE = Zlib
ZLIB_LICENSE_FILES = README

define ZLIB_CONFIGURE_CMDS
	(cd $(@D); rm -rf config.cache; \
		$(BUILD_OPTS) \
		CFLAGS="$(BUILD_CFLAGS)" \
		./configure \
		--prefix=/usr \
	)
endef

define ZLIB_BUILD_CMDS
	$(BUILD_OPTS) $(MAKE1) -C $(@D)
endef

define ZLIB_INSTALL_TARGET_CMDS
	$(MAKE1) -C $(@D) DESTDIR=$(INSTALL_DIR) LDCONFIG=true install
endef

$(eval $(generic-package))