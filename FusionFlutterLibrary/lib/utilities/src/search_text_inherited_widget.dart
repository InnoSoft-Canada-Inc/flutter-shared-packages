part of fsutilities;

class SearchTextInheritedWidget extends InheritedWidget {
  const SearchTextInheritedWidget({
    Key? key,
    String? searchText,
    RegExp? searchRegExp,
    this.highlightStyle,
    this.highlightColor = Colors.red,
    required Widget child,
  })  : _searchText = searchText,
        _searchRegExp = searchRegExp,
        assert(searchText != null || searchRegExp != null),
        assert(searchText == null || searchRegExp == null),
        super(key: key, child: child);

  final String? _searchText;
  final TextStyle? highlightStyle;
  final Color highlightColor;
  final RegExp? _searchRegExp;

  static SearchTextInheritedWidget of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<SearchTextInheritedWidget>()!;
  }

  static SearchTextInheritedWidget? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<SearchTextInheritedWidget>();
  }

  RegExp get searchRegExp {
    if (_searchRegExp != null) {
      return _searchRegExp!;
    }

    return RegExp(_searchText!, caseSensitive: false);
  }

  @override
  bool updateShouldNotify(SearchTextInheritedWidget oldWidget) {
    return _searchText != oldWidget._searchText;
  }
}
