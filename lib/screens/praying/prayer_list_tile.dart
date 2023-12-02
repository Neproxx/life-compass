import 'package:flutter/material.dart';

class PrayerListTile extends StatelessWidget {
  final Widget? leading;
  final Widget? title;
  final Widget? subtitle;
  final Widget? trailing;
  final double leadingWidth;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const PrayerListTile({
    Key? key,
    this.leading,
    this.title,
    this.subtitle,
    this.trailing,
    this.leadingWidth = 24.0,
    this.onTap,
    this.onLongPress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final TextStyle? titleStyle = Theme.of(context).textTheme.titleMedium;
    final TextStyle? subtitleStyle = Theme.of(context).textTheme.bodySmall;

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0),
        child: Row(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(right: 4.0),
              child: SizedBox(
                width: leadingWidth,
                child: leading,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (title != null)
                    DefaultTextStyle(
                        style: titleStyle ?? const TextStyle(), child: title!),
                  const SizedBox(height: 4.0),
                  if (subtitle != null)
                    DefaultTextStyle(
                        style: subtitleStyle ?? const TextStyle(),
                        child: subtitle!),
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}
