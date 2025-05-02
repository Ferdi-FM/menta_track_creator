class Person {
  int id;
  int sortIndex;
  String name;
  String? imagePath;

  Person({
    required this.id,
    required this.name,
    this.imagePath,
    required this.sortIndex
  });
}