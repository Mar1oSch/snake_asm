%include "../include/organizer/table/table_struc.inc"
%include "../include/organizer/table/column_struc.inc"

global table_manager_create_table, table_manager_add_column, table_manager_add_content
section .data
    list_length_counter dd 0

section .bss
    TABLE_MANAGER_TABLE_PTR resq 1
    TABLE_MANAGER_COLUMN_LIST_PTR resq 1

section .text
    extern malloc, realloc, free

table_manager_create_table:
    push rbp
    mov rbp, rsp
    sub rsp, 48

    ; Expect amount of rows in ECX.
    mov [rbp - 8], ecx

    mov rcx, table_size
    call malloc
    mov qword [rel TABLE_MANAGER_TABLE_PTR], rax

    mov ecx, [rbp - 8]
    mov [rax + table.row_count], ecx

    mov dword [rax + table.column_count], 0

    mov rsp, rbp
    pop rbp
    ret

table_manager_add_content:
    push rbp
    mov rbp, rsp

    ; Expect pointer to content in RCX.
    mov rax, [rel TABLE_MANAGER_TABLE_PTR]
    mov [rax + table.content_ptr], rcx

    mov rsp, rbp
    pop rbp
    ret

table_manager_add_column:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    ; Expect length of entries in column in CL.
    ; Expect type of entries in column in DL.
    mov [rbp - 8], cl
    mov [rbp - 16], dl

    cmp qword [rel TABLE_MANAGER_COLUMN_LIST_PTR], 0
    jne .add_new

.initiate:
    mov rcx, column_size
    call malloc
    mov [rel TABLE_MANAGER_COLUMN_LIST_PTR], rax

    mov rdx, [rel TABLE_MANAGER_TABLE_PTR]
    mov [rdx + table.column_list_ptr], rax

    mov cl, [rbp - 8]
    mov [rax + column.entry_length], cl

    mov cl, [rbp - 16]
    mov [rax + column.entry_type], cl

    jmp .complete

.add_new:
    mov rcx, [rel TABLE_MANAGER_COLUMN_LIST_PTR]
    mov rdx, column_size
    call realloc
    mov [rel TABLE_MANAGER_COLUMN_LIST_PTR], rax

    mov rdx, [rel TABLE_MANAGER_TABLE_PTR]
    mov [rdx + table.column_list_ptr], rax

    mov rax, column_size
    mul dword [rdx + table.column_count]

    add rax, [rel TABLE_MANAGER_COLUMN_LIST_PTR]

    mov cl, [rbp - 8]
    mov [rax + column.entry_length], cl

    mov cl, [rbp - 16]
    mov [rax + column.entry_type], cl

.complete:
    mov rax, [rel TABLE_MANAGER_TABLE_PTR]
    inc dword [rax + table.column_count]

    mov rsp, rbp
    pop rbp
    ret