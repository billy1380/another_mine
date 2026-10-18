import "package:another_mine_common/another_mine_common.dart";
import "package:jaspr/dom.dart";
import "package:jaspr/jaspr.dart";
import "package:jaspr_router/jaspr_router.dart";
import "package:willshex/willshex.dart";

/// The standalone page: a sidebar to pick a difficulty (the game's drawer), and
/// a header with the page title and its actions.
///
/// Hosts that bring their own shell leave this out and use the views directly.
class AppLayout extends StatefulComponent {
  final String title;
  final List<Component> actions;
  final Component child;

  /// Prefix of the app's paths when it is mounted under another path.
  final String basePath;

  /// Called when the sidebar opens or closes on a narrow screen, so that the
  /// game can pause while it is covered.
  final void Function(bool open)? onSidebarChanged;

  const AppLayout({
    super.key,
    required this.title,
    this.actions = const [],
    required this.child,
    this.basePath = "",
    this.onSidebarChanged,
  });

  @override
  State<AppLayout> createState() => _AppLayoutState();
}

class _AppLayoutState extends State<AppLayout> {
  bool _sidebarOpen = false;

  void _setSidebar(bool open) {
    if (_sidebarOpen == open) return;
    setState(() => _sidebarOpen = open);
    component.onSidebarChanged?.call(open);
  }

  Component _link({
    required String label,
    required String path,
    required String currentPath,
    required bool active,
  }) {
    return a(
      href: path,
      classes: "am-nav-link ${active ? "active" : ""}",
      events: {"click": (e) => _setSidebar(false)},
      [
        span([Component.text(label)]),
      ],
    );
  }

  Component _difficultyLink(String currentPath, GameDifficulty? difficulty) {
    final String base = component.basePath;
    final String path = difficulty == null
        ? "$base${GameRoutes.custom}"
        : "$base${GameRoutes.game(difficulty)}";

    final String label = difficulty == null
        ? StringUtils.upperCaseFirstLetter(customName)!
        : "${StringUtils.upperCaseFirstLetter(difficulty.name)} (${difficulty.description})";

    return _link(
      label: label,
      path: path,
      currentPath: currentPath,
      active: currentPath == path,
    );
  }

  @override
  Component build(BuildContext context) {
    final String currentPath = Router.of(context).matchList.uri.path;
    final String base = component.basePath;

    return div(classes: "am-container", [
      div(
        classes: "am-backdrop ${_sidebarOpen ? "open" : ""}",
        events: {"click": (e) => _setSidebar(false)},
        const [],
      ),
      aside(classes: "am-sidebar ${_sidebarOpen ? "open" : ""}", [
        div(classes: "am-sidebar-header", [
          h1(classes: "am-brand d-flex align-items-center", [
            img(
              src: "/icons/icon-64.png",
              alt: "",
              attributes: const {
                "width": "32",
                "height": "32",
                "style": "margin-right: 0.5rem; border-radius: 6px;",
              },
            ),
            const Component.text(Strings.startupPageTitle),
          ]),
          button(
            classes: "btn btn-sm btn-link d-lg-none text-secondary",
            attributes: const {
              "type": "button",
              "title": "Close menu",
              "aria-label": "Close menu",
            },
            events: {"click": (e) => _setSidebar(false)},
            const [i(classes: "bi bi-x-lg", [])],
          ),
        ]),
        nav(classes: "am-nav", [
          const div(classes: "am-nav-title", [
            Component.text(Strings.difficulty),
          ]),
          _difficultyLink(currentPath, GameDifficulty.beginner),
          _difficultyLink(currentPath, GameDifficulty.intermediate),
          _difficultyLink(currentPath, GameDifficulty.expert),
          _difficultyLink(currentPath, null),
          _link(
            label: Strings.scores,
            path: "$base${GameRoutes.scores}",
            currentPath: currentPath,
            active: currentPath == "$base${GameRoutes.scores}",
          ),
          _link(
            label: Strings.settingsTitle,
            path: "$base${GameRoutes.settings}",
            currentPath: currentPath,
            active: currentPath == "$base${GameRoutes.settings}",
          ),
        ]),
      ]),
      main_(classes: "am-main", [
        header(classes: "am-header", [
          div(classes: "d-flex align-items-center gap-2 min-w-0", [
            button(
              classes: "btn btn-sm btn-outline-secondary d-lg-none",
              attributes: const {
                "type": "button",
                "title": "Menu",
                "aria-label": "Menu",
              },
              events: {"click": (e) => _setSidebar(!_sidebarOpen)},
              const [i(classes: "bi bi-list fs-5", [])],
            ),
            h2(classes: "am-header-title", [Component.text(component.title)]),
          ]),
          div(classes: "am-header-actions", component.actions),
        ]),
        div(classes: "am-content", [component.child]),
      ]),
    ]);
  }
}
