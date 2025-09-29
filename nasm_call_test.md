cd C:\Users\Mario\Documents\Projekte\snake_asm\src
nasm -f win64 ..\tests\test_units\constructor_test\constructor_test.asm -o ..\tests\test_units\constructor_test\constructor_test.obj
nasm -f win64 ..\tests\main_test.asm -o ..\tests\main_test.obj
nasm -f win64 ..\tests\debugging\malloc_failed\malloc_failed.asm -o ..\tests\debugging\malloc_failed\malloc_failed.obj
nasm -f win64 ..\tests\debugging\object_not_created\object_not_created.asm -o ..\tests\debugging\object_not_created\object_not_created.obj
nasm -f win64 .\models\drawable\food\super_food\super_food.asm -o .\models\drawable\food\super_food\super_food.obj; 
nasm -f win64 .\models\drawable\food\food.asm -o .\models\drawable\food\food.obj;
nasm -f win64 .\models\drawable\snake\unit\unit.asm -o .\models\drawable\snake\unit\unit.obj;
nasm -f win64 .\models\drawable\snake\snake.asm -o .\models\drawable\snake\snake.obj;
nasm -f win64 .\models\drawable\drawable_vtable.asm -o .\models\drawable\drawable_vtable.obj;
nasm -f win64 .\models\drawable\position.asm -o .\models\drawable\position.obj;
nasm -f win64 .\models\game\board\board.asm -o .\models\game\board\board.obj;
nasm -f win64 .\models\game\player\player.asm -o .\models\game\player\player.obj;
nasm -f win64 .\models\game\game.asm -o .\models\game\game.obj;
nasm -f win64 .\models\organizer\console_manager.asm -o .\models\organizer\console_manager.obj
nasm -f win64 .\models\interface_table.asm -o .\models\interface_table.obj;
