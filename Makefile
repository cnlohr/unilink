all : universal_tool

AFLAGS:=-g -no-pie -mtune=generic -march=x86-64 -nostartfiles -nodefaultlibs
LDFLAGS:=-Tunilink.ld -Wl,--gc-sections

universal_tool.elf : universal_tool.S
	gcc $(AFLAGS) $(LDFLAGS) -o $@ $^

universal_tool : universal_tool.elf
	size $^
	objcopy -j .init -j .text -O binary $^ $@
	objcopy --only-keep-debug $^ $@.debug

debug : universal_tool
	gdb -ex "symbol-file universal_tool.debug" universal_tool 

clean :
	rm -rf *.o *~ universal_tool universal_tool.elf
