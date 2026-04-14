import 'package:flutter/material.dart';
import 'dart:math' as math;

class Responsive {
  static late MediaQueryData _mediaQueryData;
  static late double screenWidth;
  static late double screenHeight;
  static late double _blockSizeHorizontal;
  static late double _blockSizeVertical;
  static late double _safeBlockHorizontal;
  static late double _safeBlockVertical;

  static void init(BuildContext context) {
    _mediaQueryData = MediaQuery.of(context);
    screenWidth = _mediaQueryData.size.width;
    screenHeight = _mediaQueryData.size.height;
    _blockSizeHorizontal = screenWidth / 100;
    _blockSizeVertical = screenHeight / 100;

    double safeAreaHorizontal = _mediaQueryData.padding.left + _mediaQueryData.padding.right;
    double safeAreaVertical = _mediaQueryData.padding.top + _mediaQueryData.padding.bottom;
    _safeBlockHorizontal = (screenWidth - safeAreaHorizontal) / 100;
    _safeBlockVertical = (screenHeight - safeAreaVertical) / 100;
  }

  /// Scalable Pixels - adjusts based on screen width
  /// Reference width: 375 (iPhone X style)
  static double sp(double size) {
    return size * (screenWidth / 375);
  }

  /// Font scaling with a cap to prevent massive fonts on tablets
  static double fs(double size) {
    double scale = screenWidth / 375;
    return size * math.min(scale, 1.4);
  }

  /// Horizontal percentage
  static double wp(double percent) {
    return _blockSizeHorizontal * percent;
  }

  /// Vertical percentage
  static double hp(double percent) {
    return _blockSizeVertical * percent;
  }

  /// Constant padding that scales slightly
  static double get padding {
    return math.max(16.0, math.min(screenWidth * 0.06, 32.0));
  }
  
  static bool get isMobile => screenWidth < 600;
  static bool get isTablet => screenWidth >= 600 && screenWidth < 1024;
  static bool get isDesktop => screenWidth >= 1024;
}
