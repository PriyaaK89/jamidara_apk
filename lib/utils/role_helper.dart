class RoleHelper {

  /// Can assign targets (ZSM, RSM)
  static bool canAssignTarget(int level) {
    return level <= 4;
  }

  /// Can only view targets (ASM and below)
  static bool canViewOnly(int level) {
    return level > 4;
  }

  /// Can view team data (ZSM, RSM, ASM)
  static bool canViewTeam(int level) {
    return level <= 4;
  }

  /// Can see reports (everyone except interns)
  static bool canViewReports(int level) {
    return level <= 6;
  }


  /// Get level safely from user object
  static int getLevel(Map<String, dynamic>? user) {
    if (user == null) return 10;
    return user['job_role_level'] ?? 10;
  }

  /// Get role name safely
  static String getRoleName(Map<String, dynamic>? user) {
    if (user == null) return '';
    return user['job_role_name'] ?? '';
  }


  /// Decide which screen to show
  static bool shouldShowCreateTarget(Map<String, dynamic>? user) {
    final level = getLevel(user);
    return canAssignTarget(level);
  }

  /// Decide if user should only see list
  static bool shouldShowOnlyTargets(Map<String, dynamic>? user) {
    final level = getLevel(user);
    return canViewOnly(level);
  }

  /// Example: Hide features for interns
  static bool isIntern(Map<String, dynamic>? user) {
    final role = getRoleName(user).toLowerCase();
    return role.contains("intern");
  }
}