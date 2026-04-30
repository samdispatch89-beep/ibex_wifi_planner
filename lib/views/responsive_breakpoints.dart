import 'package:flutter/material.dart';

enum DeviceType { mobile, tablet, desktop }

class ResponsiveBreakpoints {
  static const double mobileMaxWidth = 600;
  static const double tabletMaxWidth = 1024;

  static DeviceType fromWidth(double width) {
    if (width < mobileMaxWidth) {
      return DeviceType.mobile;
    }
    if (width <= tabletMaxWidth) {
      return DeviceType.tablet;
    }
    return DeviceType.desktop;
  }

  static bool isMobile(BuildContext context) {
    return fromWidth(MediaQuery.sizeOf(context).width) == DeviceType.mobile;
  }

  static bool isTablet(BuildContext context) {
    return fromWidth(MediaQuery.sizeOf(context).width) == DeviceType.tablet;
  }

  static bool isDesktop(BuildContext context) {
    return fromWidth(MediaQuery.sizeOf(context).width) == DeviceType.desktop;
  }

  static double contentPadding(BuildContext context) {
    switch (fromWidth(MediaQuery.sizeOf(context).width)) {
      case DeviceType.mobile:
        return 10;
      case DeviceType.tablet:
        return 16;
      case DeviceType.desktop:
        return 24;
    }
  }

  static double panelPadding(BuildContext context) {
    switch (fromWidth(MediaQuery.sizeOf(context).width)) {
      case DeviceType.mobile:
        return 14;
      case DeviceType.tablet:
        return 18;
      case DeviceType.desktop:
        return 20;
    }
  }

  static double sectionSpacing(BuildContext context) {
    switch (fromWidth(MediaQuery.sizeOf(context).width)) {
      case DeviceType.mobile:
        return 10;
      case DeviceType.tablet:
        return 16;
      case DeviceType.desktop:
        return 18;
    }
  }
}
