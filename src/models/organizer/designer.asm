; Data:
%include "../include/data/designer_strings/designer_strings.inc"

; Strucs:
%include "../include/strucs/organizer/table/table_struc.inc"
%include "../include/strucs/organizer/table/column_format_struc.inc"
%include "../include/strucs/organizer/designer_struc.inc"
%include "../include/strucs/organizer/console_manager_struc.inc"

; The object to manage the design of the game. It is responsible for centering the output, for writing the table and for typing sequences (if it is desired).

global designer_new, designer_destroy, designer_start_screen, designer_clear, designer_type_sequence, designer_write_headline, designer_write_table

section .rodata
    ;;;;;; TABLE PAGINATION ;;;;;;
    opened_brace db "["
    closed_brace db "]"

    ;;;;;; DEBUGGING ;;;;;;
    constructor_name db "designer_new", 0

section .bss
    ; Memory space for the created designer pointer.
    ; Since there is always just one designer in the game, I decided to create a kind of a singleton.
    ; If this lcl_designer_ptr is 0, the constructor will create a new designer object.
    ; If it is not 0, it simply is going to return this pointer.
    ; This pointer is also used, to reference the object in the destructor and other functions.
    ; So it is not needed to pass a pointer to the object itself as function parameter.
    lcl_designer_ptr resq 1

section .text
    extern malloc, free
    extern Sleep

    extern console_manager_new, console_manager_write_word, console_manager_clear_all, console_manager_write_char, console_manager_get_center_x_offset, console_manager_get_center_y_offset, console_manager_set_cursor, console_manager_set_buffer_size, console_manager_write_number, console_manager_set_console_cursor_info
    extern helper_get_digits_of_number, helper_change_position

    extern malloc_failed, object_not_created

designer_new:
    .set_up:
        ; Set up stack frame.
        ; * 8 bytes local variables.
        ; * 8 bytes to keep stack 16-byte aligned.
        push rbp
        mov rbp, rsp
        sub rsp, 16

        ; Check if a designer already exists. If yes, return the pointer to it.
        cmp qword [rel lcl_designer_ptr], 0
        jne .complete

        ; Reserve 32 bytes shadow space for called functions.
        sub rsp, 32

    .create_dependend_objects:
        call console_manager_new
        mov [rbp - 8], rax

    .create_object:
        ; Creating the designer, containing space for:
        ; * - Console manager pointer (8 bytes).
        mov rcx, designer_size
        call malloc
        ; Pointer to designer object is stored in RAX now.
        ; Check if return of malloc is 0 (if it is, it failed).
        ; If it failed, it will get printed into the console.
        test rax, rax
        jz _ds_malloc_failed

        ; Save pointer to initially reserved space. Object is "officially" created now.
        mov [rel lcl_designer_ptr], rax

    .set_up_object:
        ; Use the console manager pointer returned by console_manager_new and move it into preserved memory space.
        mov rcx, [rbp - 8]
        mov [rax + designer.console_manager_ptr], rcx

    .complete:
        ; Use the pointer to the designer object as return value of this constructor.
        mov rax, qword [rel lcl_designer_ptr]

        ; Restore the old stack frame and leave the constructor.
        mov rsp, rbp
        pop rbp
        ret

_designer_destroy:
    .set_up:
        ; Set up the stack frame without local variables.
        push rbp
        mov rbp, rsp

        ; If designer is not created yet, print a debug message.
        cmp qword [rel lcl_designer_ptr], 0
        je _ds_object_failed

        ; Reserve 32 bytes shadow space for called functions.
        sub rsp, 32

    .destroy_object:
        ; Use the local lcl_designer_ptr to free the memory space and set it back to 0.
        mov rcx, [rel lcl_designer_ptr]
        call free
        mov qword [rel lcl_designer_ptr], 0

    .complete:
        ; Restore old stack frame and leave the destructor.
        mov rsp, rbp
        pop rbp
        ret

; Wrapper function to show the start screen of the game.
designer_start_screen:
    .set_up:
        ; Set up the stack frame without local variables.
        push rbp
        mov rbp, rsp

        ; If designer is not created yet, print a debug message.
        cmp qword [rel lcl_designer_ptr], 0
        je _ds_object_failed

        ; Reserve 32 bytes shadow space for called functions.
        sub rsp, 32

    .call_functions:
        call console_manager_clear_all
        call _show_headline
        call _show_name

    .complete:
        ; Restore old stack frame and return to caller.
        mov rsp, rbp
        pop rbp
        ret

; The interaction texts with the user are typing sequences with a specified amount of delay between typing the letters. If delay is 0, the text is printed immediately.
designer_type_sequence:
    ; * Expect pointer to sequence_table (table_structure: [qword: pointer, qword: length of string]) in RCX.
    ; * Expect length of table in RDX.
    ; * Expect Sleep time in R8
    .set_up:
        ; Set up stack frame.
        ; * 40 bytes local variables.
        ; * 8 bytes to keep stack 16-byte aligned.
        push rbp
        mov rbp, rsp
        sub rsp, 48

        ; Save non-volatile regs.
        mov [rbp - 8], rbx
        mov [rbp - 16], r12
        mov [rbp - 24], r13
        mov [rbp - 32], r14
        mov [rbp - 40], r15

        ; Reserve 32 bytes shadow space for called functions.
        sub rsp, 32

    .set_up_loop_base:
        ; I am setting up the base for the typing loop:
        ; * - RBX is going to be the pointer to the table containing the strings.
        ; * - R12 is the counter, which string we are at.
        ; * - R13 will hold the sleep time.
        ; * - R14 will hold the length of the table.
        ; * - R15 is the center height offset.
        mov rbx, rcx
        xor r12, r12
        mov r13, r8
        mov r14, rdx

        ; Preparing the right offset to center the text, independend of how many rows it has.
        call console_manager_get_center_y_offset
        mov r15, rax
        mov rcx, r14
        shr rcx, 1
        sub r15, rcx

    .typing_loop:
        mov rcx, rbx
        mov rdx, [rcx + 8]
        mov rcx, [rcx]
        mov r8, r15
        mov r9, r13
        call _write_char_by_char

    .typing_loop_handle:
        inc r12
        inc r15
        add rbx, 16
        cmp r12, r14
        jb .typing_loop

    .complete:
        ; Restore non-volatile regs.
        mov r15, [rbp - 40]
        mov r14, [rbp - 32]
        mov r13, [rbp - 24]
        mov r12, [rbp - 16]
        mov rbx, [rbp - 8]

        ; Restore old stack frame and return to caller.
        mov rsp, rbp
        pop rbp
        ret


designer_write_headline:
    ; * Expect pointer to headline in RCX.
    ; * Expect length of headline in RDX.
    .set_up:
            ; Set up the stack frame.
            ; * 16 bytes local variables.
            push rbp
            mov rbp, rsp
            sub rsp, 16

            ; If designer is not created yet, print a debug message.
            cmp qword [rel lcl_designer_ptr], 0
            je _ds_object_failed

            ; Save non-volatile regs.
            mov [rbp - 8], rbx
            mov [rbp - 16], r12

            ; Save params into non-volatile regs.
            mov rbx, rcx
            mov r12, rdx

            ; Reserve 32 bytes shadow space for called functions.
            sub rsp, 32

    .prepare_x:
        call console_manager_get_center_x_offset
        mov rcx, rax
        mov r8, r12
        shr r8, 1
        sub rcx, r8
        shl rcx, 16

    .write_word:
        mov rdx, rbx
        mov r8, r12
        xor r9, r9
        call console_manager_write_word

    .complete:
        ; Restore non-volatile regs.
        mov r12, [rbp - 16]
        mov rbx, [rbp - 8]

        ; Restore old stack frame and return to caller.
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
    
    ; * Expect pointer to table in RCX.
    mov r13, [rcx + table.content_ptr]                                                      ; Save table-pointer in R13.
    mov edx, [rcx + table.column_count]
    mov [rbp - 32], edx
    mov edx, [rcx + table.row_count]
    mov [rbp - 40], edx
    dec dword [rbp - 40]
    mov r9, [rcx + table.column_format_list_ptr]
    mov [rbp - 48], r9

.calculate_x:
    mov rax, [rel lcl_designer_ptr]
    mov rax, [rax + designer.console_manager_ptr]
    movzx rax, word [rax + console_manager.window_size + 4]             ; Get the width of the console-window.
    mov ecx, [rbp - 32]
    inc rcx                                                             ; Add one column for pagination.
    xor rdx, rdx
    div rcx                                                             ; Divide the width into n parts for each column

    mov [rbp - 56], ax                                                  ; Save starting X-Coordinate of the table.
    mov word [rbp - 64],2                                               ; Starting Y-coordinate of the table.

    ; Setting up correct buffer size, so the table is scrollable.
    ; xor rcx, rcx
    ; mov ecx, [rbp - 40]
    ; shl ecx, 1
    ; add ecx, 2
    ; call console_manager_set_buffer_size

.loop:
    .inner_loop:
        movzx rcx, word [rbp - 56]
        mov rdx, rcx
        shr rdx, 1
        imul rdx, r15
        add rcx, rdx
        shl rcx, 16
        mov cx, [rbp - 64]

        test r15d, r15d
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
        cmp r15d, [rbp - 32]
        je .loop_handle
        inc r15d
        jmp .inner_loop
.loop_handle:
    cmp r14d, [rbp - 40]
    je .complete
    inc r14d
    xor r15d, r15d
    add word [rbp - 64], 2
    jmp .loop

.handle_pagination:
    mov rdx, r14
    inc rdx
    call _table_pagination
    inc r15d
    jmp .inner_loop

.handle_number:
    mov r9, r8
    jmp .write

.complete:
    call console_manager_get_center_x_offset
    mov rcx, rax
    shl rcx, 16
    mov cx, word [rbp - 64]
    add cx, 2
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
    sub rsp, 48

    ; Save non-volatile regs.
    mov [rbp - 8], r15

    mov r15, [rel lcl_designer_ptr]
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
    sub rsp, 64

    ; * ExpectX- and Y- Coordinates in ECX.
    ; * Expectcount in RDX.
    mov [rbp - 8], ecx
    mov [rbp - 16], rdx

    lea rdx, [rel opened_brace]
    call console_manager_write_char

    mov rcx, [rbp - 16]
    call helper_get_digits_of_number
    mov [rbp - 24], rax

    mov ecx, [rbp - 8]
    mov rdx, 1
    xor r8, r8
    call helper_change_position
    mov [rbp - 8], eax

    mov ecx, eax
    mov rdx, [rbp - 16]
    mov r8, [rbp - 24]
    call console_manager_write_number

    mov ecx, [rbp - 8]
    mov rdx, [rbp - 24]
    xor r8, r8
    call helper_change_position

    mov ecx, eax
    lea rdx, [rel closed_brace]
    call console_manager_write_char

    mov rsp, rbp
    pop rbp
    ret

_write_char_by_char:
    ; * Expect pointer to string in RCX.
    ; * Expect length of string in RDX.
    ; * Expect starting Y-Coordinate in R8W
    ; * Expect Sleep-Time in R9
    push rbp
    mov rbp, rsp
    sub rsp, 88

    ; Save non-volatile regs.
    mov [rbp - 8], r15

    ; Get Middle of Width from the console window.
    mov r15, [rel lcl_designer_ptr]
    mov r15, [r15 + designer.console_manager_ptr]
    movzx r15, word [r15 + console_manager.window_size + 4]
    shr r15, 1
    mov [rbp - 16], r15w

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


;;;;;; ERROR HANDLING ;;;;;; 

_ds_malloc_failed:
    .set_up:
        ; Set up stack frame without local variables.
        push rbp
        mov rbp, rsp

        ; Reserve 32 bytes shadow space for called functions.
        sub rsp, 32

    .debug:
        lea rcx, [rel constructor_name]
        mov rdx, rax
        call malloc_failed

    .complete:
        ; Restore old stack frame and leave debugging function.
        mov rsp, rbp
        pop rbp
        ret

_ds_object_failed:
    .set_up:
        ; Set up stack frame without local variables.
        push rbp
        mov rbp, rsp

        ; Reserve 32 bytes shadow space for called functions.
        sub rsp, 32

    .debug:
        lea rcx, [rel constructor_name]
        call object_not_created

    .complete:
        ; Restore old stack frame and leave debugging function.
        mov rsp, rbp
        pop rbp
        ret