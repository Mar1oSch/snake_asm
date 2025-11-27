# ASCII Snake in Assembly

## Introduction: 
After going my first few steps in Assembly x86-64 bit language, I wanted to write at least one bigger project in it. That's why I decided to write a little snake.

Since the object oriented approach is the biggest part in my apprenticeship, my goal was to implement that snake in an object oriented way.
That means:
* Encapsulate methods and attributes into independend "objects" (in this case: grouped memory cells)
* Trying to implement at least one kind of interface (in this case: drawable-interface for objects, participating in the game board [which was kind of unneccessary, since I am not handling a list of drawables, but drawing them seperately of each other])

After some time in the project I realised following:
A better way to work object oriented would have been, to implement a public VTABLE, containing the pointers to the public methods of each object. Always accessible by the pointer to the object and the offset of the method. It is on the list to change that way. At the moment I am handling all methods by themselves in either realising them to the public or keeping them private inside the file. That doesn't seem to bee really object oriented. But it worked so far. I will change it in the future.

My goal was to create a file system, saving the created players and their highscores. When a player is starting the game, the player is able to choose, if a new player should be created or loading an already created one from the file. The file is sorted descending by highscore (for practice reasons, I am using a Merch Sort algorithm).

## Windows ABI: 
I am writing in NASM Windows ABI.
Parameters:
1. <b>RCX</b>
2. <b>RDX</b>
3. <b>R8</b>
4. <b>R9</b>
5. <b>Stack</b>

Volatile Regs:
* <b>Parameters</b>
* <b>R10</b>
* <b>R11</b>

Non Volatile Regs:
* <b>RBX</b>
* <b>R12 - R15</b>
* <b>RSI / RDI</b>
* <b>RBP / RSP</b>

Shadow Space:
* Every caller has to reserve 32 bytes of shadow space for the callee.
* I am using that shadow space to save the parameters into.
* Local variables are saved into the stack space, which will be reserved at the beginning of the function.

## Classes:
I divided the classes into three main parts:
1. <b>Drawables</b>
  * <b>Food:</b>
  Food(*) is consumed by the Snake. It is adding points (depending on the lvl) and adding a Snake Unit. After it was  consumed, the Board is responsible to create a new one.
  * <b>Snake:</b>
  The Snake is a singly linked list of units. It knows its length, its head and its tail.
  * <b>Unit:</b>
  The basic parts of the Snake. If a Unit is the Snakes head, it is drawn as (@). If it is not the head, it is drawn  by an (O). It always points to the next unit in the Snake.
  * <b>Position:</b>
  Every DRAWABLE object has a position, which is constituted by the X- and Y-Coordinates inside the Board.
  * <b>DRAWABLE-VTable:</b>
  The interface vtable, pointing to the common functions (get_x_coordinates, get_y_coordinates and get_char)

2. <b>Game</b>
  * <b>Board:</b>
  The Board manages the displayed objects.
  * <b>Game:</b>
  Handles the mechanics and logic. It is updating the Snake and checking collissions.
  * <b>Options:</b>
  The Options are managing the current Player, the level and the delay depending on the level. After a game was played, the user is able to change the current player, to change the level or to change both. That will be done by simply exchanging the Options object of the game.
  * <b>Player:</b>
  Player is playing the Game (obviously). Highscore is saved in the Player object, while the popints of a single game are saved in the Game itself. If the points are bigger than the highscore, the highscore of the Player are updated.

3. <b>Organizer</b>
  * <b>Console Manager:</b>
  Handles all the basic communication with the console. Recieves Input, writes words and chars, ...
  * <b>Designer:</b>
  Manages the style of the output. Especially the centering of the dialouges.
  * <b>File Manager:</b>
  The File Manager is responsible for saving the players and organizing the communicationg with the file.
  * <b>Helper:</b>
  All methods which are sometimes used by everyone (for example: Parsing int to string /string to int, merge sort, etc.) are structured inside the Helper.
  * <b>Interactor:</b>
  Is communicating with the user and reacting to inputs.
