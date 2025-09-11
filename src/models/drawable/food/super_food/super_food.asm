global super_food_new, super_food_destroy, super_food_get_points, super_food_get_char

section .rodata
super_food:
    SUPER_FOOD_INTERFACE_TABLE_OFFSET equ 0
    SUPER_FOOD_CHAR_OFFSET equ 8
    SUPER_FOOD_POINTS_OFFSET equ 16
    SUPER_FOOD_POSITION_PTR_OFFSET equ 24
super_food_end:
    SUPER_FOOD_SIZE equ super_food_end - super_food
    SUPER_FOOD_POINTS equ 250
    SUPER_FOOD_CHAR equ "§"

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

    ; Expect X-Coordinates in RCX
    ; Expect Y-Coordinates in RDX
    call position_new
    mov qword [rbp - 8], rax

    lea rcx, [rel food_vtable_super_food]
    lea rdx, [rel drawable_vtable_super_food]
    call interface_table_new
    mov qword [rbp - 16], rax

    mov rcx, SUPER_FOOD_SIZE
    call malloc
    mov qword [rbp - 24], rax

    mov rcx, [rbp - 16]
    mov qword [rax + SUPER_FOOD_INTERFACE_TABLE_OFFSET], rcx

    mov qword [rax + SUPER_FOOD_CHAR_OFFSET], SUPER_FOOD_CHAR

    mov qword [rax + SUPER_FOOD_POINTS_OFFSET], SUPER_FOOD_POINTS

    mov rcx, [rbp - 8]
    mov qword [rax + SUPER_FOOD_POSITION_PTR_OFFSET], rcx

    mov rsp, rbp
    pop rbp
    ret

super_food_get_char:
    mov rax, SUPER_FOOD_CHAR
    ret

super_food_get_points:
    mov rax, SUPER_FOOD_POINTS
    ret

super_food_destroy:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    call free

    mov rsp, rbp
    pop rbp
    ret