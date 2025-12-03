; Strucs:
%include "../include/strucs/organizer/table/table_struc.inc"
%include "../include/strucs/organizer/table/column_format_struc.inc"

; This code implements a simple table management system in assembly.
; The table manager allows for creating tables, destroying them, 
; adding columns, and adding content to the table. It manages dynamic memory 
; allocation for table structures and columns using malloc and realloc, 
; and it handles the storage of content within a table.

; The system uses the following structures:
;   - table: Stores the table's row and column counts, along with a pointer to its content and column format.
;   - column_format: Defines the structure for each column, including the length of entries and the type of entries.

; Global Functions:
;   - table_manager_create_table: Creates a new table, allocating memory for the table structure and setting the row count.
;   - table_manager_destroy_table: Frees memory allocated for a table.
;   - table_manager_add_content: Adds a pointer to content (e.g., data) to a table.
;   - table_manager_add_column: Adds a new column to the table, either by allocating new memory for column formats or reallocating 
;     existing memory to accommodate new columns.

; Table and column format structures are included from external files:
;   - table_struc.inc: Defines the table structure, including row count, column count, content pointer, and column format pointer.
;   - column_format_struc.inc: Defines the column format structure, including entry length and entry type.

global table_manager_create_table, table_manager_destroy_table, table_manager_add_column, table_manager_add_content

section .rodata
    ;;;;;; DEBUGGING ;;;;;;
    constructor_name db "table_new"

section .data
    list_length_counter dd 0

section .bss
    ; Memory space for the created table pointer.
    ; Since there is always just one table in the game, I decided to create a kind of a singleton.
    ; If this lcl_table_ptr is 0, the constructor will create a new table object.
    ; If it is not 0, it simply is going to return this pointer.
    ; This pointer is also used, to reference the object in the destructor and other functions.
    ; So it is not needed to pass a pointer to the object itself as function parameter.
    lcl_table_ptr resq 1
    lcl_tm_column_format_list_ptr resq 1

section .text
    extern malloc, realloc, free

    extern malloc_failed, object_not_created

;;;;;; PUBLIC METHODS ;;;;;;

table_manager_create_table:
    ; * Expect amount of rows in ECX.
    .set_up:
        ; Set up stack frame without local variables.
        push rbp
        mov rbp, rsp

        ; Save params into shadow space.
        mov [rbp + 16], ecx

        ; Reserve 32 bytes shadow space for called functions.
        sub rsp, 32

    .create_object:
        ; Creating the snake itself, containing space for:
        ; * - Content pointer. (8 bytes)
        ; * - Column format pointer. (8 bytes)
        ; * - Column count. (4 bytes)
        ; * - Row count. (4 bytes)
        mov rcx, table_size
        call malloc
        ; Pointer to table object is stored in RAX now.
        ; Check if return of malloc is 0 (if it is, it failed).
        ; If it failed, it will get printed into the console.
        test rax, rax
        jz _tm_malloc_failed
        ; Save pointer to initially reserved space. Object is "officially" created now.
        mov [rel lcl_table_ptr], rax

    .set_up_object:
        ; Add the row count passed in ECX.
        mov ecx, [rbp + 16]
        mov [rax + table.row_count], ecx

        ; Set column count zero initially.
        mov dword [rax + table.column_count], 0

    .complete:
        ; Restore old stack frame and return to caller.
        mov rsp, rbp
        pop rbp
        ret

table_manager_destroy_table:
    .set_up:
        ; Set up stack frame without local variables.
        push rbp
        mov rbp, rsp

        ; If table is not created, let the user know.
        cmp qword [rel lcl_table_ptr], 0
        je _tm_object_failed

        ; Reserve 32 bytes shadow space for called functions. 
        sub rsp, 32

    .destroy_object:
        ; Use the local lcl_table_ptr to free the memory space and set it back to 0.
        mov rcx, [rel lcl_table_ptr]
        call free
        mov qword [rel lcl_table_ptr], 0

    .complete:
        ; Restore old stack frame and leave destructor.
        mov rsp, rbp
        pop rbp
        ret

table_manager_add_content:
    ; * Expect pointer to content in RCX.
    .set_up:
        ; Set up stack frame without local variables.
        push rbp
        mov rbp, rsp

        ; If table is not created, let the user know.
        cmp qword [rel lcl_table_ptr], 0
        je _tm_object_failed

    .add_content:
        mov rax, [rel lcl_table_ptr]
        mov [rax + table.content_ptr], rcx

    .complete:
        ; Restore old stack frame and return to caller.
        mov rsp, rbp
        pop rbp
        ret

table_manager_add_column:
    ; * Expect length of entries in column in ECX.
    ; * Expect type of entries in column in EDX.
    .set_up:
        ; Set up stack frame without local variables.
        push rbp
        mov rbp, rsp

        ; If table is not created, let the user know.
        cmp qword [rel lcl_table_ptr], 0
        je _tm_object_failed

        ; Save params into shadow space.
        mov [rbp + 16], ecx
        mov [rbp + 24], edx

        ; Reserve 32 bytes shadow space for called functions. 
        sub rsp, 32

    ; If table already has a column, add a new one. If not, initialize the first column:
    .check_for_list:
        cmp qword [rel lcl_tm_column_format_list_ptr], 0
        jne .add

    ; Create first column format.
    .initiate:
        mov rcx, column_format_size
        call malloc

        jmp .set_up_list_pointer

    ; Realllocate memory space:
    ; Multiplicate column_format_size times column_count to get the amount of bytes needed for the array.
    .add:
        mov rcx, [rel lcl_table_ptr]

        ; Set up right size for new pointer.
        mov edx, [rcx + table.column_count]
        imul rdx, column_format_size

        ; Use the column format list pointer as pointer to update.
        mov rcx, [rcx + table.column_format_list_ptr]
        call realloc

    ; Save the pointer into the table and locally for this file.
    .set_up_list_pointer:
        mov rdx, [rel lcl_table_ptr]

        mov [rel lcl_tm_column_format_list_ptr], rax
        mov [rdx + table.column_format_list_ptr], rax

    .set_up_column_format:
        ; I am looking for the last column format to set it up correctly.
        mov rax, column_format_size
        mul dword [rdx + table.column_count]
        add rax, [rel lcl_tm_column_format_list_ptr]
        ; Now RAX points to the last column format in the list.

        ; Move the length of the entries in this column into preserved memory space.
        mov ecx, [rbp + 16]
        mov [rax + column_format.entry_length], ecx

        ; Move entry type in this column into preserved memory space:
        ; * 0 = String
        ; * 1 = int
        ; ! This is important for the designer to know, how the content should be printed into the console.
        mov ecx, [rbp + 24]
        mov [rax + column_format.entry_type], ecx

    .complete:
        ; At the End, the table pointer is returned in RAX and the column count is incremented.
        mov rax, [rel lcl_table_ptr]
        inc dword [rax + table.column_count]

        ; Restore old stack frame and return to caller.
        mov rsp, rbp
        pop rbp
        ret

;;;;;; DEBUGGING ;;;;;; 

_tm_malloc_failed:
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

_tm_object_failed:
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