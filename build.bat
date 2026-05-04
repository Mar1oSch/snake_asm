@echo off
setlocal enabledelayedexpansion

echo =========================================
echo Building Snake ASM (x64 Windows)
echo =========================================

:: 1. Verzeichnisse definieren (Optional, für die Übersicht)
echo [1/3] Cleaning up old object files...
del /s /q *.obj >nul 2>&1
del snake.exe >nul 2>&1

echo [2/3] Assembling...

:: Hier sind all deine NASM Aufrufe
nasm -f win64 -g .\src\main.asm -o .\src\main.obj
nasm -f win64 -g .\tests\debugging\malloc_failed\malloc_failed.asm -o .\tests\debugging\malloc_failed\malloc_failed.obj
nasm -f win64 -g .\tests\debugging\object_not_created\object_not_created.asm -o .\tests\debugging\object_not_created\object_not_created.obj
nasm -f win64 -g .\src\models\drawable\food\food.asm -o .\src\models\drawable\food\food.obj
nasm -f win64 -g .\src\models\drawable\snake\unit\unit.asm -o .\src\models\drawable\snake\unit\unit.obj
nasm -f win64 -g .\src\models\drawable\snake\snake.asm -o .\src\models\drawable\snake\snake.obj
nasm -f win64 -g .\src\models\drawable\position.asm -o .\src\models\drawable\position.obj
nasm -f win64 -g .\src\models\game\board\board.asm -o .\src\models\game\board\board.obj
nasm -f win64 -g .\src\models\game\player\player.asm -o .\src\models\game\player\player.obj
nasm -f win64 -g .\src\models\game\options\options.asm -o .\src\models\game\options\options.obj
nasm -f win64 -g .\src\models\game\game.asm -o .\src\models\game\game.obj
nasm -f win64 -g .\src\models\organizer\console_manager.asm -o .\src\models\organizer\console_manager.obj
nasm -f win64 -g .\src\models\organizer\file_manager.asm -o .\src\models\organizer\file_manager.obj
nasm -f win64 -g .\src\models\organizer\designer.asm -o .\src\models\organizer\designer.obj
nasm -f win64 -g .\src\models\organizer\interactor.asm -o .\src\models\organizer\interactor.obj
nasm -f win64 -g .\src\models\organizer\helper.asm -o .\src\models\organizer\helper.obj
nasm -f win64 -g .\src\models\interface_table.asm -o .\src\models\interface_table.obj
nasm -f win64 -g .\src\models\organizer\table\table.asm -o .\src\models\organizer\table\table.obj

if %errorlevel% neq 0 (
    echo.
    echo [ERROR] Assembling failed!
    pause
    exit /b %errorlevel%
)

echo [3/3] Linking...

:: Dein GCC Aufruf (alle .obj Dateien zusammensammeln)
:: Trick: Wir nutzen die Pfade direkt, um sicherzugehen
gcc -g .\src\main.obj ^
.\tests\debugging\malloc_failed\malloc_failed.obj ^
.\tests\debugging\object_not_created\object_not_created.obj ^
.\src\models\drawable\food\food.obj ^
.\src\models\drawable\snake\unit\unit.obj ^
.\src\models\drawable\snake\snake.obj ^
.\src\models\drawable\position.obj ^
.\src\models\game\board\board.obj ^
.\src\models\game\player\player.obj ^
.\src\models\game\options\options.obj ^
.\src\models\game\game.obj ^
.\src\models\organizer\console_manager.obj ^
.\src\models\organizer\file_manager.obj ^
.\src\models\organizer\interactor.obj ^
.\src\models\organizer\helper.obj ^
.\src\models\organizer\designer.obj ^
.\src\models\interface_table.obj ^
.\src\models\organizer\table\table.obj ^
-o snake.exe

if %errorlevel% neq 0 (
    echo.
    echo [ERROR] Linking failed!
    pause
    exit /b %errorlevel%
)

echo.
echo =========================================
echo SUCCESS: snake.exe created!
echo =========================================
pause
