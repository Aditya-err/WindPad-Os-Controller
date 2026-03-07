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
  
  // Settings constants
  static const int kTapMaxMs = 220;
  static const double kTapMaxDist = 12.0;
  static const double kPinchThreshold = 14.0;
  static const double kSwipeThreshold = 10.0;

  DateTime? _touchStartTime;
  Offset? _touchStartPos;
  int _fingerCount = 0;
  double? _initialPinchDist;

  WindpadGestureDetector(this.btService);

  bool _isDragging = false;
  DateTime? _lastTapTime;

  void handlePointerDown(PointerDownEvent event) {
    _fingerCount++;
    if (_fingerCount == 1) {
      _touchStartTime = DateTime.now();
      _touchStartPos = event.position;
    } else if (_fingerCount == 2) {
      // Potentially starting pinch/scroll, but let's wait for movement
    }
  }

  void handlePointerMove(PointerMoveEvent event) {
    if (_touchStartPos == null) return;

    final delta = event.localDelta;

    if (_fingerCount == 1) {
      final scaledDx = delta.dx * btService.movementScale * 2.5;
      final scaledDy = delta.dy * btService.movementScale * 2.5;

      // Check for drag priming (Double-Tap-To-Drag)
      if (!_isDragging && _lastTapTime != null && _touchStartTime != null) {
        if (DateTime.now().difference(_lastTapTime!).inMilliseconds < 450) {
          final travelDist = (event.position - _touchStartPos!).distance;
          if (travelDist > 8.0) { // Require definitive movement to lock drag
            _isDragging = true;
            btService.sendMouseButtonDown(1);
          }
        } else {
          _lastTapTime = null; // Expired
        }
      }

      btService.sendMouseMove(scaledDx.toInt(), scaledDy.toInt());
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
          btService.sendScroll(-scrollY);
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

      // Increase tap leniency distance 12 -> 24 pixels so slight shakes don't ruin a tap
      if (duration < kTapMaxMs && totalDist < 24.0) {
        if (_fingerCount == 1) {
          btService.sendMouseClick(1); // Left Click
          btService.setActiveGesture("singleTap");
          _lastTapTime = DateTime.now(); // Prime for potential drag/double tap
        } else if (_fingerCount == 2) {
          btService.sendMouseClick(2); // Right Click
          btService.setActiveGesture("twoTap");
          _lastTapTime = null;
        } else if (_fingerCount == 3) {
          btService.sendMouseClick(3); // Middle Click (optional, usually 3 or 4 mask)
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
    }
  }

  void _handlePinch(bool zoomIn) {
    // Zoom in: Ctrl + Scroll Up, Zoom out: Ctrl + Scroll Down
    // HID modifier for Ctrl is 0x01
    // But most OSes use Ctrl+Wheel. We can send Ctrl key + Scroll report.
    btService.sendKey(0x01, []); // Ctrl down (empty keys just modifier)
    btService.sendScroll(zoomIn ? 1 : -1);
  }

  void _handleThreeFingerSwipe(Offset delta) {
    if (delta.dx.abs() > delta.dy.abs()) {
      if (delta.dx > 0) {
        // Right swipe: Next Space
        // macOS: Ctrl+Right (modifier 0x01, key 0x4F)
        btService.sendKey(0x01, [0x4F]);
      } else {
        // Left swipe: Prev Space
        // macOS: Ctrl+Left (modifier 0x01, key 0x50)
        btService.sendKey(0x01, [0x50]);
      }
    } else {
      if (delta.dy > 0) {
        // Down swipe: Show Desktop / Exposé
        // macOS: Ctrl+Down (modifier 0x01, key 0x51)
        btService.sendKey(0x01, [0x51]);
      } else {
        // Up swipe: Mission Control
        // macOS: Ctrl+Up (modifier 0x01, key 0x52)
        btService.sendKey(0x01, [0x52]);
      }
    }
  }
}
