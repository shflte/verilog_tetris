# Tetris

* Tetris game implemented in verilog.

![snapshot.JPeG](img/snapshot.JPeG)

## Deploy

* Build and program the project into a FPGA board and connect the board to the monitor.

## Features

* **SRS**: The game is builded referring to the **Super Rotation System**, which is the current Tetris Guideline standard for how tetrominoes behave, defining where and how the tetrominoes **spawn**, how they **rotate**, and what **wall kicks** they may perform.

* **Pick map**: The player can select a map to start the game with.

  * The map picking stage.

    ![pick_map.JPG](img/pick_map.JPG)

  * This map is created to demonstrate the beauty of the **Super Rotation System**.  The map spawns "T" tetrominos only and allows the "T" tetrominos to traverse through the map endlessly.

    ![elevator.JPG](img/elevator.JPG) 

* **Scoring system**

* **Ghost piece**: Representing where the current tetromino will fall onto.

  

## Gameplay

The game controls involves the bottons on the FPGA boards.

![gameplay.JPG](img/gameplay.JPG)

* **Shift left/right**: btn1/ btn0
* **Soft drop**: btn2
* **Hard drop**: btn3 + btn2
* **Cloclwise/Anticlockwise rotate**: btn3 + btn1/ btn0
* **Hold**: btn3

