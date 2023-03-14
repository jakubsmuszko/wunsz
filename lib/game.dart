import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_snake_game/direction_type.dart';

import 'direction.dart';
import 'piece.dart';

import 'control_panel.dart';

class GamePage extends StatefulWidget {
  @override
  _GamePageState createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  List<Offset> positions = [];
  int length = 5;
  int step = 20;
  Direction direction = Direction.right;

  Piece food;
  Offset foodPosition;

  double screenWidth;
  double screenHeight;
  int lowerBoundX, upperBoundX, lowerBoundY, upperBoundY;

  Timer timer;
  double speed = 1;

  int score = 0;

  void draw() async {
    // jeśli wartość pozycji jest 0, generuje losową pozycję startową
    if (positions.length == 0) {
      positions.add(getRandomPositionWithinRange());
    }

    // za każdym razem, kiedy nasz wąż zje jedzenie, zwiększa się jego długość. pętla while upewnia się, że length i position są zsynchronizowane
    while (length > positions.length) {
      positions.add(positions[positions.length - 1]);
    }

    // sprawdza długość positions i zmienia jego wartości w celu nadania wrażenia, że wąż jest ruchomy
    for (var i = positions.length - 1; i > 0; i--) {
      positions[i] = positions[i - 1];
    }

    // porusza pierwszym elementem, czyli głową węża
    positions[0] = await getNextPosition(positions[0]);
  }

  Direction getRandomDirection([DirectionType type]) {
    // generuje losowy kierunek
    if (type == DirectionType.horizontal) {
      bool random = Random().nextBool();
      if (random) {
        return Direction.right;
      } else {
        return Direction.left;
      }
    } else if (type == DirectionType.vertical) {
      bool random = Random().nextBool();
      if (random) {
        return Direction.up;
      } else {
        return Direction.down;
      }
    } else {
      int random = Random().nextInt(4);
      return Direction.values[random];
    }
  }

  Offset getRandomPositionWithinRange() {
    int posX = Random().nextInt(upperBoundX) + lowerBoundX;
    int posY = Random().nextInt(upperBoundY) + lowerBoundY;
    return Offset(roundToNearestTens(posX).toDouble(), roundToNearestTens(posY).toDouble());
  }

  bool detectCollision(Offset position) {
    // sprawdza, czy wąż nie dotknął którejś z czterech wyznaczonych granic kontenera, zwracając true lub false
    if (position.dx >= upperBoundX && direction == Direction.right) {
      return true;
    } else if (position.dx <= lowerBoundX && direction == Direction.left) {
      return true;
    } else if (position.dy >= upperBoundY && direction == Direction.down) {
      return true;
    } else if (position.dy <= lowerBoundY && direction == Direction.up) {
      return true;
    }

    return false;
  }

  void showGameOverDialog() {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.red,
          shape: RoundedRectangleBorder(
              side: BorderSide(
                color: Colors.white,
                width: 3.0,
              ),
              borderRadius: BorderRadius.all(Radius.circular(10.0))),
          title: Text(
            "Koniec Gry",
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            "Twój wynik to " + score.toString() + ".",
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                restart();
              },
              child: Text(
                "Spróbuj ponownie",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<Offset> getNextPosition(Offset position) async {
    Offset nextPosition;

    if (detectCollision(position) == true) {
      if (timer != null && timer.isActive) timer.cancel();
      await Future.delayed(Duration(milliseconds: 500), () => showGameOverDialog());
      return position;
    }

    // tworzy nową pozycję dla obiektu na podstawie aktualnej pozycji, z wykorzystaniem przycisków
    if (direction == Direction.right) {
      nextPosition = Offset(position.dx + step, position.dy);
    } else if (direction == Direction.left) {
      nextPosition = Offset(position.dx - step, position.dy);
    } else if (direction == Direction.up) {
      nextPosition = Offset(position.dx, position.dy - step);
    } else if (direction == Direction.down) {
      nextPosition = Offset(position.dx, position.dy + step);
    }

    return nextPosition;

  }

  void drawFood() {
    //  tworzy element (Piece) i przechowuje go w zmiennej food, przechowuje pozycję elementu, a jeśli początkowa wartość wynosi null, tworzy go w losowej pozycji
    if (foodPosition == null) {
      foodPosition = getRandomPositionWithinRange();
    }
    // sprawdza czy pozycja jedzenia i pozycja głowy węża znajdują się w tej samej pozycji. jeśli tak jest, zwiększa długość węża, prędkosć i wynik. następnie generuje nowy element jedzenia.
    if (foodPosition == positions[0]) {
      length++;
      speed = speed + 0.25;
      score = score + 5;
      changeSpeed();

      foodPosition = getRandomPositionWithinRange();
    }

    food = Piece(
      posX: foodPosition.dx.toInt(),
      posY: foodPosition.dy.toInt(),
      size: step,
      color: Colors.red,
      isAnimated: true,
    );
  }

  List<Piece> getPieces() {
    final pieces = <Piece>[];
    draw();
    drawFood();

    // 1 - pętla for, która działa do momentu pokrycia całej długości naszego wężą
    for (var i = 0; i < length; ++i) {
      // 2 - if na wypadek, kiedy długość węża (length) nie zgadza się z długością na liście positions
      if (i >= positions.length) {
        continue;
      }

      // 3 - z każdą iteracją tworzy element (piece) z odpowiednią pozycją i dodaje do listy elementów
      pieces.add(
        Piece(
          posX: positions[i].dx.toInt(),
          posY: positions[i].dy.toInt(),
          // 4 - nadaje każdemu elementowi rozmiar oraz kolor
          size: step,
          color: Colors.green,
        ),
      );
    }

    return pieces;
  }

  Widget getControls() {
    return ControlPanel( // 1 - odwołuje się do widgetu renderującego 4 przyciski do sterowania wężem, zdefiniowanego w control_panel.dart
      onTapped: (Direction newDirection) { // 2 - metoda przyjmuje wyznaczony nowy kierunek dla wężą
        direction = newDirection; // 3 - aktualizuje nowo otrzymany kierunek
      },
    );
  }

  int roundToNearestTens(int num) {
    int divisor = step;
    int output = (num ~/ divisor) * divisor;
    if (output == 0) {
      output += step;
    }
    return output;
  }

  void changeSpeed() {
    //odświeża timer, używając metody setState, a co za tym idzie odświeża całe UI.
    if (timer != null && timer.isActive) timer.cancel();

    timer = Timer.periodic(Duration(milliseconds: 200 ~/ speed), (timer) {
      setState(() {});
    });
  }

  Widget getScore() {
    //wyświetla obecny wynik w prawym górnym rogu
    return Positioned(
      top: 50.0,
      right: 40.0,
      child: Text(
        "Wynik: " + score.toString(),
        style: TextStyle(fontSize: 24.0, color:Colors.white),
      ),
    );
  }

  void restart() {
    //w przypadku restartu gry odwołuje się do metody changeSpeed()
    score = 0;
    length = 5;
    positions = [];
    direction = getRandomDirection();
    speed = 1;

    changeSpeed();
  }

  Widget getPlayAreaBorder() {
    return Positioned(
      top: lowerBoundY.toDouble(),
      left: lowerBoundX.toDouble(),
      child: Container(
        width: (upperBoundX - lowerBoundX + step).toDouble(),
        height: (upperBoundY - lowerBoundY + step).toDouble(),
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.white.withOpacity(0.8),
            style: BorderStyle.solid,
            width: 2.0,
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    restart();
  }

  @override
  Widget build(BuildContext context) {
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;

    lowerBoundX = step;
    lowerBoundY = step;
    upperBoundX = roundToNearestTens(screenWidth.toInt() - step);
    upperBoundY = roundToNearestTens(screenHeight.toInt() - step);

    return Scaffold(
      body: Container(
        color: Colors.black,
        child: Stack(
          children: [
            getPlayAreaBorder(),
            Container(
              child: Stack(
                children: getPieces(),
              ),
            ),
            food,
            getControls(),
            getScore(),
          ],
        ),
      ),
    );
  }
}
