  ;;;;;; BIN Header ;;;;;;
header_template:
    magic db "LDB1"
    version dw 1
    header_size dw 16
    record_size dw 20
    reserved dw 0
    record_count dd 0
header_template_end:

HEADER_SIZE equ header_template_end - header_template

;;;;;; CREATE FILE CONSTANTS ;;;;;;
GENERIC_READ equ 0x80000000
GENERIC_WRITE equ 0x40000000
FILE_APPEND_DATA equ 0x0004

FILE_SHARE_WRITE equ 0x00000002
FILE_SHARE_READ equ 0x00000001

OPEN_ALWAYS equ 4

FILE_ATTRIBUTE_NORMAL equ 0x80

;;;;;; FILE POINTER CONSTANTS ;;;;;;
FILE_BEGIN   equ 0
FILE_END equ 2

;;;;;; FILE CONSTANTS ;;;;;;
FILE_NAME_OFFSET equ 0
FILE_NAME_SIZE equ 16

FILE_HIGHSCORE_OFFSET equ 16
FILE_HIGHSCORE_SIZE equ 4

FILE_RECORD_SIZE equ FILE_NAME_SIZE + FILE_HIGHSCORE_SIZE