global _start

extern GetStdHandle
extern WriteFile
extern ReadFile
extern CreateFileA
extern GetLastError

%define FILE_CREATION_FAILED -1

section .data
    query_name  : db "What's your name? ",0
    query_age   : db "What's your age? ",0
    query_uname : db "What's your username? ",0

    tell_name   : db "Your name is: ",0
    tell_age    : db "Your age is: ",0
    tell_uname  : db "Your username is: ",0

    log_name    : db ".\query_log.txt",0

    success_create_file: db "Successfully created a file.",0xd,0xa,0
    error_create_file : db "There was an error when attempting to create a file.",0xd,0xa,0

section .bss
    name : resb 128
    age  : resb 8
    uname: resb 128

section .text
_start:
    push    rbp 
    mov     rbp, rsp

    mov     rcx, query_name
    call    write_string

    mov     rcx, name
    mov     rdx, 128
    call    read_string

    mov     rcx, query_age
    call    write_string

    mov     rcx, age
    mov     rdx, 8
    call    read_string

    mov     rcx, query_uname
    call    write_string

    mov     rcx, uname
    mov     rdx, 128
    call    read_string

    mov     rcx, tell_name
    call    write_string
    mov     rcx, name
    call    write_string

    mov     rcx, tell_age
    call    write_string
    mov     rcx, age
    call    write_string

    mov     rcx, tell_uname
    call    write_string
    mov     rcx, uname
    call    write_string

    mov     rcx, log_name
    call    create_file

    cmp     rax, FILE_CREATION_FAILED
    jz      .failed_to_create_file

    ; file creation successful
    mov     r12, rax

    mov     rcx, r12
    mov     rdx, tell_name
    call    write_to_file

    mov     rcx, r12
    mov     rdx, name
    call    write_to_file

    mov     rcx, r12
    mov     rdx, tell_age
    call    write_to_file

    mov     rcx, r12
    mov     rdx, age
    call    write_to_file

    mov     rcx, r12
    mov     rdx, tell_uname
    call    write_to_file

    mov     rcx, r12
    mov     rdx, uname
    call    write_to_file

    jmp     .done

.failed_to_create_file:
    mov     rcx, error_create_file
    call    write_string

    call    GetLastError

.done:
    mov     rsp, rbp
    pop     rbp
    ret

write_string:
    push    rbp
    mov     rbp, rsp
    push    0

    mov     r12, rcx

    mov     rcx, r12
    call    strlen
    mov     r13, rax

    call    get_stdout
    mov     r14, rax

    mov     rcx, r14
    mov     rdx, r12
    mov     r8, r13
    lea     r9, [rbp-4]
    sub     rsp, 56
    mov     dword [rsp+32], 0
    call    WriteFile
    add     rsp, 56

    mov     eax, dword [rbp-4]

    mov     rsp, rbp
    pop     rbp
    ret

; RCX -> pointer to buffer
; RDX -> max bytes to read
; 
; RAX -> bytes read
read_string:
%define READ_BUFFER r12
%define MAX_READ    r13
%define STD_IN      r14
%define BYTES_READ  rbp-4

    ; save arguments in callee preserved registers
    mov     READ_BUFFER, rcx
    mov     MAX_READ, rdx

    push    rbp
    mov     rbp, rsp
    push    0

    call    get_stdin
    mov     STD_IN, rax

    mov     rcx, STD_IN
    mov     rdx, READ_BUFFER
    mov     r8, MAX_READ
    lea     r9, [BYTES_READ]
    sub     rsp, 56
    mov     qword [rsp+32], 0
    call    ReadFile
    add     rsp, 56

    mov     eax, dword [BYTES_READ]

    mov     rsp, rbp
    pop     rbp
    ret
%undef READ_BUFFER
%undef BYTES_READ

; RCX -> file name
;
; RAX -> success (0|1)
create_file:
%define GENERIC_READ  0x80000000
%define GENERIC_WRITE 0x40000000
%define GENERIC_READ_WRITE (GENERIC_READ | GENERIC_WRITE)
%define FILE_APPEND_DATA 0x00000004
%define FILE_SHARE_READ 0x00000001
%define CREATE_ALWAYS 0x00000002
%define FILE_ATTRIBUTE_NORMAL 0x00000080

    push    rbp
    mov     rbp, rsp

;HANDLE WINAPI CreateFile(
;    LPCTSTR               lpFileName,
;    DWORD                 dwDesiredAccess,
;    DWORD                 dwShareMode,
;    LPSECURITY_ATTRIBUTES lpSecurityAttributes,
;    DWORD                 dwCreationDisposition,
;    DWORD                 dwFlagsAndAttributes,
;    HANDLE                hTemplateFile
;);

    ; name already in rcx
    mov     rdx, GENERIC_READ_WRITE ; dwDesiredAccess
    mov     r8, FILE_APPEND_DATA ; dwShareMode
    mov     r9, 0 ; lpSecurityAttributes
    push    0
    push    0 ; hTemplateFile
    push    FILE_ATTRIBUTE_NORMAL ; dwFlagsAndAttributes
    push    CREATE_ALWAYS ; dwCreationDisposition
    sub     rsp, 32
    call    CreateFileA
    add     rsp, 56

    mov     rsp, rbp
    pop     rbp
    ret

%undef GENERIC_READ
%undef GENERIC_WRITE
%undef GENERIC_READ_WRITE
%undef FILE_SHARE_READ
%undef CREATE_ALWAYS
%undef FILE_ATTRIBUTE_NORMAL

; RCX -> handle to file
; RDX -> pointer to null-terminated string
;
; RAX -> number of bytes written
write_to_file:
%define BYTES_WRITTEN rbp-16
%define FILE_HANDLE r12
%define STRING r13
%define STRING_LENGTH r14

    mov     FILE_HANDLE, rcx
    mov     STRING, rdx

    push    rbp
    mov     rbp, rsp
    sub     rsp, 16
    mov     dword [BYTES_WRITTEN], 0

    mov     rcx, STRING
    call    strlen
    mov     STRING_LENGTH, rax

    mov     rcx, FILE_HANDLE
    mov     rdx, STRING
    mov     r8, STRING_LENGTH
    lea     r9, [BYTES_WRITTEN]
    sub     rsp, 48
    mov     qword [rsp+32], 0
    call    WriteFile
    add     rsp, 64

    mov     eax, dword [BYTES_WRITTEN]
    mov     rsp, rbp
    pop     rbp
    ret

%undef BYTES_WRITTEN
%undef FILE_HANDLE
%undef STRING
%undef STRING_LENGTH

strlen:
    push    rbp
    mov     rbp, rsp

    mov     rdi, rcx

    xor     rax, rax
    mov     rcx, 512
    cld

    repne   scasb
    sub     rcx, 512
    neg     rcx
    dec     rcx
    mov     rax, rcx

    mov     rsp, rbp
    pop     rbp
    ret

get_stdin:
    push    rbp
    mov     rbp, rsp

    mov     rcx, -10
    sub     rsp, 32
    call    GetStdHandle
    add     rsp, 32
    
    mov     rsp, rbp
    pop     rbp
    ret

get_stdout:
    push    rbp
    mov     rbp, rsp

    mov     rcx, -11
    sub     rsp, 32
    call    GetStdHandle
    add     rsp, 32

    mov     rsp, rbp
    pop     rbp
    ret
