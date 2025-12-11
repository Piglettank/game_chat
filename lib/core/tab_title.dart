import 'tab_title_stub.dart'
    if (dart.library.html) 'tab_title_web.dart' as tab_title;

void setTabTitle(String title) {
  tab_title.setTabTitle(title);
}
