import 'dart:ui';

import 'package:entitas_ff/entitas_ff.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:notebulk/ecs/components.dart';
import 'package:notebulk/theme.dart';
import 'package:notebulk/util.dart';

Widget buildNotesGridView(
    List<ObservableEntity> notes, Widget Function(Entity) buildNoteCard,
    [int gridCount = 2]) {
  return StaggeredGridView.countBuilder(
    shrinkWrap: true,
    physics: NeverScrollableScrollPhysics(),
    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    crossAxisCount: gridCount,
    itemCount: notes.length,
    mainAxisSpacing: 4,
    crossAxisSpacing: 4,
    itemBuilder: (context, index) => buildNoteCard(notes[index]),
    staggeredTileBuilder: (index) => StaggeredTile.fit(1),
  );
}

Widget buildNotesSliverGridView(
    List<ObservableEntity> notes, Widget Function(Entity) buildNoteCard,
    [int count = 2]) {
  assert(count > 0, 'GridView must have a cross axis count greater than zero');
  return SliverPadding(
    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    sliver: SliverStaggeredGrid.countBuilder(
      crossAxisCount: count,
      itemCount: notes.length,
      mainAxisSpacing: 4,
      crossAxisSpacing: 4,
      itemBuilder: (context, index) => buildNoteCard(notes[index]),
      staggeredTileBuilder: (index) => StaggeredTile.fit(1),
    ),
  );
}

/*
Widget buildNotesListView(
    List<ObservableEntity> notes, Widget Function(Entity) buildNoteCard) {
  return ListView.builder(
    shrinkWrap: true,
    itemCount: notes.length,
    itemBuilder: (context, index) => buildNoteCard(notes[index]),
  );
}
*/

class TabBar extends StatelessWidget {
  const TabBar({
    @required this.onTap,
    @required this.items,
    Key key,
    this.appTheme,
    this.index = 0,
    this.prevIndex = 0,
    this.scaleIcon,
    this.colorIcon,
  }) : super(key: key);

  final Function(int) onTap;
  final List<TabItem> items;
  final int index, prevIndex;
  final Animation<double> scaleIcon;
  final Animation<Color> colorIcon;
  final BaseTheme appTheme;

  @override
  Widget build(BuildContext context) {
    final tabWidth = MediaQuery.of(context).size.width / items.length - 2;
    final tabHeight = kTextTabBarHeight * 0.75;

    return Container(
      decoration: BoxDecoration(color: appTheme.appBarColor),
      height: kTextTabBarHeight,
      alignment: Alignment.center,
      padding: const EdgeInsets.only(top: 4),
      width: MediaQuery.of(context).size.width,
      child: Stack(
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              for (int i = 0; i < items.length; i++)
                InkWell(
                  onTap: () => onTap(i),
                  child: Column(
                    children: <Widget>[
                      Container(
                        height: tabHeight,
                        width: tabWidth,
                        alignment: Alignment.center,
                        child: Text(
                          items[i].label,
                          textAlign: TextAlign.center,
                          style: appTheme.biggerBodyTextStyle.copyWith(
                            color: index == i
                                ? colorIcon.value
                                : appTheme.otherTabItemColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          Positioned(
            left: 4.0 +
                (lerpDouble(
                    tabWidth * prevIndex, tabWidth * index, scaleIcon.value)),
            bottom: 0,
            child: Container(
              height: 2,
              color: appTheme.selectedTabItemColor,
              width: tabWidth,
            ),
          )
        ],
      ),
    );
  }
}

class TabItem {
  const TabItem({this.label});

  final String label;
}

class StatusBar extends StatelessWidget {
  final List<Widget> Function(int) actions;

  const StatusBar({Key key, this.actions}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final entityManager = EntityManagerProvider.of(context).entityManager;
    final appTheme =
        entityManager.getUniqueEntity<AppSettingsTag>().get<AppTheme>().value;
    final localization =
        entityManager.getUniqueEntity<AppSettingsTag>().get<Localization>();

    return AnimatableEntityObservingWidget.extended(
      provider: (em) => em.getUniqueEntity<StatusBarTag>(),
      startAnimating: false,
      curve: Curves.fastOutSlowIn,
      duration: Duration(milliseconds: 200),
      tweens: {
        'size': Tween<double>(begin: 0, end: kBottomNavigationBarHeight)
      },
      animateAdded: (c) =>
          c is Toggle ? EntityAnimation.forward : EntityAnimation.none,
      animateRemoved: (c) =>
          c is Toggle ? EntityAnimation.reverse : EntityAnimation.none,
      animateUpdated: (_, __) => EntityAnimation.none,
      builder: (statusEntity, animations, context) {
        return Stack(
          children: <Widget>[
            SizedBox(
              height: kBottomNavigationBarHeight * animations['size'].value,
              width: MediaQuery.of(context).size.width,
            ),
            Positioned(
              bottom: 0,
              child: EntityObservingWidget(
                provider: (em) => em.getUniqueEntity<PageIndex>(),
                builder: (e, _) => Container(
                  color: appTheme.appBarColor,
                  width: MediaQuery.of(context).size.width,
                  height: animations['size'].value,
                  child: statusEntity.hasT<Toggle>()
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            if (statusEntity.hasT<Contents>())
                              Text(
                                statusEntity.get<Contents>().value,
                                style: appTheme.biggerBodyTextStyle,
                              ),
                            if (statusEntity.hasT<WaitForUser>()) ...[
                              FlatButton(
                                child: Text(localization.hideActionLabel),
                                onPressed: () {
                                  statusEntity
                                    ..remove<Toggle>()
                                    ..remove<WaitForUser>();
                                },
                              )
                            ] else
                              ...actions?.call(e.get<PageIndex>().value),
                          ],
                        )
                      : SizedBox(
                          width: 0,
                          height: 0,
                        ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class ShouldLeavePromptDialog extends StatelessWidget {
  final String message, yesLabel, noLabel;
  final VoidCallback onYes, onNo;
  final BaseTheme appTheme;

  const ShouldLeavePromptDialog({
    @required this.message,
    @required this.onYes,
    @required this.onNo,
    this.appTheme,
    this.yesLabel,
    this.noLabel,
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appTheme = this.appTheme ?? LightTheme();
    return AlertDialog(
      title: Text(
        message,
        style: appTheme.titleTextStyle,
      ),
      actions: <Widget>[
        FlatButton(
          splashColor: appTheme.accentColor,
          child: Text(
            noLabel,
            style: appTheme.actionableLabelStyle,
          ),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        FlatButton(
          splashColor: appTheme.accentColor,
          child: Text(
            yesLabel,
            style: appTheme.actionableLabelStyle
                .copyWith(color: appTheme.primaryButtonColor, fontSize: 16),
          ),
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    );
  }
}

class GradientBackground extends StatelessWidget {
  const GradientBackground({Key key, this.child, this.appTheme})
      : super(key: key);

  final BaseTheme appTheme;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
        decoration: BoxDecoration(gradient: appTheme.backgroundGradient),
        child: child);
  }
}

/* class ClippableShadowPainter extends CustomPainter {
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
} */
