nasm -f win64 .\main.asm

link .\main.obj /Entry:_start /MACHINE:X64 /SUBSYSTEM:CONSOLE Kernel32.lib
