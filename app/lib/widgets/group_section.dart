import 'package:app/theme.dart';
import 'package:app/widgets/touch.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:stated/stated.dart';

class GroupSection extends StatelessWidget {
  const GroupSection({
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
        color: colors.fill.grey,
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
