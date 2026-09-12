
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:allah_everywhere/l10n/generated/app_localizations.dart';
import '../login.dart';


class LoginLink extends StatelessWidget {
  const LoginLink({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Center(
      child: RichText(
        text: TextSpan(
          text: t.alreadyHaveAccount,
          style: TextStyle(
            fontSize: 14,
            color: Colors.black,
          ),
          children: [
            TextSpan(
              text: t.loginTitle,
              style: TextStyle(
                fontSize: 14,
                color: Colors.pinkAccent,
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
