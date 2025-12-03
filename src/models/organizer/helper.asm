global helper_get_digits_of_number, helper_parse_saved_number_to_written_number, helper_is_input_just_numbers, helper_parse_string_to_int, helper_parse_int_to_string, helper_merge_sort_list, helper_change_position
section .data
    convert_number db "0000", 0

section .text
    extern malloc, free

helper_get_digits_of_number:
    push rbp
    mov rbp, rsp

    ; * Expectnumber in RCX.
    mov rax, rcx
    mov r8, 10
    xor rcx, rcx
.loop:
    xor rdx, rdx
    div r8
    test rax, rax
    jz .last_step
    inc rcx
    jmp .loop

.last_step:
    test rdx, rdx
    jz .complete
    inc rcx

.complete:
    mov rax, rcx
    mov rsp, rbp
    pop rbp
    ret

helper_is_input_just_numbers:
    push rbp
    mov rbp, rsp
    sub rsp, 48

    ; * Expectpointer to string in RCX.
    ; * Expectnumber of digits to parse in RDX.
    mov [rbp - 8], rdx

    mov rax, rcx
    mov rcx, rdx

.loop:
    mov dl, [rax]
    cmp dl, 13
    je .check_rcx
    cmp dl, "0"
    jb .wrong
    cmp dl, "9"
    ja .wrong
    inc rax
    loop .loop

.check_rcx:
    cmp rcx, [rbp - 8]
    jae .wrong

.right:
    mov rax, 1
    jmp .complete
.wrong:
    xor rax, rax

.complete:
    mov rsp, rbp
    pop rbp
    ret

helper_parse_int_to_string:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    ; Save non-volatile regs.
    mov [rbp - 8], rdi

    ; * Expectpointer to save number to in RCX.
    ; * Expectnumber in RDX.
    ; * Expectnumber of digits to write in R8.
    mov rdi, rcx
    mov rax, rdx
    mov rcx, r8

    mov r9, 10
    add rdi, rcx
    dec rdi

.loop:
    xor rdx, rdx
    div r9 
    add dl, "0"
    mov [rdi], dl
    dec rdi
    loop .loop

.complete:
    lea rax, [rdi + 1]

    ; Restore non-volatile regs.
    mov rdi, [rbp - 8]

    mov rsp, rbp
    pop rbp
    ret

helper_parse_saved_number_to_written_number:
    push rbp
    mov rbp, rsp
    sub rsp, 48

    ; Save non-volatile regs.
    mov [rbp - 8], rbx

    ; * Expectpointer to number (dword) in RCX.
    ; * Expectnumber of digits to parse in RDX.
    mov eax, [rcx]
    mov rcx, rdx
    mov ebx, 10
    lea rsi, [rel convert_number + 3]

.loop:
    xor rdx, rdx
    div ebx
    add dl, "0"
    mov [rsi], dl
    dec rsi
    loop .loop

    lea rax, [rel convert_number]

.complete:
    ; Restore non-volatile regs.
    mov rbx, [rbp - 8]

    mov rsp, rbp
    pop rbp
    ret

helper_parse_string_to_int:
    push rbp
    mov rbp, rsp
    sub rsp, 48

    ; * Expectpointer to string in RCX.
    ; * Expectnumber of digits to create in RDX.
    mov [rbp - 8], rcx
    mov [rbp - 16], rdx
    call _get_digits_in_string

    mov r8, [rbp - 8]
    mov rcx, rax
    mov r9, 10
    xor r10, r10

.loop:
    movzx rax, byte [r8]
    sub rax, "0"                                        ; sub rcx, 48
    mov r11, rcx
    dec r11
    .inner_loop:
        test r11, r11
        jz .loop_handle
        mul r9
        dec r11
        jmp .inner_loop
.loop_handle:
    add r10, rax
    inc r8
    loop .loop

.complete:
    mov rax, r10

    mov rsp, rbp
    pop rbp
    ret

helper_merge_sort_list:
    push rbp
    mov rbp, rsp
    sub rsp, 200

    ; Define basecase:
    cmp rdx, 1
    jbe .base_case

    ; Save non-volatile regs.
    mov [rbp - 8], rsi
    mov [rbp - 16], rdi

    ; * Expectpointer to list in RCX.
    ; * Expectamount of list records in RDX.
    ; * Expectrecord length in R8.
    ; * Expectoffset of value to compare in R9.
    ; * Expectsize of compared value on stack.
    mov [rbp - 24], rcx
    mov [rbp - 32], r8
    mov [rbp - 40], r9
    mov r10, [rbp + 48]
    mov [rbp - 48], r10

    mov rax, rdx 
    shr rax, 1                                  ; Length of first list.
    sub rdx, rax                                ; Length of second list.

    ; Save Length of lists.
    mov [rbp - 56], rdx
    mov [rbp - 64], rax

.create_first_list:
    ; Create first list:
    mov rcx, [rbp - 56]
    imul rcx, [rbp - 32]
    call malloc

    mov rdi, rax
    mov rsi, [rbp - 24]
    mov rcx, [rbp - 56]
    imul rcx, [rbp - 32]
    cld
    rep movsb

    mov rcx, [rbp - 56]
    imul rcx, [rbp - 32]
    sub rdi, rcx
    mov [rbp - 72], rdi

    mov rcx, rdi
    mov rdx, [rbp - 56]
    mov r8, [rbp - 32]
    mov r9, [rbp - 40]
    mov r10, [rbp - 48]
    mov [rsp + 32], r10
    call helper_merge_sort_list
    mov [rbp - 72], rax

.create_second_list:
    ; Create second list:
    mov rcx, [rbp - 64]
    imul rcx, [rbp - 32]
    call malloc

    mov rdi, rax
    mov rsi, [rbp - 24]
    mov rcx, [rbp - 56]
    imul rcx, [rbp - 32]
    add rsi, rcx

    mov rcx, [rbp - 64]
    imul rcx, [rbp - 32]
    cld
    rep movsb

    mov rcx, [rbp - 64]
    imul rcx, [rbp - 32]
    sub rdi, rcx
    mov [rbp - 80], rdi

    mov rcx, rdi
    mov rdx, [rbp - 64]
    mov r8, [rbp - 32]
    mov r9, [rbp - 40]
    mov r10, [rbp - 48]
    mov [rsp + 32], r10
    call helper_merge_sort_list
    mov [rbp - 80], rax

    mov rcx, [rbp - 24]
    mov rdx, [rbp - 72]
    mov r8, [rbp - 56]
    mov r9, [rbp - 80]
    mov r10, [rbp - 64]
    mov [rsp + 32], r10
    mov r10, [rbp - 32]
    mov [rsp + 40], r10
    mov r10, [rbp - 40]
    mov [rsp + 48], r10
    mov r10, [rbp - 48]
    mov [rsp + 56], r10
    call _merge

.complete:
    mov rsi, [rbp - 8]
    mov rdi, [rbp - 16]

    mov rsp, rbp
    pop rbp
    ret

.base_case:
    mov rax, rcx
    mov rsp, rbp
    jmp .complete

helper_change_position:
    push rbp
    mov rbp, rsp

    ; * Expectposition in ECX.
    ; * Expectnew X-Value (word) in DX.
    ; * Expectnew Y-Value (word) in R8W.
    add cx, r8w
    ror rcx, 16
    add cx, dx
    rol rcx, 16

    mov eax, ecx

    mov rsp, rbp
    pop rbp
    ret

;;;;;; PRIVATE METHODS ;;;;;;
_get_digits_in_string:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    ; * Expectpointer to string in RCX.
    ; * Expectnumber of possible digits in RDX.
    mov rax, rcx
    xor rcx, rcx

.loop:
    cmp byte [rax], "0"
    jb .complete
    cmp byte [rax], "9"
    ja .complete
    cmp rcx, rdx
    je .complete
.loop_handle:
    inc rax
    inc rcx
    jmp .loop

.complete:
    mov rax, rcx

    mov rsp, rbp
    pop rbp
    ret

_merge:
    push rbp
    mov rbp, rsp
    sub rsp, 200

    ; Save non-volatile regs.
    mov [rbp - 8], rsi
    mov [rbp - 16], rdi
    mov [rbp - 24], r13
    mov [rbp - 32], r14
    mov [rbp - 40], r15
    mov [rbp - 48], rbx

    ; * Expectpointer to save merged list in RCX.
    ; * Expectpointer to left list in RDX.
    ; * Expectlength of left list in R8.
    ; * Expectpointer to right list in R9.
    ; * Expectlength of right list on Stack.
    ; * Expectrecord size on Stack.
    ; * Expectoffset of value on Stack.
    ; * Expectsize of compared record on Stack.
    mov [rbp - 56], rcx
    mov [rbp - 64], rdx
    mov [rbp - 72], r8
    mov [rbp - 80], r9
    mov r10, [rbp + 48]
    mov [rbp - 88], r10
    mov r10, [rbp + 56]
    mov [rbp - 96], r10
    mov r10, [rbp + 64]
    mov [rbp - 104], r10
    mov r10, [rbp + 72]
    mov [rbp - 112], r10

    xor r8, r8
    mov [rbp - 120], r8
    mov [rbp - 128], r8

    ; Save pointer to Targetlist in RDI.
    mov rdi, rcx
    ; Save record size into R15.
    mov r15, [rbp - 96]
    ; Save offset into RBX.
    mov rbx, [rbp - 104]


.loop:
    ; Save pointer to left list into R13.
    mov r13, [rbp - 64]
    ; Save pointer to right list into R14.
    mov r14, [rbp - 80]

    mov r8, [rbp - 120]
    cmp r8, [rbp - 72]
    je .add_right_rest
    mov r8, [rbp - 128]
    cmp r8, [rbp - 88]
    je .add_left_rest

    ; Compare values of both lists:
    xor rax, rax
    xor rdx, rdx
    .comparison_loop:
        ; Left list:
        mov r8, [rbp - 120]
        mov r11, r8
        imul r11, r15
        add r11, rbx
        add r13, r11
        mov rcx, r13
        mov rdx, [rbp - 112]
        call helper_parse_saved_number_to_written_number
        mov rcx, rax
        mov rdx, [rbp - 112]
        call helper_parse_string_to_int
        mov [rbp - 136], rax
        ; Right list:
        mov r8, [rbp - 128]
        mov r11, r8
        imul r11, r15
        add r11, rbx
        add r14, r11
        mov rcx, r14
        mov rdx, [rbp - 112]
        call helper_parse_saved_number_to_written_number
        mov rcx, rax
        mov rdx, [rbp - 112]
        call helper_parse_string_to_int
        cmp rax, [rbp - 136]
        ja .right_bigger
    .left_bigger:
        mov rcx, r15
        mov r11, [rbp - 120]
        sub r13, rbx
        mov rsi, r13
        rep movsb
        inc qword [rbp - 120]
        jmp .loop
    .right_bigger:
        mov rcx, r15
        mov r11, [rbp - 128]
        sub r14, rbx
        mov rsi, r14
        rep movsb
        inc qword [rbp - 128]
        jmp .loop

.add_right_rest:
    mov r11, [rbp - 128]
    mov r14, [rbp - 80]
    imul r11, r15
    add r14, r11
    .add_right_rest_loop:
        mov rcx, r15
        mov rsi, r14
        rep movsb
        inc qword [rbp - 128]
        mov r11, [rbp - 128]
        cmp r11, [rbp - 88]
        je .complete
        add r14, r15
        jmp .add_right_rest_loop

.add_left_rest:
    mov r11, [rbp - 120]
    mov r13, [rbp - 64]
    imul r11, r15
    add r13, r11
    .add_left_rest_loop:
        mov rcx, r15
        mov rsi, r13
        rep movsb
        inc qword [rbp - 120]
        mov r11, [rbp - 120]
        cmp r11, [rbp - 72]
        je .complete
        add r13, r15
        jmp .add_left_rest_loop

.complete:
    mov rcx, [rbp - 64]
    call free
    mov rcx, [rbp - 80]
    call free

    mov rcx, [rbp - 72]
    add rcx, [rbp - 88]
    imul rcx, r15
    sub rdi, rcx
    mov rax, [rbp - 56]

    ; Restore non-volatile regs.
    mov rsi, [rbp - 8]
    mov rdi, [rbp - 16]
    mov r13, [rbp - 24]
    mov r14, [rbp - 32]
    mov r15, [rbp - 40]
    mov rbx, [rbp - 48]

    mov rsp, rbp
    pop rbp
    ret