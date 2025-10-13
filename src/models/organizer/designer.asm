%include "../include/organizer/designer_struc.inc"
%include "../include/organizer/console_manager_struc.inc"

global designer_new, designer_destroy, designer_start_screen, designer_clear, designer_type_sequence, designer_write_table

section .rodata
    ;;;;;; START SCREEN ;;;;;;
    headline:
        .line1 db "  SSSSSS    NNN     NNN    AAAAAAA    KKK    KKK   EEEEEEEEE",13,10, 0
        .line2 db "SSSSSSSSSS  NNNN    NNN   AAAAAAAAA   KKK   KKK    EEEEEEEEE",13,10, 0
        .line3 db "SSSS        NNNNN   NNN   AAA   AAA   KKK  KKK     EEE      ",13,10, 0
        .line4 db " SSSSS      NNN NN  NNN   AAAAAAAAA   KKKKKK       EEEEEEEE ",13,10, 0
        .line5 db "  SSSSS     NNN  NN NNN   AAAAAAAAA   KKK KKK      EEEEEEEE ",13,10, 0
        .line6 db "     SSSS   NNN   NNNNN   AAA   AAA   KKK  KKK     EEE      ",13,10, 0
        .line7 db "SSSSSSSSS   NNN    NNNN   AAA   AAA   KKK   KKK    EEEEEEEEE",13,10, 0
        .line8 db "  SSSSS     NNN     NNN   AAA   AAA   KKK    KKK   EEEEEEEEE",13,10, 0
    headline_end:

    headline_table:
        dq headline.line1, (headline.line2 - headline.line1)
        dq headline.line2, (headline.line3 - headline.line2)
        dq headline.line3, (headline.line4 - headline.line3)
        dq headline.line4, (headline.line5 - headline.line4)
        dq headline.line5, (headline.line6 - headline.line5)
        dq headline.line6, (headline.line7 - headline.line6)
        dq headline.line7, (headline.line8 - headline.line7)
        dq headline.line8, (headline_end - headline.line8)
    headline_table_end:

    HEADLINE_TABLE_SIZE equ (headline_table_end - headline_table) / 16

    by:
    db "by Mario Schanzenbach", 0
    by_end:

    BY_LENGTH equ by_end - by

    ;;;;;; LEADERBOARD SCREEN ;;;;;;
    leaderboard:
        db "LEADERBOARD", 0
    leaderboard_end:

    LEADERBOARD_SIZE equ leaderboard_end - leaderboard

    ;;;;;; TABLE ;;;;;;
    pagination_format db "[%d]", 0

section .bss
    DESIGNER_PTR resq 1

section .text
    extern malloc, free
    extern Sleep

    extern printf

    extern console_manager_new, console_manager_write_word, console_manager_clear, console_manager_set_cursor_to_end, console_manager_write_char, console_manager_get_width_to_center_offset, console_manager_set_cursor

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
    call console_manager_set_cursor_to_end

    mov rsp, rbp
    pop rbp
    ret

designer_type_sequence:
    push rbp
    mov rbp, rsp
    sub rsp, 48

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
    ; Expect Sleep time in R8
    mov [rbp - 24], rcx
    mov [rbp - 32], rdx
    mov [rbp - 40], r8
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
    mov r9, [rbp - 40]
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

designer_write_headline:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    ; Expect pointer to headline in RCX.
    ; Expect length of headline in RDX.
    mov [rbp - 8], rcx
    mov [rbp - 16], rdx

    call console_manager_get_width_to_center_offset
    mov rcx, rax

    mov rdx, [rbp - 16]
    shr rdx, 1
    sub rcx, rdx
    shl rcx, 16
    mov cx, 2
    mov rdx, [rbp - 8]
    mov r8, [rbp - 16]
    call console_manager_write_word

    mov rsp, rbp
    pop rbp
    ret

designer_write_table:
    push rbp
    mov rbp, rsp
    sub rsp, 112

    ; Save non-volatile regs.
    mov [rbp - 8], r15
    xor r15, r15                                                        ; Set column-counter to 0.
    mov [rbp - 16], r14
    xor r14, r14                                                        ; Set row-counter to 0
    mov [rbp - 24], r13

    ; Expect pointer to table in RCX.
    ; Expect amount of columns in RDX.
    ; Expect amount of rows in R8.
    ; Expect pointer to Byte-Struc showing length of each cell-entry in R9.
    mov r13, rcx                                                        ; Save table-pointer in R14.
    mov [rbp - 32], rdx
    mov [rbp - 40], r8
    mov [rbp - 48], r9

    xor rax, rax
    xor rcx, rcx
.get_record_size:
    cmp rcx, rdx
    jae .record_size_done
    movzx r8, byte [r9 + rcx]
    add rax, r8
    inc rcx
    jmp .get_record_size
.record_size_done:
    mov [rbp - 56], rax

    mov rax, [rel DESIGNER_PTR]
    mov rax, [rax + designer.console_manager_ptr]
    movzx rax, word [rax + console_manager.window_size + 4]             ; Get the width of the console-window.
    mov rcx, [rbp - 32]
    inc rcx                                                             ; Add one column for pagination.
    xor rdx, rdx
    div rcx                                                             ; Divide the width into n parts for each column.
    shr rax, 1

    mov [rbp - 64], ax                                                  ; Save center X of each column.
    mov word [rbp - 72], 2                                              ; Starting Y-coordinate of the table.

    call console_manager_clear

.loop:
    .inner_loop:
        test r15, r15
        jz .handle_pagination

        movzx rcx, word [rbp - 64]
        shl rcx, 1
        imul rcx, r15
        shl rcx, 16
        mov cx, [rbp - 72]

        mov rdx, r13

        mov r8, [rbp - 48]
        add r8, r15
        dec r8
        movzx r8, byte [r8]
        call console_manager_write_word

    .inner_loop_handle:
        mov r8, [rbp - 48]
        add r8, r15
        movzx r8, byte [r8]
        add r13, r8
        cmp r15, [rbp - 32]
        ja .loop_handle
        inc r15
        jmp .inner_loop
.loop_handle:
    cmp r14, [rbp - 40]
    je .complete
    inc r14
    xor r15, r15
    add word [rbp - 72], 2
    jmp .loop

.handle_pagination:
    movzx rcx, word [rbp - 64]
    shr rcx, 1
    shl rcx, 16
    mov cx, [rbp - 72]
    mov rdx, r14
    inc rdx
    call _table_pagination
    inc r15
    jmp .inner_loop

.complete:
    mov r13, [rbp - 24]
    mov r14, [rbp - 16]
    mov r15, [rbp - 8]

    mov rsp, rbp
    pop rbp
    ret




;;;;;; PRIVATE METHODS ;;;;;;
_show_headline:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    lea rcx, [rel headline_table]
    mov rdx, HEADLINE_TABLE_SIZE
    mov r8, 0
    call designer_type_sequence

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
    sub cx, BY_LENGTH + 1
    shl rcx, 16
    mov cx, word [r15 + console_manager.window_size + 6]
    sub cx, 3
    lea rdx, [rel by]
    mov r8, BY_LENGTH
    call console_manager_write_word

.complete:
    mov r15, [rbp - 8]
    mov rsp, rbp
    pop rbp
    ret

_table_pagination:
    push rbp
    mov rbp, rsp
    sub rsp, 48

    ; Expect X- and Y- Coordinates in ECX.
    ; Expect count in RDX.
    mov [rbp - 8], rdx

    call console_manager_set_cursor

    lea rcx, [rel pagination_format]
    mov rdx, [rbp - 8]
    call printf

    mov rsp, rbp
    pop rbp
    ret

_write_char_by_char:
    push rbp
    mov rbp, rsp
    sub rsp, 88

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
    ; Expect Sleep-Time in R9
    mov [rbp - 24], rcx
    mov [rbp - 32], rdx
    dec qword [rbp - 32]
    mov [rbp - 40], r8w
    mov [rbp - 48], r9
    shr rdx, 1
    sub [rbp - 16], dx

    xor r15, r15
    movzx rcx, word [rbp - 16]
.loop:
    shl rcx, 16
    mov cx, [rbp - 40]
    mov rdx, [rbp - 24]
    add rdx, r15
    call console_manager_write_char
    mov rcx, [rbp - 48]
    call Sleep
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