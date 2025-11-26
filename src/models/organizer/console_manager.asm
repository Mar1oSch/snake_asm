%include "../include/strucs/organizer/console_manager_struc.inc"

global console_manager_new, console_manager_destroy, console_manager_clear, console_manager_write_char, console_manager_set_cursor, console_manager_erase, console_manager_write_word, console_manager_get_width_to_center_offset, console_manager_get_height_to_center_offset, console_manager_get_numeral_input, console_manager_get_literal_input, console_manager_set_buffer_size, console_manager_write_number, console_manager_repeat_char

section .rodata
    erase_char db " "
    ;;;;; DEBUGGING ;;;;;;
    constructor_name db "console_manager", 13, 10, 0
    window_size_string db "top left corner: {%d, %d}, bottom right corner: {%d, %d}", 13, 10, 0

section .data
    _console_cursor_info:
        dd 1
        dd 0

    _console_screen_buffer_info:
        dw 0, 0
        dw 0, 0
        db 0, 0
        dw 0, 0, 0, 0
        dw 0, 0

section .bss
    CONSOLE_MANAGER_PTR resq 1
    lcl_chars_written resq 1

section .text
    extern malloc, free

    extern malloc_failed, object_not_created

    extern helper_parse_saved_number_to_written_number, helper_is_input_just_numbers, helper_parse_string_to_int, helper_parse_int_to_string
    extern file_manager_get_num_of_entries

    extern GetStdHandle
    extern SetConsoleCursorPosition, SetConsoleCursorInfo
    extern WriteConsoleA, ReadConsoleA
    extern GetConsoleScreenBufferInfo, GetNumberOfConsoleInputEvents
    extern SetConsoleScreenBufferSize
    extern FillConsoleOutputCharacterA

;;;;;; PUBLIC METHODS ;;;;;;
console_manager_new:
    push rbp
    mov rbp, rsp
    sub rsp, 88

    cmp qword [rel CONSOLE_MANAGER_PTR], 0
    jne .complete

    ; Save non-volatile regs.
    mov [rbp - 8], r15              

    mov rcx, console_manager_size
    call malloc
    mov [rel CONSOLE_MANAGER_PTR], rax
    mov r15, [rel CONSOLE_MANAGER_PTR]

    mov rcx, -10
    call GetStdHandle
    mov [r15 + console_manager.input_handle], rax

    mov rcx, -11
    call GetStdHandle
    mov [r15 + console_manager.output_handle], rax

    mov rcx, rax
    lea rdx, [rel _console_cursor_info]
    call SetConsoleCursorInfo

    call _cm_get_console_info
    lea rcx, [rel _console_screen_buffer_info]

    mov rdx, [rcx + 10]
    mov [r15 + console_manager.window_size], rdx

.complete:
    mov rax, r15
    mov r15, [rbp - 8]

    mov rsp, rbp
    pop rbp
    ret

console_manager_destroy:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    cmp qword [rel CONSOLE_MANAGER_PTR], 0
    je  _cm_object_failed

    mov rcx, [rel CONSOLE_MANAGER_PTR]
    call free

    mov rsp, rbp
    pop rbp
    ret

console_manager_write_char:
    push rbp
    mov rbp, rsp
    sub rsp, 48

    ; Expect X- and Y-Coordinates in ECX
    ; Expect pointer to char in RDX.
    mov [rbp - 8], rdx
    call _cm_set_cursor_position

    mov rcx, [rbp - 8]
    mov rdx, 1
    call _cm_write

    mov rsp, rbp
    pop rbp
    ret

console_manager_repeat_char:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    ; Expect char to write in CL.
    ; Expect number of repetitions in EDX.
    ; Expect starting coordinates in R8D
    call _cm_write_char_multiple_times

    mov rsp, rbp
    pop rbp
    ret

console_manager_write_word:
    push rbp
    mov rbp, rsp
    sub rsp, 64

    ; Expect X- and Y-Coordinates in ECX
    ; Expect pointer to word in RDX.
    ; Expect length of string in R8
    ; If it is a number, expect length of number in R9, else expect 0.
    mov [rbp - 8], rdx
    mov [rbp - 16], r8
    mov [rbp - 24], r9

    call _cm_set_cursor_position

    cmp qword [rbp - 24], 0
    je .write

    mov rcx, [rbp - 8]
    mov rdx, [rbp - 24]
    call helper_parse_saved_number_to_written_number
    mov [rbp - 8], rax

.write:
    mov rcx, [rbp - 8]
    mov rdx, [rbp - 16]
    call _cm_write

    mov rsp, rbp
    pop rbp
    ret

console_manager_write_number:
    push rbp
    mov rbp, rsp
    sub rsp, 80

    ; Expect X- and Y- Coordinates in ECX.
    ; Expect number in RDX.
    ; Expect digits to write in R8.
    mov [rbp - 8], rdx
    mov [rbp - 16], r8

    call _cm_set_cursor_position

    mov rcx, [rbp - 8]
    call malloc
    mov [rbp - 24], rax

    mov rcx, rax
    mov rdx, [rbp - 8]
    mov r8, [rbp - 16]
    call helper_parse_int_to_string

    mov rcx, rax
    mov rdx, [rbp - 16]
    call _cm_write

    ; mov rcx, [rbp - 24]
    ; call free

    mov rsp, rbp
    pop rbp
    ret

console_manager_get_numeral_input:
    push rbp
    mov rbp, rsp
    sub rsp, 64

    ; Expect number of chars to read in RCX.
    mov [rbp - 8], rcx

.loop:
    lea rcx, [rbp - 16]
    mov rdx, [rbp - 8]
    call _cm_read

    lea rcx, [rbp - 16]
    mov edx, [rbp - 8]
    call helper_is_input_just_numbers
    test rax, rax
    jz .loop

    lea rcx, [rbp - 16]
    mov rdx, [rbp - 8]
    call helper_parse_string_to_int

.complete:
    mov rsp, rbp
    pop rbp
    ret

console_manager_get_literal_input:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    ; Expect pointer to save string to in RCX.
    ; Expect number of chars to read in RDX.
    call _cm_read

.complete:
    mov rsp, rbp
    pop rbp
    ret

console_manager_clear:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    call _cm_empty_console

    mov rsp, rbp
    pop rbp
    ret

console_manager_erase:
    push rbp
    mov rbp, rsp
    sub rsp, 48

    ; Expect Position-X and Position-Y in ECX.
    ; Expect length to clear in RDX.
    mov [rbp - 8], rdx

    call _cm_set_cursor_position

    lea rcx, [rel erase_char]
    mov rdx, [rbp - 8]
    call _cm_write

    mov rsp, rbp
    pop rbp
    ret

console_manager_set_cursor:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    ; Expect Position-X and Position-Y in ECX. 
    call _cm_set_cursor_position

    mov rsp, rbp
    pop rbp
    ret

console_manager_set_buffer_size:
    push rbp
    mov rbp, rsp
    sub rsp, 56

    ; Expect height and width of new buffer size in ECX.
    mov [rbp - 8], cx                   ; Save height of new buffer size.
    shr rcx, 16
    mov [rbp - 16], cx                  ; Save width of new buffer size.

    call _cm_get_console_info

    mov rcx, [rel CONSOLE_MANAGER_PTR]
    mov dx, [rcx + console_manager.window_size + 4]
    inc dx
    add [rbp - 16], dx
    mov dx, [rcx + console_manager.window_size + 6]
    inc dx
    add [rbp - 8], dx

    mov rcx, [rcx + console_manager.output_handle]
    movzx rdx, word [rbp - 8]
    shl rdx, 16
    mov dx, [rbp - 16]
    call SetConsoleScreenBufferSize

.complete:
    mov rsp, rbp
    pop rbp
    ret

console_manager_get_width_to_center_offset:
    mov rax, [rel CONSOLE_MANAGER_PTR]
    movzx rax, word [rax + console_manager.window_size + 4]
    shr rax, 1
    ret

console_manager_get_height_to_center_offset:
    mov rax, [rel CONSOLE_MANAGER_PTR]
    movzx rax, word [rax + console_manager.window_size + 6]
    shr rax, 1
    ret



;;;;;; PRIVATE METHODS ;;;;;;;
_cm_empty_console:
    push rbp
    mov rbp, rsp
    sub rsp, 56

    cmp qword [rel CONSOLE_MANAGER_PTR], 0
    je _cm_object_failed

    call _cm_get_console_info

    mov cl, " "
    movzx edx, word [rel _console_screen_buffer_info]
    imul dx, word [rel _console_screen_buffer_info + 2]
    xor r8, r8
    call _cm_write_char_multiple_times

    call _cm_set_cursor_start

    mov rsp, rbp
    pop rbp
    ret

_cm_write_char_multiple_times:
    push rbp
    mov rbp, rsp
    sub rsp, 56

    cmp qword [rel CONSOLE_MANAGER_PTR], 0
    je _cm_object_failed

    ; Expect char to write in CL.
    ; Expect number of repetitions in EDX.
    ; Expect starting coordinates in R8D
    mov r9w, r8w
    shl r9d, 16
    shr r8d, 16
    mov r9w, r8w
    mov r8d, edx
    mov dl, cl
    mov rcx, [rel CONSOLE_MANAGER_PTR]
    mov rcx, [rcx + console_manager.output_handle]
    lea r10, [rel lcl_chars_written]
    mov qword [rsp + 32], r10
    call FillConsoleOutputCharacterA

    mov rsp, rbp
    pop rbp
    ret

_cm_get_console_info:
    push rbp
    mov rbp, rsp
    sub rsp, 56

    cmp qword [rel CONSOLE_MANAGER_PTR], 0
    je _cm_object_failed

    mov r8, [rel CONSOLE_MANAGER_PTR]
    mov rcx, [r8 + console_manager.output_handle]
    lea rdx, [rel _console_screen_buffer_info]
    call GetConsoleScreenBufferInfo

.complete:
    mov rcx, [rel CONSOLE_MANAGER_PTR]
    lea rax, [rel _console_screen_buffer_info]
    mov rdx, [rax + 10]
    mov [rcx + console_manager.window_size], rdx

    mov rsp, rbp
    pop rbp
    ret

_cm_set_cursor_position:
    push rbp
    mov rbp, rsp
    sub rsp, 56

    ; Expect COORD struct (2 words) in RCX.
    cmp qword [rel CONSOLE_MANAGER_PTR], 0
    je _cm_object_failed

    mov word [rbp - 8], cx
    shr rcx, 16
    mov word [rbp - 16], cx

    mov rcx, [rel CONSOLE_MANAGER_PTR]
    mov rcx, [rcx + console_manager.output_handle]
    mov dx, [rbp - 8]
    shl rdx, 16
    mov dx, [rbp - 16]
    call SetConsoleCursorPosition

    mov rsp, rbp
    pop rbp
    ret

_cm_set_cursor_start:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    mov rcx, [rel CONSOLE_MANAGER_PTR]
    mov rcx, [rcx + console_manager.output_handle]
    xor rdx, rdx
    call SetConsoleCursorPosition

    mov rsp, rbp
    pop rbp
    ret

_cm_write:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    cmp qword [rel CONSOLE_MANAGER_PTR], 0
    je _cm_object_failed

    ; Expect pointer to string in RCX.
    ; Expect number of chars to write in RDX.
    mov r8, rdx
    mov rdx, rcx
    mov rcx, [rel CONSOLE_MANAGER_PTR]
    mov rcx, [rcx + console_manager.output_handle]
    mov r9, 0
    xor rax, rax
    call WriteConsoleA

    mov rsp, rbp
    pop rbp
    ret

_cm_read:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    ; Expect pointer to save read bytes into in RCX.
    ; Expect number of bytes to read in RDX.
    mov [rbp - 8], rcx
    mov [rbp - 16], rdx

    mov r8, rdx
    mov rdx, rcx
    mov rcx, [rel CONSOLE_MANAGER_PTR]
    mov rcx, [rcx + console_manager.input_handle]
    lea r9, [rbp - 24]
    call ReadConsoleA

    mov eax, [rbp - 24]
    cmp rax, [rbp - 16]
    jb .complete

    mov rdx, [rbp - 16]
    dec rdx
    mov rcx, [rbp - 8]
    cmp byte [rcx + rdx], 0
    je .complete
    cmp byte [rcx + rdx], 10
    je .complete

    call _cm_clear_buffer

.complete:
    mov rsp, rbp
    pop rbp
    ret

_cm_clear_buffer:
    push rbp
    mov rbp, rsp
    sub rsp, 56

.loop:
    lea rdx, [rbp - 8]
    mov rcx, [rel CONSOLE_MANAGER_PTR]
    mov rcx, [rcx + console_manager.input_handle]   
    mov r8, 1
    lea r9, [rbp - 16]
    call ReadConsoleA
    cmp byte [rbp - 8], 10
    jne .loop

.complete:
    mov rsp, rbp
    pop rbp
    ret

; Change console attributes. Maybe it will get used some time later.

; _cm_set_up_console_text_attributes:
;     push rbp
;     mov rbp, rsp
;     sub rsp, 40

;     cmp qword [rel CONSOLE_MANAGER_PTR], 0
;     je _cm_object_failed

;     mov rcx, [rel CONSOLE_MANAGER_PTR]
;     mov rcx, [rcx + console_manager.output_handle]
;     mov rdx, 0x0E
;     call SetConsoleTextAttribute

;     mov rsp, rbp
;     pop rbp
;     ret




;;;;;; ERROR HANDLING ;;;;;;
_cm_object_failed:
    lea rcx, [rel constructor_name]
    call object_not_created

    mov rsp, rbp
    pop rbp
    ret

_cm_malloc_failed:
    lea rcx, [rel constructor_name]
    mov rdx, rax
    call malloc_failed

    mov rsp, rbp
    pop rbp
    ret