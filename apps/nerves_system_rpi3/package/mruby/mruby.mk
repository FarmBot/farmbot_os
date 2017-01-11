#############################################################
#
# mruby
#
#############################################################

MRUBY_VERSION = master
MRUBY_SITE = $(call github,mruby,mruby,$(MRUBY_VERSION))
MRUBY_LICENSE = MIT
MRUBY_LICENSE_FILES = LEGAL
MRUBY_GEMBOX = $(@D)/mrbgems/farmbot.gembox
MRUBY_CONFIG_RB = $(@D)/build_config.rb

define MRUBY_BUILD_CMDS
	cp $(NERVES_DEFCONFIG_DIR)/package/mruby/build_config.rb $(MRUBY_CONFIG_RB)
	cp $(NERVES_DEFCONFIG_DIR)/package/mruby/farmbot.gembox $(MRUBY_GEMBOX)

	export ARCH="$(ARCH)";\
	export CC="$(CC)";\
	export CFLAGS="$(CFLAGS)";\
	export CXX="$(CXX)";\
	export CXXFLAGS="$(CXXFLAGS)";\
	export LD="$(CC)";\
	export LDFLAGS="$(LDFLAGS)";\
	export AR="$(AR)";\
	export TARGET_CC="$(TARGET_CC)";\
	export TARGET_CFLAGS="$(TARGET_CFLAGS)";\
	export TARGET_CXX="$(TARGET_CXX)";\
	export TARGET_CXXFLAGS="$(TARGET_CXXFLAGS)";\
	export TARGET_LD="$(TARGET_CC)";\
	export TARGET_LDFLAGS="$(TARGET_LDFLAGS)";\
	export TARGET_AR="$(TARGET_AR)";\
		$(@D)/minirake --directory $(@D)
endef

define MRUBY_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/build/$(ARCH)/bin/mruby $(STAGING_DIR)/usr/bin/
endef

define MRUBY_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/build/$(ARCH)/bin/mruby $(TARGET_DIR)/usr/bin/
endef

$(eval $(generic-package))
