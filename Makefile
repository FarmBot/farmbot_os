.PHONY: all clean
.DEFAULT_GOAL: all

MIX_ENV := $(MIX_ENV)
MIX_TARGET := $(MIX_TARGET)

ifeq ($(MIX_ENV),)
MIX_ENV := dev
endif

ifeq ($(MIX_TARGET),)
MIX_TARGET := host
endif

PROJECTS := farmbot_celery_script \
						farmbot_core \
						farmbot_ext \
						farmbot_os

all: help

help:
	@echo "Usage: "
	@echo "	make [target]"
	@echo "TARGETS: "
	@echo "	clean - clean all."

clean_other_branch:
	rm -rf _build deps c_src config tmp

clean: clean_other_branch
	@for project in $(PROJECTS) ; do \
		echo cleaning $$project ; \
		rm -rf $$project/_build ; \
		rm -rf $$project/deps ; \
		rm -rf $$project/priv/*.so ; \
	done
