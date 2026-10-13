import 'package:flutter/material.dart';
import 'bluetooth_hid_service.dart';

enum GestureType {
  singleTap,
  twoFingerTap,
  oneFingerDrag,
  twoFingerDrag,
  pinchSpread,
  threeFingerSwipe,
}

class WindpadGestureDetector {
  final BluetoothHidService btService;

  static const int kTapMaxMs = 250;
  static const double kTapMaxDist = 12.0;
  static const double kPinchThreshold = 16.0;
  static const double kSwipeThreshold = 12.0;

  DateTime? _touchStartTime;
  Offset? _touchStartPos;
  final Map<int, Offset> _activePointers = {};
  double? _lastPinchDistance;

  // Smooth cursor — low-pass filter state
  double _smoothX = 0.0;
  double _smoothY = 0.0;

  WindpadGestureDetector(this.btService);

  bool _isDragging = false;
  DateTime? _lastTapTime;

  void handlePointerDown(PointerDownEvent event) {
    _activePointers[event.pointer] = event.position;
    final count = _activePointers.length;

    if (count == 1) {
      _touchStartTime = DateTime.now();
      _touchStartPos = event.position;
      _smoothX = 0.0;
      _smoothY = 0.0;
    } else if (count == 2) {
      final p1 = _activePointers.values.elementAt(0);
      final p2 = _activePointers.values.elementAt(1);
      _lastPinchDistance = (p1 - p2).distance;
    }
  }

  void handlePointerMove(PointerMoveEvent event) {
    _activePointers[event.pointer] = event.position;
    if (_touchStartPos == null) return;
    if (btService.trackpadLocked) return;

    final count = _activePointers.length;
    final delta = event.localDelta;

    if (count == 1) {
      final rawDx = delta.dx * btService.movementScale * 2.5;
      final rawDy = delta.dy * btService.movementScale * 2.5;

      // Low-pass filter for smooth cursor
      _smoothX = _smoothX * 0.35 + rawDx * 0.65;
      _smoothY = _smoothY * 0.35 + rawDy * 0.65;

      // Pointer acceleration curve
      final speed = (_smoothX * _smoothX + _smoothY * _smoothY);
      final accel = speed > 100 ? 1.3 : (speed > 25 ? 1.1 : 1.0);
      final outX = (_smoothX * accel).toInt();
      final outY = (_smoothY * accel).toInt();

      // Double-Tap-To-Drag
      if (!_isDragging && _lastTapTime != null && _touchStartTime != null) {
        if (DateTime.now().difference(_lastTapTime!).inMilliseconds < 450) {
          final travelDist = (event.position - _touchStartPos!).distance;
          if (travelDist > 8.0) {
            _isDragging = true;
            btService.sendMouseButtonDown(1);
          }
        } else {
          _lastTapTime = null;
        }
      }

      btService.sendMouseMove(outX, outY);
      btService.setActiveGesture(_isDragging ? "dragHold" : "drag");
    } else if (count == 2) {
      final p1 = _activePointers.values.elementAt(0);
      final p2 = _activePointers.values.elementAt(1);
      final currentDist = (p1 - p2).distance;

      if (_lastPinchDistance != null) {
        final distDelta = currentDist - _lastPinchDistance!;

        if (distDelta.abs() > kPinchThreshold) {
          final zoomIn = distDelta > 0;
          if (zoomIn) {
            btService.zoomIn();
            btService.setPinchPop("🔍 Zoom In");
          } else {
            btService.zoomOut();
            btService.setPinchPop("🔎 Zoom Out");
          }
          _lastPinchDistance = currentDist;
          btService.setActiveGesture("pinch");
          return;
        }
      }

      // Two-finger scroll
      final scrollY = delta.dy.toInt();
      if (scrollY.abs() > 0) {
        btService.sendScroll(-scrollY);
        btService.setActiveGesture("twoScroll");
      }
    } else if (count >= 3) {
      if (delta.dx.abs() > kSwipeThreshold || delta.dy.abs() > kSwipeThreshold) {
        _handleThreeFingerSwipe(delta);
        btService.setActiveGesture("threeSwipe");
      }
    }
  }

  void handlePointerUp(PointerUpEvent event) {
    final prevCount = _activePointers.length;
    _activePointers.remove(event.pointer);

    if (_isDragging) {
      btService.sendMouseButtonUp();
      _isDragging = false;
      _lastTapTime = null;
    } else if (_touchStartTime != null && _touchStartPos != null) {
      final duration = DateTime.now().difference(_touchStartTime!).inMilliseconds;
      final totalDist = (event.position - _touchStartPos!).distance;

      if (duration < kTapMaxMs && totalDist < 24.0) {
        if (prevCount == 1) {
          btService.sendMouseClick(1);
          btService.setActiveGesture("singleTap");
          _lastTapTime = DateTime.now();
        } else if (prevCount == 2) {
          btService.sendMouseClick(2);
          btService.setActiveGesture("twoTap");
          _lastTapTime = null;
        } else if (prevCount == 3) {
          btService.sendMouseClick(4); // Middle click
          _lastTapTime = null;
        }
        Future.delayed(const Duration(milliseconds: 700), () {
          btService.setActiveGesture(null);
        });
      }
    }

    if (_activePointers.isEmpty) {
      _touchStartTime = null;
      _touchStartPos = null;
      _lastPinchDistance = null;
      _isDragging = false;
      _smoothX = 0.0;
      _smoothY = 0.0;
    }
  }

  void handlePointerCancel(PointerCancelEvent event) {
    _activePointers.remove(event.pointer);
    if (_isDragging) {
      btService.sendMouseButtonUp();
      _isDragging = false;
    }
    if (_activePointers.isEmpty) {
      _touchStartTime = null;
      _touchStartPos = null;
      _lastPinchDistance = null;
      _isDragging = false;
      _smoothX = 0.0;
      _smoothY = 0.0;
    }
  }

  void _handleThreeFingerSwipe(Offset delta) {
    if (delta.dx.abs() > delta.dy.abs()) {
      if (delta.dx > 0) {
        btService.sendKey(0x01, [0x4F]); // Ctrl+Right
      } else {
        btService.sendKey(0x01, [0x50]); // Ctrl+Left
      }
    } else {
      if (delta.dy > 0) {
        btService.sendKey(0x01, [0x51]); // Ctrl+Down (show desktop)
      } else {
        btService.sendKey(0x01, [0x52]); // Ctrl+Up (mission control)
      }
    }
  }
}
