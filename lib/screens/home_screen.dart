import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_models.dart';
import '../modules/clock_view.dart';
import '../modules/stopwatch_view.dart';
import '../modules/chess_view.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  AppMode _currentMode = AppMode.clock;
  
  final CustomTheme _theme = CustomTheme(
    cardColor: const Color(0xFF3F51B5), 
    digitColor: const Color(0xFFFFF9C4), 
  );

  double _scaleFactor = 1.0; 
  double _auxScaleFactor = 1.0; // Your new variable
  bool _isLandscape = true; 
  bool _showSettingsIcon = false; 
  Timer? _controlsTimer;

  final Battery _battery = Battery();
  int _batteryLevel = 100;
  Timer? _batteryTimer;

  // Alarm State
  TimeOfDay? _alarmTime;
  bool _alarmTriggered = false;

  // Chess State
  int _p1Ms = 300000;
  int _p2Ms = 300000;
  int _initialMs = 300000;
  int _incrementMs = 0;
  int _p1Moves = 0;
  int _p2Moves = 0;
  int _activePlayer = 0; 
  bool _gameFinished = false;
  Timer? _chessTimer;
  // Add these near other chess variables
  int _customBaseMin = 10;
  int _customIncSec = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Load your Saved Settings
    _loadSettings();

    _getBatteryLevel();
    _batteryTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _getBatteryLevel();
      _checkAlarm();
    });
    
    _chessTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_currentMode == AppMode.chess && _activePlayer != 0 && !_gameFinished) {
        setState(() {
          if (_activePlayer == 1) {
            _p1Ms -= 100;
            if (_p1Ms <= 0) _finishGame(2);
          } else {
            _p2Ms -= 100;
            if (_p2Ms <= 0) _finishGame(1);
          }
        });
      }
    });
  }

  // --- PERSISTENCE ---
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _scaleFactor = prefs.getDouble('scaleFactor') ?? 1.0;
      _auxScaleFactor = prefs.getDouble('auxScaleFactor') ?? 1.0;
      
      int? cardColorVal = prefs.getInt('cardColor');
      int? digitColorVal = prefs.getInt('digitColor');
      if (cardColorVal != null) _theme.cardColor = Color(cardColorVal);
      if (digitColorVal != null) _theme.digitColor = Color(digitColorVal);

      String? bgPath = prefs.getString('bgPath');
      if (bgPath != null && File(bgPath).existsSync()) {
        _theme.backgroundImage = File(bgPath);
      }

      _isLandscape = prefs.getBool('isLandscape') ?? true;
      _applyOrientation();
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setDouble('scaleFactor', _scaleFactor);
    prefs.setDouble('auxScaleFactor', _auxScaleFactor);
    prefs.setInt('cardColor', _theme.cardColor.value);
    prefs.setInt('digitColor', _theme.digitColor.value);
    prefs.setBool('isLandscape', _isLandscape);
    
    if (_theme.backgroundImage != null) {
      prefs.setString('bgPath', _theme.backgroundImage!.path);
    } else {
      prefs.remove('bgPath');
    }
  }

  void _applyOrientation() {
    if (_isLandscape) {
      SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
    } else {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
    }
  }

  void _checkAlarm() {
    if (_alarmTime == null) return;
    final now = DateTime.now();
    if (now.hour == _alarmTime!.hour && now.minute == _alarmTime!.minute && !_alarmTriggered) {
      setState(() => _alarmTriggered = true);
      SystemSound.play(SystemSoundType.click); 
      HapticFeedback.heavyImpact();
    } else if (now.minute != _alarmTime!.minute) {
      _alarmTriggered = false;
    }
  }

  Future<void> _getBatteryLevel() async {
    final level = await _battery.batteryLevel;
    if (mounted) setState(() => _batteryLevel = level);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _batteryTimer?.cancel();
    _chessTimer?.cancel();
    _controlsTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeMetrics() => setState(() {});

  void _onScreenTap() {
    setState(() => _showSettingsIcon = true);
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showSettingsIcon = false);
    });
  }

  void _toggleOrientation() {
    setState(() => _isLandscape = !_isLandscape);
    _applyOrientation();
    _saveSettings();
    Navigator.pop(context); 
  }

  void _adjustSize(double delta) {
    setState(() => _scaleFactor = (_scaleFactor + delta).clamp(0.5, 2.0));
    _saveSettings();
  }

  void _adjustAuxSize(double delta) {
    setState(() => _auxScaleFactor = (_auxScaleFactor + delta).clamp(0.5, 2.5));
    _saveSettings();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _theme.backgroundImage = File(image.path));
      _saveSettings();
    }
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
              _saveSettings();
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  // --- CHESS ACTIONS ---
  void _switchTurn(int playerTapping) {
    if (_gameFinished) return;
    if (_activePlayer == 0) {
        HapticFeedback.selectionClick();
        setState(() => _activePlayer = (playerTapping == 1) ? 2 : 1);
        return;
    }
    if (playerTapping != _activePlayer) return;
    HapticFeedback.lightImpact();
    SystemSound.play(SystemSoundType.click);
    setState(() {
      if (_activePlayer == 1) {
        _p1Ms += _incrementMs;
        _p1Moves++;
        _activePlayer = 2;
      } else {
        _p2Ms += _incrementMs;
        _p2Moves++;
        _activePlayer = 1;
      }
    });
  }

  void _pauseChess() => setState(() => _activePlayer = 0);
  void _resetChess() => setState(() { _activePlayer = 0; _gameFinished = false; _p1Ms = _initialMs; _p2Ms = _initialMs; _p1Moves = 0; _p2Moves = 0; });
  void _setChessTime(int minutes, int incSeconds) { setState(() { _initialMs = minutes * 60 * 1000; _incrementMs = incSeconds * 1000; _resetChess(); }); Navigator.pop(context); }
  void _finishGame(int winner) { setState(() { _activePlayer = 0; _gameFinished = true; }); HapticFeedback.heavyImpact(); }

  // --- SETTINGS UI ---
  // --- SETTINGS UI ---
  void _openSettings() {
    _controlsTimer?.cancel();
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

                      // --- CHESS SETTINGS (Visible only in Chess Mode) ---
                      if (_currentMode == AppMode.chess) ...[
                        const Text("CHESS: CUSTOM GAME", style: TextStyle(color: Colors.blueAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        
                        // Custom Time Controls
                        Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10)),
                          child: Column(
                            children: [
                              // Minutes Row
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text("Minutes:", style: TextStyle(fontWeight: FontWeight.bold)),
                                  Row(
                                    children: [
                                      IconButton(icon: const Icon(Icons.remove_circle, color: Colors.red), onPressed: () => setModalState(() => _customBaseMin = (_customBaseMin - 1).clamp(1, 180))),
                                      SizedBox(width: 40, child: Center(child: Text("$_customBaseMin", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)))),
                                      IconButton(icon: const Icon(Icons.add_circle, color: Colors.green), onPressed: () => setModalState(() => _customBaseMin = (_customBaseMin + 1).clamp(1, 180))),
                                    ],
                                  )
                                ],
                              ),
                              const Divider(color: Colors.white24),
                              // Increment Row
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text("Increment (sec):", style: TextStyle(fontWeight: FontWeight.bold)),
                                  Row(
                                    children: [
                                      IconButton(icon: const Icon(Icons.remove_circle, color: Colors.red), onPressed: () => setModalState(() => _customIncSec = (_customIncSec - 1).clamp(0, 60))),
                                      SizedBox(width: 40, child: Center(child: Text("$_customIncSec", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)))),
                                      IconButton(icon: const Icon(Icons.add_circle, color: Colors.green), onPressed: () => setModalState(() => _customIncSec = (_customIncSec + 1).clamp(0, 60))),
                                    ],
                                  )
                                ],
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
                                  onPressed: () {
                                    _setChessTime(_customBaseMin, _customIncSec);
                                    // Navigator.pop(context); // _setChessTime already pops
                                  }, 
                                  child: const Text("START GAME")
                                ),
                              )
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        const Text("QUICK PRESETS", style: TextStyle(color: Colors.white54, fontSize: 12)),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 10, runSpacing: 10,
                          children: [
                            _chessPresetBtn("Bullet 1+0", 1, 0),
                            _chessPresetBtn("Bullet 1+1", 1, 1),
                            _chessPresetBtn("Blitz 3+2", 3, 2),
                            _chessPresetBtn("Blitz 5+0", 5, 0),
                            _chessPresetBtn("Rapid 10+0", 10, 0),
                            _chessPresetBtn("Rapid 15+10", 15, 10),
                            _chessPresetBtn("Classical 30+0", 30, 0),
                          ],
                        ),
                        const SizedBox(height: 30),
                        const Divider(color: Colors.white24),
                        const SizedBox(height: 10),
                      ],

                      // --- GENERAL SETTINGS ---
                      const Text("GENERAL", style: TextStyle(color: Colors.white54, fontSize: 12)),
                      const SizedBox(height: 10),

                      // Alarm (Existing)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_alarmTime == null ? "Alarm: Off" : "Alarm: ${_alarmTime!.format(context)}", style: const TextStyle(fontWeight: FontWeight.bold)),
                            Row(
                              children: [
                                if (_alarmTime != null) IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => setState(() => _alarmTime = null)),
                                IconButton(icon: const Icon(Icons.access_time), onPressed: () async {
                                    final TimeOfDay? picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                                    if (picked != null) setState(() => _alarmTime = picked);
                                    Navigator.pop(context);
                                }),
                              ],
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: 15),

                      _buildControlRow("Orientation", 
                        ElevatedButton.icon(
                          onPressed: _toggleOrientation,
                          icon: const Icon(Icons.screen_rotation),
                          label: Text(_isLandscape ? "Rotate" : "Rotate"),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[800]),
                        )
                      ),
                      const SizedBox(height: 15),

                      _buildSizeControl("Clock Size", _scaleFactor, (v) { _adjustSize(v); setModalState((){}); }),
                      const SizedBox(height: 15),
                      _buildSizeControl("Info Size", _auxScaleFactor, (v) { _adjustAuxSize(v); setModalState((){}); }),

                      const SizedBox(height: 25),
                      const Text("MODE & THEME", style: TextStyle(color: Colors.white54, fontSize: 12)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(child: _modeButton("CLOCK", AppMode.clock, setModalState)),
                          const SizedBox(width: 5),
                          Expanded(child: _modeButton("STOPWATCH", AppMode.stopwatch, setModalState)),
                          const SizedBox(width: 5),
                          Expanded(child: _modeButton("CHESS", AppMode.chess, setModalState)),
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
                            _buildSettingsIcon(Icons.delete_outline, "Reset BG", () {
                              setState(() => _theme.backgroundImage = null);
                              _saveSettings();
                            }),
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
    ).then((_) => _onScreenTap());
  }

  Widget _buildControlRow(String label, Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10)),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: const TextStyle(fontWeight: FontWeight.bold)), child]),
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
              IconButton(onPressed: () => onAdjust(-0.1), icon: const Icon(Icons.remove_circle_outline, size: 30), color: Colors.redAccent),
              Container(width: 60, alignment: Alignment.center, child: Text("${(value * 100).toInt()}%", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
              IconButton(onPressed: () => onAdjust(0.1), icon: const Icon(Icons.add_circle_outline, size: 30), color: Colors.greenAccent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chessPresetBtn(String label, int min, int inc) {
    return ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.white12, foregroundColor: Colors.white), onPressed: () => _setChessTime(min, inc), child: Text(label));
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
        decoration: BoxDecoration(color: isActive ? Colors.blueAccent : Colors.white10, borderRadius: BorderRadius.circular(8)),
        child: Center(child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isActive ? Colors.white : Colors.white60))),
      ),
    );
  }

  Widget _buildSettingsIcon(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(backgroundColor: Colors.grey[800], radius: 24, child: Icon(icon, color: Colors.white, size: 24)),
          const SizedBox(height: 5),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.white70)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onScreenTap, 
      behavior: HitTestBehavior.translucent,
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black,
                image: _theme.backgroundImage != null ? DecorationImage(image: FileImage(_theme.backgroundImage!), fit: BoxFit.cover) : null,
                gradient: _theme.backgroundImage == null ? const LinearGradient(colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)], begin: Alignment.topLeft, end: Alignment.bottomRight) : null,
              ),
            ),
          ),
          Scaffold(
            backgroundColor: _alarmTriggered ? Colors.red.withOpacity(0.3) : Colors.transparent, 
            resizeToAvoidBottomInset: false,
            body: Stack(
              children: [
                Positioned.fill(child: Padding(padding: const EdgeInsets.all(10.0), child: _buildMainContent())),
                Positioned(
                  top: 15, right: 15,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(15)),
                    child: Row(
                      children: [
                        if (_alarmTime != null) ...[Icon(Icons.alarm, size: 14, color: _alarmTriggered ? Colors.red : Colors.white70), const SizedBox(width: 8)],
                        Text("$_batteryLevel%", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(width: 5),
                        Icon(_batteryLevel > 20 ? Icons.battery_full : Icons.battery_alert, size: 14, color: _batteryLevel > 20 ? Colors.green : Colors.red),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 30, right: 30,
                  child: AnimatedOpacity(
                    opacity: _showSettingsIcon ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: FloatingActionButton(
                      backgroundColor: Colors.white12,
                      elevation: 0,
                      onPressed: _showSettingsIcon ? _openSettings : null,
                      child: const Icon(Icons.settings, color: Colors.white70, size: 30),
                    ),
                  ),
                ),
                if (_alarmTriggered)
                  Center(child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red, padding: const EdgeInsets.all(20)), onPressed: () => setState(() => _alarmTriggered = false), child: const Text("DISMISS ALARM", style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold)))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    switch (_currentMode) {
      case AppMode.chess:
        return ChessDisplay(
          theme: _theme, scaleFactor: _scaleFactor, p1Ms: _p1Ms, p2Ms: _p2Ms, p1Moves: _p1Moves, p2Moves: _p2Moves,
          activePlayer: _activePlayer, gameFinished: _gameFinished, onTapP1: () => _switchTurn(1), onTapP2: () => _switchTurn(2),
          onPause: _pauseChess, onReset: _resetChess, isLandscape: _isLandscape,
        );
      case AppMode.stopwatch:
        return StopwatchDisplay(theme: _theme, scaleFactor: _scaleFactor);
      case AppMode.clock:
      default:
        return ClockDisplay(theme: _theme, scaleFactor: _scaleFactor, auxScaleFactor: _auxScaleFactor);
    }
  }
}