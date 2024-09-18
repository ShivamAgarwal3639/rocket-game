import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

import 'package:sensors_plus/sensors_plus.dart';

void main() {
  runApp(RouletteRomeoApp());
}

// Define exact color codes from the image
class AppColors {
  static const Color yellow = Color(0xFFFFD700);
  static const Color purple = Color(0xFF9C27B0);
  static const Color lightPurple = Color(0xFFE1BEE7);
  static const Color orange = Color(0xFFFF9800);
  static const Color blue = Color(0xFF2196F3);
  static const Color lightBlue = Color(0xFF90CAF9);
  static const Color red = Color(0xFFF44336);
  static const Color pink = Color(0xFFE91E63);
  static const Color black = Colors.black;
  static const Color white = Colors.white;
}

class RouletteRomeoApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Roulette Romeo',
      theme: ThemeData(
        primarySwatch: Colors.purple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: StartPage(),
    );
  }
}

class StartPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: AppColors.white,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Roulette Romeo',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: AppColors.black,
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => GamePage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.yellow,
                  foregroundColor: AppColors.black,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                  side: const BorderSide(color: AppColors.black, width: 1),
                ),
                child: const Text('Start Game', style: TextStyle(fontSize: 24)),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => InstructionsPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.purple,
                  foregroundColor: AppColors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                  side: const BorderSide(color: AppColors.black, width: 1),
                ),
                child:
                    const Text('Instructions', style: TextStyle(fontSize: 24)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class InstructionsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Instructions')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'How to Play:',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              '1. Tilt your device left or right to move the character horizontally.',
              style: TextStyle(fontSize: 18),
            ),
            const Text(
              '2. Tap the screen to activate the booster and propel upwards.',
              style: TextStyle(fontSize: 18),
            ),
            const Text(
              '3. Collect coins and avoid obstacles as you ascend.',
              style: TextStyle(fontSize: 18),
            ),
            const Text(
              '4. Land on platforms to rest and refuel.',
              style: TextStyle(fontSize: 18),
            ),
            const Text(
              '5. Try to reach the highest altitude possible!',
              style: TextStyle(fontSize: 18),
            ),
            const Spacer(),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                ),
                child:
                    const Text('Back to Start', style: TextStyle(fontSize: 24)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GamePage extends StatefulWidget {
  @override
  _GamePageState createState() => _GamePageState();
}

class _GamePageState extends State<GamePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _characterX = 0.0;
  double _characterY = 0.0;
  double _defaultY = 0.0;
  int _coin = 0;
  int _lives = 3;
  List<Platform> _platforms = [];
  List<Coin> _coins = [];
  math.Random _random = math.Random();
  late Size _screenSize;
  double _jumpVelocity = 0.0;
  bool _isJumping = false;
  bool _isFalling = false;

  // New variables for smooth movement
  double _velocityX = 0.0;
  double _velocityY = 0.0;
  double _gravity = 0.5;
  double _jumpForce = -12.0;
  double _moveForce = 1.0;
  double _airResistance = 0.95;
  double _groundFriction = 0.8;
  bool _isOnGround = false;

  // New variables for multi-jump mechanics
  int _consecutiveJumps = 0;
  double _maxJumpForce = -20.0;
  int _maxConsecutiveJumps = 3;
  DateTime _lastJumpTime = DateTime.now();

  // Add these new variables for gesture control
  double _swipeStartX = 0.0;
  double _swipeThreshold = 50.0; // Minimum distance to trigger a swipe

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..addListener(_updateGame);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _screenSize = MediaQuery.of(context).size;
    _characterX = _screenSize.width / 2 - 25;
    _defaultY = _screenSize.height * 0.7;
    _characterY = _defaultY;
    _startGame();
  }

  void _startGame() {
    _platforms.clear();
    _coins.clear();
    _coin = 0;
    _lives = 3;
    _spawnInitialObjects();
    _controller.repeat();
  }

  void _restartGame() {
    setState(() {
      _platforms.clear();
      _coins.clear();

      // Set the character's initial position to 25% below the top edge
      _characterY = _screenSize.height * 0.25;

      // Set the character's horizontal position to the middle of the screen
      _characterX =
          _screenSize.width / 2 - 25; // Assuming the character width is 50

      _isJumping = false;
      _isFalling = true; // Set to true so the character starts falling
      _velocityY = 0; // Reset vertical velocity
      _velocityX = 0; // Reset horizontal velocity

      _spawnInitialObjects();
      _controller.repeat();
    });
  }

  void _spawnInitialObjects() {
    double yPos = _screenSize.height;
    for (int i = 0; i < 5; i++) {
      _spawnPlatform(yPos);
      yPos += 150;
    }
  }

  void _updateGame() {
    if (!mounted) return;
    setState(() {
      // Apply physics
      _velocityY += _gravity;
      _velocityX *= _isOnGround ? _groundFriction : _airResistance;
      _velocityY *= _airResistance;

      // Update position
      _characterX += _velocityX;
      _characterY += _velocityY;

      // Bound character within screen
      _characterX = _characterX.clamp(0, _screenSize.width - 50);

      // Prevent player from going below half of the screen
      double minY = _screenSize.height * 0.5;
      if (_characterY > minY) {
        _characterY = minY;
        _velocityY = 0;
        _isOnGround = true;
        _consecutiveJumps = 0; // Reset consecutive jumps when touching ground
      } else {
        _isOnGround = false;
      }

      // Move objects upward (camera effect)
      _moveObjects();

      // Check collisions
      _checkCollisions();

      // Manage objects (remove off-screen, spawn new)
      _manageObjects();

      // Check game over conditions
      if (_characterY <= 0 && _lives <= 0) {
        _showGameOver();
      } else if (_characterY <= 5) {
        _lives--;
        _restartGame();
      }
    });
  }

  void _moveLeft() {
    _velocityX -= _moveForce;
  }

  void _moveRight() {
    _velocityX += _moveForce;
  }

  void _jump() {
    DateTime now = DateTime.now();
    Duration timeSinceLastJump = now.difference(_lastJumpTime);

    // Calculate jump force based on consecutive jumps and time between jumps
    double jumpForce = _jumpForce * (1 + (_consecutiveJumps * 0.2));
    jumpForce = jumpForce.clamp(_maxJumpForce, _jumpForce);

    // Apply additional force for rapid taps
    if (timeSinceLastJump.inMilliseconds < 200) {
      jumpForce *= 1.5;
    }

    _velocityY = jumpForce;
    _isOnGround = false;
    _consecutiveJumps = (_consecutiveJumps + 1).clamp(0, _maxConsecutiveJumps);
    _lastJumpTime = now;
  }

  void _checkCollisions() {
    bool collided = false;

    // Check platform collisions
    for (var platform in _platforms) {
      for (var brick in platform.bricks) {
        if (_characterY + 50 >= brick.y &&
            _characterY + 50 <= brick.y + BRICK_SIZE &&
            _characterX + 25 >= brick.x &&
            _characterX + 25 <= brick.x + BRICK_SIZE) {
          if (platform.hasSpikes) {
            _loseLife();
          } else {
            _isOnGround = true;
            _velocityY = 0;
            _characterY = brick.y - 50;
            _consecutiveJumps =
                0; // Reset consecutive jumps when landing on platform
          }
          collided = true;
          break;
        }
      }
      if (collided) break;
    }

    // Check coin collisions
    _coins.removeWhere((coin) {
      if (_characterX < coin.x + coin.radius &&
          _characterX + 50 > coin.x - coin.radius &&
          _characterY < coin.y + coin.radius &&
          _characterY + 50 > coin.y - coin.radius) {
        _coin += 10;
        return true;
      }
      return false;
    });
  }

  void _moveObjects() {
    double speed = 2.0;
    for (var platform in _platforms) {
      for (var brick in platform.bricks) {
        brick.y -= speed;
      }
    }
    for (var coin in _coins) {
      coin.y -= speed;
    }
    // Move character down to create illusion of upward movement
    _characterY += speed;
  }

  void _manageObjects() {
    // Remove off-screen objects
    _platforms
        .removeWhere((platform) => platform.bricks.last.y + BRICK_SIZE < 0);
    _coins.removeWhere((coin) => coin.y + coin.radius < 0);

    // Spawn new platform if needed
    if (_platforms.isEmpty ||
        _platforms.last.bricks.last.y < _screenSize.height - 150) {
      _spawnPlatform(_screenSize.height);
    }

    // Reset character position if it goes off-screen
    if (_characterY > _screenSize.height) {
      _characterY = _defaultY;
      _isJumping = false;
      _isFalling = true;
    }
  }

  void _loseLife() {
    _lives--;
    if (_lives <= 0) {
      _showGameOver();
    } else {
      _restartGame();
    }
  }

  void _showGameOver() {
    _controller.stop();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Game Over'),
          content: Text('Your score: $_coin'),
          actions: <Widget>[
            TextButton(
              child: const Text('Play Again'),
              onPressed: () {
                Navigator.of(context).pop();
                _startGame();
              },
            ),
          ],
        );
      },
    ).then((_) {
      if (!_controller.isAnimating) {
        _startGame();
      }
    });
  }

  static const double BRICK_SIZE = 60.0;
  static const double SMALL_BRICK_SIZE = BRICK_SIZE / 3;

  void _handleTap() {
    if (!_isJumping && !_isFalling) {
      setState(() {
        _isJumping = true;
        _jumpVelocity = 10.0;
      });
    }
  }

  void _spawnPlatform(double yPos) {
    double maxPlatformWidth = _screenSize.width * 0.6;
    int maxBricks = (maxPlatformWidth / BRICK_SIZE).floor();
    int numBricks = math.max(1, _random.nextInt(maxBricks) + 1);

    double platformWidth = numBricks * BRICK_SIZE;

    // Determine platform position
    double platformX;
    double middleProbability = 0.15; // 15% chance for middle platforms

    if (_random.nextDouble() < middleProbability) {
      // Middle platform (not touching walls)
      platformX = _random.nextDouble() *
              (_screenSize.width - platformWidth - 2 * BRICK_SIZE) +
          BRICK_SIZE;
    } else {
      // Left or right edge
      bool isLeftEdge = _random.nextBool();
      platformX = isLeftEdge ? 0 : _screenSize.width - platformWidth;
    }

    bool hasSpikes = _random.nextDouble() < 0.3; // 30% chance of spikes

    List<Brick> bricks = [];
    for (int i = 0; i < numBricks; i++) {
      List<SmallBrick> smallBricks = [];
      for (int j = 0; j < 9; j++) {
        bool exists =
            _random.nextDouble() < 0.9; // 90% chance of small brick existing
        Color color = _getRandomColor();
        smallBricks.add(SmallBrick(exists: exists, color: color));
      }
      bricks.add(Brick(
        x: platformX + i * BRICK_SIZE,
        y: yPos,
        smallBricks: smallBricks,
      ));
    }

    _platforms.add(Platform(bricks: bricks, hasSpikes: hasSpikes));

    // Spawn coin on platform (50% chance)
    if (_random.nextBool() && !hasSpikes) {
      _coins.add(Coin(
        x: platformX + platformWidth / 2,
        y: yPos - 30,
        radius: 15,
      ));
    }

    // Spawn fuel pickup (20% chance)
    // if (_random.nextDouble() < 0.2 && !hasSpikes) {
    //   _fuelPickups.add(FuelPickup(
    //     x: _random.nextDouble() * (_screenSize.width - 30),
    //     y: yPos - 45,
    //     size: 30,
    //   ));
    // }
  }

  Color _getRandomColor() {
    List<Color> colors = [
      AppColors.purple,
      AppColors.lightPurple,
      AppColors.blue,
      AppColors.lightBlue,
      AppColors.yellow,
      AppColors.orange,
    ];
    return colors[_random.nextInt(colors.length)];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SafeArea(
      child: Scaffold(
        body: GestureDetector(
          onTap: _jump,
          onHorizontalDragUpdate: (details) {
            if (details.primaryDelta! > 0) {
              _moveRight();
            } else {
              _moveLeft();
            }
          },
          child: Container(
            color: AppColors.lightBlue,
            child: Stack(
              children: [
                // Update platform rendering
                ..._platforms
                    .expand((platform) => platform.bricks)
                    .expand((brick) {
                  List<Widget> smallBricks = [];
                  for (int i = 0; i < 3; i++) {
                    for (int j = 0; j < 3; j++) {
                      int index = i * 3 + j;
                      if (brick.smallBricks[index].exists) {
                        smallBricks.add(Positioned(
                          left: brick.x + j * SMALL_BRICK_SIZE,
                          top: brick.y + i * SMALL_BRICK_SIZE,
                          child: Container(
                            width: SMALL_BRICK_SIZE,
                            height: SMALL_BRICK_SIZE,
                            decoration: BoxDecoration(
                              color: brick.smallBricks[index].color,
                              border:
                                  Border.all(color: AppColors.black, width: 1),
                            ),
                          ),
                        ));
                      }
                    }
                  }
                  return smallBricks;
                }),
                // Render spikes
                ..._platforms
                    .where((platform) => platform.hasSpikes)
                    .expand((platform) => platform.bricks)
                    .map((brick) => const Text(
                          "D",
                          style: TextStyle(color: Colors.white),
                        )),
                ..._coins.map((coin) => Positioned(
                      left: coin.x - coin.radius,
                      top: coin.y - coin.radius,
                      child: Container(
                        width: coin.radius * 2,
                        height: coin.radius * 2,
                        decoration: BoxDecoration(
                          color: AppColors.yellow,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.black, width: 1),
                        ),
                      ),
                    )),
                // ..._fuelPickups.map((fuel) => Positioned(
                //       left: fuel.x,
                //       top: fuel.y,
                //       child: Container(
                //         width: fuel.size,
                //         height: fuel.size,
                //         decoration: BoxDecoration(
                //           color: AppColors.orange,
                //           shape: BoxShape.rectangle,
                //           border: Border.all(color: AppColors.black, width: 1),
                //         ),
                //         child: const Icon(Icons.local_gas_station,
                //             color: AppColors.white),
                //       ),
                //     )),
                Positioned(
                  left: _characterX,
                  top: _characterY,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.blue,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: AppColors.black, width: 1),
                    ),
                  ),
                ),
                // UI Elements
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.yellow,
                                border: Border.all(
                                    color: AppColors.black, width: 1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Coins: $_coin',
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.black),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.pink,
                                border: Border.all(
                                    color: AppColors.black, width: 1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Lives: $_lives',
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.white),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ));
  }

  // Add these new methods for gesture control
  void _onDragStart(DragStartDetails details) {
    _swipeStartX = details.localPosition.dx;
  }

  void _onDragUpdate(DragUpdateDetails details) {
    double dragDistance = details.localPosition.dx - _swipeStartX;
    if (dragDistance.abs() > _swipeThreshold) {
      if (dragDistance > 0) {
        _moveRight();
      } else {
        _moveLeft();
      }
      _swipeStartX = details.localPosition.dx;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class Coin {
  double x;
  double y;
  double radius;

  Coin({required this.x, required this.y, required this.radius});
}

class FuelPickup {
  double x;
  double y;
  double size;

  FuelPickup({required this.x, required this.y, required this.size});
}

class SmallBrick {
  bool exists;
  Color color;

  SmallBrick({required this.exists, required this.color});
}

class Brick {
  double x;
  double y;
  List<SmallBrick> smallBricks;

  Brick({required this.x, required this.y, required this.smallBricks});
}

class Platform {
  List<Brick> bricks;
  bool hasSpikes;

  Platform({required this.bricks, required this.hasSpikes}) {
    if (hasSpikes) {
      // Make the top of each brick red if the platform has spikes
      for (var brick in bricks) {
        for (int i = 0; i < 3; i++) {
          brick.smallBricks[i].color = AppColors.red;
        }
      }
    }
  }
}
