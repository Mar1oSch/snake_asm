
%include "../include/strucs/interface_table_struc.inc"
%include "../include/strucs/position_struc.inc"
%include "../include/strucs/snake/unit_struc.inc"

global unit_new, unit_destroy, unit_get_char_ptr, unit_draw, unit_get_x_position, unit_get_y_position, unit_reset

section .rodata
    UNIT_CHAR equ "O"

    constructor_name db "unit_new", 0

section .text
    extern malloc, free

    extern position_new, position_destroy
    extern interface_table_new, interface_table_destroy
    extern drawable_vtable_unit
    extern malloc_failed

;;;;;; PUBLIC METHODS ;;;;;;
unit_new:
    push rbp
    mov rbp, rsp
    sub rsp, 72

    ; Expect X- and Y-Coordinates in ECX
    ; Expect direction in RDX
    ; Expect Unit-Char or 0 in R8B
    mov [rbp - 8], rdx
    mov byte [rbp - 16], r8b

    call position_new
    mov [rbp - 24], rax                     ; Save position pointer.

    lea rcx, [rel drawable_vtable_unit]
    mov rdx, 0
    call interface_table_new
    mov qword [rbp - 32], rax               ; Save interface_table_pointer

    mov rcx, unit_size
    call malloc
    test rax, rax
    jz _u_malloc_failed

    mov rcx, [rbp - 32]
    mov qword [rax + unit.interface_table_ptr], rcx
    mov rcx, [rbp - 24]
    mov qword [rax + unit.position_ptr], rcx
    mov rcx, [rbp - 8]
    mov qword [rax + unit.direction], rcx
    mov qword [rax + unit.next_unit_ptr], 0
    cmp byte [rbp - 16], 0
    jne .head_char
    mov byte [rax + unit.char], UNIT_CHAR
    jmp .complete

.head_char:
    mov r8b, byte [rbp - 16]
    mov [rax + unit.char], r8b

.complete:
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

unit_destroy:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    call free

    mov rsp, rbp
    pop rbp
    ret

unit_reset:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    ; Expect unit-pointer in RCX.
    mov [rbp - 8], rcx

    mov rcx, [rcx + unit.position_ptr]
    call position_destroy

    mov rcx, [rbp - 8]
    mov rcx, [rcx + unit.interface_table_ptr]
    call interface_table_destroy

    mov rcx, [rbp - 8]
    call unit_destroy

    mov rsp, rbp
    pop rbp
    ret




;;;;;; PRIVATE METHODS ;;;;;;


;;;;;; DRAWABLE INTERFACE ;;;;;;
unit_get_char_ptr:
    ; Expect pointer to unit-object in RCX.
    lea rax, [rcx + unit.char]
    ret

unit_get_x_position:
    ; Expect pointer to unit-object in RCX.
    mov rax, [rcx + unit.position_ptr]
    movzx rax, word [rax + position.x]
    ret

unit_get_y_position:
    ; Expect pointer to unit-object in RCX.
    mov rax, [rcx + unit.position_ptr]
    movzx rax, word [rax + position.y]
    ret

;;;;;; ERROR HANDLING ;;;;;;
_u_malloc_failed:
    lea rcx, [rel constructor_name]
    mov rdx, rax
    call malloc_failed

    mov rsp, rbp
    pop rbp
    ret