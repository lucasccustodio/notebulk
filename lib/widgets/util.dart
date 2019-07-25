import 'package:flutter/material.dart';
import 'package:tinycolor/tinycolor.dart';

class FadeRoute extends PageRouteBuilder {
  final Widget page;
  FadeRoute({this.page})
      : super(
          pageBuilder: (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
          ) =>
              page,
          transitionsBuilder: (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
            Widget child,
          ) =>
              FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
}

class GradientLineSeparator extends StatelessWidget {
  const GradientLineSeparator({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 8),
      child: Container(
        width: double.maxFinite,
        height: 1,
        decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
              Theme.of(context).brightness == Brightness.dark
                  ? Colors.black
                  : Colors.white,
              Theme.of(context).primaryColor
            ])),
      ),
    );
  }
}

class BottomNavigation extends StatelessWidget {
  final Function(int) onTap;
  final List<TabItem> items;
  final int index;
  final Animation<double> scaleIcon;
  final Animation<Color> colorIcon;

  const BottomNavigation(
      {Key key,
      this.onTap,
      this.items,
      this.index = 0,
      this.scaleIcon,
      this.colorIcon})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: kBottomNavigationBarHeight,
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          border: Border(
              top: BorderSide(
                  color: HSVColor.fromColor(Theme.of(context).cardColor)
                      .withValue(0.5)
                      .toColor()))),
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              for (int i = 0; i < items.length; i++)
                Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.diagonal3Values(
                      index == i ? scaleIcon.value : 1.0,
                      index == i ? scaleIcon.value : 1.0,
                      1.0),
                  child: GestureDetector(
                    onTap: () {
                      onTap(i);
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(
                          items[i].icon,
                          color: index == i ? colorIcon.value : Colors.grey,
                        ),
                        Text(
                          items[i].label,
                          style: Theme.of(context).textTheme.caption.copyWith(
                              color:
                                  index == i ? colorIcon.value : Colors.grey),
                        )
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class TabItem {
  final IconData icon;
  final String label;

  const TabItem({this.icon, this.label});
}

//Nice gradient background that helps stylize the app.
class GradientBackground extends StatelessWidget {
  final bool darkMode;
  final Color themeColor;
  final Widget child;

  const GradientBackground(
      {Key key,
      this.child,
      this.darkMode = true,
      this.themeColor = Colors.purple})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
        decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.2, 1.0],
                colors: [darkMode ? Colors.black : Colors.white, themeColor])),
        child: child);
  }
}

class FABMenu extends StatelessWidget {
  final Animation<Color> toggleButtonColor;
  final Animation<double> animateIcon;
  final Animation<double> translateButton;
  final double _fabHeight = 56.0;
  final Function(int) onPressed;
  final VoidCallback onToggle;

  const FABMenu(
      {Key key,
      this.toggleButtonColor,
      this.animateIcon,
      this.translateButton,
      this.onPressed,
      this.onToggle})
      : super(key: key);

  Widget addNote(BuildContext context) {
    return Container(
      child: FloatingActionButton(
        onPressed: () {
          onPressed(0);
        },
        elevation: animateIcon.value * 6,
        tooltip: 'Note',
        heroTag: 'addNoteBtn',
        backgroundColor: Theme.of(context).accentColor,
        child: Icon(
          Icons.note,
          color: TinyColor(Theme.of(context).accentColor).isDark()
              ? Colors.white
              : Colors.black,
        ),
      ),
    );
  }

  Widget addList(BuildContext context) {
    return Container(
      child: FloatingActionButton(
        onPressed: () {
          onPressed(2);
        },
        elevation: animateIcon.value * 6,
        tooltip: 'Add list',
        heroTag: 'addListBtn',
        backgroundColor: Theme.of(context).accentColor,
        child: Icon(
          Icons.list,
          color: TinyColor(Theme.of(context).accentColor).isDark()
              ? Colors.white
              : Colors.black,
        ),
      ),
    );
  }

  Widget addPhoto(BuildContext context) {
    return Container(
      child: FloatingActionButton(
        onPressed: () {
          onPressed(1);
        },
        elevation: animateIcon.value * 6,
        tooltip: 'Add list',
        heroTag: 'addPhotoBtn',
        backgroundColor: Theme.of(context).accentColor,
        child: Icon(
          Icons.camera,
          color: TinyColor(Theme.of(context).accentColor).isDark()
              ? Colors.white
              : Colors.black,
        ),
      ),
    );
  }

  Widget toggle(BuildContext context) {
    return Container(
      child: FloatingActionButton(
        backgroundColor: toggleButtonColor.value,
        onPressed: onToggle,
        tooltip: 'Toggle',
        heroTag: 'toogleBtn',
        child: animateIcon.value > 0.5
            ? FadeTransition(
                opacity: animateIcon,
                child: Icon(
                  Icons.close,
                  color: Theme.of(context).appBarTheme.color,
                ),
              )
            : Icon(
                Icons.add,
                color: Theme.of(context).appBarTheme.color,
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        SizedBox(
          height: _fabHeight * 3,
          width: _fabHeight * 4,
        ),
        Positioned(
          top: translateButton.value + _fabHeight,
          left: translateButton.value + _fabHeight / 2,
          child: addNote(context),
        ),
        Positioned(
          top: translateButton.value + _fabHeight,
          left: _fabHeight * 1.5,
          child: addPhoto(context),
        ),
        Positioned(
          top: translateButton.value + _fabHeight,
          left: -translateButton.value + _fabHeight * 2.5,
          child: addList(context),
        ),
        Positioned(
          bottom: 0,
          left: _fabHeight * 1.5,
          child: toggle(context),
        ),
      ],
    );
  }
}
