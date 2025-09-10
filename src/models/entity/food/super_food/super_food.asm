global super_food_new, super_food_destroy

section .rodata
    SUPER_FOOD_POINTS equ 250
    SUPER_FOOD_SIZE equ 64
    SUPER_FOOD_VTABLE_OFFSET equ 0
    SUPER_FOOD_POINTS_OFFSET equ 8
    SUPER_FOOD_POSITION_OFFSET equ 16

section .text
    extern malloc
    extern free

super_food_new:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    mov rcx, SUPER_FOOD_SIZE
    call malloc

    mov qword [rax + SUPER_FOOD_POINTS_OFFSET], SUPER_FOOD_POINTS
    mov rsp, rbp
    pop rbp
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