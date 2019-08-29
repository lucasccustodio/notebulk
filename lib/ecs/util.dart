import 'package:entitas_ff/entitas_ff.dart';
import 'package:flutter/material.dart';
import 'package:notebulk/ecs/components.dart';

void selectNote(Entity toSelect) {
  if (toSelect.hasT<Selected>())
    toSelect.remove<Selected>();
  else
    toSelect.set(Selected());
}

enum ListItemAnimation {
  fadeIn,
  fadeOut,
  enterLeft,
  enterRight,
  expand,
  shrink
}

class GroupObservingListBuilder extends StatefulWidget {
  const GroupObservingListBuilder(
      {@required this.matcher,
      @required this.itemBuilder,
      this.curve = Curves.bounceIn,
      this.reversed = true,
      this.duration = const Duration(milliseconds: 300),
      this.onAdded,
      this.onUpdated,
      Key key})
      : super(key: key);

  final Curve curve;
  final EntityMatcher matcher;
  final bool reversed;
  final EntityWidgetBuilder itemBuilder;
  final ListItemAnimation onAdded;
  final ListItemAnimation onUpdated;
  final Duration duration;

  @override
  _GroupObservingListBuilderState createState() =>
      _GroupObservingListBuilderState();
}

class _GroupObservingListBuilderState extends State<GroupObservingListBuilder>
    implements GroupObserver {
  EntityGroup _group;
  int _added, _updated;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _group?.removeObserver(this);
    final entityManager = EntityManagerProvider.of(context).entityManager;
    assert(entityManager != null);
    _group = entityManager.groupMatching(widget.matcher);
    _group?.addObserver(this);
  }

  @override
  void dispose() {
    _group?.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groupLength = _group?.entities?.length ?? 0;

    return ListView.builder(
      itemCount: groupLength,
      itemBuilder: (context, index) => AnimatableEntityObservingWidget(
        key: ValueKey('ListItem${_group.entities[index].creationIndex}'),
        provider: (_) => _group.entities[index],
        startAnimating: true,
        duration: widget.duration,
        curve: widget.curve,
        tweens: {'_default': Tween<double>(begin: 0.0, end: 1.0)},
        onAnimationEnd: (end) {
          if (!end) {
            _added = -1;
            _updated = -1;
            _update();
          }
        },
        builder: (itemEntity, anim, context) {
          final delta = anim['_default'].value;

          if (index == _added) {
            return _AnimatedListItem(
              builder: widget.itemBuilder,
              delta: delta,
              animation: widget.onAdded,
              entity: itemEntity,
            );
          } else if (index == _updated) {
            return _AnimatedListItem(
              builder: widget.itemBuilder,
              delta: delta,
              animation: widget.onUpdated,
              entity: itemEntity,
            );
          } else
            return widget.itemBuilder(itemEntity, context);
        },
      ),
      reverse: widget.reversed,
      shrinkWrap: true,
    );
  }

  @override
  void added(EntityGroup group, ObservableEntity entity) {
    _added = _group.entities.indexOf(entity);
    _update();
  }

  @override
  void removed(EntityGroup group, ObservableEntity entity) {}

  @override
  void updated(EntityGroup group, ObservableEntity entity) {
    _updated = _group.entities.indexOf(entity);
    _update();
  }

  void _update() {
    if (mounted) {
      setState(() {});
    }
  }
}

class GroupObservingGridBuilder extends StatefulWidget {
  const GroupObservingGridBuilder(
      {@required this.matcher,
      @required this.itemBuilder,
      @required this.delegate,
      this.reversed = true,
      this.duration = const Duration(milliseconds: 300),
      this.onAdded,
      this.onUpdated,
      Key key})
      : super(key: key);

  final EntityMatcher matcher;
  final bool reversed;
  final SliverGridDelegate delegate;
  final EntityWidgetBuilder itemBuilder;
  final ListItemAnimation onAdded;
  final ListItemAnimation onUpdated;
  final Duration duration;

  @override
  _GroupObservingGridBuilderState createState() =>
      _GroupObservingGridBuilderState();
}

class _GroupObservingGridBuilderState extends State<GroupObservingGridBuilder>
    implements GroupObserver {
  EntityGroup _group;
  int _added, _updated;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _group?.removeObserver(this);
    final entityManager = EntityManagerProvider.of(context).entityManager;
    assert(entityManager != null);
    _group = entityManager.groupMatching(widget.matcher);
    _group?.addObserver(this);
  }

  @override
  void dispose() {
    _group?.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groupLength = _group?.entities?.length ?? 0;

    return GridView.builder(
      primary: false,
      itemCount: groupLength,
      shrinkWrap: true,
      gridDelegate: widget.delegate,
      itemBuilder: (context, index) => AnimatableEntityObservingWidget(
        key: Key('GridItem${_group.entities[index].creationIndex}'),
        provider: (_) => _group.entities[index],
        startAnimating: true,
        duration: widget.duration,
        tweens: {'_default': Tween<double>(begin: 0.0, end: 1.0)},
        onAnimationEnd: (end) {
          if (!end) {
            _updated = -1;
          }
        },
        builder: (itemEntity, anim, context) {
          final delta = anim['_default'].value;

          if (index == _added) {
            return _AnimatedListItem(
              builder: widget.itemBuilder,
              delta: delta,
              animation: widget.onAdded,
              entity: itemEntity,
            );
          } else if (index == _updated) {
            return _AnimatedListItem(
              builder: widget.itemBuilder,
              delta: delta,
              animation: widget.onUpdated,
              entity: itemEntity,
            );
          } else
            return widget.itemBuilder(itemEntity, context);
        },
      ),
    );
  }

  @override
  void added(EntityGroup group, ObservableEntity entity) {
    _added = group.entities.indexOf(entity);
    _update();
  }

  @override
  void removed(EntityGroup group, ObservableEntity entity) {
    _update();
  }

  @override
  void updated(EntityGroup group, ObservableEntity entity) {
    _updated = group.entities.indexOf(entity);
    _update();
  }

  void _update() {
    if (mounted) {
      setState(() {});
    }
  }
}

class _AnimatedListItem extends StatelessWidget {
  const _AnimatedListItem({
    @required this.entity,
    @required this.animation,
    @required this.builder,
    @required this.delta,
    Key key,
  }) : super(key: key);

  final EntityWidgetBuilder builder;
  final ListItemAnimation animation;
  final double delta;
  final Entity entity;

  @override
  Widget build(BuildContext context) {
    var itemWidget = builder(entity, context);

    switch (animation) {
      case ListItemAnimation.fadeIn:
        itemWidget = Opacity(
          opacity: delta,
          child: itemWidget,
        );
        break;
      case ListItemAnimation.fadeOut:
        itemWidget = Opacity(
          opacity: 1.0 - delta,
          child: itemWidget,
        );
        break;
      case ListItemAnimation.expand:
        itemWidget = ClipRect(
          child: Align(
            child: itemWidget,
            widthFactor: delta,
            heightFactor: delta,
          ),
        );
        break;
      case ListItemAnimation.shrink:
        itemWidget = ClipRect(
          child: Align(
            child: itemWidget,
            widthFactor: 1.0 - delta,
            heightFactor: 1.0 - delta,
          ),
        );
        break;
      case ListItemAnimation.enterLeft:
        itemWidget = FractionalTranslation(
          child: itemWidget,
          translation: Offset(-1.0 + delta, 0),
          transformHitTests: true,
        );
        break;
      case ListItemAnimation.enterRight:
        itemWidget = FractionalTranslation(
          child: itemWidget,
          translation: Offset(1.0 + delta, 0),
          transformHitTests: true,
        );
        break;
      default:
    }

    return itemWidget;
  }
}
