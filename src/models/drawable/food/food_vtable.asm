global VTABLE_FOOD_POINTS_OFFSET
global food_vtable_food, food_vtable_super_food

section .rodata
    VTABLE_FOOD_POINTS_OFFSET equ 0

section .text
    extern food_get_points
    extern super_food_get_points

food_vtable_food:
    dq food_get_points

food_vtable_super_food:
    dq super_food_get_points