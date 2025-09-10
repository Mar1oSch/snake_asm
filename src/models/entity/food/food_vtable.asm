global VTABLE_FOOD_POINTS_OFFSET

global vtable_food, vtable_super_food

section .rodata
    VTABLE_FOOD_POINTS_OFFSET equ 0

section .text
    extern food_get_points
    extern super_food_get_points

vtable_food:
    dq food_get_points

vtable_super_food:
    dq super_food_get_points