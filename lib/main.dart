import 'dart:async';
import 'dart:io';
import 'dart:math'; // Required for 3D flip math
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  WakelockPlus.enable();

  runApp(const MyClockApp());
}

class MyClockApp extends StatelessWidget {
  const MyClockApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mega Flip Clock',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.transparent,
        dialogBackgroundColor: const Color(0xFF222222),
      ),
      home: const HomeScreen(),
    );
  }
}

// --- MODELS ---
enum AppMode { clock, stopwatch }

class CustomTheme {
  File? backgroundImage;
  Color cardColor;
  Color digitColor;

  CustomTheme({
    this.backgroundImage,
    required this.cardColor,
    required this.digitColor,
  });
}

// --- HOME SCREEN ---
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  AppMode _currentMode = AppMode.clock;
  
  // Theme State
  final CustomTheme _theme = CustomTheme(
    cardColor: const Color(0xFF3F51B5), 
    digitColor: const Color(0xFFFFF9C4), 
  );

  double _scaleFactor = 1.0;      
  double _auxScaleFactor = 1.0;   
  bool _isLandscape = true; 

  final Battery _battery = Battery();
  int _batteryLevel = 100;
  Timer? _batteryTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _getBatteryLevel();
    _batteryTimer = Timer.periodic(const Duration(minutes: 1), (_) => _getBatteryLevel());
  }

  Future<void> _getBatteryLevel() async {
    final level = await _battery.batteryLevel;
    if (mounted) setState(() => _batteryLevel = level);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _batteryTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    setState(() {});
  }

  // --- ACTIONS ---
  void _toggleOrientation() {
    setState(() {
      _isLandscape = !_isLandscape;
    });
    
    if (_isLandscape) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft, 
        DeviceOrientation.landscapeRight
      ]);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp, 
        DeviceOrientation.portraitDown
      ]);
    }
    Navigator.pop(context); 
  }

  void _adjustSize(double delta) {
    setState(() {
      _scaleFactor = (_scaleFactor + delta).clamp(0.5, 2.0);
    });
  }

  void _adjustAuxSize(double delta) {
    setState(() {
      _auxScaleFactor = (_auxScaleFactor + delta).clamp(0.5, 2.5);
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) setState(() => _theme.backgroundImage = File(image.path));
  }

  void _pickColor(bool isCard) {
    Color tempColor = isCard ? _theme.cardColor : _theme.digitColor;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isCard ? 'Card Color' : 'Font Color'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: tempColor,
            onColorChanged: (c) => tempColor = c,
            enableAlpha: false,
            displayThumbColor: true,
            hexInputBar: true,
            labelTypes: const [],
          ),
        ),
        actions: [
          TextButton(
            child: const Text('DONE', style: TextStyle(color: Colors.white)),
            onPressed: () {
              setState(() {
                if (isCard) _theme.cardColor = tempColor;
                else _theme.digitColor = tempColor;
              });
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  // --- SETTINGS PANEL ---
  void _openSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black.withOpacity(0.95),
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.85,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(25.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(child: Text("SETTINGS", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 3, fontSize: 18))),
                      const SizedBox(height: 25),

                      _buildControlRow("Orientation", 
                        ElevatedButton.icon(
                          onPressed: _toggleOrientation,
                          icon: const Icon(Icons.screen_rotation),
                          label: Text(_isLandscape ? "To Portrait" : "To Landscape"),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                        )
                      ),
                      const SizedBox(height: 15),

                      _buildSizeControl("Clock Size", _scaleFactor, (v) { _adjustSize(v); setModalState((){}); }),
                      const SizedBox(height: 15),

                      _buildSizeControl("Info Size (Date/Sec)", _auxScaleFactor, (v) { _adjustAuxSize(v); setModalState((){}); }),

                      const SizedBox(height: 25),
                      const Text("MODE & THEME", style: TextStyle(color: Colors.white54, fontSize: 12)),
                      const SizedBox(height: 10),

                      Row(
                        children: [
                          Expanded(child: _modeButton("CLOCK", AppMode.clock, setModalState)),
                          const SizedBox(width: 10),
                          Expanded(child: _modeButton("STOPWATCH", AppMode.stopwatch, setModalState)),
                        ],
                      ),
                      const SizedBox(height: 20),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildSettingsIcon(Icons.image, "BG Image", _pickImage),
                          _buildSettingsIcon(Icons.format_paint, "Card Color", () => _pickColor(true)),
                          _buildSettingsIcon(Icons.text_fields, "Font Color", () => _pickColor(false)),
                          if (_theme.backgroundImage != null)
                            _buildSettingsIcon(Icons.delete_outline, "Reset BG", () => setState(() => _theme.backgroundImage = null)),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            );
          }
        );
      },
    );
  }

  Widget _buildControlRow(String label, Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          child,
        ],
      ),
    );
  }

  Widget _buildSizeControl(String label, double value, Function(double) onAdjust) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10)),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () => onAdjust(-0.1),
                icon: const Icon(Icons.remove_circle_outline, size: 30),
                color: Colors.redAccent,
              ),
              Container(
                width: 60,
                alignment: Alignment.center,
                child: Text("${(value * 100).toInt()}%", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              IconButton(
                onPressed: () => onAdjust(0.1),
                icon: const Icon(Icons.add_circle_outline, size: 30),
                color: Colors.greenAccent,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _modeButton(String title, AppMode mode, Function setModalState) {
    bool isActive = _currentMode == mode;
    return GestureDetector(
      onTap: () {
        setState(() => _currentMode = mode);
        setModalState(() {});
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? Colors.blueAccent : Colors.white10,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isActive ? Colors.white : Colors.white60))),
      ),
    );
  }

  Widget _buildSettingsIcon(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: Colors.grey[800],
            radius: 24,
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 5),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.white70)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black,
              image: _theme.backgroundImage != null 
                ? DecorationImage(image: FileImage(_theme.backgroundImage!), fit: BoxFit.cover)
                : null,
              gradient: _theme.backgroundImage == null 
                ? const LinearGradient(
                    colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight)
                : null,
            ),
          ),
        ),
        Scaffold(
          backgroundColor: Colors.transparent, 
          resizeToAvoidBottomInset: false, 
          body: Stack(
            children: [
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: _currentMode == AppMode.clock
                    ? ClockDisplay(
                        theme: _theme, 
                        scaleFactor: _scaleFactor, 
                        auxScaleFactor: _auxScaleFactor
                      )
                    : StopwatchDisplay(theme: _theme, scaleFactor: _scaleFactor),
                ),
              ),
              Positioned(
                top: 15, right: 15,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(15)),
                  child: Row(
                    children: [
                      Text("$_batteryLevel%", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(width: 5),
                      Icon(_batteryLevel > 20 ? Icons.battery_full : Icons.battery_alert, size: 14, color: _batteryLevel > 20 ? Colors.green : Colors.red),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 30, right: 30,
                child: FloatingActionButton(
                  backgroundColor: Colors.white12,
                  elevation: 0,
                  onPressed: _openSettings,
                  child: const Icon(Icons.settings, color: Colors.white70, size: 30),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// --- CLOCK DISPLAY ---
class ClockDisplay extends StatefulWidget {
  final CustomTheme theme;
  final double scaleFactor;
  final double auxScaleFactor;

  const ClockDisplay({
    super.key, 
    required this.theme, 
    required this.scaleFactor,
    required this.auxScaleFactor,
  });

  @override
  State<ClockDisplay> createState() => _ClockDisplayState();
}

class _ClockDisplayState extends State<ClockDisplay> {
  late Timer _timer;
  late DateTime _now;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() => _now = DateTime.now()));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isLandscape = constraints.maxWidth > constraints.maxHeight;
        
        String hour = DateFormat('hh').format(_now);
        String minute = DateFormat('mm').format(_now);
        String second = DateFormat('ss').format(_now);
        String amPm = DateFormat('a').format(_now).toUpperCase();
        
        String dateText = DateFormat('dd/MM/yy').format(_now); 
        String dayText = DateFormat('EEEE').format(_now); 

        double shortSide = constraints.maxWidth < constraints.maxHeight 
            ? constraints.maxWidth 
            : constraints.maxHeight;
        
        double baseSize = isLandscape ? shortSide * 0.75 : shortSide * 0.55; 
        double finalSize = baseSize * widget.scaleFactor;

        return Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: isLandscape
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // HOUR CARD (FLIPPABLE)
                      FlippableCard(
                        mainText: hour, 
                        topLabel: dateText,
                        bottomLeftLabel: amPm,
                        size: finalSize, 
                        theme: widget.theme,
                        auxScale: widget.auxScaleFactor,
                      ),
                      SizedBox(width: finalSize * 0.05),
                      // MINUTE CARD (FLIPPABLE)
                      FlippableCard(
                        mainText: minute, 
                        topLabel: dayText,
                        bottomRightLabel: second,
                        size: finalSize, 
                        theme: widget.theme,
                        auxScale: widget.auxScaleFactor,
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FlippableCard(
                        mainText: hour, 
                        topLabel: dateText,
                        bottomLeftLabel: amPm,
                        size: finalSize, 
                        theme: widget.theme,
                        auxScale: widget.auxScaleFactor,
                      ),
                      SizedBox(height: finalSize * 0.05),
                      FlippableCard(
                        mainText: minute, 
                        topLabel: dayText,
                        bottomRightLabel: second,
                        size: finalSize, 
                        theme: widget.theme,
                        auxScale: widget.auxScaleFactor,
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}

// --- STOPWATCH DISPLAY ---
class StopwatchDisplay extends StatefulWidget {
  final CustomTheme theme;
  final double scaleFactor;
  const StopwatchDisplay({super.key, required this.theme, required this.scaleFactor});

  @override
  State<StopwatchDisplay> createState() => _StopwatchDisplayState();
}

class _StopwatchDisplayState extends State<StopwatchDisplay> {
  final Stopwatch _stopwatch = Stopwatch();
  late Timer _timer;
  String _formatted = "00:00:00";

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 30), (_) {
      if (_stopwatch.isRunning) {
        setState(() => _formatted = _formatTime(_stopwatch.elapsedMilliseconds));
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatTime(int ms) {
    int hundreds = (ms / 10).truncate() % 100;
    int seconds = (ms / 1000).truncate() % 60;
    int minutes = (ms / (1000 * 60)).truncate() % 60;
    return "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}:${hundreds.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double shortSide = constraints.maxWidth < constraints.maxHeight 
            ? constraints.maxWidth 
            : constraints.maxHeight;
        List<String> parts = _formatted.split(':');

        double baseSize = shortSide * 0.35; 
        double finalSize = baseSize * widget.scaleFactor;

        return Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    FlippableCard(mainText: parts[0], size: finalSize, theme: widget.theme),
                    Text(":", style: TextStyle(fontSize: finalSize * 0.5, color: Colors.white54)),
                    FlippableCard(mainText: parts[1], size: finalSize, theme: widget.theme),
                    Text(".", style: TextStyle(fontSize: finalSize * 0.5, color: Colors.white54)),
                    FlippableCard(mainText: parts[2], size: finalSize * 0.7, theme: widget.theme),
                  ],
                ),
                SizedBox(height: finalSize * 0.2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FloatingActionButton(
                      backgroundColor: widget.theme.cardColor,
                      heroTag: "play",
                      onPressed: () => setState(() => _stopwatch.isRunning ? _stopwatch.stop() : _stopwatch.start()),
                      child: Icon(_stopwatch.isRunning ? Icons.pause : Icons.play_arrow, color: widget.theme.digitColor, size: 30),
                    ),
                    const SizedBox(width: 30),
                    FloatingActionButton(
                      backgroundColor: Colors.white24,
                      heroTag: "reset",
                      onPressed: () => setState(() { _stopwatch.reset(); _formatted = "00:00:00"; }),
                      child: const Icon(Icons.refresh, color: Colors.white),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }
}

// --- NEW FLIPPABLE CARD WIDGET ---
class FlippableCard extends StatelessWidget {
  final String mainText;
  final double size;
  final CustomTheme theme;
  final String? topLabel;
  final String? bottomLeftLabel;
  final String? bottomRightLabel;
  final double auxScale;

  const FlippableCard({
    super.key,
    required this.mainText,
    required this.size,
    required this.theme,
    this.topLabel,
    this.bottomLeftLabel,
    this.bottomRightLabel,
    this.auxScale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    // We use AnimatedSwitcher to flip between the "Old" DigitCard and the "New" DigitCard
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 450), // Speed of the flip
      transitionBuilder: (Widget child, Animation<double> animation) {
        // Create a Rotation Effect on the X Axis (Vertical Flip)
        final rotateAnim = Tween(begin: pi, end: 0.0).animate(animation);
        
        return AnimatedBuilder(
          animation: rotateAnim,
          child: child,
          builder: (context, child) {
            final isUnder = (ValueKey(mainText) != child?.key);
            var tilt = ((animation.value - 0.5).abs() - 0.5) * 0.003;
            tilt *= isUnder ? -1.0 : 1.0;
            final value = isUnder ? min(rotateAnim.value, pi / 2) : rotateAnim.value;
            
            return Transform(
              transform: Matrix4.rotationX(value)..setEntry(3, 2, 0.001), // 0.001 adds 3D perspective
              alignment: Alignment.center,
              child: child,
            );
          },
        );
      },
      // IMPORTANT: Key must change for animation to trigger
      child: DigitCard(
        key: ValueKey(mainText), 
        mainText: mainText,
        size: size,
        theme: theme,
        topLabel: topLabel,
        bottomLeftLabel: bottomLeftLabel,
        bottomRightLabel: bottomRightLabel,
        auxScale: auxScale,
      ),
    );
  }
}

// --- VISUAL DIGIT CARD ---
class DigitCard extends StatelessWidget {
  final String mainText;
  final double size;
  final CustomTheme theme;
  final String? topLabel;
  final String? bottomLeftLabel;
  final String? bottomRightLabel;
  final double auxScale;

  const DigitCard({
    super.key, 
    required this.mainText, 
    required this.size, 
    required this.theme,
    this.topLabel,
    this.bottomLeftLabel,
    this.bottomRightLabel,
    this.auxScale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    double topFontSize = size * 0.08 * auxScale;
    double cornerFontSize = size * 0.12 * auxScale;
    double mainFontSize = size * 0.75;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(size * 0.15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.5), offset: Offset(size*0.02, size*0.02), blurRadius: 10),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (topLabel != null)
            Positioned(
              top: size * 0.06,
              child: Text(
                topLabel!,
                style: TextStyle(fontSize: topFontSize, fontWeight: FontWeight.bold, color: theme.digitColor),
              ),
            ),

          Text(
            mainText, 
            style: TextStyle(fontSize: mainFontSize, fontWeight: FontWeight.w900, color: theme.digitColor, height: 0.9)
          ),

          Positioned(
            top: size / 2, 
            left: 0, 
            right: 0, 
            child: Container(height: size * 0.008, color: Colors.black38)
          ),

          Positioned(
            top: 0, left: 0, right: 0, height: size / 2,
            child: Container(decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter, 
                  end: Alignment.bottomCenter, 
                  colors: [Colors.white10, Colors.transparent]
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(size * 0.15)),
            )),
          ),

          if (bottomLeftLabel != null)
            Positioned(
              bottom: size * 0.06,
              left: size * 0.08,
              child: Text(
                bottomLeftLabel!,
                style: TextStyle(fontSize: cornerFontSize, fontWeight: FontWeight.bold, color: theme.digitColor),
              ),
            ),

          if (bottomRightLabel != null)
            Positioned(
              bottom: size * 0.06,
              right: size * 0.08,
              child: Text(
                bottomRightLabel!,
                style: TextStyle(fontSize: cornerFontSize, fontWeight: FontWeight.bold, color: theme.digitColor),
              ),
            ),
        ],
      ),
    );
  }
}