import 'nova_page_guide.dart';
import 'package:flutter/foundation.dart';
import 'nova_training_service.dart';
import 'nova_walkthrough.dart';

class NovaTrainingController extends ChangeNotifier {
  NovaTrainingController({NovaTrainingService? service})
    : service = service ?? NovaTrainingService();
  static final instance = NovaTrainingController();
  final NovaTrainingService service;
  bool active = false, hosted = false, saving = false;
  String role = 'buyer';
  int index = 0;
  int _generation = 0;
  bool? savedToProfile;
  List<NovaStep>? _pageSteps;
  bool _automaticPageGuide = false;
  bool get pageOnly => _pageSteps != null;
  String currentPage = 'buyer/home';
  String calculatorMode = 'business';
  List<NovaStep> get steps => _pageSteps ?? novaWalkthrough(role);
  void startPage(String page, {bool automatic = false}) {
    if (saving) return;
    _generation++;
    role = page.startsWith('seller/')
        ? 'seller'
        : page.startsWith('member/')
        ? 'member'
        : 'buyer';
    _automaticPageGuide = automatic;
    _pageSteps = [
      if (automatic)
        NovaStep(
          'welcome',
          'Hi, I’m Pebble.',
          'I’ll show you around this page. Use Next and Back, or close the guide and request me again from the header.',
          page,
          NovaMood.welcome,
        ),
      ...novaPageWalkthrough(page),
    ];
    index = 0;
    active = true;
    savedToProfile = null;
    notifyListeners();
    navigate?.call(step);
  }

  NovaStep get step => steps[index.clamp(0, steps.length - 1)];
  void Function(NovaStep)? navigate;
  VoidCallback? exit;
  void start({String? role, bool replay = true}) {
    if (saving) return;
    _generation++;
    _pageSteps = null;
    this.role = role ?? service.progress.role;
    if (!{'buyer', 'seller', 'member'}.contains(this.role)) this.role = 'buyer';
    index = replay ? 0 : service.progress.step.clamp(0, steps.length - 1);
    active = true;
    savedToProfile = null;
    notifyListeners();
    navigate?.call(step);
  }

  void chooseRole(String value) {
    role = value;
    index = 0;
    notifyListeners();
    navigate?.call(step);
  }

  Future<void> next() async {
    if (!active || saving) return;
    if (index == steps.length - 1) {
      if (pageOnly && !_automaticPageGuide && service.progress.completed) {
        active = false;
        notifyListeners();
        exit?.call();
        return;
      }
      saving = true;
      notifyListeners();
      final generation = _generation;
      final result = await service.save(
        role: role,
        step: pageOnly ? 0 : index,
        finish: true,
      );
      if (generation != _generation) return;
      savedToProfile = result;
      saving = false;
      active = false;
      notifyListeners();
      exit?.call();
      return;
    }
    index++;
    notifyListeners();
    navigate?.call(step);
    // Progress is cached immediately; profile synchronization is serialized.
    if (!pageOnly) service.save(role: role, step: index);
  }

  void back() {
    if (index == 0 || saving) return;
    index--;
    notifyListeners();
    navigate?.call(step);
    if (!pageOnly) service.save(role: role, step: index);
  }

  void accountChanged() {
    _generation++;
    saving = false;
    savedToProfile = null;
    pause();
  }

  void pause() {
    if (saving) return;
    active = false;
    notifyListeners();
    exit?.call();
  }
}
