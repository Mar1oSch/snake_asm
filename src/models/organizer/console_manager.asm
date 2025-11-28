; Strucs:
%include "../include/strucs/organizer/console_manager_struc.inc"

; This is the console manager, which is responsible for managing the basic communication with the console. Every interaction with it is handled here.

global console_manager_new, console_manager_destroy, console_manager_clear, console_manager_write_char, console_manager_set_cursor, console_manager_erase, console_manager_write_word, console_manager_get_width_to_center_offset, console_manager_get_height_to_center_offset, console_manager_get_numeral_input, console_manager_get_literal_input, console_manager_set_buffer_size, console_manager_write_number, console_manager_repeat_char, console_manager_set_console_cursor_info

section .rodata
    ;;;;;; ERASER ;;;;;;
    erase_char db " "

    ;;;;; CONSTANTS ;;;;;;
    STD_OUTPUT_HANDLE equ -11
    STD_INPUT_HANDLE equ -10
    WINDOW_SIZE_OFFSET equ 10

    ;;;;; DEBUGGING ;;;;;;
    constructor_name db "console_manager", 13, 10, 0

section .data
    ; This is the parameter which needs to get passed into "SetConsoleCursorInfo". I am using it to turn of the visibility of the cursor while the game is running. And then turning it one, if a user input is requested.
    _console_cursor_info:
        dd 5
        dd 0

    ; I need the console screen buffer info as parameter for "GetConsoleScreenBufferInfo". It is used to calculate the center of the window and to increase the buffer size for the leaderboard.
    _console_screen_buffer_info:
        dw 0, 0
        dw 0, 0
        db 0, 0
        dw 0, 0, 0, 0
        dw 0, 0

section .bss
    ; Memory space for the created game pointer.
    ; Since there is always just one game in the game, I decided to create a kind of a singleton.
    ; If this lcl_game_ptr is 0, the constructor will create a new game object.
    ; If it is not 0, it simply is going to return this pointer.
    ; This pointer is also used, to reference the object in the destructor and other functions.
    ; So it is not needed to pass a pointer to the object itself as function parameter.
    lcl_console_manager_ptr resq 1

    ; A parameter to recieve the actual amount of chars written (it is passed into "WriteConsoleA")
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

; Here the console manager gets created. 
console_manager_new:
.set_up:
    ; Set up stack frame.
    ; 8 bytes local variables.
    ; 8 bytes to keep stack 16-byte aligned.
    push rbp
    mov rbp, rsp
    sub rsp, 16

    ; If a console manager already exists, skip the creation and simply return the pointer to it.
    cmp qword [rel lcl_console_manager_ptr], 0
    jne .complete

    ; Save non-volatile regs.
    mov [rbp - 8], rbx              

    ; Reserve 32 bytes shadow space for called functions. 
    sub rsp, 32

.create_object:
    ; Creating the console_manager, containing space for:
    ; * - Output handle. (8 bytes)
    ; * - Input handle. (8 bytes)
    ; * - Window dimensions. (8 bytes)
    mov cx, console_manager_size
    call malloc
    ; Pointer to console_manager object is stored in RAX now.
    ; Check if return of malloc is 0 (if it is, it failed).
    ; If it failed, it will get printed into the console.
    test rax, rax
    jz _cm_malloc_failed

    ; Save pointer to initially reserved space. Object is "officially" created now.
    mov [rel lcl_console_manager_ptr], rax

    ; Make RBX containing lcl_console_manager_ptr to set object up.
    mov rbx, rax

.set_up_object:
    ; Save output handle into preserved memory space.
    mov rcx, STD_OUTPUT_HANDLE
    call GetStdHandle
    mov [rbx + console_manager.output_handle], rax

    ; Save input handle into preserved memory space.
    mov rcx, STD_INPUT_HANDLE
    call GetStdHandle
    mov [rbx + console_manager.input_handle], rax

    ; Get Screen buffer info.
    call _cm_get_console_info
    lea rcx, [rel _console_screen_buffer_info]

    ; Save window dimensions into preserved memory space.
    mov rdx, [rcx + WINDOW_SIZE_OFFSET]
    mov [rbx + console_manager.window_size], rdx

.complete:
    ; Return console manager pointer in RAX.
    mov rax, [rel lcl_console_manager_ptr]

    ; Restore non-volatile regs.
    mov rbx, [rbp - 8]

    ; Restore old stack frame and return to caller.
    mov rsp, rbp
    pop rbp
    ret

; Simple destructor to free memory space.
console_manager_destroy:
    .set_up:
        ; Set up stack frame without local variables.
        push rbp
        mov rbp, rsp

        ; If console_manager is not created, let the user know.
        cmp qword [rel lcl_console_manager_ptr], 0
        je _cm_object_failed

        ; Reserve 32 bytes shadow space for called functions. 
        sub rsp, 32

    .destroy_object:
        ; Use the local lcl_console_manager_ptr to free the memory space and set it back to 0.
        mov rcx, [rel lcl_console_manager_ptr]
        call free
        mov qword [rel lcl_console_manager_ptr], 0

    .complete:
        ; Restore old stack frame and leave destructor.
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

console_manager_set_console_cursor_info:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    ; Expect 0 if cursor is off, anything else if it is on in ECX.
    lea rdx, [rel _console_cursor_info]
    mov [rdx + 4], ecx
    mov rcx, [rel lcl_console_manager_ptr]
    mov rcx, [rcx + console_manager.output_handle]
    call SetConsoleCursorInfo

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

    mov rcx, [rel lcl_console_manager_ptr]
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
    mov rax, [rel lcl_console_manager_ptr]
    movzx rax, word [rax + console_manager.window_size + 4]
    shr rax, 1
    ret

console_manager_get_height_to_center_offset:
    mov rax, [rel lcl_console_manager_ptr]
    movzx rax, word [rax + console_manager.window_size + 6]
    shr rax, 1
    ret



;;;;;; PRIVATE METHODS ;;;;;;;
_cm_empty_console:
    push rbp
    mov rbp, rsp
    sub rsp, 56

    cmp qword [rel lcl_console_manager_ptr], 0
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

    cmp qword [rel lcl_console_manager_ptr], 0
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
    mov rcx, [rel lcl_console_manager_ptr]
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

    cmp qword [rel lcl_console_manager_ptr], 0
    je _cm_object_failed

    mov r8, [rel lcl_console_manager_ptr]
    mov rcx, [r8 + console_manager.output_handle]
    lea rdx, [rel _console_screen_buffer_info]
    call GetConsoleScreenBufferInfo

.complete:
    mov rcx, [rel lcl_console_manager_ptr]
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
    cmp qword [rel lcl_console_manager_ptr], 0
    je _cm_object_failed

    mov word [rbp - 8], cx
    shr rcx, 16
    mov word [rbp - 16], cx

    mov rcx, [rel lcl_console_manager_ptr]
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

    mov rcx, [rel lcl_console_manager_ptr]
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

    cmp qword [rel lcl_console_manager_ptr], 0
    je _cm_object_failed

    ; Expect pointer to string in RCX.
    ; Expect number of chars to write in RDX.
    mov r8, rdx
    mov rdx, rcx
    mov rcx, [rel lcl_console_manager_ptr]
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
    mov rcx, [rel lcl_console_manager_ptr]
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
    mov rcx, [rel lcl_console_manager_ptr]
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

;     cmp qword [rel lcl_console_manager_ptr], 0
;     je _cm_object_failed

;     mov rcx, [rel lcl_console_manager_ptr]
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