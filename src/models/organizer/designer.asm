; Constants:
%include "./include/data/organizer/console_manager/console_manager_constants.inc"

; Data:
%include "./include/data/organizer/designer/designer_strings.inc"

; Strucs:
%include "./include/strucs/organizer/table/table_struc.inc"
%include "./include/strucs/organizer/table/column_format_struc.inc"
%include "./include/strucs/organizer/designer_struc.inc"
%include "./include/strucs/organizer/console_manager_struc.inc"

; The object to manage the design of the game. It is responsible for centering the output, for writing the table and for typing sequences (if it is desired).

global designer_new

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

    extern console_manager_new
    extern helper_get_digits_of_number, helper_change_position

    extern malloc_failed, object_not_created


;;;;;; VTABLES ;;;;;;
designer_methods_vtable:
    dq designer_start_screen
    dq designer_type_sequence
    dq designer_write_headline
    dq designer_write_table
    dq designer_destroy

;;;;;; PUBLIC METHODS ;;;;;;
designer_new:
    .set_up:
        ; Set up stack frame:
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
        ; Save methods_vtable into its preserved memory space.
        lea rcx, [rel designer_methods_vtable]
        mov [rax + designer.methods_vtable_ptr], rcx

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

designer_destroy:
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
        mov r10, [rel lcl_designer_ptr]
        mov r10, [r10 + designer.console_manager_ptr]
        mov r10, [r10 + console_manager.methods_vtable_ptr]
        call [r10 + CONSOLE_MANAGER_METHODS_CLEAR_ALL_OFFSET]
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
        ; Set up stack frame:
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
        mov r10, [rel lcl_designer_ptr]
        mov r10, [r10 + designer.console_manager_ptr]
        mov r10, [r10 + console_manager.getter_vtable_ptr]
        call [r10 + CONSOLE_MANAGER_GETTER_Y_OFFSET]
        mov r15, rax
        mov rcx, r14
        shr rcx, 1
        sub r15, rcx

    .typing_loop:
        mov rcx, rbx
        mov rdx, [rcx + 8]
        mov rcx, [rcx]
        mov r8w, r15w
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
        ; * 24 bytes local variables.
        ; * 8 bytes to keep stack 16-byte aligned.
        push rbp
        mov rbp, rsp
        sub rsp, 32

        ; If designer is not created yet, print a debug message.
        cmp qword [rel lcl_designer_ptr], 0
        je _ds_object_failed

        ; Save non-volatile regs.
        mov [rbp - 8], rbx
        mov [rbp - 16], r12
        mov [rbp - 24], r13

        ; Save params into non-volatile regs.
        mov rbx, rcx
        mov r12, rdx

        ; Prepare console_manager pointer in R13.
        mov r13, [rel lcl_designer_ptr]
        mov r13, [r13 + designer.console_manager_ptr]


        ; Reserve 32 bytes shadow space for called functions.
        sub rsp, 32

    .prepare_x:
        mov r10, [r13 + console_manager.getter_vtable_ptr]
        call [r10 + CONSOLE_MANAGER_GETTER_X_OFFSET]
        mov rcx, rax
        mov r8, r12
        shr r8, 1
        sub rcx, r8
        shl rcx, 16

    .write_word:
        mov rdx, rbx
        mov r8, r12
        xor r9, r9
        mov r10, [r13 + console_manager.methods_vtable_ptr]
        call [r10 + CONSOLE_MANAGER_METHODS_WRITE_WORD_OFFSET]

    .complete:
        ; Restore non-volatile regs.
        mov r13, [rbp - 24]
        mov r12, [rbp - 16]
        mov rbx, [rbp - 8]

        ; Restore old stack frame and return to caller.
        mov rsp, rbp
        pop rbp
        ret

; This is a function to write a table. For example the leaderboard of the game (which is, to be honest, the only table in this game).
; It uses the table struc and depending on the amount of columns, it is dividing the screen into n parts.
; I optimized that function for 3 parts, since I have one part for the pagination, one for the player name and one for the highscore.
designer_write_table:
    ; * Expect pointer to table in RCX.
    .set_up:
        ; Set up stack frame:
        ; * 80 bytes local variables.
        push rbp
        mov rbp, rsp
        sub rsp, 80

        ; Save non-volatile regs.
        mov [rbp - 8], rbx
        mov [rbp - 16], r12
        mov [rbp - 24], r13
        mov [rbp - 32], r14
        mov [rbp - 40], r15

        ; Reserve 32 bytes shadow space for called functions.
        sub rsp, 32

    .set_up_loop_base:
        ; I am setting up the base for the update loop:
        ; * - RBX is going to be the content pointer.
        ; * - R12D is the active column count.
        ; * - R13D is the active row count.
        ; * - R14D will hold the active coordinates. 
        ; * - R15 will be the column format list pointer.
        mov rbx, [rcx + table.content_ptr]                                                      ; Save table-pointer in rbx.
        mov r12d, [rcx + table.column_count]
        mov r13d, [rcx + table.row_count]
        dec r13d
        mov r15, [rcx + table.column_format_list_ptr]

        ; Save console_manager pointer onto stack.
        mov r10, [rel lcl_designer_ptr]
        mov r10, [r10 + designer.console_manager_ptr]
        mov [rbp - 48], r10

        ; I have to set up three local variables for the loop, to get back to them every iteration:
        ; * First local variable: Column count of table.
        mov [rbp - 56], r12d

        ; * Second local variable: Row count of table.
        mov [rbp - 64], r13d

        ; In every column loop, the format list is looped through again. That's why in the beginning of the row loop, I am always loading it's starting point(er) again into R15.
        ; * Third local variable: Column format list pointer.
        mov [rbp - 72], r15

    .calculate_column_width:
        ; Retrieving the width of the console window.
        mov rax, [rel lcl_designer_ptr]
        mov rax, [rax + designer.console_manager_ptr]
        movzx rax, word [rax + console_manager.window_size + 4]

        ; Adding the column count + 1 for pagination.
        mov ecx, r12d
        inc rcx

        ; Dividing the width / (column count + 1) to get n parts.
        xor rdx, rdx
        div rcx                                                             

    .starting_coordinates:
        mov r14w, ax
        shl r14d, 16
        mov r14w, 2

    .set_up_counters:
        xor r12d, r12d
        xor r13d, r13d

        ; Setting up correct buffer size, so the table is scrollable.
        ; xor rcx, rcx
        ; mov ecx, r13d
        ; shl ecx, 1
        ; add ecx, 2
        ; call console_manager_set_buffer_size
    .row_loop:
        ; Saving the starting point(er) of the column format list.
        mov r15, [rbp - 72]

        .column_loop:
            ; Preparing coordinates in ECX.
            ror r14d, 16
            movzx ecx, r14w
            mov edx, ecx
            shr edx, 1
            imul edx, r12d
            add ecx, edx
            shl ecx, 16
            rol r14d, 16
            mov cx, r14w

            ; If R12D is 0 paginate.
            test r12d, r12d
            jz .handle_pagination

            ; Let RDX point to active content.
            mov rdx, rbx

            ; Point to active column format.
            mov r9d, r12d
            dec r9d
            imul r9d, column_format_size
            add r15, r9
            mov r8d, [r15 + column_format.entry_length]

            ; * Fourth local variable: Length of column entry.
            mov [rbp - 80], r8d

            ; Check if entry is string or int.
            ; If it is a int, handle it.
            cmp dword [r15 + column_format.entry_type], 0
            jne .handle_number

            ; Else set R9 0 and write.
            xor r9, r9

        .write:
            mov r10, [rbp - 48]
            mov r10, [r10 + console_manager.methods_vtable_ptr]
            call [r10 + CONSOLE_MANAGER_METHODS_WRITE_WORD_OFFSET]

        .column_loop_handle:
            ; Mark entry as written.
            mov ecx, [rbp - 80]
            add rbx, rcx

            ; Check if end of columns is reached.
            cmp r12d, [rbp - 56]
            je .row_loop_handle

            ; If not, move to next column.
            inc r12d
            jmp .column_loop

    .row_loop_handle:
        ; Check if end of rows is reached.
        cmp r13d, [rbp - 64]
        je .complete

        ; If not, move to next row.
        inc r13d

        ; Start from first column.
        xor r12d, r12d

        ; Move 2 in Y-coordinates.
        add r14w, 2
        jmp .row_loop

    .handle_pagination:
        mov rdx, r13
        inc rdx
        call _table_pagination
        inc r12d
        jmp .column_loop

    .handle_number:
        mov r9, r8
        jmp .write

    .complete:
        mov r10, [rbp - 48]
        mov r10, [r10 + console_manager.getter_vtable_ptr]
        call [r10 + CONSOLE_MANAGER_GETTER_X_OFFSET]
        mov rcx, rax
        shl rcx, 16
        mov cx, r14w
        add cx, 2
        mov r10, [rbp - 48]
        mov r10, [r10 + console_manager.setter_vtable_ptr]
        call [r10 + CONSOLE_MANAGER_SETTER_CURSOR_POS_OFFSET]

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




;;;;;; PRIVATE METHODS ;;;;;;
_show_headline:
    .set_up:
        ; Set up the stack frame without local variables.
        push rbp
        mov rbp, rsp

        ; If designer is not created yet, print a debug message.
        cmp qword [rel lcl_designer_ptr], 0
        je _ds_object_failed

        ; Reserve 32 bytes shadow space for called functions.
        sub rsp, 32

    .type_headline:
        lea rcx, [rel headline_table]
        mov rdx, HEADLINE_TABLE_SIZE
        mov r8, 0
        call designer_type_sequence

    .complete:
        ; Restore old stack frame and return to caller.
        mov rsp, rbp
        pop rbp
        ret

_show_name:
    .set_up:
        ; Set up the stack frame without local variables.
        push rbp
        mov rbp, rsp

        ; If designer is not created yet, print a debug message.
        cmp qword [rel lcl_designer_ptr], 0
        je _ds_object_failed

        ; Reserve 32 bytes shadow space for called functions.
        sub rsp, 32

    .type_name:
        ; Prepare console_manager pointer in R10.
        mov r10, [rel lcl_designer_ptr]
        mov r10, [r10 + designer.console_manager_ptr]

        ; Move width of console window into CX.
        mov cx, [r10 + console_manager.window_size + 4]
        sub cx, AUTHOR_LENGTH + 1
        shl ecx, 16

        ; Move height of console window into CX.
        mov cx, [r10 + console_manager.window_size + 6]
        sub cx, 3

        lea rdx, [rel author]

        mov r8, AUTHOR_LENGTH
        xor r9, r9
        mov r10, [r10 + console_manager.methods_vtable_ptr]
        call [r10 + CONSOLE_MANAGER_METHODS_WRITE_WORD_OFFSET]

    .complete:
        ; Restore old stack frame and return to caller.
        mov rsp, rbp
        pop rbp
        ret


_table_pagination:
    ; * Expect X- and Y- Coordinates in ECX.
    ; * Expect count in RDX.
    .set_up:
        ; Set up stack frame:
        ; * 32 bytes local variables.
        push rbp
        mov rbp, rsp
        sub rsp, 32

        ; If designer is not created yet, print a debug message.
        cmp qword [rel lcl_designer_ptr], 0
        je _ds_object_failed

        ; Save non-volatile regs.
        mov [rbp - 8], rbx
        mov [rbp - 16], r12
        mov [rbp - 24], r13
        mov [rbp - 32], r14

        ; Save params into non-volatile regs.
        mov ebx, ecx
        mov r12, rdx

        ; Prepare console_manager.methods_table in R14.
        mov r14, [rel lcl_designer_ptr]
        mov r14, [r14 + designer.console_manager_ptr]
        mov r14, [r14 + console_manager.methods_vtable_ptr]

        ; Reserve 32 bytes shadow space for called functions.
        sub rsp, 32

    .open_brace:
        lea rdx, [rel opened_brace]
        call [r14 + CONSOLE_MANAGER_METHODS_WRITE_CHAR_OFFSET]

    .write_number:
        ; At first I calculate how many digits the number has to know how many bytes the string needs.
        mov rcx, r12
        call helper_get_digits_of_number
        mov r13, rax

        ; Then the cursor gets moved.
        mov ecx, ebx
        mov rdx, 1
        xor r8, r8
        call helper_change_position
        mov ebx, eax

        ; And the number is written. It needs to know its position, the number itself and the amount of digits.
        mov ecx, eax
        mov rdx, r12
        mov r8, r13
        call [r14 + CONSOLE_MANAGER_METHODS_WRITE_NUMBER_OFFSET]

    .close_brace:
        mov ecx, ebx
        mov rdx, r13
        xor r8, r8
        call helper_change_position

        mov ecx, eax
        lea rdx, [rel closed_brace]
        call [r14 + CONSOLE_MANAGER_METHODS_WRITE_CHAR_OFFSET]

    .complete:
        ; Restore non-volatile regs.
        mov r14, [rbp - 32]
        mov r13, [rbp - 24]
        mov r12, [rbp - 16]
        mov rbx, [rbp - 8]

        ; Restore old stack frame and return to caller.
        mov rsp, rbp
        pop rbp
        ret

_write_char_by_char:
    ; * Expect pointer to string in RCX.
    ; * Expect length of string in RDX.
    ; * Expect starting Y-Coordinate in R8W
    ; * Expect Sleep-Time in R9
    .set_up:
        ; Set up stack frame:
        ; * 56 bytes local variables.
        ; * 8 bytes to keep stack 16-byte aligned.
        push rbp
        mov rbp, rsp
        sub rsp, 64

        ; If designer is not created yet, print a debug message.
        cmp qword [rel lcl_designer_ptr], 0
        je _ds_object_failed

        ; Save non-volatile regs.
        mov [rbp - 8], rbx
        mov [rbp - 16], r12
        mov [rbp - 24], r13
        mov [rbp - 32], r14
        mov [rbp - 40], r15

        ; Reserve 32 bytes shadow space for called functions.
        sub rsp, 32

    .set_up_loop_base:
        ; I am setting up the base for the update loop:
        ; * - RBX is going to be the pointer to the string.
        ; * - R12 is the length of the string.
        ; * - R13W is the starting Y-coordinate.
        ; * - R14 will be the loop counter.
        ; * - R15 is the console_manager.method_table.

        ; Move params into non-volatile regs.
        mov rbx, rcx
        mov r12, rdx
        dec r12
        mov r13w, r8w
        mov [rbp - 48], r9
        shr rdx, 1
        mov r14, rdx

        ; Prepare console_manager pointer in R15.
        mov r15, [rel lcl_designer_ptr]
        mov r15, [r15 + designer.console_manager_ptr]

        ; Get Middle of Width from the console window.
        mov r10, [r15 + console_manager.getter_vtable_ptr]
        call [r10 + CONSOLE_MANAGER_GETTER_X_OFFSET]
        sub rax, r14
        ; * First local variable: X-offset of string.
        mov [rbp - 56], rax

        ; Prepare console_manager.methods_vtable in R15.
        mov r15, [r15 + console_manager.methods_vtable_ptr]

        ; Prepare loop counter.
        xor r14, r14

    .write_char_loop:
        mov rcx, [rbp - 56]
        add cx, r14w
        shl rcx, 16
        mov cx, r13w
        mov rdx, rbx
        add rdx, r14
        call [r15 + CONSOLE_MANAGER_METHODS_WRITE_CHAR_OFFSET]

        mov rcx, [rbp - 48]
        call Sleep

    .write_char_loop_handle:
        cmp r14, r12
        jae .complete
        inc r14
        jmp .write_char_loop

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