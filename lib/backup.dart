import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';

import 'package:sensors_plus/sensors_plus.dart';

void main() {
  runApp(RouletteRomeoApp());
}

class RouletteRomeoApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Roulette Romeo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
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
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue[300]!, Colors.purple[300]!],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Roulette Romeo',
                style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
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
                  backgroundColor: Colors.orange,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
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
                  backgroundColor: Colors.green,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
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

class _GamePageState extends State<GamePage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _characterX = 0.0;
  double _characterY = 0.0;
  double _defaultY = 0.0;
  int _fuel = 100;
  int _coin = 0;
  int _lives = 3;
  List<Platform> _platforms = [];
  List<Coin> _coins = [];
  List<FuelPickup> _fuelPickups = [];
  Random _random = Random();
  late Size _screenSize;
  double _jumpVelocity = 0.0;
  bool _isJumping = false;
  bool _isFalling = false;

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
    _fuelPickups.clear();
    _coin = 0;
    _fuel = 5;
    _lives = 3;
    _spawnInitialObjects();
    _controller.repeat();
  }

  void _restartGame() {
    _platforms.clear();
    _coins.clear();
    _fuelPickups.clear();
    _characterY = _defaultY;
    _isJumping = false;
    _isFalling = false;
    _spawnInitialObjects();
    _controller.repeat();
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
      // Move objects upward
      _moveObjects();

      // Update character position
      if (_isJumping) {
        _characterY -= _jumpVelocity;
        _jumpVelocity -= 0.5; // Apply gravity
        if (_jumpVelocity <= 0) {
          _isJumping = false;
          _isFalling = true;
        }
      } else if (_isFalling) {
        _characterY += 5; // Fall speed
        if (_characterY >= _defaultY) {
          _characterY = _defaultY;
          _isFalling = false;
        }
      }

      // _fuel -= 1; // Decrease fuel over time

      // Check collisions
      _checkCollisions();

      // Remove off-screen objects and spawn new ones
      _manageObjects();

      // Check if player touches the top of the screen
      if (_characterY <= 0) {
        _loseLife();
      }

      // Game over condition
      if (_lives <= 0) {
        _showGameOver();
      }
    });
  }

  void _moveObjects() {
    double speed = 2.0;
    for (var platform in _platforms) {
      platform.y -= speed;
    }
    for (var coin in _coins) {
      coin.y -= speed;
    }
    for (var fuel in _fuelPickups) {
      fuel.y -= speed;
    }
  }

  void _manageObjects() {
    _platforms.removeWhere((platform) => platform.y + platform.height < 0);
    _coins.removeWhere((coin) => coin.y + coin.radius < 0);
    _fuelPickups.removeWhere((fuel) => fuel.y + fuel.size < 0);

    if (_platforms.isEmpty || _platforms.last.y < _screenSize.height - 150) {
      _spawnPlatform(_screenSize.height);
    }
  }

  void _checkCollisions() {
    // Check platform collisions
    for (var platform in _platforms) {
      if (_characterY + 50 >= platform.y &&
          _characterY + 50 <= platform.y + platform.height &&
          _characterX + 25 >= platform.x &&
          _characterX + 25 <= platform.x + platform.width) {
        if (platform.hasSpikes) {
          _loseLife();
        } else {
          _isJumping = false;
          _isFalling = false;
          _characterY = platform.y - 50;
        }
        break;
      }
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

    // Check fuel pickup collisions
    _fuelPickups.removeWhere((fuel) {
      if (_characterX < fuel.x + fuel.size &&
          _characterX + 50 > fuel.x &&
          _characterY < fuel.y + fuel.size &&
          _characterY + 50 > fuel.y) {
        _fuel = min(_fuel + 1, 5);
        return true;
      }
      return false;
    });
  }

  void _loseLife() {
    _lives--;
    if (_lives <= 0) {
      _showGameOver();
    } else {
      _restartGame();
    }
  }

  void _moveLeft() {
    setState(() {
      _characterX = max(_characterX - 10, 0);
    });
  }

  void _moveRight() {
    setState(() {
      _characterX = min(_characterX + 10, _screenSize.width - 50);
    });
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

  void _handleTap() {
    if (!_isJumping && !_isFalling && _fuel > 0) {
      setState(() {
        _isJumping = true;
        _jumpVelocity = 10.0;
        _fuel = max(_fuel - 1, 0);
      });
    }
  }

  void _spawnPlatform(double yPos) {
    double platformWidth = _random.nextDouble() * 100 + 100;
    double platformX =
        _random.nextDouble() * (_screenSize.width - platformWidth);
    bool hasSpikes = _random.nextDouble() < 0.3; // 30% chance of spikes

    int numBlocks = (platformWidth / 20).ceil(); // Each block is 20x20
    for (int i = 0; i < numBlocks; i++) {
      _platforms.add(Platform(
        x: platformX + i * 20,
        y: yPos,
        width: 20,
        height: 20,
        hasSpikes: hasSpikes,
      ));
    }

    // Spawn coin on platform (50% chance)
    if (_random.nextBool() && !hasSpikes) {
      _coins.add(Coin(
        x: platformX + platformWidth / 2,
        y: yPos - 17.5,
        radius: 15,
      ));
    }

    // Spawn fuel pickup (20% chance)
    if (_random.nextDouble() < 0.2 && !hasSpikes) {
      _fuelPickups.add(FuelPickup(
        x: _random.nextDouble() * (_screenSize.width - 30),
        y: yPos - 32.5,
        size: 30,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTapDown: (_) => _handleTap(),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.lightBlue[200]!, Colors.purple[200]!],
            ),
          ),
          child: Stack(
            children: [
              // Platforms
              ..._platforms.map((platform) => Positioned(
                left: platform.x,
                top: platform.y,
                child: Container(
                  width: platform.width,
                  height: platform.height,
                  decoration: BoxDecoration(
                    color: platform.hasSpikes ? Colors.red : Colors.green,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: platform.hasSpikes
                      ? const Icon(Icons.arrow_upward,
                      color: Colors.white, size: 14)
                      : null,
                ),
              )),
              // Coins
              ..._coins.map((coin) => Positioned(
                left: coin.x - coin.radius,
                top: coin.y - coin.radius,
                child: Container(
                  width: coin.radius * 2,
                  height: coin.radius * 2,
                  decoration: const BoxDecoration(
                    color: Colors.yellow,
                    shape: BoxShape.circle,
                  ),
                ),
              )),
              // Fuel Pickups
              ..._fuelPickups.map((fuel) => Positioned(
                left: fuel.x,
                top: fuel.y,
                child: Container(
                  width: fuel.size,
                  height: fuel.size,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.rectangle,
                  ),
                  child: const Icon(Icons.local_gas_station,
                      color: Colors.white),
                ),
              )),
              // Character
              Positioned(
                left: _characterX,
                top: _characterY,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(25),
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Coins: $_coin',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Fuel: $_fuel',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'Lives: $_lives',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Container(
                            height: 60,
                            width: 60,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: IconButton(
                              onPressed: _moveLeft,
                              icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            height: 60,
                            width: 60,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: IconButton(
                              onPressed: _moveRight,
                              icon: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.black),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}


class Platform {
  double x;
  double y;
  double width;
  double height;
  bool hasSpikes;

  Platform(
      {required this.x,
        required this.y,
        required this.width,
        required this.height,
        required this.hasSpikes});
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
