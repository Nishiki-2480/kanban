class Task {
  String title;
  int status; // 0:聴きたい 1:聴いた 2:好き
  String url;
  Task(this.title, [this.status = 0, this.url = '']);
}
