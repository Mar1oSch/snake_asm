;;;;;; METHODS VTABLE CONSTANTS ;;;;;;
CONSOLE_MANAGER_METHODS_VTABLE_WRITE_CHAR_OFFSET equ 0
CONSOLE_MANAGER_METHODS_VTABLE_REPEAT_CHAR_OFFSET equ 8
CONSOLE_MANAGER_METHODS_VTABLE_WRITE_WORD_OFFSET equ 16
CONSOLE_MANAGER_METHODS_VTABLE_WRITE_NUMBER_OFFSET equ 24
CONSOLE_MANAGER_METHODS_VTABLE_RECIEVE_NUMBER_OFFSET equ 32
CONSOLE_MANAGER_METHODS_VTABLE_RECIEVE_LETTERS_OFFSET equ 40
CONSOLE_MANAGER_METHODS_VTABLE_CLEAR_ALL_OFFSET equ 48
CONSOLE_MANAGER_METHODS_VTABLE_CLEAR_SEQUENCE_OFFSET equ 56
CONSOLE_MANAGER_METHODS_VTABLE_WRITE_CHARDESTRUCTOR_OFFSET equ 64

;;;;;; GETTER VTABLE CONSTANTS ;;;;;;
CONSOLE_MANAGER_GETTER_VTABLE_X_OFFSET equ 0
CONSOLE_MANAGER_GETTER_VTABLE_Y_OFFSET equ 8

;;;;;; SETTER VTABLE CONSTANTS ;;;;;;
CONSOLE_MANAGER_SETTER_CURSOR_INFO_OFFSET equ 0
CONSOLE_MANAGER_SETTER_CURSOR_POS_OFFSET equ 8
CONSOLE_MANAGER_SETTER_BUFFER_SIZE_OFFSET equ 8

;;;;; CONSTANTS ;;;;;;
STD_OUTPUT_HANDLE equ -11
STD_INPUT_HANDLE equ -10
WINDOW_SIZE_OFFSET equ 10


console_manager_methods_vtable:
    dq console_manager_write_char
    dq console_manager_repeat_char
    dq console_manager_write_word
    dq console_manager_write_number
    dq console_manager_recieve_numeral_input
    dq console_manager_recieve_literal_input
    dq console_manager_clear_all
    dq console_manager_clear_sequence
    dq console_manager_destroy

console_manager_getter_vtable:
    dq console_manager_get_center_x_offset
    dq console_manager_get_center_y_offset

console_manager_setter_vtable:
    dq console_manager_set_console_cursor_info
    dq console_manager_set_cursor
    dq console_manager_set_buffer_size