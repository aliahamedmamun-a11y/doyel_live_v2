import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;

class DeliciousFoodGameView extends StatelessWidget {
  const DeliciousFoodGameView({super.key});

  @override
  Widget build(BuildContext context) {
    return const GameScreen();
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  int timerValue = 30;
  int userDiamonds = 360;
  int selectedBetValue = 10;
  List<int> activeBets = [];
  bool isSaladSelected = false;
  bool isPizzaSelected = false;

  int? winningIndex;
  int? spinningIndex;
  bool showWinResult = false;
  Timer? _timer;
  Timer? _aiHandTimer;
  int aiHandIndex = 0;

  List<String> resultHistory = [
    "🍅", "🍕", "🍢", "🍖", "🥩", "🥕", "🌽", "🥗",
  ];

  final List<Map<String, dynamic>> wheelItems = [
    {"name": "Tomato", "multi": 5, "icon": "🍅", "color": Colors.red},
    {"name": "Pizza", "multi": 10, "icon": "🍕", "color": Colors.orange},
    {"name": "Kebab", "multi": 15, "icon": "🍢", "color": Colors.brown},
    {"name": "Meat", "multi": 25, "icon": "🍖", "color": Colors.redAccent},
    {"name": "Steak", "multi": 45, "icon": "🥩", "color": Colors.brown},
    {"name": "Carrot", "multi": 5, "icon": "🥕", "color": Colors.orangeAccent},
    {"name": "Corn", "multi": 5, "icon": "🌽", "color": Colors.yellow},
    {"name": "Salad", "multi": 5, "icon": "🥗", "color": Colors.green},
  ];

  @override
  void initState() {
    super.initState();
    startTimer();
    startAiHandMovement();
  }

  void startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && !showWinResult && spinningIndex == null) {
        setState(() {
          if (timerValue > 0) {
            timerValue--;
          } else {
            processSpin();
          }
        });
      }
    });
  }

  void startAiHandMovement() {
    _aiHandTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      if (mounted && !showWinResult && spinningIndex == null) {
        setState(() {
          aiHandIndex = (aiHandIndex + 1) % 8;
        });
      }
    });
  }

  void processSpin() {
    int finalWinner = math.Random().nextInt(8);
    int currentStep = 0;
    // Shorter total steps for less time (16 instead of 24)
    int totalSteps = 16 + finalWinner;

    // Much faster spinning speed (50ms instead of 70ms)
    Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        spinningIndex = currentStep % 8;
        currentStep++;
      });

      if (currentStep > totalSteps) {
        timer.cancel();
        setState(() {
          winningIndex = finalWinner;
          spinningIndex = null;
          showWinResult = true;

          resultHistory.insert(0, wheelItems[winningIndex!]['icon']);
          if (resultHistory.length > 8) resultHistory.removeLast();

          if (activeBets.contains(winningIndex)) {
            userDiamonds += (selectedBetValue * (wheelItems[winningIndex!]['multi'] as int));
          }

          activeBets.clear();
          isSaladSelected = false;
          isPizzaSelected = false;
        });

        Timer(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              showWinResult = false;
              winningIndex = null;
              timerValue = 30;
            });
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _aiHandTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                colors: [Color(0xFFFFD54F), Color(0xFFF57C00), Color(0xFFE65100)],
                center: Alignment.center,
                radius: 1.2,
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildWheelSection(),
                          _buildCombinedPanel(),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (showWinResult) _buildWinOverlay(),
        ],
      ),
    );
  }

  Widget _buildCombinedPanel() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        children: [
          _buildSelectionPanel(),
          _buildTodayPrizeSection(),
          _buildLeaderboardSection(),
        ],
      ),
    );
  }

  Widget _buildWinOverlay() {
    final winner = wheelItems[winningIndex!];
    return Container(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("WINNER!", style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.yellow, decoration: TextDecoration.none)),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.yellow, width: 8),
                boxShadow: [BoxShadow(color: Colors.yellow.withOpacity(0.5), blurRadius: 30, spreadRadius: 10)],
              ),
              child: Text(winner['icon'], style: const TextStyle(fontSize: 80, decoration: TextDecoration.none)),
            ),
            const SizedBox(height: 10),
            Text(winner['name'], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white, decoration: TextDecoration.none)),
            Text("Win ${winner['multi']}x", style: const TextStyle(fontSize: 18, color: Colors.orangeAccent, decoration: TextDecoration.none)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusBar(),
          const SizedBox(height: 5),
          _buildActionBar(),
        ],
      ),
    );
  }

  Widget _buildStatusBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back, color: Colors.white),
            ),
            const SizedBox(width: 10),
            const Text("Delicious", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
        _buildDiamondDisplay(),
      ],
    );
  }

  Widget _buildActionBar() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(15)),
          child: const Row(
            children: [
              Icon(Icons.videogame_asset, size: 14, color: Colors.yellow),
              Text(" More >", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _buildCircleIcon(Icons.access_time_filled, Colors.yellow),
        const SizedBox(width: 8),
        _buildCircleIcon(Icons.help, Colors.yellow),
      ],
    );
  }

  Widget _buildCircleIcon(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Icon(icon, size: 16, color: Colors.red),
    );
  }

  Widget _buildDiamondDisplay() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange, width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.diamond, color: Colors.orange, size: 18),
          Text(" $userDiamonds >", style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildWheelSection() {
    return SizedBox(
      width: 350,
      height: 520,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            bottom: 80,
            child: CustomPaint(
              size: const Size(280, 200),
              painter: FramePainter(),
            ),
          ),
          CustomPaint(
            size: const Size(290, 290),
            painter: SpokesPainter(),
          ),
          Container(
            width: 290,
            height: 290,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.blue.shade900, width: 10),
            ),
          ),
          Container(
            width: 275,
            height: 275,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.blue.shade400, width: 4),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 10,
            right: 10,
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.blue.shade700,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
                border: Border.all(color: Colors.blue.shade900, width: 6),
                boxShadow: [
                  BoxShadow(color: Colors.black38, blurRadius: 10, offset: const Offset(0, 5))
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildPlatformItem("Salad", Icons.restaurant, isSaladSelected, Colors.greenAccent, (timerValue == 0 || spinningIndex != null || showWinResult) ? null : () {
                    setState(() => isSaladSelected = !isSaladSelected);
                  }),
                  _buildPlatformItem("Pizza", Icons.local_pizza, isPizzaSelected, Colors.orangeAccent, (timerValue == 0 || spinningIndex != null || showWinResult) ? null : () {
                    setState(() => isPizzaSelected = !isPizzaSelected);
                  }),
                ],
              ),
            ),
          ),
          ...List.generate(8, (index) {
            double angle = (index * 45 - 90) * (math.pi / 180);
            return Transform.translate(
              offset: Offset(135 * math.cos(angle), 135 * math.sin(angle)),
              child: _buildPod(index),
            );
          }),
          if (!showWinResult && spinningIndex == null)
            ...List.generate(1, (index) {
              double angle = (aiHandIndex * 45 - 90) * (math.pi / 180);
              return Transform.translate(
                offset: Offset(120 * math.cos(angle), 120 * math.sin(angle)),
                child: Transform.rotate(
                  angle: angle + math.pi / 2,
                  child: const Icon(
                    Icons.touch_app,
                    size: 45,
                    color: Colors.white,
                    shadows: [Shadow(color: Colors.black54, blurRadius: 10)],
                  ),
                ),
              );
            }),
          _buildCenterHub(),
        ],
      ),
    );
  }

  Widget _buildPod(int index) {
    bool isWinner = winningIndex == index && showWinResult;
    bool isSelected = activeBets.contains(index);
    bool isSpinning = spinningIndex == index;
    bool isWin5 = wheelItems[index]['multi'] == 5;

    return GestureDetector(
      onTap: (timerValue == 0 || spinningIndex != null || showWinResult) ? null : () => setState(() {
        isSelected ? activeBets.remove(index) : activeBets.add(index);
      }),
      child: Container(
        width: 85,
        height: 85,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: (isWinner || isSpinning) ? Colors.yellow : (isSelected ? (isWin5 ? Colors.green : Colors.red) : Colors.blue.shade800),
            width: 5,
          ),
          boxShadow: (isWinner || isSpinning || isSelected)
              ? [BoxShadow(color: (isWinner || isSpinning) ? Colors.yellow : (isWin5 ? Colors.green : Colors.red).withOpacity(0.5), blurRadius: 10)]
              : [],
        ),
        child: ClipOval(
          child: Column(
            children: [
              Expanded(
                flex: 3,
                child: Container(
                  color: isSelected ? (isWin5 ? Colors.green.shade50 : Colors.red.shade50) : Colors.white.withOpacity(0.95),
                  width: double.infinity,
                  child: Center(
                    child: Text(wheelItems[index]['icon'], style: const TextStyle(fontSize: 35)),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Container(
                  color: isSelected ? (isWin5 ? Colors.green.shade100 : Colors.red.shade100) : const Color(0xFFE1F5FE).withOpacity(0.95),
                  width: double.infinity,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "win ${wheelItems[index]['multi']} times",
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? (isWin5 ? Colors.green.shade900 : Colors.red.shade900) : Colors.blue.shade900,
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.diamond, size: 10, color: isSelected ? (isWin5 ? Colors.green : Colors.red) : Colors.orange),
                          Icon(Icons.diamond, size: 10, color: isSelected ? (isWin5 ? Colors.green : Colors.red) : Colors.orange),
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

  Widget _buildPlatformItem(String label, IconData icon, bool isSelected, Color baseColor, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.yellow.shade700,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black87, width: 2),
            ),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: Icon(icon, color: Colors.brown, size: 28),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: isSelected ? Colors.red : Colors.yellow.shade700,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.black87, width: 2),
            ),
            child: Text(
              "$label >",
              style: TextStyle(color: isSelected ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCenterHub() {
    return Container(
      width: 130,
      height: 130,
      decoration: BoxDecoration(
        color: Colors.red.shade700,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.blue.shade900, width: 8),
        boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 10)],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("Round 1646", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
          // Shows larger "Start" / "Stop" text
          Text(timerValue > 0 ? "Start" : "Stop", style: const TextStyle(fontSize: 18, color: Colors.yellow, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(12)),
            child: Text("${timerValue}s", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionPanel() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF29B6F6),
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(15), topRight: Radius.circular(15)),
        border: Border.all(color: Colors.white, width: 1),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [_buildStepLabel("1", "Select Amount"), const SizedBox(width: 20), _buildStepLabel("2", "Select Food")],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [10, 50, 100, 1000].map((val) {
              bool isSelected = selectedBetValue == val;
              return GestureDetector(
                onTap: (timerValue == 0 || spinningIndex != null || showWinResult) ? null : () => setState(() => selectedBetValue = val),
                child: Container(
                  width: 75,
                  height: 65,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isSelected ? Colors.red : Colors.grey.shade300, width: isSelected ? 3 : 1),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [Colors.yellow, Colors.orange])),
                        child: const Icon(Icons.diamond, color: Colors.white, size: 20),
                      ),
                      Text("x$val", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStepLabel(String step, String text) {
    return Row(
      children: [
        CircleAvatar(radius: 8, backgroundColor: Colors.blue.shade900, child: Text(step, style: const TextStyle(fontSize: 10, color: Colors.white))),
        const SizedBox(width: 5),
        Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
      ],
    );
  }

  Widget _buildTodayPrizeSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(color: Color(0xFFE53935)),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [Icon(Icons.circle, size: 8, color: Colors.white), SizedBox(width: 5), Text("Today's prize", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white))]),
              Row(children: [Icon(Icons.diamond, size: 16, color: Colors.orange), Text(" 1400  ", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)), Icon(Icons.circle, size: 16, color: Colors.grey), Text(" 0", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))]),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: Colors.red.shade300, borderRadius: BorderRadius.circular(10)),
                  child: const Text("Result", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(resultHistory.length, (index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              CircleAvatar(radius: 14, backgroundColor: Colors.white, child: Text(resultHistory[index], style: const TextStyle(fontSize: 16))),
                              if (index == 0) Positioned(top: -5, left: -5, child: Container(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1), decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(5), border: Border.all(color: Colors.white, width: 1)), child: const Text("New", style: TextStyle(fontSize: 6, color: Colors.white, fontWeight: FontWeight.bold)))),
                            ],
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardSection() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: const BoxDecoration(
        color: Color(0xFF039BE5),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(15), bottomRight: Radius.circular(15)),
      ),
      child: Row(
        children: [
          _buildLeaderCard("Yellow Diamonds", "4721600", "https://i.pravatar.cc/150?u=1", Colors.orange),
          const SizedBox(width: 8),
          _buildLeaderCard("Black Diamonds", "5860500", "https://i.pravatar.cc/150?u=2", Colors.blue),
        ],
      ),
    );
  }

  Widget _buildLeaderCard(String name, String value, String imgUrl, Color iconColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
        child: Row(
          children: [
            CircleAvatar(radius: 15, backgroundImage: NetworkImage(imgUrl)),
            const SizedBox(width: 5),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(color: Colors.black, fontSize: 8, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                  Row(children: [Icon(Icons.diamond, size: 10, color: iconColor), Text(value, style: const TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.bold))]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()..color = Colors.blue.shade600..style = PaintingStyle.fill;
    final borderPaint = Paint()..color = Colors.blue.shade900..style = PaintingStyle.stroke..strokeWidth = 8;
    final path = Path();
    double legWidth = 60;
    path.moveTo(size.width * 0.4, 0);
    path.lineTo(size.width * 0.1, size.height);
    path.lineTo(size.width * 0.1 + legWidth, size.height);
    path.lineTo(size.width * 0.4 + legWidth, 0);
    path.close();
    path.moveTo(size.width * 0.6, 0);
    path.lineTo(size.width * 0.9, size.height);
    path.lineTo(size.width * 0.9 - legWidth, size.height);
    path.lineTo(size.width * 0.6 - legWidth, 0);
    path.close();
    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, borderPaint);
    canvas.drawRect(Rect.fromLTWH(size.width * 0.3, size.height * 0.5, size.width * 0.4, 15), fillPaint);
    canvas.drawRect(Rect.fromLTWH(size.width * 0.3, size.height * 0.5, size.width * 0.4, 15), borderPaint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class SpokesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.blue.shade900, Colors.blue.shade400],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 5;

    for (int i = 0; i < 8; i++) {
      double angle = (i * 45 - 90) * (math.pi / 180);
      canvas.drawLine(
        center,
        Offset(center.dx + radius * math.cos(angle), center.dy + radius * math.sin(angle)),
        paint,
      );
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
