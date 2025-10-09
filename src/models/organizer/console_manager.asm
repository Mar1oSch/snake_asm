%include "../include/organizer/console_manager_struc.inc"

global console_manager_new, console_manager_destroy, console_manager_clear, console_manager_write_char, console_manager_move_cursor, console_manager_erase, console_manager_write_word, console_manager_move_cursor_to_end, console_manager_get_width_to_center_offset, console_manager_get_height_to_center_offset, console_manager_read

section .rodata
    erase_char db " "

    ;;;;; DEBUGGING ;;;;;;
    constructor_name db "console_manager", 13, 10, 0
    window_size_string db "top left corner: {%d, %d}, bottom right corner: {%d, %d}", 13, 10, 0

section .data
    _console_screen_buffer_info:
        dw 0, 0
        dw 0, 0
        db 0, 0
        dw 0, 0, 0, 0
        dw 0, 0

section .bss
    CONSOLE_MANAGER_PTR resq 1
    CHAR_PTR resq 1

section .text
    extern malloc, free

    extern malloc_failed, object_not_created

    extern GetStdHandle
    extern SetConsoleCursorPosition
    extern WriteConsoleA, ReadConsoleA
    extern GetConsoleScreenBufferInfo, GetNumberOfConsoleInputEvents
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

    call _cm_get_console_info
    lea rcx, [rel _console_screen_buffer_info]

    mov rdx, [rcx + 10]
    mov [r15 + console_manager.window_size], rdx

; .debugging:
;     lea rcx, [rel window_size_string]
;     movzx rdx, word [r15 + console_manager.window_size]
;     movzx r8, word [r15 + console_manager.window_size + 2]
;     movzx r9, word [r15 + console_manager.window_size + 4]
;     movzx r10, word [r15 + console_manager.window_size + 6]
;     mov [rsp + 32], r10
;     call printf

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

console_manager_write_word:
    push rbp
    mov rbp, rsp
    sub rsp, 48

    ; Expect X- and Y-Coordinates in ECX
    ; Expect pointer to word in RDX.
    ; Expect length of string in R8
    mov [rbp - 8], rdx
    mov [rbp - 16], r8

    call _cm_set_cursor_position

    mov rcx, [rbp - 8]
    mov rdx, [rbp - 16]
    call _cm_write

    mov rsp, rbp
    pop rbp
    ret

console_manager_read:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    ; Expect pointer to save string to in RCX.
    ; Expect number of chars to read in RDX.
    mov [rbp - 8], rdx

    mov r8, rdx
    mov rdx, rcx
    mov rcx, [rel CONSOLE_MANAGER_PTR]
    mov rcx, [rcx + console_manager.input_handle]
    lea r9, [rbp - 16]
    call ReadConsoleA

    mov eax, [rbp - 16]
    cmp rax, [rbp - 8]
    jb .complete

    call _cm_clear_buffer

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
    sub rsp, 40

    ; Expect Position-X and Position-Y in ECX.
    call _cm_set_cursor_position

    lea rcx, [rel erase_char]
    mov rdx, 1
    call _cm_write

    mov rsp, rbp
    pop rbp
    ret

console_manager_move_cursor:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    ; Expect Position-X and Position-Y in ECX. 
    call _cm_set_cursor_position

    mov rsp, rbp
    pop rbp
    ret

console_manager_move_cursor_to_end:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    mov [rbp - 8], r15
    mov r15, [rel CONSOLE_MANAGER_PTR]
    movzx rcx, word [r15 + console_manager.window_size + 4]
    sub cx, 2
    shl rcx, 16
    mov cx, [r15 + console_manager.window_size + 6]
    sub cx, 2
    call _cm_set_cursor_position

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

    mov rdx, [rel CONSOLE_MANAGER_PTR]

    mov cx, word [rdx + console_manager.window_size + 4]
    mov word[rbp- 8], cx
    mov cx, word [rdx + console_manager.window_size + 6]
    mov word[rbp - 16], cx

    mov rcx, [rdx + console_manager.output_handle]
    mov rdx, " "
    movzx r8, word [rbp - 8]
    movzx r9, word [rbp - 16]
    imul r8, r9
    xor r9, r9
    lea r10, [rel CHAR_PTR]
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
    xor rax, rax
    mov eax, dword [rcx + console_manager.window_size + 4]

    mov rsp, rbp
    pop rbp
    ret

_cm_set_cursor_position:
    push rbp
    mov rbp, rsp
    sub rsp, 40

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

_cm_write:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    cmp qword [rel CONSOLE_MANAGER_PTR], 0
    je _cm_object_failed

    ; Expect pointer to char in RCX.
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

_cm_clear_buffer:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    mov rcx, [rel CONSOLE_MANAGER_PTR]
    mov rcx, [rcx + console_manager.input_handle]   
    lea rdx, [rbp - 8]
    call GetNumberOfConsoleInputEvents
    mov eax, dword [rbp - 8]
    test eax, eax
    jz .complete

.loop:
    mov rcx, [rel CONSOLE_MANAGER_PTR]
    mov rcx, [rcx + console_manager.input_handle]   
    lea rdx, [rbp - 8]
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