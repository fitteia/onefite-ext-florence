# Build one extension bundle against an existing onefite-c-code checkout.
# This deliberately produces a separate archive; it does not modify C/local.
C_ROOT ?= ..
MODEL_DIR := models/florence
BUILD_DIR := $(MODEL_DIR)/build
LIBDIR ?= $(C_ROOT)/lib
INCLUDEDIR ?= $(C_ROOT)/include/external/florence
METADIR ?= $(C_ROOT)
METAOUT ?= $(C_ROOT)/META-C.json
CC ?= cc
FC = gfortran
CFLAGS ?= -O3 -fPIC -I$(MODEL_DIR) -I$(C_ROOT)/core/onefit-3.1 -I$(C_ROOT)/include
FFLAGS ?= -O3 -fPIC -ffixed-form -std=legacy

.PHONY: all clean test install
all: $(BUILD_DIR)/libonefit-external-models.a

$(BUILD_DIR):
	mkdir -p $@

$(BUILD_DIR)/Florence_c.o: $(MODEL_DIR)/Florence_c.c $(MODEL_DIR)/Florence_c.h $(MODEL_DIR)/Florence_f.h | $(BUILD_DIR)
	$(CC) $(CFLAGS) -c $< -o $@

$(BUILD_DIR)/Florence_f.o: $(MODEL_DIR)/Florence_f.f $(MODEL_DIR)/Florence_f.h | $(BUILD_DIR)
	$(FC) $(FFLAGS) -c $< -o $@

$(BUILD_DIR)/libonefit-external-models.a: $(BUILD_DIR)/Florence_c.o $(BUILD_DIR)/Florence_f.o
	ar rcs $@ $^

test:
	$(MODEL_DIR)/tests/run_tests.sh

install: all
	mkdir -p $(LIBDIR) $(INCLUDEDIR) $(METADIR)/extensions/florence
	install -m 0644 $(BUILD_DIR)/libonefit-external-models.a $(LIBDIR)/
	install -m 0644 $(MODEL_DIR)/Florence_c.h $(MODEL_DIR)/Florence_f.h $(INCLUDEDIR)/
	install -m 0644 $(MODEL_DIR)/META-C-model.json $(METADIR)/extensions/florence/
	install -m 0644 LICENSE NOTICE $(METADIR)/extensions/florence/
	python3 tools/merge-meta.py $(C_ROOT)/META-C.json $(MODEL_DIR)/META-C-model.json $(METAOUT)

clean:
	rm -rf $(BUILD_DIR)
	$(MAKE) -C $(MODEL_DIR)/tests clean 2>/dev/null || true
