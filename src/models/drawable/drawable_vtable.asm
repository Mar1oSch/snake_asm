global DRAWABLE_VTABLE_CHAR_PTR_OFFSET, DRAWABLE_VTABLE_X_POSITION_OFFSET, DRAWABLE_VTABLE_Y_POSITION_OFFSET
global drawable_vtable_food, drawable_vtable_unit

section .rodata
    DRAWABLE_VTABLE_CHAR_PTR_OFFSET equ 0
    DRAWABLE_VTABLE_X_POSITION_OFFSET equ 8
    DRAWABLE_VTABLE_Y_POSITION_OFFSET equ 16

section .text
    extern food_get_char_ptr, food_get_x_position, food_get_y_position
    extern unit_get_char_ptr, unit_get_x_position, unit_get_y_position

drawable_vtable_food:
    dq food_get_char_ptr 
    dq food_get_x_position
    dq food_get_y_position

drawable_vtable_unit:
    dq unit_get_char_ptr
    dq unit_get_x_position
    dq unit_get_y_position
