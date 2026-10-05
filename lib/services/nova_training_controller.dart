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
  List<NovaStep> get steps => novaWalkthrough(role);
  NovaStep get step => steps[index.clamp(0, steps.length - 1)];
  void Function(NovaStep)? navigate;
  VoidCallback? exit;
  void start({String? role, bool replay = true}) {
    if (saving) return;
    _generation++;
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
      saving = true;
      notifyListeners();
      final generation = _generation;
      final result = await service.save(role: role, step: index, finish: true);
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
    service.save(role: role, step: index);
  }

  void back() {
    if (index == 0 || saving) return;
    index--;
    notifyListeners();
    navigate?.call(step);
    service.save(role: role, step: index);
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
