################################################################################
# LuaRocks package infrastructure
# see http://luarocks.org/
#
# This file implements an infrastructure that eases development of
# package .mk files for LuaRocks packages.
# LuaRocks supports various build.type : builtin, make, cmake.
# This luarocks infrastructure supports only the builtin mode,
# the make & cmake modes could be directly handled by generic & cmake infrastructure.
#
# See the Buildroot documentation for details on the usage of this
# infrastructure
#
# In terms of implementation, this LuaRocks infrastructure requires
# the .mk file to only specify metadata information about the
# package: name, version, etc.
#
################################################################################

LUAROCKS_RUN_CMD = $(STAGING_DIR)/usr/bin/luarocks
LUAROCKS_CFLAGS = $(BUILD_CFLAGS) -fPIC
LUAROCKS_CFLAGS += -DLUA_COMPAT_5_2

################################################################################
# inner-luarocks-package -- defines how the configuration, compilation and
# installation of a LuaRocks package should be done, implements a few hooks to
# tune the build process and calls the generic package infrastructure to
# generate the necessary make targets
#
#  argument 1 is the lowercase package name
#  argument 2 is the uppercase package name, including a HOST_ prefix
#             for host packages
#  argument 3 is the uppercase package name, without the HOST_ prefix
#             for host packages
#  argument 4 is the type (target or host)
################################################################################

define inner-luarocks-package

ifndef $(2)_NAME_UPSTREAM
  ifdef $(3)_NAME_UPSTREAM
    $(2)_NAME_UPSTREAM = $($(3)_NAME_UPSTREAM)
  else
    $(2)_NAME_UPSTREAM ?= $(1)
  endif
endif

ifndef $(2)_SUBDIR
  ifdef $(3)_SUBDIR
    $(2)_SUBDIR = $($(3)_SUBDIR)
  else
    $(2)_SUBDIR ?= $$($(3)_NAME_UPSTREAM)-$$(shell echo "$$($(3)_VERSION)" | sed -e "s/-[0-9]$$$$//")
  endif
endif

ifndef $(2)_ROCKSPEC
  ifdef $(3)_ROCKSPEC
    $(2)_ROCKSPEC = $($(3)_ROCKSPEC)
  else
    $(2)_ROCKSPEC ?= $$(call LOWERCASE,$$($(3)_NAME_UPSTREAM))-$$($(3)_VERSION).rockspec
  endif
endif

ifndef $(2)_SOURCE
  ifdef $(3)_SOURCE
    $(2)_SOURCE = $($(3)_SOURCE)
  else
    $(2)_SOURCE ?= $$(call LOWERCASE,$$($(3)_NAME_UPSTREAM))-$$($(3)_VERSION).src.rock
  endif
endif

ifndef $(2)_SITE
  ifdef $(3)_SITE
    $(2)_SITE = $($(3)_SITE)
  else
    $(2)_SITE ?= $$(call qstrip,$$(LUAROCKS_MIRROR))
  endif
endif

$(2)_DEPENDENCIES += luarocks

#
# Extract step. Extract into a temporary dir and move the relevant part to the
# source dir.
#
ifndef $(2)_EXTRACT_CMDS
define $(2)_EXTRACT_CMDS
	mkdir -p $$($(2)_DIR)/luarocks-extract
	cd $$($(2)_DIR)/luarocks-extract && \
		LUAROCKS_CONFIG=$$(LUAROCKS_CONFIG_FILE) \
		$$(LUAROCKS_RUN_CMD) unpack --force $$($(2)_DL_DIR)/$$($(2)_SOURCE)
	mv $$($(2)_DIR)/luarocks-extract/*/* $$($(2)_DIR)
endef
endif

#
# Build/install step.
#
ifndef $(2)_INSTALL_CMDS
define $(2)_INSTALL_CMDS
	cd $$($(2)_SRCDIR) && \
		LUAROCKS_CONFIG=$$(LUAROCKS_CONFIG_FILE) \
		$$(LUAROCKS_RUN_CMD) make --keep --deps-mode none --no-manifest \
			--tree "$$(INSTALL_DIR)/usr" \
			LUA_INCDIR="$$(STAGING_DIR)/usr/include" \
			LUA_LIBDIR="$$(STAGING_DIR)/usr/lib" \
			CC=$$(BUILD_CC) \
			LD=$$(BUILD_CC) \
			CFLAGS="$$(LUAROCKS_CFLAGS)" \
			LIBFLAG="-shared $$(BUILD_LDFLAGS)" \
			$$($(2)_BUILD_OPTS) $$($(2)_ROCKSPEC)
endef
endif

# Call the generic package infrastructure to generate the necessary
# make targets
$(call inner-generic-package,$(1),$(2),$(3),$(4))

endef

################################################################################
# luarocks-package -- the target generator macro for LuaRocks packages
################################################################################

luarocks-package = $(call inner-luarocks-package,$(pkgname),$(call UPPERCASE,$(pkgname)),$(call UPPERCASE,$(pkgname)),target)
