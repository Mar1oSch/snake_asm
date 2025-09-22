
%include "../include/interface_table_struc.inc"
%include "../include/position_struc.inc"
%include "../include/snake/unit_struc.inc"

global unit_new, unit_destroy, unit_get_char_ptr, unit_draw, unit_get_x_position, unit_get_y_position, unit_update

section .rodata
    constructor_name db "unit_new", 0

section .text
    extern malloc
    extern free
    extern printf
    extern position_new
    extern interface_table_new
    extern drawable_vtable_unit
    extern GetStdHandle, SetConsoleCursorPosition, WriteConsoleA
    extern malloc_failed

;;;;;; PUBLIC FUNCTIONS ;;;;;;
unit_new:
    push rbp
    mov rbp, rsp
    sub rsp, 72

    ; Expect X- and Y-Coordinates in ECX
    ; Expect direction in RDX
    mov [rbp - 8], rdx

    ; Save position pointer into the stack.
    call position_new
    mov [rbp - 16], rax

    lea rcx, [rel drawable_vtable_unit]
    mov rdx, 0
    call interface_table_new
    mov qword [rbp - 24], rax

    mov rcx, unit_size
    call malloc
    test rax, rax
    jz _u_malloc_failed
    mov qword [rbp - 32], rax

    mov rcx, [rbp - 24]
    mov qword [rax + unit.interface_table_ptr], rcx
    mov rcx, [rbp - 16]
    mov qword [rax + unit.position_ptr], rcx
    mov byte [rax + unit.char], "O"
    mov rcx, [rbp - 8]
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

unit_destroy:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    call free

    mov rsp, rbp
    pop rbp
    ret

unit_update:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    ; Expect pointer to unit object in RCX.
    ; Expect direction in RDX.
    mov [rbp - 8], rcx
    mov [rbp - 16], rdx

    call _update_position

    mov rcx, [rbp - 8]
    mov rdx, [rbp - 16]
    call _update_direction

    mov rsp, rbp
    pop rbp
    ret




;;;;;; PRIVATE FUNCTIONS ;;;;;;
_update_position:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    ; Expect pointer to unit in RCX.
    mov [rbp - 8], rcx
    mov rdx, [rcx + unit.position_ptr]
    mov [rbp - 16], rdx                             ; Save position pointer of unit.

    mov r8, [rcx + unit.direction]
    cmp r8, 0
    je .left
    cmp r8, 1
    je .up
    cmp r8, 2
    je .right
    cmp r8, 3
    je .down
    call _u_direction_error

; Update the position of the unit depending on its direction.
.left:
    dec word [rdx + position.x]
    jmp .complete
.up:
    dec word [rdx + position.y]
    jmp .complete
.right:
    inc word [rdx + position.x]
    jmp .complete
.down:
    inc word [rdx + position.y]

.complete:
    mov rsp, rbp
    pop rbp
    ret

_update_direction:
    ; Expect pointer to unit object in RCX.
    ; Expect new direction in RDX.
    mov [rcx + unit.direction], rdx
    ret

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
_u_direction_error:
    lcl_direction_error db "Direction is illegal: %d"

    ; Expect pointer to unit object in RCX.
    push rbp
    mov rbp, rsp
    sub rsp, 40

    mov [rbp - 8], rcx
    lea rcx, [rel lcl_direction_error]
    mov rdx, [rbp - 8]
    mov rdx, [rdx + unit.direction]
    call printf

    mov rsp, rbp
    pop rbp
    ret