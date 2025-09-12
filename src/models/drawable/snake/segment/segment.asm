global segment_new, segment_destroy, segment_get_char, segment_draw, segment_get_x_position, segment_get_y_position
global SEGMENT_INTERFACE_TABLE_PTR_OFFSET, SEGMENT_POSITION_PTR_OFFSET, SEGMENT_CHAR_OFFSET, SEGMENT_DIRECTION_OFFSET, SEGMENT_NEXT_SEGMENT_PTR_OFFSET
section .rodata
segment_struct:
    SEGMENT_INTERFACE_TABLE_PTR_OFFSET equ 0
    SEGMENT_POSITION_PTR_OFFSET equ 8
    SEGMENT_CHAR_OFFSET equ 16
    SEGMENT_DIRECTION_OFFSET equ 17
    SEGMENT_NEXT_SEGMENT_PTR_OFFSET equ 25
segment_struct_end:
    SEGMENT_SIZE equ segment_struct_end - segment_struct

section .text
    extern malloc
    extern free
    extern position_new, POSITION_X_OFFSET, POSITION_Y_OFFSET
    extern interface_table_new
    extern drawable_vtable_segment
    extern GetStdHandle, SetConsoleCursorPosition, WriteConsoleA

segment_new:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    ; Expect X-Coordinates in CX
    ; Expect Y-Coordinates in DX
    ; Expect direction in R8
    mov qword [rbp - 8], r8

    lea rcx, [rel drawable_vtable_segment]
    mov rdx, 0
    call interface_table_new
    mov qword [rbp - 16], rax

    ; Save position pointer into the stack.
    call position_new
    mov qword [rbp - 24], rax


    mov rcx, SEGMENT_SIZE
    call malloc
    mov qword [rbp - 32], rax

    mov rcx, [rbp - 16]
    mov qword [rax + SEGMENT_INTERFACE_TABLE_PTR_OFFSET], rcx
    mov rcx, [rbp - 24]
    mov qword [rax + SEGMENT_POSITION_PTR_OFFSET], rcx
    mov rcx, [rbp - 8]
    mov qword [rax + SEGMENT_DIRECTION_OFFSET], rcx
    mov qword [rax + SEGMENT_NEXT_SEGMENT_PTR_OFFSET], 0

    mov rsp, rbp
    pop rbp
    ret

segment_get_char:
    ; Expect pointer to segment-object in RCX.
    mov rax, [rcx + SEGMENT_CHAR_OFFSET]
    ret

segment_get_x_position:
    ; Expect pointer to segment-object in RCX.
    mov rax, [rcx + SEGMENT_INTERFACE_TABLE_PTR_OFFSET]
    mov rax, [rax + POSITION_X_OFFSET]
    ret

segment_get_y_position:
    ; Expect pointer to segment-object in RCX.
    mov rax, [rcx + SEGMENT_INTERFACE_TABLE_PTR_OFFSET]
    mov rax, [rax + POSITION_Y_OFFSET]
    ret

segment_draw:
    ; Expect pointer to segment object in RCX.
    push rbp
    mov rbp, rsp
    sub rsp, 56

    mov qword [rbp - 8], rcx
    mov rcx, -11
    call GetStdHandle
    mov qword [rbp - 16], rax

    mov rcx, rax
    mov rax, [rbp - 8]
    mov rdx, [rax + SEGMENT_POSITION_PTR_OFFSET]
    call SetConsoleCursorPosition

    mov rcx, [rbp - 16]
    mov rdx, [rbp - 8]
    mov rdx, [rdx + SEGMENT_CHAR_OFFSET]
    mov r8, 1
    xor r9, r9
    mov qword [rsp + 40], 0
    call WriteConsoleA

    mov rsp, rbp
    pop rbp
    ret

segment_destroy:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    call free

    mov rsp, rbp
    pop rbp
    ret