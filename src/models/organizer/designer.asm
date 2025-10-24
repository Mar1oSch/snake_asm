; Data:
%include "../include/data/designer_strings/designer_strings.inc"

; Strucs:
%include "../include/strucs/organizer/table/table_struc.inc"
%include "../include/strucs/organizer/table/column_format_struc.inc"
%include "../include/strucs/organizer/designer_struc.inc"
%include "../include/strucs/organizer/console_manager_struc.inc"

global designer_new, designer_destroy, designer_start_screen, designer_clear, designer_type_sequence, designer_write_headline, designer_write_table

section .rodata
;;;;;; TABLE ;;;;;;
opened_brace db "["
closed_brace db "]"

section .bss
    DESIGNER_PTR resq 1

section .text
    extern malloc, free
    extern Sleep

    extern console_manager_new, console_manager_write_word, console_manager_clear, console_manager_set_cursor_to_end, console_manager_write_char, console_manager_get_width_to_center_offset, console_manager_set_cursor

    extern helper_parse_int_to_string, helper_get_digits_of_number, helper_change_position

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

    call designer_clear
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
    sub rsp, 56

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
    xor cx, cx
    mov rdx, [rbp - 8]
    mov r8, [rbp - 16]
    xor r9, r9
    call console_manager_write_word

    mov rsp, rbp
    pop rbp
    ret

designer_write_table:
    push rbp
    mov rbp, rsp
    sub rsp, 120

    ; Save non-volatile regs.
    mov [rbp - 8], r15
    xor r15, r15                                                        ; Set column-counter to 0.
    mov [rbp - 16], r14
    xor r14, r14                                                        ; Set row-counter to 0
    mov [rbp - 24], r13
    
    ; Expect pointer to table in RCX.
    ; Expect column count in RDX.
    ; Expect row count in R8.
    ; Expect DWORD Struc (Length of Entry, Type of Entry) per Column in R9.
    mov r13, [rcx + table.content_ptr]                                                      ; Save table-pointer in R13.
    mov edx, [rcx + table.column_count]
    mov [rbp - 32], rdx
    mov r8d, [rcx + table.row_count]
    mov [rbp - 40], r8
    dec qword [rbp - 40]
    mov r9, [rcx + table.column_format_ptr]
    mov [rbp - 48], r9

    mov rax, [rel DESIGNER_PTR]
    mov rax, [rax + designer.console_manager_ptr]
    movzx rax, word [rax + console_manager.window_size + 4]             ; Get the width of the console-window.
    mov rcx, [rbp - 32]
    inc rcx                                                             ; Add one column for pagination.
    xor rdx, rdx
    div rcx                                                             ; Divide the width into n parts for each column

    mov [rbp - 56], ax                                                  ; Save starting X-Coordinate of the table.
    mov word [rbp - 64], 3                                              ; Starting Y-coordinate of the table.

.loop:
    .inner_loop:

        movzx rcx, word [rbp - 56]
        mov rdx, rcx
        shr rdx, 1
        imul rdx, r15
        add rcx, rdx
        shl rcx, 16
        mov cx, [rbp - 64]

        test r15, r15
        jz .handle_pagination

        mov rdx, r13

        mov r10, [rbp - 48]
        mov r9, r15
        dec r9
        imul r9, column_format_size
        add r10, r9
        mov r8d, [r10 + column_format.entry_length]
        mov [rbp - 72], r8

        cmp dword [r10 + column_format.entry_type], 0
        jne .handle_number

        xor r9, r9

    .write:    
        call console_manager_write_word

    .inner_loop_handle:
        mov ecx, dword [rbp - 72]
        add r13, rcx
        cmp r15, [rbp - 32]
        je .loop_handle
        inc r15
        jmp .inner_loop
.loop_handle:
    cmp r14, [rbp - 40]
    je .complete
    inc r14
    xor r15, r15
    add word [rbp - 64], 2
    jmp .loop

.handle_pagination:
    mov rdx, r14
    inc rdx
    call _table_pagination
    inc r15
    jmp .inner_loop

.handle_number:
    mov r9, r8
    jmp .write

.complete:
    call console_manager_get_width_to_center_offset
    mov rcx, rax
    shl rcx, 16
    mov cx, word [rbp - 64]
    inc cx
    call console_manager_set_cursor

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
    xor r9, r9
    call console_manager_write_word

.complete:
    mov r15, [rbp - 8]
    mov rsp, rbp
    pop rbp
    ret

_table_pagination:
    push rbp
    mov rbp, rsp
    sub rsp, 72

    ; Expect X- and Y- Coordinates in ECX.
    ; Expect count in RDX.
    mov [rbp - 8], ecx
    mov [rbp - 16], rdx

    lea rdx, [rel opened_brace]
    call console_manager_write_char

    mov rcx, [rbp - 16]
    call helper_get_digits_of_number
    mov [rbp - 24], rax

    mov rcx, rax
    call malloc

    mov rcx, rax
    mov rdx, [rbp - 16]
    mov r8, [rbp - 24]
    call helper_parse_int_to_string
    mov [rbp - 32], rax

    mov ecx, [rbp - 8]
    mov rdx, 1
    xor r8, r8
    call helper_change_position
    mov [rbp - 8], eax

    mov ecx, eax
    mov rdx, [rbp - 32]
    mov r8, [rbp - 24]
    xor r9, r9
    call console_manager_write_word

    mov ecx, [rbp - 8]
    mov rdx, [rbp - 24]
    xor r8, r8
    call helper_change_position

    mov ecx, eax
    lea rdx, [rel closed_brace]
    call console_manager_write_char

    mov rcx, [rbp - 32]
    call free

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