%include "../include/organizer/console_manager_struc.inc"

global console_manager_new, console_manager_destroy, console_manager_setup

section .rodata
    constructor_name db "console_manager", 13, 10, 0
    fence_char db "#"

section .bss
    CONSOLE_MANAGER_PTR resq 1
    CONSOLE_MANAGER_BUFFER_SIZE resw 2
    CHAR_PTR resq 1

section .text
    extern malloc
    extern free
    extern cm_malloc_failed, object_not_created
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
    je  cm_object_failed

    mov rcx, [rel CONSOLE_MANAGER_PTR]
    call free

    mov rsp, rbp
    pop rbp
    ret

console_manager_setup:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    ; Expect board width and height in ECX 
    mov word [rbp - 8], cx
    shr rcx, 16
    mov word [rbp - 16], cx

    call empty_console
    xor rcx, rcx
    mov cx, [rbp - 8]
    shl rcx, 16
    mov cx, [rbp - 16]
    call draw_fence

    mov rsp, rbp
    pop rbp
    ret




;;;;;; PRIVATE METHODS ;;;;;;;
empty_console:
    push rbp
    mov rbp, rsp
    sub rsp, 56

    cmp qword [rel CONSOLE_MANAGER_PTR], 0
    je cm_object_failed

    call get_buffer_size

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

draw_fence:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    ; Expect Width and Height of Board in RCX
    mov word [rbp - 8], cx
    shr rcx, 16
    mov word [rbp - 16], cx

    ; Save non-volatile regs.
    mov [rbp - 24], r15

    xor r15, r15        ; Zero Height counter
.loop:
    cmp r15, 0
    je .draw_whole_line
    cmp r15w, [rbp - 16]
    je .draw_whole_line
.draw_single_char:
    mov cx, r15w
    shl rcx, 16
    mov cx, 0
    call set_cursor_position
    lea rcx, [rel fence_char] 
    call write_char
    mov cx, r15w
    shl rcx, 16
    mov cx, word [rbp - 8]
    call set_cursor_position
    lea rcx, [rel fence_char] 
    call write_char
    jmp .loop_handle

.draw_whole_line:
    xor r14, r14        ; Zeor Width counter
    .inner_loop:
        mov cx, r15w
        shl rcx, 16
        mov cx, r14w
        call set_cursor_position
        lea rcx, [rel fence_char]
        call write_char
    .inner_loop_handle:
        cmp r14w, [rbp - 8]
        je .loop_handle
        inc r14w
        jmp .inner_loop
.loop_handle:
    cmp r15w, [rbp - 16]
    je .complete
    inc r15
    jmp .loop

.complete:
    mov rsp, rbp
    pop rbp
    ret

get_buffer_size:
    push rbp
    mov rbp, rsp
    sub rsp, 56

    cmp qword [rel CONSOLE_MANAGER_PTR], 0
    je cm_object_failed

    mov rcx, [rel CONSOLE_MANAGER_PTR]
    mov rcx, [rcx + console_manager.handle]
    lea rdx, [rel CONSOLE_MANAGER_BUFFER_SIZE]
    call GetConsoleScreenBufferInfo

    xor rax, rax
    mov eax, dword [rel CONSOLE_MANAGER_BUFFER_SIZE]

    mov rsp, rbp
    pop rbp
    ret

set_cursor_position:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    ; Expect COORD struct (2 words) in rcx.
    cmp qword [rel CONSOLE_MANAGER_PTR], 0
    je cm_object_failed

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

write_char:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    ; Expect pointer to char in rcx.
    cmp qword [rel CONSOLE_MANAGER_PTR], 0
    je cm_object_failed

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
cm_object_failed:
    lea rcx, [rel constructor_name]
    call object_not_created

    mov rsp, rbp
    pop rbp
    ret

cm_malloc_failed:
    lea rcx, [rel constructor_name]
    mov rdx, rax
    call cm_malloc_failed

    mov rsp, rbp
    pop rbp
    ret