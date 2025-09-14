global super_food_new, super_food_destroy, super_food_get_points, super_food_get_char, super_food_get_x_position, super_food_get_y_position, super_food_draw

section .rodata
super_food_struct:
    SUPER_FOOD_INTERFACE_TABLE_PTR_OFFSET equ 0
    SUPER_FOOD_CHAR_OFFSET equ 8
    SUPER_FOOD_POINTS_OFFSET equ 9
    SUPER_FOOD_POSITION_PTR_OFFSET equ 17
super_food_end_struct:
    SUPER_FOOD_SIZE equ super_food_end_struct - super_food_struct
    SUPER_FOOD_POINTS equ 250
    SUPER_FOOD_CHAR equ "§"

section .text
    extern malloc
    extern free
    extern position_new, POSITION_X_OFFSET, POSITION_Y_OFFSET
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

    mov rcx, SUPER_FOOD_SIZE
    call malloc
    mov qword [rbp - 24], rax

    mov rcx, [rbp - 16]
    mov qword [rax + SUPER_FOOD_INTERFACE_TABLE_PTR_OFFSET], rcx

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

super_food_get_x_position:
    ; Expect pointer to super_food_object in RCX.
    mov rax, [rcx + SUPER_FOOD_POSITION_PTR_OFFSET]
    mov rax, [rax + POSITION_X_OFFSET]
    ret

super_food_get_y_position:
    ; Expect pointer to super_food_object in RCX.
    mov rax, [rcx + SUPER_FOOD_POSITION_PTR_OFFSET]
    mov rax, [rax + POSITION_Y_OFFSET]
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