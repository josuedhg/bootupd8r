DEBUG ?=
OVMF_CODE_PATH ?=
OVMF_VARS_TEMPLATE_PATH ?=
TEST_IMAGE ?=
ROOT_PASSWORD ?=

ifeq ($(DEBUG),-v)
	Q :=
else
	Q := @
endif

check:
	$(Q)bash tests/run_all.sh $(OVMF_CODE_PATH) $(OVMF_VARS_TEMPLATE_PATH) $(TEST_IMAGE) $(ROOT_PASSWORD) $(DEBUG)

test: check
