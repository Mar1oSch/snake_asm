global helper_get_digits_of_number, helper_parse_number_to_string, helper_is_input_just_numbers, helper_parse_string_to_digits
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

helper_is_input_just_numbers:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    ; Expect pointer to string in RCX.
    ; Expect number of digits to parse in RDX.
    mov rax, rcx
    mov rcx, rdx

.loop:
    mov bl, [rax]
    cmp bl, "0"
    jb .wrong
    cmp bl, "9"
    ja .wrong
    inc rax
    loop .loop

.right:
    mov rax, 1
    jmp .complete
.wrong:
    xor rax, rax

.complete:
    mov rsp, rbp
    pop rbp
    ret

helper_parse_string_to_digits:
    push rbp
    mov rbp, rsp
    sub rsp, 48

    ; Expect pointer to string in RCX.
    ; Expect number of digits to create in RDX.
    mov [rbp - 8], rdx
.loop:
    test rdx, rdx
    jz .complete
    mov al, [rcx]
    sub al, "0" ; sub rcx, 48
    mov [rcx], al
    dec rdx
    inc rcx
    jmp .loop

.complete:
    sub rcx, [rbp - 8]
    movzx rax, byte [rcx]

    mov rsp, rbp
    pop rbp
    ret

