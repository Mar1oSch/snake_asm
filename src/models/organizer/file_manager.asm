; Data:
%include "../include/data/file_manager_data/file_manager_data.inc"

; Strucs:
%include "../include/strucs/organizer/file_manager_struc.inc"
%include "../include/strucs/organizer/table/table_struc.inc"

; The file manager handles the communication with the leaderboard.bin. It creates and updates players and their entries.
; 
global file_manager_new, file_manager_add_leaderboard_record, file_manager_destroy, file_manager_get_record_by_index, file_manager_get_name, file_manager_update_highscore, file_manager_get_num_of_entries, file_manager_get_total_bytes, file_manager_create_table_from_file, file_manager_destroy_table_from_file, file_manager_update_table

section .rodata
    leaderboard_file_name db "leaderboard.bin", 0  

    ;;;;;; Debugging ;;;;;;
    constructor_name db "file_manager_new", 0
    format db "%16s", 0

section .bss
    ; Memory space for the created file manager pointer.
    ; Since there is always just one file manager in the game, I decided to create a kind of a singleton.
    ; If this lcl_file_manager_ptr is 0, the constructor will create a new file manager object.
    ; If it is not 0, it simply is going to return this pointer.
    ; This pointer is also used, to reference the object in the destructor and other functions.
    ; So it is not needed to pass a pointer to the object itself as function parameter.
    lcl_file_manager_ptr resq 1

    ; Two variables indicating the existance of a header in the file.
    ; They are checked to ensure, the file header is initialized.
    lcl_file_size_large_int resq 1
    lcl_fm_header resq 2

    ; Using these variables to store the names or record sizes to search for.
    lcl_fm_active_record resb FILE_RECORD_SIZE
    lcl_fm_active_name resb FILE_NAME_SIZE

    ; Storing the active file pointer in here. So Instead of having to find out, where the filepointer points to atm, it is just saved here.
    lcl_fm_active_file_ptr resq 1


    ; A parameter to recieve the actual amount of bytes written (it is passed into "WriteFile")
    lcl_bytes_written resd 1

    ; A parameter to recieve the actual amount of bytes read (it is passed into "ReadFile")
    lcl_bytes_read resd 1

section .text
    extern malloc, realloc, free

    extern CreateFileA, CloseHandle
    extern ReadFile, WriteFile
    extern GetFileSizeEx, SetFilePointerEx

    extern table_manager_create_table, table_manager_add_column, table_manager_add_content, table_manager_destroy_table
    extern helper_merge_sort_list

    extern malloc_failed, object_not_created

;;;;;; PUBLIC METHODS ;;;;;;
file_manager_new:
    .set_up:
        ; Set up stack frame:
        ; * 24 bytes function params.
        ; * 8 bytes to keep stack 16-byte aligned.
        push rbp
        mov rbp, rsp
        sub rsp, 32

        ; If a file manager already exists, skip the creation and simply return the pointer to it.
        cmp qword [rel lcl_file_manager_ptr], 0
        jne .complete           

        ; Reserve 32 bytes shadow space for called functions. 
        sub rsp, 32

    .create_object:
        ; Creating the file_manager, containing space for:
        ; * - File handle. (8 bytes)
        mov rcx, file_manager_size
        call malloc
        ; Pointer to file_manager object is stored in RAX now.
        ; Check if return of malloc is 0 (if it is, it failed).
        ; If it failed, it will get printed into the console.
        test rax, rax
        jz _fm_malloc_failed

        ; Save pointer to initially reserved space. Object is "officially" created now.
        mov [rel lcl_file_manager_ptr], rax

    .create_file:
        lea rcx, [rel leaderboard_file_name]                ; lpFileName
        mov rdx, GENERIC_READ | GENERIC_WRITE               ; dwDesiredAccess
        mov r8, FILE_SHARE_READ | FILE_SHARE_WRITE          ; dwShareMode
        mov r9, 0                                           ; lpSecurityAttributes (optional)
        mov dword [rsp + 32], OPEN_ALWAYS                   ; dwCreationDisposition
        mov dword [rsp + 40], FILE_ATTRIBUTE_NORMAL         ; dwFlagsAndAttributes
        mov dword [rsp + 48], 0                             ; hTemplateFile (optional)
        call CreateFileA

    .set_up_object:
        mov rcx, [rel lcl_file_manager_ptr]
        mov [rcx + file_manager.file_handle], rax

    .complete:
        ; Return file manager pointer in RAX.
        mov rax, [rel lcl_file_manager_ptr]

        ; Restore old stack frame and return to caller.
        mov rsp, rbp
        pop rbp
        ret

; Simple destructor to free memory space.
file_manager_destroy:
    .set_up:
        ; Set up stack frame without local variables.
        push rbp
        mov rbp, rsp

        ; If file_manager is not created, let the user know.
        cmp qword [rel lcl_file_manager_ptr], 0
        je _fm_object_failed

        ; Reserve 32 bytes shadow space for called functions. 
        sub rsp, 32

    .destroy_object:
        ; Use the local lcl_file_manager_ptr to free the memory space and set it back to 0.
        mov rcx, [rel lcl_file_manager_ptr]
        call free
        mov qword [rel lcl_file_manager_ptr], 0

    .complete:
        ; Restore old stack frame and leave destructor.
        mov rsp, rbp
        pop rbp
        ret

; Creating the leaderboard from the leaderboard.bin.
file_manager_create_table_from_file:
    .set_up:
        ; Set up stack frames.
        ; * 16 bytes local variables.
        push rbp
        mov rbp, rsp
        sub rsp, 16

        ; If file_manager is not created, let the user know.
        cmp qword [rel lcl_file_manager_ptr], 0
        je _fm_object_failed

        ; Reserve 32 bytes shadow space for called functions. 
        sub rsp, 32
    
    .init_header:
        call _ensure_header_initialized

    .get_total_bytes:
        call file_manager_get_total_bytes

    .get_memory_space:
        mov rcx, rax
        call malloc

    .save_records:
        mov rcx, rax
        call _get_all_records
        ; * First local variable: String containing all records.
        mov [rbp - 8], rax

    .get_rows:
        call file_manager_get_num_of_entries

    .create_object:
        mov rcx, rax
        call table_manager_create_table
        ; * Second local variable: Pointer to created table.
        mov [rbp - 16], rax

    .add_first_column:
        mov ecx, FILE_NAME_SIZE
        xor rdx, rdx
        call table_manager_add_column

    .add_second_column:
        mov ecx, FILE_HIGHSCORE_SIZE
        mov edx, 1
        call table_manager_add_column

    .add_content:
        mov rcx, [rbp - 8]
        call table_manager_add_content

    .complete:
        ; Return pointer to table in RAX.
        mov rax, [rbp - 16]

        ; Restore old stack frame and return to caller.
        mov rsp, rbp
        pop rbp
        ret

file_manager_destroy_table_from_file:
    ; * Expect pointer to table in RCX.
    .set_up:
        ; Set up stack frame without local variables.
        push rbp
        mov rbp, rsp

        ; If file_manager is not created, let the user know.
        cmp qword [rel lcl_file_manager_ptr], 0
        je _fm_object_failed

        ; Reserve 32 bytes shadow space for called functions. 
        sub rsp, 32

    .destroy_object:
        call table_manager_destroy_table

    .complete:
        ; Restore old stack frame and return to caller.
        mov rsp, rbp
        pop rbp
        ret

;;;;;; ADD FUNCTIONS ;;;;;;

; If a new player is created, it gets added into the leaderboard file. The magic happens in this function.
file_manager_add_leaderboard_record:
    ; * Expect pointer to player_name in RCX.
    ; * Expect highscore in RDX.
    .set_up:
        ; Set up stack frame without local variables.
        push rbp
        mov rbp, rsp

        ; Save regs into shadow space.
        mov [rbp + 16], rcx
        mov [rbp + 24], rdx

        ; If file_manager is not created, let the user know.
        cmp qword [rel lcl_file_manager_ptr], 0
        je _fm_object_failed

        ; Reserve 32 bytes shadow space for called functions. 
        sub rsp, 32

    .init_header:
        call _ensure_header_initialized

    .set_position:
        call _set_pointer_end

    .write_name:
        mov rcx, [rbp + 16]
        mov rdx, FILE_NAME_SIZE
        call _fm_write

    .write_highscore:
        lea rcx, [rbp + 24]
        mov rdx, FILE_HIGHSCORE_SIZE
        call _fm_write

    .complete:
        ; Restore old stack frame and return to caller.
        mov rsp, rbp
        pop rbp
        ret

;;;;;; UPDATE ;;;;;;

; Change the highscore entry for a player at index RDX.
file_manager_update_highscore:
    ; * Expect highscore in RCX.
    ; * Expect player index in RDX.
    .set_up:
        ; Set up stack frame without local variables.
        push rbp
        mov rbp, rsp

        ; Save regs into shadow space.
        mov [rbp + 16], rcx
        mov [rbp + 24], rdx

        ; If file_manager is not created, let the user know.
        cmp qword [rel lcl_file_manager_ptr], 0
        je _fm_object_failed

        ; Reserve 32 bytes shadow space for called functions. 
        sub rsp, 32

    .init_header:
        call _ensure_header_initialized

    .set_position:
        mov rcx, [rbp + 24]
        mov rdx, FILE_HIGHSCORE_OFFSET
        call _set_pointer

    .update_highscore:
        lea rcx, [rbp + 16]
        mov rdx, FILE_HIGHSCORE_SIZE
        call _fm_write

    .sort_leaderboard:
        call _update_leaderboard_in_file

    .complete:
        ; Restore old stack frame and return to caller.
        mov rsp, rbp
        pop rbp
        ret

; Updating the table with new leaderboard entries.
file_manager_update_table:
    ; * Expect pointer to table in RCX.
    .set_up:
        ; Set up stack frame:
        ; * 16 bytes local variables.
        push rbp
        mov rbp, rsp
        sub rsp, 16

        ; Save non-volatile regs.
        mov [rbp - 8], rbx
        mov [rbp - 16], r12

        ; Save pointer to table in RBX.
        mov rbx, rcx

        ; If file_manager is not created, let the user know.
        cmp qword [rel lcl_file_manager_ptr], 0
        je _fm_object_failed

        ; Reserve 32 bytes shadow space for called functions. 
        sub rsp, 32

    .init_header:
        call _ensure_header_initialized

    .update_row_count:
        call file_manager_get_num_of_entries
        mov edx, [rbx + table.row_count]
        mov [rbx + table.row_count], eax

    .update_content:
        call file_manager_get_total_bytes
        mov rdx, rax
        mov rcx, [rbx + table.content_ptr]
        call realloc
        mov r12, rax

    .sort_leaderboard:
        call _update_leaderboard_in_file

    .save_records:
        mov rcx, r12
        call _get_all_records

    .update_table:
        mov [rbx + table.content_ptr], r12

    .complete:
        ; Return table pointer in RAX.
        mov rax, rbx

        ; Restore non-volatile regs.
        mov r12, [rbp - 16]
        mov rbx, [rbp - 8]

        ; Restore old stack frame and return to caller.
        mov rsp, rbp
        pop rbp
        ret

;;;;;; GETTER ;;;;;;

; Recieving the index as parameter and return the record belonging to that index.
file_manager_get_record_by_index:
    ; * Expect buffer to player_struc in RCX.
    ; * Expect index of player in file in RDX.
    .set_up:
        ; Set up stack frame without local variables.
        push rbp
        mov rbp, rsp

        ; Save regs into shadow space.
        mov [rbp + 16], rcx
        mov [rbp + 24], rdx

        ; If file_manager is not created, let the user know.
        cmp qword [rel lcl_file_manager_ptr], 0
        je _fm_object_failed

        ; Reserve 32 bytes shadow space for called functions. 
        sub rsp, 32

    .init_header:
        call _ensure_header_initialized

    .set_position:
        mov rcx, [rbp + 24]
        mov rdx, FILE_NAME_OFFSET
        call _set_pointer

    .get_record:
        ; Read record into passed pointer.
        mov rcx, [rbp + 16]
        mov rdx, FILE_RECORD_SIZE
        call _fm_read

    .complete:
        ; Restore old stack frame and return to caller.
        mov rsp, rbp
        pop rbp
        ret

; This function looks for a specified name (handed in by the register RCX) and returns its index in RAX if found.
; If it doesn't find that name, it returns -1 in RAX.
file_manager_get_name:
    ; * Expect pointer to name in RCX.
    .set_up:
        ; Set up stack frame:
        ; * 32 bytes local variables.
        push rbp
        mov rbp, rsp
        sub rsp, 32

        ; Save non-volatile regs.
        mov [rbp - 8], rsi
        mov [rbp - 16], rdi
        mov [rbp - 24], rbx
        mov [rbp - 32], r12

        ; Make RBX point to the desired name.
        mov rbx, rcx

        ; Set loop counter to zero (will be the index of the name).
        xor r12, r12

        ; Reserve 32 bytes shadow space for called functions.
        sub rsp, 32

    .init_header:
        call _ensure_header_initialized

    .find_name_loop:
        ; Load active name into lcl_fm_active_name.
        lea rcx, [rel lcl_fm_active_name]
        mov rdx, r12
        call _get_name

        ; If 0 bytes were read, end of file is reached.
        cmp dword [rel lcl_bytes_read], 0
        je .not_equal

        ; Prepare name passed into the function and read name from file to compare them.
        mov rsi, rbx
        mov rdi, rax

        .check_name_loop:
            ; Compare the names byte by byte. 
            ; If RCX reaches 0, and Zeroflag is set, the name is equal.
            mov rcx, FILE_NAME_SIZE
            cld
            repe cmpsb
            jz .equal

    .find_name_loop_handle:
        ; Move to the next name.
        inc r12
        jmp .find_name_loop

    .equal:
        ; If it is that name, return the index.
        mov rax, r12
        jmp .complete

    .not_equal:
        ; If there is no equal name, return -1 (since 0 is a potential index).
        mov rax, -1

    .complete:
        ; Restore non-volatile registers.
        mov r12, [rbp - 32]
        mov rbx, [rbp - 24]
        mov rdi, [rbp - 16]
        mov rsi, [rbp - 8]

        ; Restore old stack frame and return to caller.
        mov rsp, rbp
        pop rbp
        ret

file_manager_get_total_bytes:
    .set_up:
        ; Set up stack frame without local variables.
        push rbp
        mov rbp, rsp

        ; If file_manager is not created, let the user know.
        cmp qword [rel lcl_file_manager_ptr], 0
        je _fm_object_failed

        ; Reserve 32 bytes shadow space for called functions. 
        sub rsp, 32

    .init_header:
        call _ensure_header_initialized

    .get_bytes:
        call _set_pointer_end
        ; File pointer is at the end of file and contains the total bytes number.
        ; Subtract the HEADER_SIZE and return the result.
        mov rax, [rel lcl_fm_active_file_ptr]
        sub rax, HEADER_SIZE

    .complete:
        ; Restore old stack frame and return to caller.
        mov rsp, rbp
        pop rbp
        ret


file_manager_get_num_of_entries:
    .set_up:
        ; Set up stack frame without local variables.
        push rbp
        mov rbp, rsp

        ; If file_manager is not created, let the user know.
        cmp qword [rel lcl_file_manager_ptr], 0
        je _fm_object_failed

        ; Reserve 32 bytes shadow space for called functions. 
        sub rsp, 32

    .init_header:
        call _ensure_header_initialized

    .get_num:
        ; Get the total bytes and divide it by the FILE_RECORD_SIZE.
        call file_manager_get_total_bytes
        mov rcx, FILE_RECORD_SIZE
        xor rdx, rdx
        div rcx

    .complete:
        ; Return num of entries in RAX.

        ; Restore old stack frame and return to caller.
        mov rsp, rbp
        pop rbp
        ret




;;;;;; PRIVATE METHODS ;;;;;;

;;;;;; READ ;;;;;;

_fm_read:
    ; * Expect pointer to string to load read chars into in RCX.
    ; * Expect number of bytes to read in RDX.
    .set_up:
        ; Set up stack frame:
        ; * 8 bytes function params.
        ; * 8 bytes to keep stack 16-byte aligned.
        push rbp
        mov rbp, rsp
        sub rsp, 16

        ; If file_manager is not created, let the user know.
        cmp qword [rel lcl_file_manager_ptr], 0
        je _fm_object_failed

        ; Reserve 32 bytes shadow space for called functions. 
        sub rsp, 32

    .read:
        mov r8, rdx
        mov rdx, rcx
        mov rcx, [rel lcl_file_manager_ptr]
        mov rcx, [rcx + file_manager.file_handle]
        lea r9, [rel lcl_bytes_read]
        mov qword [rsp + 32], 0
        call ReadFile

    .complete:
        ; Restore old stack frame and return to caller.
        mov rsp, rbp
        pop rbp
        ret

;;;;;; WRITE ;;;;;;
_fm_write:
    ; * Expect pointer to string to write in RCX.
    ; * Expect amount of bytes to write in RDX.
    .set_up:
        ; Set up stack frame:
        ; * 8 bytes for function params.
        ; * 8 bytes to keep stack 16-byte aligned.
        push rbp
        mov rbp, rsp
        sub rsp, 16

        ; If file_manager is not created, let the user know.
        cmp qword [rel lcl_file_manager_ptr], 0
        je _fm_object_failed

        ; Reserve 32 bytes shadow space for called functions. 
        sub rsp, 32

    .write:
        mov r8, rdx
        mov rdx, rcx
        mov rcx, [rel lcl_file_manager_ptr]
        mov rcx, [rcx + file_manager.file_handle]
        lea r9, [rel lcl_bytes_written]
        mov qword [rsp + 32], 0
        call WriteFile

    .complete:
        ; Restore old stack frame and return to caller.
        mov rsp, rbp
        pop rbp
        ret

;;;;;; SETTER ;;;;;;
_set_pointer:
    ; * Expect index in RCX.
    ; * Expect offset in RDX.
    .set_up:
        ; Set up stack frame without local variables.
        push rbp
        mov rbp, rsp

        ; If file_manager is not created, let the user know.
        cmp qword [rel lcl_file_manager_ptr], 0
        je _fm_object_failed

        ; Save params into shadow space.
        mov [rbp + 16], rdx

        ; Reserve 32 bytes shadow space for called functions. 
        sub rsp, 32

    .calculate_position:
        mov rdx, rcx
        ; Multiplicate index with the record size, to jump to destination record.
        imul rdx, FILE_RECORD_SIZE   

        ; Add the HEADER_SIZE to get to the right offset.
        add rdx, HEADER_SIZE  

        ; Add the offset to get either to the name or highscore.
        add rdx, [rbp + 16]                      

    .set_position:
        mov rcx, [rel lcl_file_manager_ptr]
        mov rcx, [rcx + file_manager.file_handle]
        lea r8, [rel lcl_fm_active_file_ptr]
        mov r9, FILE_BEGIN
        call SetFilePointerEx

    .complete:
        ; Restore old stack frame and return to caller.
        mov rsp, rbp
        pop rbp
        ret

_set_pointer_start:
    .set_up:
        ; Set up stack frame without local variables.
        push rbp
        mov rbp, rsp

        ; If file_manager is not created, let the user know.
        cmp qword [rel lcl_file_manager_ptr], 0
        je _fm_object_failed

        ; Reserve 32 bytes shadow space for called functions. 
        sub rsp, 32

    .set_position:
        mov rcx, [rel lcl_file_manager_ptr]
        mov rcx, [rcx + file_manager.file_handle]
        xor rdx, rdx
        lea r8, [rel lcl_fm_active_file_ptr]
        mov r9, FILE_BEGIN
        call SetFilePointerEx

    .complete:
        ; Restore old stack frame and return to caller.
        mov rsp, rbp
        pop rbp
        ret

_set_pointer_end:
    .set_up:
        ; Set up stack frame without local variables.
        push rbp
        mov rbp, rsp

        ; If file_manager is not created, let the user know.
        cmp qword [rel lcl_file_manager_ptr], 0
        je _fm_object_failed

        ; Reserve 32 bytes shadow space for called functions. 
        sub rsp, 32

    .set_position:
        mov rcx, [rel lcl_file_manager_ptr]
        mov rcx, [rcx + file_manager.file_handle]
        xor rdx, rdx
        lea r8, [rel lcl_fm_active_file_ptr]
        mov r9, FILE_END
        call SetFilePointerEx

    .complete:
        ; Restore old stack frame and return to caller.
        mov rsp, rbp
        pop rbp
        ret


;;;;;; GETTER ;;;;;;
_get_name:
    ; * Expect pointer to buffer to save name into in RCX.
    ; * Expect index of desired record in RDX
    .set_up:
        ; Set up stack frame:
        ; * 8 bytes local variables.
        ; * 8 bytes to keep stack 16-byte aligned.
        push rbp
        mov rbp, rsp
        sub rsp, 16

        ; Save non-volatile regs.
        mov [rbp - 8], rbx

        ; Save params into non-volatile regs.
        mov rbx, rcx

        ; If file_manager is not created, let the user know.
        cmp qword [rel lcl_file_manager_ptr], 0
        je _fm_object_failed

        ; Reserve 32 bytes shadow space for called functions. 
        sub rsp, 32

    .set_position:
        mov rcx, rdx
        mov rdx, FILE_NAME_OFFSET
        call _set_pointer

    .read:
        mov rcx, rbx
        mov rdx, FILE_NAME_SIZE
        call _fm_read

    .complete:
        ; Return pointer to name in RAX.
        mov rax, rbx

        ; Restore non-volatile regs.
        mov rbx, [rbp - 8]

        ; Restore old stack frame and return to caller.
        mov rsp, rbp
        pop rbp
        ret

_get_all_records:
    ; * Expect pointer to memory, big enough to hold records in RCX.
    .set_up:
        ; Set up stack frame:
        ; * 16 bytes local variables.
        push rbp
        mov rbp, rsp
        sub rsp, 16

        ; Save non-volatile regs.
        mov [rbp - 8], rbx

        ; Save params into non-volatile regs.
        mov rbx, rcx

        ; If file_manager is not created, let the user know.
        cmp qword [rel lcl_file_manager_ptr], 0
        je _fm_object_failed

        ; Reserve 32 bytes shadow space for called functions. 
        sub rsp, 32

    .get_bytes:
        call file_manager_get_total_bytes
        ; * Second local variable: total bytes of file.
        mov [rbp - 16], rax

    .set_position:
        xor rcx, rcx
        mov rdx, FILE_NAME_OFFSET
        call _set_pointer

    .read:
        mov rcx, rbx
        mov rdx, [rbp - 16]
        call _fm_read

    .complete:
        ; Return pointer to entries in RAX.
        mov rax, rbx

        ; Restore non-volatile regs.
        mov rbx, [rbp - 8]

        ; Restore old stack frame and return to caller.
        mov rsp, rbp
        pop rbp
        ret

;;;;;; UPDATE ;;;;;;

_update_leaderboard_in_file:
    .set_up:
        ; Set up stack frame:
        ; * 16 bytes local variables.
        ; * 8 bytes function params.
        ; * 8 bytes to keep stack 16-byte aligned.
        push rbp
        mov rbp, rsp
        sub rsp, 32

        ; Save non-volatile regs.
        mov [rbp - 8], rbx
        mov [rbp - 16], r12

        ; If file_manager is not created, let the user know.
        cmp qword [rel lcl_file_manager_ptr], 0
        je _fm_object_failed

        ; Reserve 32 bytes shadow space for called functions. 
        sub rsp, 32

    .get_bytes:
        call file_manager_get_total_bytes
        mov r12, rax

    .get_memory_space:
        mov rcx, rax
        call malloc
        mov rbx, rax

    .get_records:
        mov rcx, rax
        call _get_all_records

    .get_num:
        call file_manager_get_num_of_entries

    .merge_sort:
        mov rcx, rbx
        mov rdx, rax
        mov r8, FILE_RECORD_SIZE
        mov r9, FILE_HIGHSCORE_OFFSET
        mov qword [rsp + 32], FILE_HIGHSCORE_SIZE
        call helper_merge_sort_list

    .set_position:
        xor rcx, rcx
        xor rdx, rdx
        call _set_pointer

    .write:
        mov rcx, rbx
        mov rdx, r12
        call _fm_write

    .free_memory_space:
        mov rcx, rbx
        call free

    .complete:
        ; Restore non-volatile regs:
        mov r12, [rbp - 16]
        mov rbx, [rbp - 8]

        ; Restore old stack frame and return to caller.
        mov rsp, rbp
        pop rbp
        ret





;;;;;; INIT HEADER ;;;;;;

_ensure_header_initialized:
    push rbp
    mov rbp, rsp
    sub rsp, 48

    ; Save non-volatile registers.
    mov [rbp - 8], rbx

    mov rbx, [rel lcl_file_manager_ptr]
    mov rbx, [rbx + file_manager.file_handle]

    mov rcx, rbx
    lea rdx, [rel lcl_file_size_large_int]
    call GetFileSizeEx
    test eax, eax
    jz .init_header

    mov rax, [rel lcl_file_size_large_int]
    cmp rax, HEADER_SIZE
    jb .init_header

    call _set_pointer_start

    lea rcx, [rel lcl_fm_header]
    mov rdx, HEADER_SIZE
    call _fm_read
    test eax, eax
    jz .init_header

    mov eax, [rel lcl_fm_header]
    cmp eax, [rel magic]
    jne .init_header

    movzx eax, word [rel lcl_fm_header + 8]
    cmp ax, FILE_RECORD_SIZE
    jne .init_header

    xor rax, rax
    jmp .complete

.init_header:
    call _set_pointer_start

    lea rcx, [rel header_template]
    mov rdx, HEADER_SIZE
    call _fm_write

    xor rax, rax

.complete:
    mov rbx, [rbp - 8]
    mov rsp, rbp
    pop rbp
    ret


;;;;;; ERROR HANDLING ;;;;;;

_fm_malloc_failed:
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

_fm_object_failed:
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