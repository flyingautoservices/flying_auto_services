import 'package:flutter/material.dart';
import 'package:flying_auto_services/utils/app_theme.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final double height;
  final Widget? title;
  final List<Widget>? actions;
  final bool centerTitle;
  final Color? backgroundColor;
  final bool showLogo;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final PreferredSizeWidget? bottom;

  const CustomAppBar({
    Key? key,
    this.height = 52.0,
    this.title,
    this.actions,
    this.centerTitle = true,
    this.backgroundColor,
    this.showLogo = true,
    this.showBackButton = false,
    this.onBackPressed,
    this.bottom,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: height,
      backgroundColor: backgroundColor ?? AppTheme.primaryColor,
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      automaticallyImplyLeading: false,
      centerTitle: centerTitle,
      title: title,
      bottom: bottom,
      actions: actions,
      leading: showBackButton ? IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
      ) : null,
      flexibleSpace: Container(
        child: SafeArea(
        child: Row(
          mainAxisAlignment:
              centerTitle && !showBackButton
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
          children: [
            if (showBackButton)
              IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
              ),
            if (showLogo) ...[
              Image.asset(
                'assets/images/logoplane.png',
                height: height * 0.7,
                width: 160,
              ),
              const SizedBox(width: 8),
              Image.asset(
                'assets/images/logotext.png',
                height: height * 0.7,
                width: 160,
              ),
            ],
            if (title != null && !showLogo)
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: showBackButton ? 8.0 : 16.0,
                ),
                child: DefaultTextStyle(
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  child: title!,
                ),
              ),
            if (actions != null) ...[
              const Spacer(),
              ...actions!,
              const SizedBox(width: 16),
            ],
            // Bottom widget is handled separately
          ],
        ),
      ),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(bottom != null ? height + 48 : height);
}
