%include "../include/food/super_food_struc.inc"
%include "../include/position_struc.inc"
%include "../include/interface_table_struc.inc"

global super_food_new, super_food_destroy, super_food_get_points, super_food_get_char_ptr, super_food_get_x_position, super_food_get_y_position, super_food_draw

section .rodata
    SUPER_FOOD_POINTS equ 250
    SUPER_FOOD_CHAR equ "*"

section .text
    extern malloc
    extern free
    extern position_new
    extern interface_table_new
    extern food_vtable_super_food
    extern drawable_vtable_super_food

super_food_new:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    ; Expect X-Coordinates in CX
    ; Expect Y-Coordinates in DX
    call position_new
    mov qword [rbp - 8], rax

    lea rcx, [rel food_vtable_super_food]
    lea rdx, [rel drawable_vtable_super_food]
    call interface_table_new
    mov qword [rbp - 16], rax

    mov rcx, super_food_size
    call malloc
    mov qword [rbp - 24], rax

    mov rcx, [rbp - 16]
    mov qword [rax + super_food.interface_table_ptr], rcx

    mov byte [rax + super_food.char], SUPER_FOOD_CHAR

    mov qword [rax + super_food.points], SUPER_FOOD_POINTS

    mov rcx, [rbp - 8]
    mov qword [rax + super_food.position_ptr], rcx

    mov rsp, rbp
    pop rbp
    ret

super_food_get_char_ptr:
    lea rax, SUPER_FOOD_CHAR
    ret

super_food_get_x_position:
    ; Expect pointer to super_food_object in RCX.
    mov rax, [rcx + super_food.position_ptr]
    mov rax, [rax + position.x]
    ret

super_food_get_y_position:
    ; Expect pointer to super_food_object in RCX.
    mov rax, [rcx + super_food.position_ptr]
    mov rax, [rax + position.y]
    ret

super_food_get_points:
    mov rax, SUPER_FOOD_POINTS
    ret

super_food_draw:
    ret

super_food_destroy:
    ; Expect pointer to super_food_object in RCX.
    push rbp
    mov rbp, rsp
    sub rsp, 40

    call free

    mov rsp, rbp
    pop rbp
    ret