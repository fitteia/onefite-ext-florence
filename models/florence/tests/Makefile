MODEL_DIR ?= ..
C_ROOT ?= ../../..
CC ?= cc
FC ?= gfortran
CFLAGS ?= -O2 -fPIC -I$(MODEL_DIR)
FFLAGS ?= -O2 -ffixed-form

.PHONY: all clean
all: run

build:
	mkdir -p build
	$(FC) $(FFLAGS) $(MODEL_DIR)/Florence_f.f -o build/Florence_f.o
	$(CC) $(CFLAGS) -c $(MODEL_DIR)/Florence_c.c -o build/Florence_c.o
	$(CC) $(CFLAGS) test_driver.c build/Florence_f.o build/Florence_c.o -lgfortran -lm -o build/driver
	$(CC) $(CFLAGS) staleness_demo.c build/Florence_f.o build/Florence_c.o -lgfortran -lm -o build/staleness_demo
	$(FC) $(FFLAGS) -c test_eigensolver.f -o build/test_eigensolver.o
	$(FC) build/test_eigensolver.o build/Florence_f.o -o build/test_eigensolver

run: build
	@true

clean:
	rm -rf build
