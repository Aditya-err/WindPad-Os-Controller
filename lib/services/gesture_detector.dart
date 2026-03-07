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

  static const int kTapMaxMs = 200;
  static const double kTapMaxDist = 10.0;
  static const double kPinchThreshold = 14.0;
  static const double kSwipeThreshold = 10.0;

  DateTime? _touchStartTime;
  Offset? _touchStartPos;
  int _fingerCount = 0;
  double? _initialPinchDist;

  // Smooth cursor — low-pass filter state
  double _smoothX = 0.0;
  double _smoothY = 0.0;

  WindpadGestureDetector(this.btService);

  bool _isDragging = false;
  DateTime? _lastTapTime;

  void handlePointerDown(PointerDownEvent event) {
    _fingerCount++;
    if (_fingerCount == 1) {
      _touchStartTime = DateTime.now();
      _touchStartPos = event.position;
      _smoothX = 0.0;
      _smoothY = 0.0;
    }
  }

  void handlePointerMove(PointerMoveEvent event) {
    if (_touchStartPos == null) return;
    if (btService.trackpadLocked) return;

    final delta = event.localDelta;

    if (_fingerCount == 1) {
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
    } else if (_fingerCount == 2) {
      if (_initialPinchDist == null) {
        _initialPinchDist = (event.position - _touchStartPos!).distance;
      } else {
        final currentDist = (event.position - _touchStartPos!).distance;
        final distDelta = currentDist - _initialPinchDist!;

        if (distDelta.abs() > kPinchThreshold) {
          final zoomIn = distDelta > 0;
          _handlePinch(zoomIn);
          _initialPinchDist = currentDist;
          btService.setActiveGesture("pinch");
          btService.setPinchPop(zoomIn ? "🔍 Zoom In" : "🔎 Zoom Out");
        } else {
          final scrollY = delta.dy.toInt();
          final scrollX = delta.dx.toInt();
          if (scrollY.abs() >= scrollX.abs()) {
            btService.sendScroll(-scrollY);
          }
          btService.setActiveGesture("scroll");
        }
      }
    } else if (_fingerCount >= 3) {
      if (delta.dx.abs() > kSwipeThreshold || delta.dy.abs() > kSwipeThreshold) {
        _handleThreeFingerSwipe(delta);
        btService.setActiveGesture("threeSwipe");
      }
    }
  }

  void handlePointerUp(PointerUpEvent event) {
    if (_isDragging) {
      btService.sendMouseButtonUp();
      _isDragging = false;
      _lastTapTime = null;
    } else if (_touchStartTime != null && _touchStartPos != null) {
      final duration = DateTime.now().difference(_touchStartTime!).inMilliseconds;
      final totalDist = (event.position - _touchStartPos!).distance;

      if (duration < kTapMaxMs && totalDist < 24.0) {
        if (_fingerCount == 1) {
          btService.sendMouseClick(1);
          btService.setActiveGesture("singleTap");
          _lastTapTime = DateTime.now();
        } else if (_fingerCount == 2) {
          btService.sendMouseClick(2);
          btService.setActiveGesture("twoTap");
          _lastTapTime = null;
        } else if (_fingerCount == 3) {
          btService.sendMouseClick(4); // Middle click
          _lastTapTime = null;
        }
        Future.delayed(const Duration(milliseconds: 700), () {
          btService.setActiveGesture(null);
        });
      }
    }

    _fingerCount--;
    if (_fingerCount <= 0) {
      _fingerCount = 0;
      _touchStartTime = null;
      _touchStartPos = null;
      _initialPinchDist = null;
      _isDragging = false;
      _smoothX = 0.0;
      _smoothY = 0.0;
    }
  }

  void handlePointerCancel(PointerCancelEvent event) {
    if (_isDragging) {
      btService.sendMouseButtonUp();
      _isDragging = false;
    }
    _fingerCount--;
    if (_fingerCount <= 0) {
      _fingerCount = 0;
      _touchStartTime = null;
      _touchStartPos = null;
      _initialPinchDist = null;
      _isDragging = false;
      _smoothX = 0.0;
      _smoothY = 0.0;
    }
  }

  void _handlePinch(bool zoomIn) {
    btService.sendKey(0x01, []);
    btService.sendScroll(zoomIn ? 1 : -1);
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
