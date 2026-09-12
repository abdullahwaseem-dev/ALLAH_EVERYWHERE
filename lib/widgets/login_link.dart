
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:allah_everywhere/l10n/generated/app_localizations.dart';
import 'package:allah_everywhere/utils/utils/constraints/colors.dart';
import '../login.dart';


class LoginLink extends StatelessWidget {
  const LoginLink({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? VoidColors.goldDark : VoidColors.gold;
    final textColor = isDark ? VoidColors.textDarkPrimary : VoidColors.oliveDeep;
    return Center(
      child: RichText(
        text: TextSpan(
          text: t.alreadyHaveAccount,
          style: TextStyle(
            fontSize: 14,
            color: textColor,
          ),
          children: [
            TextSpan(
              text: t.loginTitle,
              style: TextStyle(
                fontSize: 14,
                color: accent,
                decoration: TextDecoration.underline,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  Get.to(() => Login());
                },
            ),
          ],
        ),
      ),
    );
  }
}
