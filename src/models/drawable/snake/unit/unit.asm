
%include "../include/interface_table_struc.inc"
%include "../include/position_struc.inc"
%include "../include/snake/unit_struc.inc"

global unit_new, unit_destroy, unit_get_char, unit_draw, unit_get_x_position, unit_get_y_position

section .rodata
    constructor_name db "unit_new", 0

section .text
    extern malloc
    extern free
    extern position_new
    extern interface_table_new
    extern drawable_vtable_unit
    extern GetStdHandle, SetConsoleCursorPosition, WriteConsoleA
    extern malloc_failed

unit_new:
    push rbp
    mov rbp, rsp
    sub rsp, 72

    ; Expect X-Coordinates in CX
    ; Expect Y-Coordinates in DX
    ; Expect direction in R8
    mov qword [rbp - 8], r8

    ; Save position pointer into the stack.
    call position_new
    mov qword [rbp - 16], rax

    lea rcx, [rel drawable_vtable_unit]
    mov rdx, 0
    call interface_table_new
    mov qword [rbp - 24], rax

    mov rcx, unit_size
    call malloc
    test rax, rax
    jz .failed
    mov qword [rbp - 32], rax

    mov rcx, [rbp - 24]
    mov qword [rax + unit.interface_table_ptr], rcx
    mov rcx, [rbp - 16]
    mov qword [rax + unit.position_ptr], rcx
    mov rcx, [rbp - 8]
    mov byte [rax + unit.char], "o"
    mov qword [rax + unit.direction], rcx
    mov qword [rax + unit.next_unit_ptr], 0

    mov rsp, rbp
    pop rbp
    ret

.failed:
    lea rcx, [rel constructor_name]
    mov rdx, rax
    call malloc_failed

    mov rsp, rbp
    pop rbp
    ret

unit_get_char:
    ; Expect pointer to unit-object in RCX.
    mov rax, [rcx + unit.char]
    ret

unit_get_x_position:
    ; Expect pointer to unit-object in RCX.
    mov rax, [rcx + unit.position_ptr]
    mov rax, [rax + position.x]
    ret

unit_get_y_position:
    ; Expect pointer to unit-object in RCX.
    mov rax, [rcx + unit.position_ptr]
    mov rax, [rax + position.y]
    ret

unit_draw:
    ; Expect pointer to unit object in RCX.
    ; Expect Console Handle in RDX

    push rbp
    mov rbp, rsp
    sub rsp, 56

    mov [rbp - 8], rcx         ; Push unit object onto the stack.
    mov [rbp - 16], rdx          ; Push handle onto the stack.

    mov rax, rcx
    mov rcx, rdx
    mov rdx, [rax + unit.position_ptr]
    call SetConsoleCursorPosition

    mov rcx, [rbp - 16]
    mov rdx, [rbp - 8]
    mov rdx, [rdx + unit.char]
    mov r8, 1
    xor r9, r9
    mov qword [rsp + 40], 0
    call WriteConsoleA

    mov rsp, rbp
    pop rbp
    ret

unit_destroy:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    call free

    mov rsp, rbp
    pop rbp
    ret