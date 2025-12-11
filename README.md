# ASCII Snake in Assembly

## Introduction
After taking my first steps in x86-64 Assembly, I wanted to create at least one larger project in it. That’s why I decided to implement a small Snake game.

Since object-oriented programming is a major part of my apprenticeship, my goal was to structure this project in an object-oriented way. That means:

* Encapsulating methods and attributes into independent “objects” (in this case: grouped memory cells)
* Implementing at least one kind of interface (in this case: a **drawable interface** for objects that appear on the game board — which turned out to be somewhat unnecessary because I don’t maintain a list of drawables and instead draw each object individually)

I manage methods through **vtables**.  
Each class has its own static constructor table, which is the only global part of the class.  
Object-bound methods are divided into three tables:

1. **Method vtable**
2. **Getter vtable**
3. **Setter vtable**

Because of this, an object may reserve space for up to three vtable pointers.

My goal was to achieve real object orientation by encapsulating code and exposing only vtables as entry points to an object’s methods.

I also wanted to create a file system to store players and their highscores. When starting the game, the user can choose to create a new player or load an existing one from the file. The file is sorted in descending order by highscore (for practice reasons I implemented a merge sort algorithm).

---

## Windows ABI
This project is written in **NASM** targeting the **Windows x64 ABI**.

### Parameter registers
1. **RCX**
2. **RDX**
3. **R8**
4. **R9**
5. Additional parameters on the stack

### Volatile registers
* **RCX, RDX, R8, R9** (parameters)
* **R10**
* **R11**

### Non-volatile registers
* **RBX**
* **R12–R15**
* **RSI / RDI**
* **RBP / RSP**

### Shadow space
* Every caller must reserve **32 bytes** of shadow space for the callee.
* I use this shadow space to store parameters (unless they are moved into non-volatile registers for use across function calls).
* Local variables are pushed onto stack space reserved at the beginning of the function.

---

## Classes

I divided the classes into three main groups.

---

### 1. Drawables
* **Food:**  
  Food is consumed by the Snake. It awards points (depending on the level) and adds a snake unit. After consumption, the Board creates a new Food object.

* **Snake:**  
  The Snake is implemented as a singly linked list of units. It keeps track of its length, head, and tail.

* **Unit:**  
  A basic snake segment. The head is drawn as `(@)`; all other units are drawn as `(O)`. Each unit points to the next one.

* **Position:**  
  Every drawable object has a position consisting of X and Y coordinates inside the Board.

* **Drawable VTable:**  
  The interface vtable pointing to the shared functions: `get_x_coordinates`, `get_y_coordinates`, and `get_char`.

---

### 2. Game
* **Board:**  
  Manages all objects displayed on the screen.

* **Game:**  
  Handles all game logic. It updates the Snake and checks for collisions.

* **Options:**  
  Manages the current Player, the level, and the delay (which depends on the level).  
  After a game ends, the user can change the player, change the level, or change both — done simply by replacing the Game’s Options object.

* **Player:**  
  Represents a player. The highscore is stored inside the Player object, while the score of the current game is kept inside the Game. If the score exceeds the highscore, the Player’s highscore is updated.

---

### 3. Organizer
* **Console Manager:**  
  Handles console I/O — receiving input, writing characters and strings, etc.

* **Designer:**  
  Controls the visual style of console output, especially centering dialogue text.

* **File Manager:**  
  Responsible for saving players and managing all file system interaction.

* **Helper:**  
  Contains utility functions frequently used across the project (integer–string parsing, merge sort, etc.).

* **Interactor:**  
  Communicates with the user and responds to input.
