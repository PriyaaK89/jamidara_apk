import 'package:flutter/material.dart';
import '../../layout/main_layout.dart';

class DistributorOnboardingPage extends StatefulWidget {
  const DistributorOnboardingPage({super.key});

  @override
  State<DistributorOnboardingPage> createState() =>
      _DistributorOnboardingPageState();
}

class _DistributorOnboardingPageState extends State<DistributorOnboardingPage> {
  final _formKey = GlobalKey<FormState>();

  /// Controllers (Basic)
  final customerName = TextEditingController();
  final gstController = TextEditingController();
  final firmName = TextEditingController();
  // bussiness add ress
  final businessAddress = TextEditingController();
  final bussinessterritory = TextEditingController();
  final bussinesstehsil = TextEditingController();
  final bussinesstate = TextEditingController();
  final bussinessdistrict = TextEditingController();
  final bussinesspincode = TextEditingController();
  final bussinesslandmark = TextEditingController();
  final bussinesscontact = TextEditingController();
  final bussinessaltcontact = TextEditingController();
  // firm details
  final firmPan = TextEditingController();
  final firmAadhar = TextEditingController();
  final firmEmail = TextEditingController();
  final firmsince = TextEditingController();
  final branch = TextEditingController();

  // responsible person details
  final responsiblePersonName = TextEditingController();
  final responsiblePersonAddress = TextEditingController();
  final responsiblePersonMobile = TextEditingController();
  final responsiblePersonAltMobile = TextEditingController();
  final responsiblePersonEmail = TextEditingController();
  // license details
  final seedLicenseNumber = TextEditingController();
  final seedLicenseExpiry = TextEditingController();
  final fertilizerLicenseNumber = TextEditingController();
  final pesticideLicenseNumber = TextEditingController();
  // transport details
  final transportAgency1Name = TextEditingController();
  final transportAgency2Name = TextEditingController();
  // bank details
  final firmbankName = TextEditingController();
  final firmbankBranch = TextEditingController();
  final firmbankAccountNumber = TextEditingController();
  final firmbankIfsc = TextEditingController();

  // cheque details
  final cheque1Number = TextEditingController();
  final cheque2Number = TextEditingController();
  // other details

  final annualTurnover = TextEditingController();
  final creditdurationperiod = TextEditingController();
  final securityamount = TextEditingController();
  final expectedsaleperyear = TextEditingController();

  /// Dropdowns
  String firmType = "";
  String gstType = "";
  String jurisdiction = "";
  String sourceOfFunds = "";
  String firmgsttype = "";

  /// Dynamic Fields
  List<Map<String, TextEditingController>> partners = [];
  List<Map<String, TextEditingController>> companies = [
    {"name": TextEditingController(), "turnover": TextEditingController()},
  ];

  /// INPUT STYLE
  InputDecoration input(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),

      /// DEFAULT BORDER
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),

      /// NORMAL (when not focused)
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),

      /// WHEN USER CLICKS FIELD
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color(0xFF1B5E20), // your green color
          width: 1.5,
        ),
      ),

      /// ERROR BORDER (optional)
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),

      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
    );
  }

  /// ADD PARTNER
  void addPartner() {
    setState(() {
      partners.add({
        "name": TextEditingController(),
        "mobile": TextEditingController(),
      });
    });
  }

  void removePartner(int index) {
    setState(() {
      partners.removeAt(index);
    });
  }

  /// ADD COMPANY
  void addCompany() {
    setState(() {
      companies.add({
        "name": TextEditingController(),
        "turnover": TextEditingController(),
      });
    });
  }

  // remove comapny
  void removeCompany(int index) {
    setState(() {
      companies.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentIndex: 4,
      currentRoute: "distributor_onboarding",
      onTabChange: (i) => Navigator.pop(context),

      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 🔥 TOP TITLE
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color.fromARGB(255, 37, 82, 40),
                    Color.fromARGB(255, 48, 110, 51),
                    Color.fromARGB(255, 115, 167, 117),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: const [
                  Icon(Icons.person_add, color: Colors.white),
                  SizedBox(width: 10),
                  Text(
                    "Distributor Onboarding",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// FORM CARD
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 10),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // gst no
                    TextFormField(
                      controller: gstController,
                      decoration: input("GST Number"),
                    ),

                    const SizedBox(height: 12),

                    /// CUSTOMER NAME
                    TextFormField(
                      controller: customerName,
                      decoration: input("Customer Name"),
                    ),

                    const SizedBox(height: 12),

                    /// FIRM NAME
                    TextFormField(
                      controller: firmName,
                      decoration: input("Firm Name"),
                    ),

                    const SizedBox(height: 12),

                    /// FIRM TYPE
                    DropdownButtonFormField(
                      value: firmType.isEmpty ? null : firmType,
                      items: ["proprietorship", "partnership"]
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                      onChanged: (val) {
                        setState(() => firmType = val.toString());
                      },
                      decoration: input("Firm Type"),
                    ),

                    const SizedBox(height: 12),

                    /// BUSINESS ADDRESS
                    TextFormField(
                      controller: businessAddress,
                      decoration: input("Business Address"),
                    ),

                    const SizedBox(height: 12),

                    /// STATE
                    TextFormField(
                      controller: bussinesstate,
                      decoration: input("State"),
                    ),

                    const SizedBox(height: 12),

                    /// DISTRICT
                    TextFormField(
                      controller: bussinessdistrict,
                      decoration: input("District"),
                    ),

                    const SizedBox(height: 12),

                    /// PINCODE
                    TextFormField(
                      controller: bussinesspincode,
                      decoration: input("Pincode"),
                    ),

                    const SizedBox(height: 20),

                    ///  PARTNERS SECTION
                    if (firmType == "partnership") ...[
                      const Align(
                        alignment: Alignment.centerLeft,
                     
                      ),

                      const SizedBox(height: 10),

                      ...partners.asMap().entries.map((entry) {
                        int i = entry.key;
                        var partner = entry.value;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: const [
                              BoxShadow(color: Colors.black12, blurRadius: 5),
                            ],
                          ),

                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                            
                              Text(
                                "Partner ${i + 1}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                                IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () {
                                      if (partners.length > 1) {
                                        removePartner(i);
                                      }
                                    },
                                  ),
                                

                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: partner["name"],
                                      decoration: input("Partner Name"),
                                    ),
                                  ),

                                  const SizedBox(width: 8),

                                  /// ❌ DELETE BUTTON
                                
                                ],
                              ),

                              const SizedBox(height: 8),

                              TextFormField(
                                controller: partner["mobile"],
                                decoration: input("Mobile"),
                              ),
                            ],
                          ),
                        );
                      }).toList(),

                      ElevatedButton(
                        onPressed: addPartner,
                        child: const Text("Add Partner"),
                      ),

                      const SizedBox(height: 20),
                    ],
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Other Companies",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),

                    const SizedBox(height: 10),

                    ...companies.asMap().entries.map((entry) {
                      int index = entry.key;
                      var company = entry.value;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(
                            color: Colors.grey.shade300,
                          ), //  BORDER
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(color: Colors.black12, blurRadius: 5),
                          ],
                        ),

                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: company["name"],
                                    decoration: input("Company Name"),
                                  ),
                                ),

                                const SizedBox(width: 8),

                                ///  DELETE BUTTON
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () {
                                    if (companies.length > 1) {
                                      removeCompany(index);
                                    }
                                  },
                                ),
                              ],
                            ),

                            const SizedBox(height: 8),

                            /// TURNOVER FIELD
                            TextFormField(
                              controller: company["turnover"],
                              decoration: input("Turnover"),
                            ),
                          ],
                        ),
                      );
                    }).toList(),

                    /// add comapny button
                    ElevatedButton(
                      onPressed: addCompany,
                      child: const Text("Add Company"),
                    ),

                    const SizedBox(height: 20),

                    ///  SOURCE OF FUNDS
                    DropdownButtonFormField(
                      value: sourceOfFunds.isEmpty ? null : sourceOfFunds,
                      items: ["loan", "own_funds", "investment"]
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                      onChanged: (val) {
                        setState(() => sourceOfFunds = val.toString());
                      },
                      decoration: input("Source of Funds"),
                    ),

                    const SizedBox(height: 20),

                    ///  SUBMIT BUTTON
                    InkWell(
                      onTap: () {
                        if (_formKey.currentState!.validate()) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Submitted")),
                          );
                        }
                      },
                      child: Container(
                        height: 50,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color.fromARGB(255, 37, 82, 40),
                              Color.fromARGB(255, 48, 110, 51),
                              Color.fromARGB(255, 115, 167, 117),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          "SUBMIT",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
