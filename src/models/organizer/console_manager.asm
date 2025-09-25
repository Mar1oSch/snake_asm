%include "../include/organizer/console_manager_struc.inc"

global console_manager_new, console_manager_destroy, console_manager_setup, console_manager_write, console_manager_move_cursor, console_manager_erase

section .rodata
    constructor_name db "console_manager", 13, 10, 0
    erase_char db " "

section .bss
    CONSOLE_MANAGER_PTR resq 1
    CONSOLE_MANAGER_BUFFER_SIZE resw 2
    CHAR_PTR resq 1

section .text
    extern malloc
    extern free
    extern malloc_failed, object_not_created
    extern GetStdHandle, printf
    extern SetConsoleCursorPosition, WriteConsoleA
    extern GetConsoleScreenBufferInfo, FillConsoleOutputCharacterA
    extern printf

;;;;;; PUBLIC METHODS ;;;;;;
console_manager_new:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    cmp qword [rel CONSOLE_MANAGER_PTR], 0
    jne .complete

    mov rcx, console_manager_size
    call malloc
    mov [rel CONSOLE_MANAGER_PTR], rax

    mov rcx, -11
    call GetStdHandle
    mov rcx, [rel CONSOLE_MANAGER_PTR]
    mov [rcx + console_manager.handle], rax

.complete:
    mov rax, [rel CONSOLE_MANAGER_PTR]
    mov rsp, rbp
    pop rbp
    ret

console_manager_destroy:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    cmp qword [rel CONSOLE_MANAGER_PTR], 0
    je  _cm_object_failed

    mov rcx, [rel CONSOLE_MANAGER_PTR]
    call free

    mov rsp, rbp
    pop rbp
    ret

console_manager_write:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    ; Expect X- and Y-Coordinates in ECX
    ; Expect pointer to char in RDX.
    mov [rbp - 8], rdx
    call _cm_set_cursor_position

    mov rcx, [rbp - 8]
    call _cm_write_char

    mov rsp, rbp
    pop rbp
    ret

console_manager_setup:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    call _cm_empty_console

    mov rsp, rbp
    pop rbp
    ret

console_manager_erase:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    ; Expect Position-X and Position-Y in ECX.
    call _cm_set_cursor_position

    lea rcx, [rel erase_char]
    call _cm_write_char

    mov rsp, rbp
    pop rbp
    ret

console_manager_move_cursor:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    ; Expect Position-X and Position-Y in ECX. 
    call _cm_set_cursor_position

    mov rsp, rbp
    pop rbp
    ret




;;;;;; PRIVATE METHODS ;;;;;;;
_cm_empty_console:
    push rbp
    mov rbp, rsp
    sub rsp, 56

    cmp qword [rel CONSOLE_MANAGER_PTR], 0
    je _cm_object_failed

    call _cm_get_buffer_size

    mov word[rbp- 8], ax
    shr rax, 16
    mov word[rbp - 16], ax

    mov rdx, [rel CONSOLE_MANAGER_PTR]
    mov rcx, [rdx + console_manager.handle]
    mov rdx, " "
    movzx r8, word [rbp - 8]
    movzx r9, word [rbp - 16]
    imul r8, r9
    xor r9, r9
    lea r10, [rel CHAR_PTR]
    mov qword [rsp + 32], r10
    call FillConsoleOutputCharacterA

    mov rsp, rbp
    pop rbp
    ret

_cm_get_buffer_size:
    push rbp
    mov rbp, rsp
    sub rsp, 56

    cmp qword [rel CONSOLE_MANAGER_PTR], 0
    je _cm_object_failed

    mov rcx, [rel CONSOLE_MANAGER_PTR]
    mov rcx, [rcx + console_manager.handle]
    lea rdx, [rel CONSOLE_MANAGER_BUFFER_SIZE]
    call GetConsoleScreenBufferInfo

    xor rax, rax
    mov eax, dword [rel CONSOLE_MANAGER_BUFFER_SIZE]

    mov rsp, rbp
    pop rbp
    ret

_cm_set_cursor_position:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    ; Expect COORD struct (2 words) in RCX.
    cmp qword [rel CONSOLE_MANAGER_PTR], 0
    je _cm_object_failed

    mov word [rbp - 8], cx
    shr rcx, 16
    mov word [rbp - 16], cx

    mov rcx, [rel CONSOLE_MANAGER_PTR]
    mov rcx, [rcx + console_manager.handle]
    mov dx, [rbp - 8]
    shl rdx, 16
    mov dx, [rbp - 16]
    call SetConsoleCursorPosition

    mov rsp, rbp
    pop rbp
    ret

_cm_write_char:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    ; Expect pointer to char in rcx.
    cmp qword [rel CONSOLE_MANAGER_PTR], 0
    je _cm_object_failed

    mov [rbp - 8], rcx

    mov rcx, [rel CONSOLE_MANAGER_PTR]
    mov rcx, [rcx + console_manager.handle]
    mov rdx, [rbp - 8]
    mov r8, 1
    mov r9, 0
    xor rax, rax
    call WriteConsoleA

    mov rsp, rbp
    pop rbp
    ret




;;;;;; ERROR HANDLING ;;;;;;
_cm_object_failed:
    lea rcx, [rel constructor_name]
    call object_not_created

    mov rsp, rbp
    pop rbp
    ret

_cm_malloc_failed:
    lea rcx, [rel constructor_name]
    mov rdx, rax
    call malloc_failed

    mov rsp, rbp
    pop rbp
    ret