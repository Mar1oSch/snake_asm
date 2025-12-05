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
    ; * Expect pointer to list in RCX.
    ; * Expect amount of list records in RDX.
    ; * Expect record length in R8.
    ; * Expect offset of value to compare in R9.
    ; * Expect size of compared value on stack [rbp + 48].
.set_up:
    ; Set up stack frame:
    ; * 72 bytes local variables.
    ; * 24 bytes function params.
    push rbp
    mov rbp, rsp
    sub rsp, 96

    ; Define basecase:
    cmp rdx, 1
    jbe .base_case

    ; Save non-volatile regs.
    mov [rbp - 8], rsi
    mov [rbp - 16], rdi
    mov [rbp - 24], rbx
    mov [rbp - 32], r12
    mov [rbp - 40], r13
    mov [rbp - 48], r14
    mov [rbp - 56], r15

    ; Make RBX point to the initial list.
    mov rbx, rcx

    ; Make R12 the length of each list record.
    mov r12, r8

    ; Make R13 the offset of the value to compare.
    mov r13, r9

    ; Reserve 32 bytes shadow space for called functions.
    sub rsp, 32

.prepare_median_value:
    ; Calculate the median.
    mov rax, rdx 
    shr rax, 1
    sub rdx, rax

    ; Make R14 length of left list.
    mov r14, rdx

    ; Make R15 length of right list.
    mov r15, rax

.create_left_list:
    ; To get the size needed for first list: length of left list * record length.
    mov rcx, r14
    imul rcx, r12

    ; * First local variable: bytes of left list.
    mov [rbp - 64], rcx

    ; Get memory space.
    call malloc

    ; Set up RDI as newly created memory space.
    ; Set up RSI as initial list.
    mov rdi, rax
    mov rsi, rbx

    ; Use earlier calculated amount of bytes to know, how many bytes have to be copied into new list.
    mov rcx, [rbp - 64]
    cld
    rep movsb

    ; Reset RDI to starting point.
    mov rcx, [rbp - 64]
    sub rdi, rcx

    ; Set up params for next recursion:
    ; * RCX now holds the created left list as initial list.
    ; * RDX holds the calculated length of left list.
    ; * R8 is the length of each record.
    ; * R9 will be the value offset.
    ; * On the stack [rsp + 32] is the size of the compared value.
    mov rcx, rdi
    mov rdx, r14
    mov r8, r12
    mov r9, r13
    mov r10, [rbp + 48]
    mov [rsp + 32], r10
    call helper_merge_sort_list

    ; * Second local variable: Created left list.
    mov [rbp - 72], rax

.create_right_list:
    ; To get the size needed for first list: length of right list * record length.
    mov rcx, r15
    imul rcx, r12

    ; * Update first local variable: bytes of right list.
    mov [rbp - 64], rcx

    ; Get memory space.
    call malloc

    ; Set up RDI as newly created memory space.
    ; RSI is already at the perfect place from first move.
    mov rdi, rax

    ; Use earlier calculated amount of bytes to know, how many bytes have to be copied into new list. 
    mov rcx, [rbp - 64]
    cld
    rep movsb

    ; Reset RDI to starting point.
    mov rcx, [rbp - 64]
    sub rdi, rcx

    ; Set up params for next recursion:
    ; * RCX now holds the created right list as initial list.
    ; * RDX holds the calculated length of right list.
    ; * R8 is the length of each record.
    ; * R9 will be the value offset.
    ; * On the stack [rsp + 32] is the size of the compared value.
    mov rcx, rdi
    mov rdx, r15
    mov r8, r12
    mov r9, r13
    mov r10, [rbp + 48]
    mov [rsp + 32], r10
    call helper_merge_sort_list
    ; Right list is in RAX now.

.merge:
    ; Set up params for _merge.
    mov rcx, rbx
    mov rdx, [rbp - 72]
    mov r8, r14
    mov r9, rax
    mov [rsp + 32], r15
    mov [rsp + 40], r12
    mov [rsp + 48], r13
    call _merge
    ; Merged list is in RAX now and will be returned.

.complete:
    ; Restore non-volatile regs.
    mov r15, [rbp - 56]
    mov r14, [rbp - 48]
    mov r13, [rbp - 40]
    mov r12, [rbp - 32]
    mov rbx, [rbp - 24]
    mov rdi, [rbp - 16]
    mov rsi, [rbp - 8]

    ; Restore old stack frame and return to caller.
    mov rsp, rbp
    pop rbp
    ret

.base_case:
    ; Base case:
    ; Initial list is the returned list.
    mov rax, rcx

    ; Restore old stack frame and end recursion.
    mov rsp, rbp
    pop rbp
    ret





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
        ; * 64 bytes local variables.
        push rbp
        mov rbp, rsp
        sub rsp, 64

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
        ; I am setting up the base for the update loop:
        ; * - RDI will point to the targetlist, which will be filled during the merge process.
        ; * - RSI will holt the pointer to the list part, which is written into RDI next.
        ; * - RBX is the record size.
        ; * - R12 is the index for the left list.
        ; * - R13 is the index for the right list.
        ; * - R14 is the pointer to the left list.
        ; * - R15 is the pointer to the right list.

        ; Save pointer to Targetlist in RDI.
        mov rdi, rcx

        ; Save pointer to left list into R13.
        mov r14, rdx

        ; Save pointer to right list into R14.
        mov r15, r9

        ; Save record size into RBX.
        mov rbx, [rbp + 56]

        ; Set loop counter to zero.
        xor r12, r12
        xor r13, r13

    .merge_loop:
        ; Check if end of left list is reached. If yes, add the right rest to target.
        cmp r12, [rbp + 32]
        je .add_right_rest

        ; Check if end of right list is reached. If yes, add the left rest to target.
        cmp r13, [rbp + 48]
        je .add_left_rest

        ; Compare values of both lists:
        .comparison_loop:
            ; Get left value:
            mov rax, r12
            mul rbx
            add rax, [rbp + 64]
            lea rcx, [r14 + rax]
            call helper_parse_saved_to_int
            mov [rbp - 64], rax

            ; Get right value:
            mov rax, r13
            mul rbx
            add rax, [rbp + 64]
            lea rcx, [r15 + rax]
            call helper_parse_saved_to_int

            ; Prepare record size for copying string.
            mov rcx, rbx

            ; Compare values. If RAX is bigger than RBX, right value is bigger.
            cmp rax, [rbp - 64]
            ja .right_bigger

        .left_bigger:
            ; Multiplicate left counter with record size.
            mov rax, r12
            mul rcx

            ; Load pointer at [base address + counter * record size] and transfer record to target.
            lea rsi, [r14 + rax]
            rep movsb

            ; Increment counter and loop again.
            inc r12
            jmp .merge_loop

        .right_bigger:
            ; Multiplicate right counter with record size.
            mov rax, r13
            mul rcx

            ; Load pointer at [base address + counter * record size] and transfer record to target.
            lea rsi, [r15 + rax]
            rep movsb

            ; Increment counter and loop again.
            inc r13
            jmp .merge_loop

    .add_left_rest:
        ; Prepare pointer to the first record of rest.
        mov rcx, rbx
        mov rax, r12
        mul rcx

        .add_left_rest_loop:
            ; Make RSI point to active record and transfer to RDI.
            lea rsi, [r14 + rax]
            rep movsb

            ; Increment counter and check, if length of right list is reached.
            inc r12
            cmp r12, [rbp + 32]
            je .complete

            ; If not, reset RCX as copy counter and add it to RAX to get to next entry.
            mov rcx, rbx
            add rax, rcx
            jmp .add_left_rest_loop

    .add_right_rest:
        ; Prepare pointer to the first record of rest.
        mov rcx, rbx
        mov rax, r13
        mul rcx

        .add_right_rest_loop:
            ; Make RSI point to active record and transfer to RDI.
            lea rsi, [r15 + rax]
            rep movsb

            ; Increment counter and check, if length of right list is reached.
            inc r13
            cmp r13, [rbp + 48]
            je .complete

            ; If not, reset RCX as copy counter and add it to RAX to get to next entry.
            mov rcx, rbx
            add rax, rcx
            jmp .add_right_rest_loop

    .complete:
        ; Free the memory space of created sublists.
        mov rcx, [rbp + 24]
        call free
        mov rcx, [rbp + 40]
        call free

        ; Restore non-volatile regs.
        mov r15, [rbp - 56]
        mov r14, [rbp - 48]
        mov r13, [rbp - 40]
        mov r12, [rbp - 32]
        mov rbx, [rbp - 24]
        mov rdi, [rbp - 16]
        mov rsi, [rbp - 8]

        ; Return the merges list in RAX.
        mov rax, [rbp + 16]

        ; Restore old stack frame and return to caller.
        mov rsp, rbp
        pop rbp
        ret

