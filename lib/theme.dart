import 'package:flutter/material.dart';
export 'icons.dart';

mixin _FontWeight {
  static FontWeight normal = FontWeight.w400;
  static FontWeight medium = FontWeight.w500;
  static FontWeight bold = FontWeight.w700;
}

abstract class BaseTheme {
  Brightness get brightness;
  Color get primaryColor;
  Color get accentColor;
  Color get appTitleColor;
  Color get appBarColor;
  Color get selectedTabItemColor;
  Color get otherTabItemColor;
  Color get settingsContainerColor;
  Color get settingsLabelContainerColor;
  Color get primaryButtonColor;
  Color get secondaryButtonColor;
  Color get tertiaryButtonColor;
  Color get buttonIconColor;
  Color get buttonLabelColor;
  List<Color> reminderPriorityColors = [
    Colors.blue,
    Colors.green,
    Colors.yellow,
    Colors.orange,
    Colors.red,
    Colors.black
  ];
  LinearGradient get backgroundGradient;
  Color get textFieldFillColor;

  static Color grey = Colors.grey;
  static Color lightGrey = Colors.grey.shade600;
  static Color darkGrey = Colors.grey.shade400;
  static Color darkestGrey = Color.fromRGBO(15, 15, 15, 1.0);

  TextStyle get baseStyle;

  TextStyle get appTitleTextStyle => TextStyle(
      color: appTitleColor,
      fontSize: 24,
      fontFamily: 'PalanquinDark',
      fontWeight: _FontWeight.bold);

  TextStyle get bodyTextStyle =>
      baseStyle.copyWith(fontSize: 12, fontWeight: _FontWeight.normal);

  TextStyle get biggerBodyTextStyle =>
      baseStyle.copyWith(fontSize: 14, fontWeight: _FontWeight.medium);

  TextStyle get titleTextStyle =>
      baseStyle.copyWith(fontSize: 16, fontWeight: _FontWeight.bold);

  TextStyle get subtitleTextStyle => baseStyle.copyWith(
      fontSize: 14, color: lightGrey, fontWeight: _FontWeight.medium);

  TextStyle get cardWidgetContentsTyle => bodyTextStyle;

  TextStyle get cardWidgetTodoItemStyle => bodyTextStyle;

  TextStyle get cardWidgetTagStyle => bodyTextStyle.copyWith(
      fontWeight: _FontWeight.medium, color: primaryButtonColor);

  TextStyle get cardWidgetTimestampStyle => bodyTextStyle.copyWith(
      color: brightness == Brightness.light ? lightGrey : darkGrey,
      fontWeight: _FontWeight.bold);

  TextStyle get formLabelStyle => biggerBodyTextStyle.copyWith(
        color: darkGrey,
      );

  TextStyle get actionableLabelStyle => subtitleTextStyle.copyWith(
      fontWeight: _FontWeight.bold, color: baseStyle.color);
}

class LightTheme extends BaseTheme {
  @override
  // TODO: implement primaryColor
  Color get primaryColor => Color(0xFFF6D365);
  @override
  // TODO: implement accentColor
  Color get accentColor => Color(0xFFC83660);
  @override
  // TODO: implement brightness
  Brightness get brightness => Brightness.light;
  @override
  Color get appBarColor => Colors.white;
  @override
  Color get appTitleColor => Colors.black;

  @override
  // TODO: implement backgroundGradient
  LinearGradient get backgroundGradient => LinearGradient(
        colors: [Colors.white, primaryColor],
        begin: Alignment(0, -0.4),
        end: Alignment.bottomCenter,
      );

  @override
  // TODO: implement buttonIconColor
  Color get buttonIconColor => Colors.white;

  @override
  // TODO: implement buttonLabelColor
  Color get buttonLabelColor => Colors.white;

  @override
  // TODO: implement otherTabItemColor
  Color get otherTabItemColor => BaseTheme.lightGrey;

  @override
  // TODO: implement primaryButtonColor
  Color get primaryButtonColor => accentColor;

  @override
  // TODO: implement secondaryButtonColor
  Color get secondaryButtonColor => BaseTheme.darkGrey;

  @override
  // TODO: implement selectedTabItemColor
  Color get selectedTabItemColor => accentColor;

  @override
  // TODO: implement settingsContainerColor
  Color get settingsContainerColor => Colors.white;

  @override
  // TODO: implement settingsLabelContainerColor
  Color get settingsLabelContainerColor => Colors.blue;

  @override
  // TODO: implement tertiaryButtonColor
  Color get tertiaryButtonColor => Colors.black;

  @override
  // TODO: implement textFieldFillColor
  Color get textFieldFillColor => BaseTheme.lightGrey;

  @override
  // TODO: implement formLabelStyle
  TextStyle get formLabelStyle =>
      super.formLabelStyle.copyWith(color: baseStyle.color.withOpacity(0.75));

  @override
  // TODO: implement baseStyle
  TextStyle get baseStyle =>
      TextStyle(fontFamily: 'Palanquin', color: Colors.black, height: 1.2);
}

class DarkTheme extends BaseTheme {
  @override
  // TODO: implement primaryColor
  Color get primaryColor => Color(0xFFC83660);
  @override
  // TODO: implement accentColor
  Color get accentColor => Color(0xFFF6D365);
  @override
  // TODO: implement brightness
  Brightness get brightness => Brightness.dark;
  @override
  Color get appBarColor => BaseTheme.darkestGrey;
  @override
  Color get appTitleColor => Colors.white;

  @override
  // TODO: implement backgroundGradient
  LinearGradient get backgroundGradient => LinearGradient(
        colors: [BaseTheme.darkestGrey, primaryColor],
        begin: Alignment(0, -0.4),
        end: Alignment.bottomCenter,
      );

  @override
  // TODO: implement buttonIconColor
  Color get buttonIconColor => Colors.black;

  @override
  // TODO: implement buttonLabelColor
  Color get buttonLabelColor => Colors.black;

  @override
  // TODO: implement otherTabItemColor
  Color get otherTabItemColor => BaseTheme.darkGrey;

  @override
  // TODO: implement primaryButtonColor
  Color get primaryButtonColor => accentColor;

  @override
  // TODO: implement secondaryButtonColor
  Color get secondaryButtonColor => BaseTheme.darkGrey;

  @override
  // TODO: implement selectedTabItemColor
  Color get selectedTabItemColor => primaryColor;

  @override
  // TODO: implement settingsContainerColor
  Color get settingsContainerColor => BaseTheme.darkestGrey;

  @override
  // TODO: implement settingsLabelContainerColor
  Color get settingsLabelContainerColor => primaryColor;

  @override
  // TODO: implement tertiaryButtonColor
  Color get tertiaryButtonColor => Colors.white;

  @override
  // TODO: implement textFieldFillColor
  Color get textFieldFillColor => BaseTheme.lightGrey;

  @override
  // TODO: implement baseStyle
  TextStyle get baseStyle =>
      TextStyle(fontFamily: 'Palanquin', color: Colors.white, height: 1.2);

  @override
  TextStyle get subtitleTextStyle =>
      super.subtitleTextStyle.copyWith(color: BaseTheme.darkGrey);
}

class BlankTheme extends DarkTheme {
  @override
  // TODO: implement backgroundGradient
  LinearGradient get backgroundGradient =>
      LinearGradient(colors: [Colors.black, Colors.black]);
}
