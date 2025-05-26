# Copyright 2018 Embedded Microprocessor Benchmark Consortium (EEMBC)
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# 
# Original Author: Shay Gal-on

#File : core_portme.mak


include /f-of-e-tools/tools/sunflower/conf/setup.conf

TREEROOT = $(SUNFLOWERROOT)
GB3_ROOT = /gb3-resources

TARGET-ARCH	= riscv32-elf
TARGET		= riscv

PROGRAM		= ./coremark
PROGRAM-SF	= ./barebones/coremark-sf
INIT		= ./barebones/init
INIT-SF		= ./barebones/init-sf

INCLUDE_DIR = ../include



PORT_CFLAGS = -Os -ffreestanding -nostdlib -nodefaultlibs -fno-builtin -ffunction-sections -fdata-sections -march=rv32i -mabi=ilp32 $(TARGET-ARCH-FLAGS) -Wl,--strip-unneeded
FLAGS_STR = "$(PORT_CFLAGS) $(XCFLAGS) $(XLFLAGS) $(LFLAGS_END)"
CFLAGS = $(PORT_CFLAGS) -I$(PORT_DIR) -I. -DFLAGS_STR=\"$(FLAGS_STR)\" 
#Flag : LFLAGS_END
#	Define any libraries needed for linking or other flags that should come at the end of the link line (e.g. linker scripts). 
#	Note : On certain platforms, the default clock_gettime implementation is supported but requires linking of librt.
SEPARATE_COMPILE=1
# Flag : SEPARATE_COMPILE
# You must also define below how to create an object file, and how to link.
OBJOUT 	= -o
LFLAGS 	= -flto --gc-sections -L$(TOOLSLIB)/$(TARGET) -Map $(PROGRAM).map -Tbarebones/sail.ld
#LFLAGS = -Ttext $(LOADADDR-SF)  -L$(TOOLSLIB)/$(TARGET) -Map $(PROGRAM).map # emulator
ASFLAGS = -march=rv32i -mabi=ilp32
OFLAG 	= -o
COUT 	= -c

SREC2HEX = srec2hex
LOADADDR-SF = 0x08004000


# Flag : PORT_SRCS
# 	Port specific source files can be added here
#	You may also need cvt.c if the fcvt functions are not provided as intrinsics by your compiler!
PORT_SRCS = $(PORT_DIR)/core_portme.c $(PORT_DIR)/ee_printf.c
vpath %.c $(PORT_DIR)
vpath %.S $(PORT_DIR)


LFLAGS_END = -lc -lgcc
#LFLAGS_END = -lc -lgcc -lgloss #emulator


# Flag : LOAD
#	For a simple port, we assume self hosted compile and run, no load needed.

# Flag : RUN
#	For a simple port, we assume self hosted compile and run, simple invocation of the executable



OEXT = .o
EXE =
# FLAG : OPATH
# Path to the output folder. Default - current folder.
OPATH = ./
MKDIR = mkdir -p



$(OPATH)$(PORT_DIR)/%$(OEXT) : %.c
	$(CC) $(CFLAGS) $(XCFLAGS) $(COUT) $< $(OBJOUT) $@

$(OPATH)%$(OEXT) : %.c
	$(CC) $(CFLAGS) $(XCFLAGS) $(COUT) $< $(OBJOUT) $@

$(OPATH)$(PORT_DIR)/%$(OEXT) : %.s
	$(AS) $(ASFLAGS) $< $(OBJOUT) $@


PORT_OBJS =\
	$(INIT).o\
	$(PORT_SRCS:.c=.o) \


.PHONY: port_postbuild
port_postbuild:
	mkdir -p $(GB3_ROOT)/processor/programs/
	$(OBJCOPY) -O srec $(PROGRAM) $(PROGRAM).sr
	$(SREC2HEX) -b 8192 $(PROGRAM).sr
	cp program.hex $(GB3_ROOT)/processor/programs/
	cp data.hex $(GB3_ROOT)/processor/programs/

PORT_CLEAN =\
	init.i *.o $(PROGRAM) $(PROGRAM).sr $(PROGRAM).map \
	init-sf.i *.o $(PROGRAM-SF) $(PROGRAM-SF).sr $(PROGRAM-SF).map \
	program.hex data.hex

.PHONY : port_prebuild port_prerun port_postrun port_preload port_postload




