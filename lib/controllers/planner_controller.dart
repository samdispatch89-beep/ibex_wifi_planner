import 'package:flutter/foundation.dart';

import '../models/planner_models.dart';
import '../repositories/planner_repository.dart';

class PlannerController extends ChangeNotifier {
  PlannerController({required PlannerRepository repository})
    : _repository = repository,
      _snapshot = repository.loadSnapshot(),
      _pages = repository.loadPages();

  final PlannerRepository _repository;
  final PlannerSnapshot _snapshot;
  final List<DashboardPageDefinition> _pages;

  int _selectedIndex = 0;
  bool _isDeploymentProfileExpanded = false;

  PlannerSnapshot get snapshot => _snapshot;
  List<DashboardPageDefinition> get pages => List.unmodifiable(_pages);
  int get selectedIndex => _selectedIndex;
  DashboardPageDefinition get selectedPage => _pages[_selectedIndex];
  PlannerRepository get repository => _repository;
  bool get isDeploymentProfileExpanded => _isDeploymentProfileExpanded;

  void selectPage(int index) {
    if (index < 0 || index >= _pages.length || index == _selectedIndex) {
      return;
    }

    _selectedIndex = index;
    notifyListeners();
  }

  void toggleDeploymentProfile() {
    _isDeploymentProfileExpanded = !_isDeploymentProfileExpanded;
    notifyListeners();
  }
}
