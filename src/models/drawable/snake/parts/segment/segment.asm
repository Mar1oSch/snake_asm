global segment_new, segment_destroy, segment_get_char

section .rodata
segment:
    SEGMENT_INTERFACE_TABLE_OFFSET equ 0
    SEGMENT_POSITION_PTR_OFFSET equ 8
    SEGMENT_CHAR_OFFSET equ 16
    SEGMENT_DIRECTION_OFFSET equ 24
    SEGMENT_NEXT_SEGMENT_PTR_OFFSET equ 32
segment_end:
    SEGMENT_SIZE equ segment_end - segment
    SEGMENT_CHAR equ "o"

section .text
    extern malloc
    extern free
    extern position_new

segment_new:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    ; Expect X-Coordinates in RCX
    ; Expect Y-Coordinates in RDX
    ; Expect direction in R8
    ; Save position pointer into the stack.
    mov qword [rbp - 8], r8

    call position_new
    mov qword [rbp - 16], rax

    mov rcx, SEGMENT_SIZE
    call malloc

    mov qword [rbp - 24], rax
    mov rcx, [rbp - 16]
    mov qword [rax + SEGMENT_POSITION_PTR_OFFSET], rcx
    mov qword [rax + SEGMENT_CHAR_OFFSET], SEGMENT_CHAR
    mov rcx, [rbp - 8]
    mov qword [rax + SEGMENT_DIRECTION_OFFSET], rcx
    mov qword [rax + SEGMENT_NEXT_SEGMENT_PTR_OFFSET], 0

    mov rsp, rbp
    pop rbp
    ret

segment_get_char:
    mov rax, SEGMENT_CHAR
    ret

segment_destroy:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    call free

    mov rsp, rbp
    pop rbp
    ret