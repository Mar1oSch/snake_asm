global helper_get_digits_of_number, helper_parse_number_to_string, helper_is_input_just_numbers, helper_parse_string_to_number
section .data
    convert_number db "0000", 0

section .text
helper_get_digits_of_number:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    ; Expect number in RCX.
    mov rax, rcx
    mov rbx, 10
    xor rcx, rcx
.loop:
    xor rdx, rdx
    div rbx
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

    ; Expect pointer to string in RCX.
    ; Expect number of digits to parse in RDX.
    mov [rbp - 8], rdx
    mov rax, rcx
    mov rcx, rdx

.loop:
    mov bl, [rax]
    cmp bl, 13
    je .check_rcx
    cmp bl, "0"
    jb .wrong
    cmp bl, "9"
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

helper_parse_number_to_string:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    ; Expect pointer to number (dword) in RCX.
    ; Expect number of digits to parse in RDX.
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

    mov rsp, rbp
    pop rbp
    ret

helper_parse_string_to_number:
    push rbp
    mov rbp, rsp
    sub rsp, 48

    ; Expect pointer to string in RCX.
    ; Expect number of digits to create in RDX.
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
    mov rdx, rcx
    dec rdx
    .inner_loop:
        test rdx, rdx
        jz .loop_handle
        mul r9
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

;;;;;; PRIVATE FUNCTIONS ;;;;;;
_get_digits_in_string:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    ; Expect pointer to string in RCX.
    ; Expect number of possible digits in RDX.
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