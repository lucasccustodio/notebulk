import 'dart:ui';

import 'package:entitas_ff/entitas_ff.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:notebulk/ecs/components.dart';
import 'package:notebulk/widgets/cards.dart';
import 'package:tinycolor/tinycolor.dart';

Widget buildEmptyNote(String message,
    [List<ListItem> items = const [], List<String> tags = const []]) {
  return InfoCardWidget(
    message: message,
    tags: tags,
    listItems: items,
  );
}

Widget buildNotesGridView(
    List<Entity> notes, Widget Function(Entity) buildNoteCard,
    [String emptyMessage, List<ListItem> items = const [], List<String> tags]) {
  return StaggeredGridView.countBuilder(
    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    crossAxisCount: 2,
    itemCount: notes.isEmpty ? 1 : notes.length,
    mainAxisSpacing: 4,
    crossAxisSpacing: 4,
    itemBuilder: (context, index) => notes.isEmpty
        ? buildEmptyNote(emptyMessage, items, tags)
        : buildNoteCard(notes[index]),
    staggeredTileBuilder: (index) => StaggeredTile.fit(1),
  );
}

Widget buildNotesSliverGridView(
    List<Entity> notes, Widget Function(Entity) buildNoteCard,
    [String emptyMessage, List<ListItem> items = const [], List<String> tags]) {
  return SliverPadding(
    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    sliver: SliverStaggeredGrid.countBuilder(
      crossAxisCount: 2,
      itemCount: notes.isEmpty ? 1 : notes.length,
      mainAxisSpacing: 4,
      crossAxisSpacing: 4,
      itemBuilder: (context, index) => notes.isEmpty
          ? buildEmptyNote(emptyMessage, items, tags)
          : buildNoteCard(notes[index]),
      staggeredTileBuilder: (index) => StaggeredTile.fit(1),
    ),
  );
}

Widget buildNotesListView(
    List<Entity> notes, Widget Function(Entity) buildNoteCard,
    [String emptyMessage, List<ListItem> items = const []]) {
  return ListView.builder(
    shrinkWrap: true,
    itemCount: notes.isEmpty ? 1 : notes.length,
    itemBuilder: (context, index) => notes.isEmpty
        ? buildEmptyNote(emptyMessage, items)
        : buildNoteCard(notes[index]),
  );
}

class FadeRoute extends PageRouteBuilder {
  FadeRoute({this.page})
      : super(
          pageBuilder: (
            context,
            animation,
            secondaryAnimation,
          ) =>
              page,
          transitionsBuilder: (
            context,
            animation,
            secondaryAnimation,
            child,
          ) =>
              FadeTransition(
            opacity: animation,
            child: child,
          ),
        );

  final Widget page;
}

class GradientLineSeparator extends StatelessWidget {
  const GradientLineSeparator({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Container(
          width: double.maxFinite,
          height: 1,
          decoration: BoxDecoration(
            gradient: RadialGradient(
                colors: [Theme.of(context).primaryColor, Colors.black],
                radius: 200.0),
          )),
    );
  }
}

class BottomNavigation extends StatelessWidget {
  const BottomNavigation(
      {@required this.onTap,
      @required this.items,
      Key key,
      this.index = 0,
      this.scaleIcon,
      this.colorIcon,
      this.containerColor = Colors.transparent})
      : super(key: key);

  final Function(int) onTap;
  final List<TabItem> items;
  final int index;
  final Animation<double> scaleIcon;
  final Animation<Color> colorIcon;
  final Color containerColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: containerColor),
      height: kBottomNavigationBarHeight,
      width: MediaQuery.of(context).size.width,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              for (int i = 0; i < items.length; i++)
                Transform.scale(
                  scale: i == index ? scaleIcon.value : 1.0,
                  alignment: Alignment.center,
                  child: GestureDetector(
                    onTap: () => onTap(i),
                    behavior: HitTestBehavior.opaque,
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width /
                          items.length *
                          0.75,
                      child: Icon(
                        items[i].icon,
                        color: index == i
                            ? colorIcon.value
                            : Theme.of(context).accentColor,
                      ),
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
  const TabItem({this.icon, this.label});

  final IconData icon;
  final String label;
}

//Nice gradient background that helps stylize the app.
class GradientBackground extends StatelessWidget {
  const GradientBackground(
      {Key key,
      this.child,
      this.darkMode = true,
      this.themeColor = Colors.purple})
      : super(key: key);

  final bool darkMode;
  final Color themeColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
        decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [darkMode ? Colors.black : Colors.white, themeColor])),
        child: child);
  }
}

class FABMenu extends StatelessWidget {
  const FABMenu({
    @required this.onPressed,
    @required this.onToggle,
    @required int numButtons,
    @required List<IconData> buttonIcons,
    Key key,
    this.toggleButtonColor,
    this.animateIcon,
  })  : assert(buttonIcons.length == numButtons,
            'buttonIcons.length must be atleast equal to numButtons'),
        _numButtons = numButtons,
        _buttonIcons = buttonIcons,
        super(key: key);

  final Animation<Color> toggleButtonColor;
  final Animation<double> animateIcon;
  final double _fabHeight = 56.0;
  final Function(int) onPressed;
  final VoidCallback onToggle;
  final int _numButtons;
  final List<IconData> _buttonIcons;

  Widget toggle(BuildContext context) {
    return FloatingActionButton(
      heroTag: 'FABToggle',
      backgroundColor: toggleButtonColor.value,
      child: Transform.rotate(
          angle: 0.8 * animateIcon.value,
          child: Icon(
            Icons.add,
            size: 32,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black
                : Colors.white,
          )),
      onPressed: onToggle,
    );
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = TinyColor(Theme.of(context).accentColor).isDark()
        ? Colors.white
        : Colors.black;
    return Stack(
      children: <Widget>[
        SizedBox(
          height: _fabHeight * (_numButtons + 2),
          width: _fabHeight,
        ),
        for (int i = 0; i < _numButtons; i++)
          Positioned(
              bottom:
                  ((_fabHeight + 8) * (_numButtons - i)) * animateIcon.value,
              child: FloatingActionButton(
                heroTag: 'FAB$i',
                child: Icon(_buttonIcons[i], color: iconColor),
                elevation: animateIcon.value,
                onPressed: () => onPressed(i),
              )),
        Positioned(right: 0, bottom: 0, child: toggle(context))
      ],
    );
  }
}

class ClippableShadowPainter extends CustomPainter {
  ClippableShadowPainter({@required this.shadow, @required this.clipper});

  final Shadow shadow;
  final CustomClipper<Path> clipper;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = shadow.toPaint();
    final clipPath = clipper.getClip(size).shift(shadow.offset);
    canvas.drawPath(clipPath, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
