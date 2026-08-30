// lib/utils/endpoints.dart
class Endpoints {
  static const String login = '/auth/login';
  static const String markAttendance = '/mark-emp-attendance';
  static const String saveLocation = '/save-location';
  static const String getDistrict = '/getstatecity';
  static const String getArea = '/areas';
  static const String uploadEmpVisit = '/upload-visit';
  static const String getCustomers = '/getCustomers';
  static const String getCustomerById = '/get_customer_details';
  static const String uploadExpenses = '/upload-my-expense';
  static const String getSalaryReport = '/my-daily-salary';
  static const String getVisitReport = '/my-visits';
  static const String getAttendanceReport = '/my-attendance';
  static const String getProfile = '/auth/get-employee-details';
  static const String getStreetAddress =
      'https://maps.googleapis.com/maps/api/geocode/json';
  static const String createOnBoardingOfDistributor = '/create-distributor';
  static const String verifyGST = '/verify-gst';
  static const String getTodayVisitCount = '/get-my-todayVisitCount';
  static const String updateUserStatus = '/auth/update-status';
  static const String sendForAadharKYC = '/digilocker-kyc';
  static const String getDetailsFromAadhar = '/kyc-status';
  static const String getMe = '/auth/my-profile';
  static const String updateProfileImage = '/auth/upload-profile-image';
  static const String createTarget = '/create-target';
  static const String myTargets = '/my-targets';
  static const String getMyTeam = '/my-team';
  static const String createSalesApprovalRequest =
      "/create-sales-approval-request";
  static const String getMyAssignedLedgers = "/get-my-assigned-ledgers";
  static const String getStockItemsList = "/get-stock-items/dropdown";
  static const String getStockItemDetailsById = "/getstockItemByID";
  static const String getUsersbySelectedLevel = "/users-by-level";
  static const String viewVisitByHirarchy = "/hierarchy-visits";
  static const String getVisitDetailsByID = "/get-hierarchy-visits";
  static const String getRouteByEmpId = "/get-route";

  static const String getNotification = "/get-notifications";
  static const String getNotificationsCount = "/get-notification-counts";
  static const String markNotificationsRead = "/mark-notifications-read";

  static const String getEmployeeVisitProgress =
      "/visit-targets/progress/employee"; // append /:employeeId
  static const String getVisitTargetHistory = "/visit-targets/progress/history";

  static const String createReceiptRequest = "/create-receipt-approval-request";
  static const String getLedgerDetailsByID = "/getLedgerDetailsById";

  // NEW — confirm these match your actual backend routes
static const String getBankAccountLedgerDropdown = "/bank-ledger-dropdown";
static const String createPurchaseApprovalRequest = "/create-purchase-approval-request";

  static const String createCreditNoteApprovalRequest =
      "/create-credit-note-approval-request";
  static const String getSalesByCustomer = "/get-sales-by-customer";
  static const String getSaleItemsById = "/get-sales-item"; // + /$saleId/items
  static const String getSalesBillReferences = "/sales-bill-references";
  static const String getSalesReturnLedgers = "/sales-ledger-dropdown";

  static const String getLedgerOverdueStatus = "/sales/ledger-overdue-status";
  static const String getTeamTargets = '/get-teamwise-visit-target-template';
}
