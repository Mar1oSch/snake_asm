global food_new, food_destroy

section .rodata
    FOOD_POINTS equ 100
    FOOD_SIZE equ 64
    FOOD_VTABLE_OFFSET equ 0
    FOOD_POINTS_OFFSET equ 8
    FOOD_POSITION_OFFSET equ 16

section .text
    extern malloc
    extern free

food_new:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    mov rcx, FOOD_SIZE
    call malloc

    mov qword [rax + FOOD_POINTS_OFFSET], FOOD_POINTS
    mov rsp, rbp
    pop rbp
    ret

food_get_points:
    mov rax, FOOD_POINTS
    ret

food_destroy:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    call free

    mov rsp, rbp
    pop rbp
    ret