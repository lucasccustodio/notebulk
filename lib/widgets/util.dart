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

Widget buildAnimatedNotesSliverGridView(
    List<ObservableEntity> notes, Widget Function(Entity) buildNoteCard,
    [String emptyMessage, List<ListItem> items = const [], List<String> tags]) {
  return SliverPadding(
    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    sliver: SliverStaggeredGrid.countBuilder(
      crossAxisCount: 2,
      itemCount: notes.length,
      mainAxisSpacing: 4,
      crossAxisSpacing: 4,
      itemBuilder: (context, index) => buildNoteCard(notes[index]),
      staggeredTileBuilder: (index) => StaggeredTile.fit(1),
    ),
  );
}

Widget buildNotesListView(
    List<ObservableEntity> notes, Widget Function(Entity) buildNoteCard) {
  return ListView.builder(
    shrinkWrap: true,
    itemCount: notes.length,
    itemBuilder: (context, index) => buildNoteCard(notes[index]),
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

class PushRoute extends PageRouteBuilder {
  PushRoute({this.page})
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
              SlideTransition(
            position: Tween<Offset>(begin: Offset(0, 1), end: Offset(0, 0))
                .animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeInOut,
                    reverseCurve: Curves.fastOutSlowIn)),
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
  const BottomNavigation({
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
                        //color: Colors.white,
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
  const TabItem({this.icon, this.label});

  final IconData icon;
  final String label;
}

class StatusBarContainer extends StatelessWidget {
  final List<Widget> Function(int) actions;
  final Widget fab;

  const StatusBarContainer({Key key, this.actions, this.fab}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final entityManager = EntityManagerProvider.of(context).entityManager;
    final appTheme =
        entityManager.getUniqueEntity<AppSettingsTag>().get<AppTheme>().value;
    final localization =
        entityManager.getUniqueEntity<AppSettingsTag>().get<Localization>();

    return AnimatableEntityObservingWidget(
      provider: (em) => em.getUniqueEntity<DisplayStatusTag>(),
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
            if (fab != null)
              Positioned(
                  bottom: 8 + animations['size'].value, right: 8, child: fab),
            SizedBox(
              height: kBottomNavigationBarHeight + (fab != null ? 64 : 0),
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

class RichTextController extends TextEditingController {
  @override
  TextSpan buildTextSpan({TextStyle style, bool withComposing}) {
    if (!value.composing.isValid || !withComposing) {
      return TextSpan(style: style, text: text);
    }
    final composingStyle = style.merge(
      const TextStyle(decoration: TextDecoration.underline),
    );
    return TextSpan(style: style, children: <TextSpan>[
      TextSpan(text: value.composing.textBefore(value.text)),
      TextSpan(
        style: composingStyle,
        text: value.composing.textInside(value.text),
      ),
      TextSpan(text: value.composing.textAfter(value.text)),
    ]);
  }
}

//Nice gradient background that helps stylize the app.
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
