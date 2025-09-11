global DRAWABLE_VTABLE_CHAR_OFFSET
global drawable_vtable_food, drawable_vtable_super_food, drawable_vtable_head, drawable_vtable_segment

section .rodata
    DRAWABLE_VTABLE_CHAR_OFFSET equ 0

section .text
    extern food_get_char
    extern super_food_get_char
    extern head_get_char
    extern segment_get_char

drawable_vtable_food:
    dq food_get_char

drawable_vtable_super_food:
    dq super_food_get_char

drawable_vtable_head:
    dq head_get_char

drawable_vtable_segment:
    dq segment_get_char