import 'dart:ui';

import 'package:entitas_ff/entitas_ff.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:notebulk/ecs/components.dart';
import 'package:notebulk/widgets/cards.dart';
import 'package:tinycolor/tinycolor.dart';

Widget buildEmptyNote(String message, [List<ListItem> items = const []]) {
  return InfoCardWidget(
    message: message,
    tags: const ['Dicas', 'Ajuda', 'Informativo'],
    listItems: items,
  );
}

Widget buildNotesGridView(
    List<Entity> notes, Widget Function(Entity) buildNoteCard,
    [String emptyMessage, List<ListItem> items = const []]) {
  return StaggeredGridView.countBuilder(
    crossAxisCount: 2,
    itemCount: notes.isEmpty ? 1 : notes.length,
    mainAxisSpacing: 4,
    crossAxisSpacing: 4,
    itemBuilder: (context, index) => notes.isEmpty
        ? buildEmptyNote(emptyMessage, items)
        : buildNoteCard(notes[index]),
    staggeredTileBuilder: (index) => StaggeredTile.fit(1),
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
      {Key key,
      this.onTap,
      this.items,
      this.index = 0,
      this.scaleIcon,
      this.colorIcon})
      : super(key: key);

  final Function(int) onTap;
  final List<TabItem> items;
  final int index;
  final Animation<double> scaleIcon;
  final Animation<Color> colorIcon;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.transparent, boxShadow: const [
        //BoxShadow(color: Colors.black45, spreadRadius: 2, blurRadius: 8)
      ]),
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
                    child: Container(
                      padding: EdgeInsets.all(16),
                      child: Icon(
                        items[i].icon,
                        color: index == i ? colorIcon.value : Colors.grey,
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
  const FABMenu(
      {Key key,
      this.toggleButtonColor,
      this.animateIcon,
      this.onPressed,
      this.onToggle})
      : super(key: key);

  final Animation<Color> toggleButtonColor;
  final Animation<double> animateIcon;
  final double _fabHeight = 56.0;
  final Function(int) onPressed;
  final VoidCallback onToggle;

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
    final icons = [Icons.note, Icons.list, Icons.camera];
    final iconColor = TinyColor(Theme.of(context).accentColor).isDark()
        ? Colors.white
        : Colors.black;
    return Stack(
      children: <Widget>[
        SizedBox(
          height: _fabHeight * 5,
          width: _fabHeight,
        ),
        for (int i = 0; i < 3; i++)
          Positioned(
              bottom:
                  (i * (_fabHeight + 8) + (_fabHeight + 8)) * animateIcon.value,
              child: FloatingActionButton(
                heroTag: 'FAB$i',
                child: Icon(icons[2 - i], color: iconColor),
                elevation: 8 * animateIcon.value,
                onPressed: () => onPressed(2 - i),
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
