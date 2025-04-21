import 'package:flutter/material.dart';

import 'generated/l10n.dart';

class Utilities {

  Utilities();

  String getWeekDay(int w, bool shortVersion){
    List<String> weekdays = [
      S.current.Mo,
      S.current.Di,
      S.current.Mi,
      S.current.Do,
      S.current.Fr,
      S.current.Sa,
      S.current.So
    ];
    return shortVersion ? weekdays[w-1].substring(0,2) : weekdays[w-1];
  }

  Widget getHelpBurgerMenu(BuildContext context, String pageKey){
    return Padding(
      padding: EdgeInsets.only(right: 5),
      child: MenuAnchor(
          menuChildren: <Widget>[
            MenuItemButton(
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Icon(Icons.help_rounded),
                    SizedBox(width: 10),
                    Text(S.current.help)
                  ],
                ),
              ),
              onPressed: () => Utilities().showHelpDialog(context, pageKey),
            ),
          ],
          builder: (BuildContext context, MenuController controller, Widget? child) {
            return TextButton(
              focusNode: FocusNode(),
              onPressed: () {
                if (controller.isOpen) {
                  controller.close();
                } else {
                  controller.open();
                }
              },
              child: Icon(Icons.menu, size: 30, color: Theme.of(context).appBarTheme.foregroundColor,),
            );
          }
      ),
    );
  }

  void showHelpDialog(BuildContext context, String whichSite, [String? name]) {
    TextSpan mainText;

    switch (whichSite) {
      case "PersonPage":
        mainText = TextSpan(
          children: [
            WidgetSpan(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(S.current.help_PersonPage_1, textAlign: TextAlign.center),
                    Text(S.current.help_PersonPage_2, textAlign: TextAlign.center),
                    Text(S.current.help_PersonPage_3, textAlign: TextAlign.center),
                    Text(S.current.help_PersonPage_4, textAlign: TextAlign.center)

                  ],
                ),
              ),
            ),
          ],
          style: TextStyle(fontSize: 10),
        );
      case "planView":
        mainText = TextSpan(
          children: [
            WidgetSpan(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(S.current.help_PlanView_1, textAlign: TextAlign.center),
                    Text(S.current.help_PlanView_2, textAlign: TextAlign.center),
                    Text(S.current.help_PlanView_3, textAlign: TextAlign.center),
                    Text(S.current.help_PlanView_4, textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
          ],
          style: TextStyle(fontSize: 10),
        );
        break;
      default:
        mainText = TextSpan(
          children: [
            WidgetSpan(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Basic", textAlign: TextAlign.center),
                    ],
                ),
              ),
            ),
          ],
          style: TextStyle(fontSize: 10),
        );
        break;
    }

    showDialog(
      context: context,
      builder: (BuildContext bc) {
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.5,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(S.current.help, style: Theme.of(context).textTheme.headlineLarge),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ShaderMask(
                      shaderCallback: (Rect bounds) {
                        return LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black,
                            Colors.black,
                            Colors.transparent
                          ],
                          stops: [0.0, 0.03, 0.9, 1.0],
                        ).createShader(bounds);
                      },
                      blendMode: BlendMode.dstIn,
                      child: Scrollbar(
                          thumbVisibility: true,
                          child: SingleChildScrollView(
                            child: RichText(
                              text: mainText,
                              textAlign: TextAlign.center,
                            ),
                          )
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(context, "confirmed");
                      },
                      child: const Text("OK"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<bool?> showDeleteDialog(String text,  BuildContext context) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(S.current.delete),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(text),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(S.current.delete,style: TextStyle(color: Colors.redAccent),),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
            TextButton(
              child: Text(S.current.cancel),
              onPressed: () {
                Navigator.of(context).pop(false);
              },),
          ],
        );
      },
    );
  }

  void showSnackBar(BuildContext context, String text){
    if(context.mounted){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(text),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.fixed,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.only(topLeft: Radius.circular(10),topRight: Radius.circular(10))
          ),
          showCloseIcon: true,
        ),
      );
    }
  }

  void showFloatingSnackBar(BuildContext context, String text){
    if(context.mounted){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(text),
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(bottom: 150, left: 10,right: 10),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)
          ),
          showCloseIcon: true,
        ),
      );
    }
  }
}