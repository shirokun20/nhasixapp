import 'package:flutter/material.dart';
import 'package:nhasixapp/core/constants/colors_const.dart';

class TextStyleConst {
  static TextStyle styleLight({
    Color textColor = ColorsConst.primaryTextColor,
    double size = 14,
  }) {
    return TextStyle(
      fontSize: size,
      color: textColor,
      fontWeight: FontWeight.w300,
    );
  }

  static TextStyle styleRegular({
    Color textColor = ColorsConst.primaryTextColor,
    double size = 14,
  }) {
    return TextStyle(
      fontSize: size,
      color: textColor,
      fontWeight: FontWeight.normal,
    );
  }

  static TextStyle styleMedium({
    Color textColor = ColorsConst.primaryTextColor,
    double size = 14,
  }) {
    return TextStyle(
      fontSize: size,
      color: textColor,
      fontWeight: FontWeight.w500,
    );
  }

  static TextStyle styleSemiBold({
    Color textColor = ColorsConst.primaryTextColor,
    double size = 14,
  }) {
    return TextStyle(
      fontSize: size,
      color: textColor,
      fontWeight: FontWeight.w600,
    );
  }

  static TextStyle styleBold({
    Color textColor = ColorsConst.primaryTextColor,
    double size = 14,
  }) {
    return TextStyle(
      fontSize: size,
      color: textColor,
      fontWeight: FontWeight.w700,
    );
  }

  static TextStyle styleExtraBold({
    Color textColor = ColorsConst.primaryTextColor,
    double size = 14,
  }) {
    return TextStyle(
      fontSize: size,
      color: textColor,
      fontWeight: FontWeight.w800,
    );
  }
}
