import 'package:app/app.dart';
import 'package:app/blocs/router.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:stated/stated.dart';

class ProfilePage with AppPage, AppPageView {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Profile')),
      body: ListView(
        children: [
          SizedBox(height: 24),
          ProfilePictureTile(),
          SizedBox(height: 24),
        ],
      ),
    );
  }
}

class Group extends StatelessWidget {
  const Group({
    super.key,
    required this.children,
    this.margin = const EdgeInsets.only(left: 16, right: 8),
  });

  final List<Widget> children;
  final EdgeInsets margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey.shade800,
      ),
      clipBehavior: Clip.antiAlias,
      child: ListView.separated(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) => children[index],
        separatorBuilder: (_, _) => Container(
          height: 1,
          margin: EdgeInsets.only(left: 48),
          width: double.infinity,
          color: Colors.white.withValues(alpha: .2),
        ),
        itemCount: children.length,
      ),
    );
  }
}

class GroupTile extends StatelessWidget {
  const GroupTile({
    super.key,
    this.leading,
    this.child,
    this.trailing = const Icon(CupertinoIcons.forward),
    this.onTap,
  });

  final Widget? leading;
  final Widget? child;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Touch(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: 42),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: [
            leading?.pipe(
                  (e) => Padding(
                    padding: EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                    child: e,
                  ),
                ) ??
                SizedBox(width: 48),
            Expanded(child: child ?? const SizedBox.shrink()),
            ?trailing?.pipe(
              (e) => Padding(
                padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: e,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfilePictureTile extends StatelessWidget {
  const ProfilePictureTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 72,
          backgroundColor: Colors.grey,
          foregroundImage: app.profile.picture,
        ),
        TextButton(
          onPressed: app.profile.takePicture,
          child: Text('Take Photo'),
        ),
      ],
    );
  }
}

class Touch extends StatefulWidget {
  const Touch({
    super.key,
    this.child,
    this.onTap,
  });

  final Widget? child;
  final VoidCallback? onTap;

  @override
  State<Touch> createState() => _TouchState();
}

class _TouchState extends State<Touch> {
  bool isDown = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: handleTapDown,
      onTapCancel: handleTapCancel,
      onTapUp: handleTapUp,
      child: AnimatedContainer(
        duration: kThemeChangeDuration,
        decoration: isDown
            ? BoxDecoration(color: Colors.white.withValues(alpha: .1))
            : BoxDecoration(color: Colors.transparent),
        child: widget.child,
      ),
    );
  }

  void handleTapDown(TapDownDetails details) {
    isDown = true;
    setState(() {});
  }

  void handleTapCancel() {
    isDown = false;
    setState(() {});
  }

  void handleTapUp(TapUpDetails details) => handleTapCancel();
}
