import 'package:flutter/material.dart';
import 'package:menta_track_creator/database_helper.dart';
import 'package:menta_track_creator/person.dart';
import 'generated/l10n.dart';
import 'main.dart';

class CommentPage extends StatefulWidget {
  final Person person;

  const CommentPage({
    super.key,
    required this.person
  });

  @override
  CommentPageState createState() => CommentPageState();
}

class CommentPageState extends State<CommentPage>{
  List<Map<String,dynamic>> commentList = [];

  @override
  void initState() {
    super.initState();
    setUpPage();
  }

  void setUpPage() async{
    var tempCommentList = await DatabaseHelper().getComment(widget.person.id);
    setState(() {
      commentList = List<Map<String,dynamic>>.from(tempCommentList);
      commentList.sort((a, b) {
        int indexA = a["sortIndex"] as int;
        int indexB = b["sortIndex"] as int;
        return indexA.compareTo(indexB);
      });
    });
  }

  Future<bool?> _showAddCommentDialog([String? existingTitle, String? existingComment]) async {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController commentController = TextEditingController();

    titleController.text = existingTitle ?? "";
    commentController.text = existingComment ?? "";

    return showDialog<bool>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(existingTitle != null ? S.current.comments_updateNote : S.current.comments_addNote),
          content: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(labelText: S.current.comments_title),
                ),
                SizedBox(height: 10),
                TextField(
                  controller: commentController,
                  maxLines: 6,
                  scrollPadding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 18*5),
                  decoration: InputDecoration(
                    labelText: S.current.comments_note(0),
                    border: OutlineInputBorder(borderSide: BorderSide(color: Theme.of(context).primaryColorLight)),
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(S.current.cancel),
              onPressed: () {
                navigatorKey.currentState?.pop();
              },
            ),
            TextButton(
              child: Text(existingTitle != null ? S.current.update : S.current.add),
              onPressed: () async {
                if(titleController.text.isNotEmpty && commentController.text.isNotEmpty){
                  existingTitle != null && existingComment != null
                      ? await DatabaseHelper().updateComment(widget.person.id, existingTitle, existingComment, titleController.text, commentController.text)
                      : await DatabaseHelper().insertComment(widget.person.id, titleController.text, commentController.text, commentList.length);
                  setUpPage();
                  navigatorKey.currentState?.pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
            padding: EdgeInsets.only(left: 16,right: 16,bottom: 15),
            child: Column(
              children: [
                SizedBox(height: 20,),
                Align(
                  alignment: Alignment.center,
                  child: Text(
                      S.current.comments_note(1),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Theme.of(context).appBarTheme.backgroundColor, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2)
                  ),
                ),
                SizedBox(height: 20),
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
                        stops: [0.0, 0.03, 0.95, 1.0],
                      ).createShader(bounds);
                    },
                    blendMode: BlendMode.dstIn,
                    child: ReorderableListView.builder(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      itemCount: commentList.length,
                      itemBuilder: (context, index) {
                        final map = commentList[index];
                        String title = map["commentTitle"];
                        String comment = map["commentText"];
                        return  Padding(
                            key: Key("$title-$comment"),
                            padding: EdgeInsets.symmetric(vertical: 5),
                            child: ClipRRect(
                              key: Key("$title-$comment"),
                              borderRadius: BorderRadius.circular(12),
                              child: Dismissible(
                                key: Key("$title-$comment"),
                                direction: DismissDirection.endToStart,
                                onDismissed: (direction) async {
                                  final itemToDelete = commentList[index];
                                  setState(() {
                                    commentList.removeAt(index);
                                  });

                                  ScaffoldMessenger.of(context).clearSnackBars();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(S.current.comment_deleted),
                                      action: SnackBarAction(
                                        label: S.current.comment_undo,
                                        onPressed: () {
                                          setState(() {
                                            commentList.insert(index, itemToDelete);
                                          });
                                        },
                                      ),
                                      duration: Duration(seconds: 3),
                                    ),
                                  );

                                  // Datenbank löschen erst nach der Snackbar-Zeit
                                  Future.delayed(Duration(seconds: 3), () async {
                                    if (!commentList.contains(itemToDelete)) {
                                      await DatabaseHelper().deleteComment(widget.person.id, title, comment,);
                                      await DatabaseHelper().updateCommentList(widget.person.id, commentList);
                                    }
                                  });
                                },
                                background: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    color: Colors.red,
                                  ),
                                  alignment: Alignment.centerRight,
                                  padding: EdgeInsets.symmetric(horizontal: 10),
                                  child: Icon(
                                    Icons.delete,
                                    color: Colors.white,
                                  ),
                                ),
                                child: InfoListTile(
                                  key: Key("$title-$comment"),
                                  index: index,
                                  title: title,
                                  comment: comment,
                                  onUpdate: () async{
                                    _showAddCommentDialog(title, comment);
                                  },
                                ),
                              ),
                            ),
                        );
                      },
                      proxyDecorator: (child, index, animation) {
                        return Material(
                          elevation: 15,
                          color: Colors.transparent,
                          child: child,
                        );
                      },
                      onReorder: (int oldIndex, int newIndex) {
                        setState(() {
                          if (newIndex > oldIndex) newIndex -= 1;
                          final item = commentList.removeAt(oldIndex);
                          commentList.insert(newIndex, item);
                          DatabaseHelper().updateCommentList(widget.person.id, commentList);
                        });
                      },
                      buildDefaultDragHandles: false,
                    ),
                  ),
                ),
                SizedBox(height: 15)
              ],
            )
        ),
      floatingActionButton: FloatingActionButton(
          onPressed: (){
            _showAddCommentDialog();
          },
          child: Icon(Icons.note_add)),
    );

  }
}

class InfoListTile extends StatefulWidget {
  final String title;
  final String comment;
  final int index;
  final VoidCallback onUpdate;
  const InfoListTile({super.key, required this.title, required this.comment, required this.index, required this.onUpdate});

  @override
  InfoListTileState createState() => InfoListTileState();
}

class InfoListTileState extends State<InfoListTile> {
  bool showInfo = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).listTileTheme.tileColor,
      elevation: 5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 5, left: 15, right: 15),
            child: Row(
              children: [
                SizedBox(width: 10,),
                ReorderableDragStartListener(
                    index: widget.index,
                    child: Icon(Icons.drag_handle)
                ),
                SizedBox(width: 14),
                Text(widget.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),),
                Spacer(),
                IconButton(
                    onPressed: (){
                        widget.onUpdate();
                    },
                    icon: Icon(Icons.edit, size: 22,color: Theme.of(context).appBarTheme.backgroundColor)),
              ],
            ),
          ),
          Padding(
              padding: EdgeInsets.only(left: 17, right: 17, top: 3, bottom: 10),
              child: Text(widget.comment, style: TextStyle(fontSize: 16),)
          ),
        ],
      ),
    );
  }
}

//STandartd ListTile:
/*
ListTile(

                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: Icon(Icons.note),
                          title: Text(map["commentTitle"]),
                          subtitle: Text(map["commentText"]),
                          trailing: IconButton(
                            icon: Icon(Icons.delete, color: Theme.of(context).appBarTheme.backgroundColor),
                            onPressed: () {
                              print("DELETE");
                            },
                          ),
                        );
 */

//Für später (Idee die besten/schlechtesten Aktivitäten zu importieren)
/*
GestureDetector(
                        child: Container(
                          color: Colors.transparent,
                          width: double.infinity,
                          child: Padding(
                            padding: EdgeInsets.all(4),
                            child: Row(
                              spacing: 10,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(S.current.activity_filter),
                                Icon(_expandFilters ? Icons.expand_less_rounded : Icons.expand_more_rounded)
                              ],
                            ),
                          ),
                        ),
                        onTap: (){
                          setState(() {
                            _expandFilters = _expandFilters == false ? true : false;
                          });
                        },
                      ),
if(_expandFilters)...{
                        SizedBox(height: 20),
                        AutoSizeText(S.current.activity_filter_desc1 ,textAlign: TextAlign.center, maxLines: 1, minFontSize: 16,),
                        Container(
                          width: MediaQuery.of(context).size.width,
                          padding: EdgeInsets.all(10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: List.generate(3, (index) {
                              bool isSelected = _selectedTimeButtonIndex == index;
                              return SizedBox(
                                width: _selectedTimeButtonIndex == index ? MediaQuery.of(context).size.width*0.27 : MediaQuery.of(context).size.width*0.23,
                                height: 45,
                                child: TextButton(
                                  onPressed: () {
                                    if(_hapticFeedback) HapticFeedback.lightImpact();
                                    onFilterTimeButtonPressed(index);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(13)
                                    ),
                                    padding: EdgeInsets.symmetric(horizontal: isSelected ? 15 : 5),
                                    backgroundColor: isSelected ? Theme.of(context).appBarTheme.backgroundColor?.withAlpha(120) : Theme.of(context).listTileTheme.tileColor?.withAlpha(120), // Farbänderung
                                  ),
                                  child: FittedBox(
                                      child: Padding(padding: EdgeInsets.all(1),
                                          child: Text(S.current.buttonTimeDisplay(index), textAlign: TextAlign.center,style: Theme.of(context).brightness == Brightness.light ? TextStyle(color: Colors.black87): TextStyle())
                                      )
                                  ), //Utilities().getActivityAdjective(index) style: TextStyle(fontWeight: selectedButtonIndex == index ? FontWeight.bold : FontWeight.normal)
                                ),
                              ) ;
                            }),
                          ),
                        ),
                        Container(
                          width: MediaQuery.of(context).size.width,
                          padding: EdgeInsets.all(10),
                          child: Row(
                            spacing: 5,
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: List.generate(4, (index) {
                              bool isSelected = _selectedButtonIndex == index;
                              return SizedBox(
                                width: _selectedButtonIndex == index ? MediaQuery.of(context).size.width*0.23 : MediaQuery.of(context).size.width*0.19,
                                height: 45,
                                child: TextButton(
                                  onPressed: () {
                                    if(_hapticFeedback) HapticFeedback.lightImpact();
                                    onFilterButtonPressed(index);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(13)
                                    ),
                                    padding: EdgeInsets.symmetric(horizontal: isSelected ? 15 : 5),
                                    backgroundColor: isSelected ? Theme.of(context).appBarTheme.backgroundColor?.withAlpha(120) : Theme.of(context).listTileTheme.tileColor?.withAlpha(120), // Farbänderung
                                  ),
                                  child: FittedBox(
                                      child: Padding(padding: EdgeInsets.all(1),
                                          child:   Text(S.current.buttonDisplay(index), textAlign: TextAlign.center, style: Theme.of(context).brightness == Brightness.light ? TextStyle(color: Colors.black87): TextStyle())
                                      )
                                  ), //Utilities().getActivityAdjective(index) style: TextStyle(fontWeight: selectedButtonIndex == index ? FontWeight.bold : FontWeight.normal)
                                ),
                              ) ;
                            }),
                          ),
                        ),
                        AutoSizeText(S.current.activity_filter_desc2 ,textAlign: TextAlign.center, minFontSize: 16, maxLines: 1,),
                        SizedBox(height: 16),
                      },
 */