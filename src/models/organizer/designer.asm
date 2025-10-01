%include "../include/organizer/designer_struc.inc"
%include "../include/organizer/console_manager_struc.inc"

global designer_new, designer_destroy, designer_start_screen, designer_clear, designer_type_sequence

section .rodata
;;;;;; START SCREEN ;;;;;;
headline_table:
    dq .line1
    dq .line2
    dq .line3
    dq .line4
    dq .line5
    dq .line6
    dq .line7
    dq .line8

    .line1 db "  SSSSSS    NNN     NNN    AAAAAAA    KKK    KKK   EEEEEEEEE",13,10, 0
    .line2 db "SSSSSSSSSS  NNNN    NNN   AAAAAAAAA   KKK   KKK    EEEEEEEEE",13,10, 0
    .line3 db "SSSS        NNNNN   NNN   AAA   AAA   KKK  KKK     EEE",13,10, 0
    .line4 db " SSSSS      NNN NN  NNN   AAAAAAAAA   KKKKKK       EEEEEEEE",13,10, 0
    .line5 db "  SSSSS     NNN  NN NNN   AAAAAAAAA   KKK KKK      EEEEEEEE",13,10, 0
    .line6 db "     SSSS   NNN   NNNNN   AAA   AAA   KKK  KKK     EEE",13,10, 0
    .line7 db "SSSSSSSSS   NNN    NNNN   AAA   AAA   KKK   KKK    EEEEEEEEE",13,10, 0
    .line8 db "  SSSSS     NNN     NNN   AAA   AAA   KKK    KKK   EEEEEEEEE",13,10,0

by:
  db "by Mario Schanzenbach", 0
by_end:

by_length equ by_end - by

section .bss
    DESIGNER_PTR resq 1

section .text
    extern malloc, free
    extern Sleep

    extern console_manager_new, console_manager_print_word, console_manager_clear, console_manager_move_cursor_to_end, console_manager_print_char

designer_new:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    cmp qword [rel DESIGNER_PTR], 0
    jne .complete

    mov rcx, designer_size
    call malloc
    mov [rel DESIGNER_PTR], rax

    call console_manager_new
    mov rcx, [rel DESIGNER_PTR]
    mov [rcx + designer.console_manager_ptr], rax

.complete:
    mov rax, [rel DESIGNER_PTR]

    mov rsp, rbp
    pop rbp
    ret

designer_destroy:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    mov rcx, [rel DESIGNER_PTR]
    call free

    mov rsp, rbp
    pop rbp
    ret

designer_start_screen:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    call _show_headline
    call _show_name

    mov rsp, rbp
    pop rbp
    ret

designer_clear:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    call console_manager_clear
    call console_manager_move_cursor_to_end

    mov rsp, rbp
    pop rbp
    ret

designer_type_sequence:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    ; Save non-volatile regs.
    mov [rbp - 8], r15

    ; Get Middle of Height from the console window.
    mov r15, [rel DESIGNER_PTR]
    mov r15, [r15 + designer.console_manager_ptr]
    movzx r15, word [r15 + console_manager.window_size + 6]
    shr r15, 1
    mov [rbp - 16], r15w

    ; Expect pointer to sequence_table (table_structure: qword: pointer, qword: length of string) in RCX.
    ; Expect length of table in RDX.
    mov [rbp - 24], rcx
    mov [rbp - 32], rdx
    dec qword [rbp - 32]
    shr rdx, 1
    sub [rbp - 16], dx

    ; Clear console before writing new sequence.
    call console_manager_clear

    xor r15, r15
.loop:
    mov rcx, [rbp - 24]
    mov rdx, [rcx + 8]
    mov rcx, [rcx]
    mov r8w, [rbp - 16]
    call _write_char_by_char
.loop_handle:
    cmp r15, [rbp - 32]
    jae .complete
    inc r15
    add qword [rbp - 24], 16
    inc word [rbp - 16]
    jmp .loop

.complete:
    mov r15, [rbp - 8]
    mov rsp, rbp
    pop rbp
    ret

;;;;;; PRIVATE METHODS ;;;;;;
_show_headline:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    mov [rbp - 8], r15

    call console_manager_clear

    mov r15, [rel DESIGNER_PTR]
    mov r15, [r15 + designer.console_manager_ptr]

    mov cx, word [r15 + console_manager.window_size + 4]
    shr rcx, 1
    sub cx, 30
    mov [rbp - 16], cx

    mov cx, word [r15 + console_manager.window_size + 6]
    shr rcx, 1
    sub cx, 4
    mov [rbp - 24], cx

    mov byte [rbp - 32], 0

.loop:
    mov cx, word [rbp - 16]
    shl rcx, 16
    mov cx, word [rbp - 24] 
    
    lea rdx, [rel headline_table]
    movzx r8, byte [rbp - 32]
    shl r8, 3
    add rdx, r8
    mov rdx, [rdx]
    call console_manager_print_word

.loop_handle:
    cmp byte [rbp - 32], 7
    je .complete
    inc byte [rbp - 32]
    inc word [rbp - 24]
    jmp .loop

.complete:
    call console_manager_move_cursor_to_end
    mov r15, [rbp - 8]
    mov rsp, rbp
    pop rbp
    ret

_show_name:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    ; Save non-volatile regs.
    mov [rbp - 8], r15

    mov r15, [rel DESIGNER_PTR]
    mov r15, [r15 + designer.console_manager_ptr]
    movzx rcx, word [r15 + console_manager.window_size + 4]
    sub cx, by_length + 1
    shl rcx, 16
    mov cx, word [r15 + console_manager.window_size + 6]
    sub cx, 3
    lea rdx, [rel by]
    call console_manager_print_word

.complete:
    mov r15, [rbp - 8]
    mov rsp, rbp
    pop rbp
    ret

_write_char_by_char:
    push rbp
    mov rbp, rsp
    sub rsp, 80

    ; Save non-volatile regs.
    mov [rbp - 8], r15

    ; Get Middle of Width from the console window.
    mov r15, [rel DESIGNER_PTR]
    mov r15, [r15 + designer.console_manager_ptr]
    movzx r15, word [r15 + console_manager.window_size + 4]
    shr r15, 1
    mov [rbp - 16], r15w

    ; Expect pointer to string in RCX.
    ; Expect length of string in RDX.
    ; Expect starting Y-Coordinate in R8W
    mov [rbp - 24], rcx
    mov [rbp - 32], rdx
    dec qword [rbp - 32]
    mov [rbp - 40], r8w

    shr rdx, 1
    sub [rbp - 16], dx

    xor r15, r15
    movzx rcx, word [rbp - 16]
.loop:
    shl rcx, 16
    mov cx, [rbp - 40]
    mov rdx, [rbp - 24]
    add rdx, r15
    call console_manager_print_char
    ; mov rcx, 50
    ; call Sleep
.loop_handle:
    cmp r15, [rbp - 32]
    jae .complete
    inc r15
    movzx rcx, word [rbp - 16]
    add cx, r15w
    jmp .loop

.complete:
    mov r15, [rbp - 8]
    mov rsp, rbp
    pop rbp
    ret