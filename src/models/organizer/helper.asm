global helper_get_digits_of_number, helper_parse_saved_to_int, helper_is_input_just_numbers, helper_parse_string_to_int, helper_parse_int_to_string, helper_merge_sort_list, helper_change_position

; This is a helper file to solve general problems in the program.

section .text
    extern malloc, free


helper_change_position:
    ; * Expect position in ECX.
    ; * Expect new X-Value in DX.
    ; * Expect new Y-Value in R8W.
    ; No stack frame required.
    ; No function calls.
    ; No local variables.
    .change_position:
        add cx, r8w
        ror rcx, 16
        add cx, dx
        rol rcx, 16

    .complete:
        ; Return new position in EAX.
        mov eax, ecx
        ret

; Divide the number by ten every time. As long as the result is not zero, increment the count.
; If it is zero, check for the remainder. If it is not zero, increment the counter once more.
; The counter now is the amount of digits the number has.
helper_get_digits_of_number:
    ; * Expect number in RCX.
    ; No stack frame required.
    ; No function calls.
    ; No local variables.
    .set_up_loop_base:
        ; Set up dividend
        mov rax, rcx

        ; Set up divisor.
        mov r8, 10

        ; Set counter zero.
        xor rcx, rcx

    .division_loop:
        xor rdx, rdx
        div r8

        ; Check if RAX is 0. If it is, go to the last check.
        test rax, rax
        jz .last_check

        ; If not, increment counter and loop again.
        inc rcx
        jmp .division_loop

    ; If remainder of last division is not 0, increment counter once more.
    .last_check:
        test rdx, rdx
        jz .complete
        inc rcx

    .complete:
        ; Return counter in RAX.
        mov rax, rcx
        ret


;;;;;; VALIDATOR ;;;;;;

helper_is_input_just_numbers:
    ; * Expect pointer to string in RCX.
    ; * Expect number of digits to parse in RDX.
    ; No stack frame required.
    ; No function calls.
    ; No local variables.
    .set_up_loop_base:
        ; RAX contains the string. RCX will be the counter.
        mov rax, rcx
        mov rcx, rdx

    .check_loop:
        ; Check if active byte is a Line Feed (13). If it is, there is one more step to check.
        cmp byte [rax], 13
        je .check_rcx

        ; Check if active byte is between the range of "0" (48) and "9" (57). If it is not, input is not just numbers.
        cmp byte [rax], "0"
        jb .wrong
        cmp byte [rax], "9"
        ja .wrong

        ; If it is, we increase RAX to check the next byte.
        inc rax
        loop .check_loop

    .check_rcx:
        ; If read char is LF (13) and RCX is above (that shouldn't happen) or equal RDX, it means that the user input is empty. So input is not just numbers. If RCX is below RDX, it means the loop at least once was correct and the input is just numbers.
        cmp rcx, rdx
        jae .wrong

    .right:
        ; Return 1 if true.
        mov rax, 1
        jmp .complete

    .wrong:
        ; And 0 if false.
        xor rax, rax

    .complete:
        ret


;;;;;; PARSER ;;;;;;

helper_parse_int_to_string:
    ; * Expect pointer to save number to in RCX.
    ; * Expect number in RDX.
    ; * Expect number of digits to write in R8.
    .set_up:
        ; Set up stack frame:
        ; * 8 bytes local variables.
        ; * 8 bytes to keep stack 16-byte aligned.
        push rbp
        mov rbp, rsp
        sub rsp, 16

        ; Save non-volatile regs.
        mov [rbp - 8], rdi

    .set_up_loop_base:
        ; RDI will be the destination memory space.
        mov rdi, rcx

        ; RAX is the dividend.
        mov rax, rdx

        ; RCX the loop counter (number of digits to write).
        mov rcx, r8

        ; R8 will be the divisor.
        mov r8, 10

        ; Setting up RDI correctly (it is pointing to the last digit).
        add rdi, rcx
        dec rdi

    .division_loop:
        xor rdx, rdx
        div r8 

        ; Turn remainder into a ASCII-number by adding "0" (48).
        add dl, "0"

        ; Move that byte into the memory space.
        mov [rdi], dl

        ; Decrement RDI by one and loop again if RCX is not 0 yet.
        dec rdi
        loop .division_loop

    .complete:
        ; Return the starting memory address. 
        mov rax, rdi
        inc rax

        ; Restore non-volatile regs.
        mov rdi, [rbp - 8]

        ; Restore old stack frame and return to caller.
        mov rsp, rbp
        pop rbp
        ret

helper_parse_saved_to_int:
    ; * Expect pointer to number in RCX.
    mov eax, [rcx]
    ret

helper_parse_string_to_int:
    ; * Expect pointer to string in RCX.
    ; * Expect number of digits to create in RDX.
    .set_up:
        ; Set up stack frame without local variables.
        push rbp
        mov rbp, rsp

        ; Save params into shadow space.
        mov [rbp + 16], rcx

        ; Reserve 32 bytes shadow space for called functions.
        sub rsp, 32

    .get_digits:
        call _get_digits_in_string

    .set_up_loop_base:
        ; Number of digits is the loop count.
        mov rcx, rax

        ; R8 is the factor 10.
        mov r8, 10

        ; R9 is the pointer to the string.
        mov r9, [rbp + 16]

        ; R10 will temporaly hold the result.
        xor r10, r10

    .preperation_loop:
        ; Moving the more significant digit into RAX.
        movzx rax, byte [r9]

        ; Turning it into an int.
        sub rax, "0"

        ; Preparing R11 as the amount of times, RAX has to be multiplied by ten to get to the place it needs to be.
        mov r11, rcx
        dec r11

        .multiplication_loop:
            ; If R11 is 0, no more multiplication needs to be done.
            test r11, r11
            jz .preperation_loop_handle

            ; Else multiply value in RAX by R8.
            mul r8

            ; Decrement R11 and loop again.
            dec r11
            jmp .multiplication_loop

    .preperation_loop_handle:
        ; Add the product to R10 and move to next byte.
        add r10, rax
        inc r9
        loop .preperation_loop

    .complete:
        ; Return the result in RAX.
        mov rax, r10

        ; Restore old stack frame and return to caller.
        mov rsp, rbp
        pop rbp
        ret

;;;;;; MERGE SORT ;;;;;;
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
    ; * Expectsize of compared value on stack [rbp + 48].
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





;;;;;; PRIVATE METHODS ;;;;;;

_get_digits_in_string:
    ; * Expect pointer to string in RCX.
    ; * Expect number of possible digits in RDX.
    ; No stack frame required.
    ; No function calls.
    ; No local variables.
    .set_up_loop_base:
        ; RAX as counter is set to 0 first.
        xor rax, rax

    .comparison_loop:
        ; Check if active byte is between "0" (48) and "9" (57).
        ; If not, it is no digit anymore and the loop is done.
        cmp byte [rcx + rax], "0"
        jb .complete
        cmp byte [rcx + rax], "9"
        ja .complete

        ; If it is, compare counter to possible digits.
        ; If it is equal, we are completed.
        cmp rax, rdx
        je .complete

    .loop_handle:
        ; Increment the counter and loop again.
        inc rax
        jmp .comparison_loop

    .complete:
        ; Return the count in RAX.
        ret

_merge:
    ; * Expect pointer to save merged list in RCX.
    ; * Expect pointer to left list in RDX.
    ; * Expect length of left list in R8.
    ; * Expect pointer to right list in R9.
    ; * Expect length of right list on Stack [rbp + 48].
    ; * Expect record size on Stack [rbp + 56].
    ; * Expect offset of value on Stack [rbp + 64].
.set_up:
    ; Set up stack frame:
    ; * 112 bytes local variables.
    push rbp
    mov rbp, rsp
    sub rsp, 128

    ; Save non-volatile regs.
    mov [rbp - 8], rsi
    mov [rbp - 16], rdi
    mov [rbp - 24], rbx
    mov [rbp - 32], r12
    mov [rbp - 40], r13
    mov [rbp - 48], r14
    mov [rbp - 56], r15

    ; Save params into shadow space.
    mov [rbp + 16], rcx
    mov [rbp + 24], rdx
    mov [rbp + 32], r8
    mov [rbp + 40], r9

    ; Reserve 32 bytes shadow space for called functions.
    sub rsp, 32

.set_up_loop_base:
    xor r8, r8
    mov [rbp - 88], r8
    mov [rbp - 96], r8

    ; Save pointer to Targetlist in RDI.
    mov rdi, rcx
    ; Save record size into R15.
    mov r15, [rbp + 56]
    ; Save offset into RBX.
    mov rbx, [rbp + 64]

    sub rsp, 32
.merge_loop:
    ; Save pointer to left list into R13.
    mov r13, [rbp + 24]
    ; Save pointer to right list into R14.
    mov r14, [rbp + 40]

    mov r8, [rbp - 88]
    cmp r8, [rbp + 32]
    je .add_right_rest
    mov r8, [rbp - 96]
    cmp r8, [rbp + 48]
    je .add_left_rest

    ; Compare values of both lists:
    xor rax, rax
    xor rdx, rdx
    .comparison_loop:
        ; Left list:
        mov r8, [rbp - 88]
        mov r11, r8
        imul r11, r15
        add r11, rbx
        add r13, r11
        mov rcx, r13
        call helper_parse_saved_to_int
        mov [rbp - 104], rax
        ; Right list:
        mov r8, [rbp - 96]
        mov r11, r8
        imul r11, r15
        add r11, rbx
        add r14, r11
        mov rcx, r14
        call helper_parse_saved_to_int
        cmp rax, [rbp - 104]
        ja .right_bigger
    .left_bigger:
        mov rcx, r15
        mov r11, [rbp - 88]
        sub r13, rbx
        mov rsi, r13
        rep movsb
        inc qword [rbp - 88]
        jmp .merge_loop
    .right_bigger:
        mov rcx, r15
        mov r11, [rbp - 96]
        sub r14, rbx
        mov rsi, r14
        rep movsb
        inc qword [rbp - 96]
        jmp .merge_loop

.add_right_rest:
    mov r11, [rbp - 96]
    mov r14, [rbp + 40]
    imul r11, r15
    add r14, r11
    .add_right_rest_loop:
        mov rcx, r15
        mov rsi, r14
        rep movsb
        inc qword [rbp - 96]
        mov r11, [rbp - 96]
        cmp r11, [rbp + 48]
        je .complete
        add r14, r15
        jmp .add_right_rest_loop

.add_left_rest:
    mov r11, [rbp - 88]
    mov r13, [rbp + 24]
    imul r11, r15
    add r13, r11
    .add_left_rest_loop:
        mov rcx, r15
        mov rsi, r13
        rep movsb
        inc qword [rbp - 88]
        mov r11, [rbp - 88]
        cmp r11, [rbp + 32]
        je .complete
        add r13, r15
        jmp .add_left_rest_loop

.complete:
    mov rcx, [rbp + 24]
    call free
    mov rcx, [rbp + 40]
    call free

    mov rcx, [rbp + 32]
    add rcx, [rbp + 48]
    imul rcx, r15
    sub rdi, rcx
    mov rax, [rbp + 16]

    ; Restore non-volatile regs.
    mov r15, [rbp - 56]
    mov r14, [rbp - 48]
    mov r13, [rbp - 40]
    mov r12, [rbp - 32]
    mov rbx, [rbp - 24]
    mov rdi, [rbp - 16]
    mov rsi, [rbp - 8]

    mov rsp, rbp
    pop rbp
    ret