import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DistributorAgreementModal extends StatelessWidget {
  final String customerName;
  final String firmName;
  final String businessAddress;
  final String firmType;
  final String bussinessdistrict;
  final String securityamount;
  final String creditdurationperiod;
  // final String juridictionArea;
  final List<Map<String, TextEditingController>> partners;
  final String ownerName;
  final String ownerAadhar;
  final String ownerAddress;
  final String ownerState;
  final String ownerDistrict;
  final String ownerTehsil;
  final String ownerPincode;
  final String ownerMobile;
  final String seedLicenceNo;
  final String fertilizerLicenceNo;
  final String gstNumber;
  final String pesticideLicenseNumber;
  final String firmbankName;
  final String firmbankAccountNumber;
  final String firmEmail;
  final String bussinessterritory;

  const DistributorAgreementModal({
    super.key,
    required this.customerName,
    required this.firmName,
    required this.businessAddress,
    required this.firmType,
    required this.bussinessdistrict,
    required this.securityamount,
    required this.creditdurationperiod,
    // required this.juridictionArea,
    required this.partners,
    required this.ownerName,
    required this.ownerAadhar,
    required this.ownerAddress,
    required this.ownerState,
    required this.ownerDistrict,
    required this.ownerTehsil,
    required this.ownerPincode,
    required this.ownerMobile,
    required this.seedLicenceNo,
    required this.fertilizerLicenceNo,
    required this.pesticideLicenseNumber,
    required this.gstNumber,
    required this.firmbankAccountNumber,
    required this.firmbankName,
    required this.firmEmail,
    required this.bussinessterritory,
  });

  Widget _annexureTable() {
    String keyPerson = "";
    String address = "";
    String contact = "";
    String state = "";
String district = "";
String tehsil = "";
String pincode = "";

    ///  CONDITION BASED DATA
   if (firmType == "proprietorship") {
  keyPerson = "$ownerName, $ownerAadhar";
  address =
      "$ownerAddress, $ownerTehsil, $ownerDistrict, $ownerState - $ownerPincode";
  contact = ownerMobile;
} else {
  keyPerson = partners
      .map((p) => "${p["name"]?.text}, ${p["aadhar_no"]?.text}")
      .join("\n");

  address = partners.map((p) => p["address"]?.text ?? "").join("\n");
  state = partners.map((p) => p["state"]?.text ?? "").join("\n");
  district = partners.map((p) => p["district"]?.text ?? "").join("\n");
  tehsil = partners.map((p) => p["tehsil"]?.text ?? "").join("\n");
  pincode = partners.map((p) => p["pincode"]?.text ?? "").join("\n");

  /// Combine all into one
  address =
      "$address\n$tehsil\n$district\n$state\n$pincode";

  contact = partners.map((p) => p["mobile"]?.text ?? "").join(", ");
}

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),

        const Center(
          child: Column(
            children: [
              Text(
                'Annexure "A"',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 4),
              Text(
                'List of Documents of the Distributor',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        Table(
          border: TableBorder.all(color: Colors.black54),
          columnWidths: const {
            0: FlexColumnWidth(1.2),
            1: FlexColumnWidth(1.5),
          },
          children: [
            _row(
              "Name and Address of the Distributor (with valid address document)",
              "$firmName, $businessAddress",
            ),

            _row("Name of Key Person/s with Aadhaar No.", keyPerson),

            _row("Residential Address", address ),

            _row("Contact No.", contact),
            _row("Email Id", firmEmail),
            _row("Seed License Number", seedLicenceNo),
            _row("Pesticide License Number", pesticideLicenseNumber),
            _row("Fertilizer License Number", fertilizerLicenceNo),
            _row("GST Number", gstNumber),
            _row("Name of the Bank", firmbankName),
            _row("Bank Account Number", firmbankAccountNumber),
            _row("Bank Gurantee (if any)", "No"),
            _row("Authority Letter for Signing the agreement ", "Yes"),
          ],
        ),
      ],
    );
  }

 TableRow _row(String title, String value) {
  return TableRow(
    children: [
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold, // BOLD VALUE
          ),
        ),
      ),
    ],
  );
}

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        height: size.height * 0.9,
        width: size.width * 0.95,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
        ),
        child: Column(
          children: [
            ///  HEADER
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: const BoxDecoration(
                color: Color(0xFF2E7D32),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: const [
                  Icon(Icons.description, color: Colors.white),
                  SizedBox(width: 10),
                  Text(
                    "Distributor Agreement",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            ///  BODY
            Expanded(
              child: Scrollbar(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// Agreement Text
                      SelectableText.rich(
                        _agreementTextRich(),
                        style: const TextStyle(
                          fontSize: 13.5,
                          height: 1.6,
                          color: Colors.black87,
                        ),
                      ),

                      /// SPACE BEFORE TABLE
                      const SizedBox(height: 10),

                      /// ANNEXURE TABLE
                      _annexureTable(),
                    ],
                  ),
                ),
              ),
            ),

            ///  ACTION BUTTONS
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: Colors.grey),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.close),
                      label: const Text("Close"),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  ///  Agreement Text (Dynamic)
  TextSpan _agreementTextRich() {
    String today = DateFormat('dd MMMM yyyy').format(DateTime.now());
    const normal = TextStyle(
      fontSize: 13.5,
      color: Colors.black87,
      height: 1.6,
    );
    const highlight = TextStyle(
      fontSize: 13.5,
      color: Colors.blue,
      fontWeight: FontWeight.bold,
    );
       const bold = TextStyle(
      fontSize: 13.5,
      color: Color.fromARGB(255, 33, 33, 33),
      fontWeight: FontWeight.bold,
    );



    return TextSpan(
      style: normal,
      children: [
        const TextSpan(text: "\nDISTRIBUTOR AGREEMENT FORM\n\n"),
        const TextSpan(
          text:
              'This Distributorship Agreement ("Agreement") is made and entered into this ',
        ),
        TextSpan(text: today, style: highlight),
        const TextSpan(text: ' by and between\n'),
      TextSpan(
  children: [
    const TextSpan(
      text: 'JAMIDARA SEEDS CORPORATION',
      style: TextStyle(
        fontWeight: FontWeight.bold,
      ),
    ),

    const TextSpan(
      text: ', a Company INDIAN PARTNERSHIP ACT,1932, and having its ZONEL registered office at, ',
    ),

    const TextSpan(
      text:
          'JAMIDARA SEEDS CORPORATION 73,GANESH NAGAR-||, MURLIPURA JAIPUR (RAJ)-302039',
      style: TextStyle(
        fontWeight: FontWeight.bold,
      ),
    ),

    const TextSpan(
      text: ', registered office at ',
    ),

    const TextSpan(
      text:
          'JAMIDARA SEEDS CORPORATION 105 NEMI CHNAD MARKET ALWAR-301001',
      style: TextStyle(
        fontWeight: FontWeight.bold,
      ),
    ),

    const TextSpan(
      text:
          ', (hereinafter referred to as "the Company") which expression shall, unless repugnant to the subject or context or meaning thereof, include, if applicable, successors and assigns) of the ONE PART.\n\n                                      And\n',
    ),
  ],
),
        TextSpan(text: firmName, style: highlight),
        const TextSpan(text: ' a '),
        TextSpan(text: firmType, style: highlight),
        const TextSpan(text: ' concern having its place of business at '),
        TextSpan(text: businessAddress, style: highlight),
        const TextSpan(text: ', '),
        TextSpan(text: bussinessdistrict, style: highlight),
        const TextSpan(text: ' . Represented through its proprietor '),
        TextSpan(text: customerName, style: highlight),

        TextSpan(text: customerName, style: highlight),

        if (firmType == "proprietorship")
          TextSpan(
            text:
                ', $ownerAddress, $ownerState, $ownerDistrict, $ownerTehsil, $ownerPincode ',
            style: highlight,
          ),
        const TextSpan(
          text:
              'Company and Distributor both hereinafter referred individually as "Party" or collectively as the "Parties".\n\nWHEREAS:\n\n',
        ),

        const TextSpan(
          text:
              '(A) Company carries on the business of manufacturing, marketing, distribution of various SEEDS like VEGETABLE SEEDS, CROPS SEEDS , FODDER SEEDS ,crop protection chemicals etc. (hereinafter referred to as “the Products”);\n\n',
        ),

        const TextSpan(
          text:
              '(B) Distributor had approached and represented to the Company that it has got the required valid Seeds, pesticide ,license, skill and experience to market the seeds & agro chemical products and has shown interest to act as a Distributor of the said Products on non-exclusive basis for the Company at ',
        ),

        TextSpan(text: bussinessterritory, style: highlight),
        const TextSpan(text: '\n\n'),
        const TextSpan(
          text:
              '(C) Company, based on the representation of the Distributor and documents / details submitted / agreed to submit (more specifically detailed in Annexure “A” herein) appointed it as a Distributor for marketing the said Products in the said ',
        ),

        ///  District again
        TextSpan(text: bussinessterritory, style: highlight),

        const TextSpan(text: ' Territory;\n\n'),

        const TextSpan(
          text:
              '(D) The Parties herein now agrees to reduce in writing the terms and conditions under which the Distributor was engaged by the Company, which are as follows.\n\n',
        ),
        const TextSpan(
          text:
              'NOW THIS AGREEMENT WITHNESSETH AND IT IS HEREBY AGREED BY AND BETWEEN THE PARTIES HERETO AS FOLLOWS;\n\n',
        ),

        TextSpan(
          children: [
            const TextSpan(
              text: "\n1. ENGAGEMENT\n",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const TextSpan(
              text:
                  "Company have granted to Distributor and Distributor have accepts from Company the non-exclusive right to distribute the Products in the Territory, upon and subject to all terms and conditions set forth in this Agreement. Company shall sell and the Distributor shall purchase on a principal to principal basis the Products offered by the Company. Distributor covenants and agrees to purchase the said products for its own account exclusively from Company and to market, distribute and sell the same only in the Territory based on the label claim of the Product and in compliance with all statutory provisions.\n\n"
                  "Company reserves its right to appoint more than one Distributor at its own discretion in the Territory in which the Distributor shall operate under this Agreement. The Company shall also have the right to sell the Products directly to any other person / party in the Territory of the Distributor or appoint additional Distributors/dealers in the Territory. \n\n",
              style: TextStyle(
                fontSize: 13.5,
                height: 1.6,
                color: Colors.black87,
              ),
            ),
          ],
        ),

        TextSpan(
          children: [
            const TextSpan(
              text: "\n2. TERM\n",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            TextSpan(
              text:
                  "This appointment (unless otherwise terminated as provided in Termination clause) shall be effective from $today. This Aagreement shall remain valid until terminated in terms of this present. \n\n",
              style: TextStyle(
                fontSize: 13.5,
                height: 1.6,
                color: Colors.black87,
              ),
            ),
          ],
        ),

        TextSpan(
          children: [
            /// HEADING
            const TextSpan(
              text: "\n3. TERMS OF SECURITY DEPOSIT\n",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),

            /// POINT (i)
            const TextSpan(
              text: "(i) Distributor has furnished an amount of Rs. ",
              style: TextStyle(
                fontSize: 13.5,
                height: 1.6,
                color: Colors.black87,
              ),
            ),
            TextSpan(
              text: securityamount,
              style: const TextStyle(
                fontSize: 13.5,
                height: 1.6,
                color: Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),

            const TextSpan(
              text:
                  " (Rupees) as and by way of interest free Security Deposit for due performance of the terms and conditions mentioned in this Agreement.\n\n"
                  "(ii) Distributor shall furnish all necessary security documents as per requirement of Company from time to time. Further, Distributor will keep as a security its secured assets which will depend on goods/stocks made available to it. Company will not have any right over said assets but if Distributor defaults its payment then Company will use its right to lien over said assets to the extent of amount of default.\n",
              style: TextStyle(
                fontSize: 13.5,
                height: 1.6,
                color: Colors.black87,
              ),
            ),
          ],
        ),

        TextSpan(
  children: [
    /// HEADING
    const TextSpan(
      text: "\n4. PRICE\n",
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
    ),

    /// POINT (i)
    const TextSpan(
      text:
          "(i) Products will be sold to the Distributor at the price in force. All levies, duties, octroi, or any other taxes, as may be applicable from time to time, will be charged extra. No other discounts, including quantity discounts, will be allowed unless explicitly specified in writing by the Company. The Company reserves the right to change the price of the Products or vary/alter the terms and conditions of sale, if necessary, from time to time.\n\n",
      style: TextStyle(
        fontSize: 13.5,
        height: 1.6,
        color: Colors.black87,
      ),
    ),

    /// POINT (ii)
    const TextSpan(
      text:
          "(ii) The said prices shall be on a Carriage Paid To (CPT) basis at the Company’s premises and shall be exclusive of GST payable on the Products or in respect of the sale or purchase thereof.\n\n",
      style: TextStyle(
        fontSize: 13.5,
        height: 1.6,
        color: Colors.black87,
      ),
    ),

    /// POINT (iii)
    const TextSpan(
      text:
          "(iii) The Company further reserves to itself the absolute right to revise the prices of the Products and/or the terms and conditions for delivery and payment from time to time. Such revised prices, terms, and conditions shall come into effect from the date announced by the Company to the Distributor.\n\n",
      style: TextStyle(
        fontSize: 13.5,
        height: 1.6,
        color: Colors.black87,
      ),
    ),
  ],
),

TextSpan(
  children: [
    /// HEADING
    const TextSpan(
      text: "\n5. PAYMENT\n",
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
    ),

    /// POINT (a)
    const TextSpan(
      text:
          "(a) Distributor shall make payment to the Company in accordance with the terms and conditions specified in the invoice accompanying each consignment of the Products supplied to it. Any delay in payment shall make the Distributor liable to pay interest from the due date till the date of realization of payment, at such rate as may be specified in the invoice.\n\n",
      style: TextStyle(
        fontSize: 13.5,
        height: 1.6,
        color: Colors.black87,
      ),
    ),

    /// POINT (b)
    const TextSpan(
      text:
          "(b) The Company shall have a lien over the Products sold and supplied by it until the Distributor pays the entire sale price of the same to the Company. The Company shall have the right to take back the entire or part of the Products, as it deems fit and proper, to recover its dues.\n\n",
      style: TextStyle(
        fontSize: 13.5,
        height: 1.6,
        color: Colors.black87,
      ),
    ),

    /// POINT (c)
    const TextSpan(
      text:
          "(c) It is strictly prohibited for any distributor to give cash, goods, or any other form of benefit to an employee. If any distributor engages in such activities and suffers any financial loss, they shall be solely responsible for it. The Company shall not be responsible in any manner. The Company shall not make any kind of payment adjustment from the employee’s salary on behalf of the distributor. In such transactions, the Company shall bear no responsibility whatsoever.\n\n",
      style: TextStyle(
        fontSize: 13.5,
        height: 1.6,
        color: Colors.black87,
      ),
    ),
  ],
),

TextSpan(
  children: [
    const TextSpan(
      text: "\n6. ADVANCE PAYMENT RELATED\n",
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
    ),

    const TextSpan(
      text:
          "If any amount is deposited by the Distributor under an advance payment scheme with the Company, only goods equivalent to that amount will be provided by the Company. The amount shall not be refunded.\n\n"
          "If payment has been made for any product or scheme and any balance amount remains, or if any goods are returned, then the remaining amount shall be adjusted only against the same goods. The balance amount shall be settled by providing the same goods in the following year. It shall not be adjusted against any other scheme or product.\n\n",
      style: TextStyle(
        fontSize: 13.5,
        height: 1.6,
        color: Colors.black87,
      ),
    ),

    const TextSpan(
      text: "7. CASH DISCOUNT\n",
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
    ),

    const TextSpan(
      text:
          "Cash discount, if any, shall be as mentioned in the prevailing price list or any cash discount scheme as offered by the Company in writing.\n\n"
          "Such cash discount will only be considered on the amount received by the Company within the stipulated time. The date of demand draft and/or the date of deposit of cash, cheques, or online transfer shall be considered by the Company for offering cash discount, if any.\n\n",
      style: TextStyle(
        fontSize: 13.5,
        height: 1.6,
        color: Colors.black87,
      ),
    ),
  ],
),

TextSpan(
  children: [
    const TextSpan(
      text: "\n8. THE MAXIMUM CREDIT PERIOD\n",
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
    ),

     TextSpan(
      text:
          "The maximum credit period will be $creditdurationperiod days from the date of invoice. In case of any delay in payment beyond the stipulated time, interest at the rate of 24% per annum shall be charged by the Company.\n\n",
      style: TextStyle(
        fontSize: 13.5,
        height: 1.6,
        color: Colors.black87,
      ),
    ),


    const TextSpan(
      text: "9. PAYMENT TERMS FOR CREDIT SALE\n",
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
    ),

    const TextSpan(
      text:
          "(i) Payment towards credit sales shall be made within the stipulated period by way of RTGS/NEFT transfer/DD/Cheque.\n\n"
          "(ii) No cash shall be handed over to any of the Company’s sales or development staff. No reimbursement to the Distributor will be made by the Company for any cash given to the sales/development staff under any circumstances.\n\n",
      style: TextStyle(
        fontSize: 13.5,
        height: 1.6,
        color: Colors.black87,
      ),
    ),

    const TextSpan(
      text: "10. DELIVERY\n",
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
    ),

    const TextSpan(
      text:
          "The Company’s liability shall cease when the Products are delivered by the Company to the carrier at the dispatching point for delivery to the Distributor’s place. However, the Company may, at its discretion, deliver the Products to the Distributor’s premises at its cost.\n\n",
      style: TextStyle(
        fontSize: 13.5,
        height: 1.6,
        color: Colors.black87,
      ),
    ),

    const TextSpan(
      text: "11. SALES PROMOTION\n",
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
    ),

    const TextSpan(
      text:
          "Apart from adequate stock keeping, it is clearly understood that the Distributor shall actively engage in selling, including participation in local and/or regional agricultural fairs and exhibitions and, in general, contribute to the promotion of sales of the Products in cooperation with the Company’s representatives.\n\n",
      style: TextStyle(
        fontSize: 13.5,
        height: 1.6,
        color: Colors.black87,
      ),
    ),
  ],
),

TextSpan(
  children: [
    const TextSpan(
      text: "\n12. STOCK RETURNS\n",
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
    ),

    const TextSpan(
      text:
          "For any stock returns or replacement, to and fro freight charges will be debited to the Distributor within 15 days from the date of invoicing for replacement, subject to the approval of the Zonal Head of the Company.\n\n",
      style: TextStyle(
        fontSize: 13.5,
        height: 1.6,
        color: Colors.black87,
      ),
    ),


    const TextSpan(
      text: "13. DAMAGED / LEAKAGE STOCKS\n",
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
    ),

    const TextSpan(
      text:
          "(i) Any damaged or leakage stock should be intimated by the Distributor within 15 days from the date of receipt.\n\n"
          "(ii) A copy of the Company’s Area Manager/Area Officer’s verification report, obtained by the Distributor during the first visit after reporting the damage/leakage and duly countersigned by the Area Manager/Regional Head, must be submitted.\n\n"
          "(iii) All defective containers and stored material shall be forwarded to the depot within 7 days after the above verification.\n\n",
      style: TextStyle(
        fontSize: 13.5,
        height: 1.6,
        color: Colors.black87,
      ),
    ),


    const TextSpan(
      text: "14. CLAIMS\n",
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
    ),

    const TextSpan(
      text:
          "Claims based on verbal commitments made by the sales/field staff without prior written sanction from the Zonal Heads will not be entertained or accepted under any circumstances.\n\n",
      style: TextStyle(
        fontSize: 13.5,
        height: 1.6,
        color: Colors.black87,
      ),
    ),
  ],
),

TextSpan(
  children: [

    const TextSpan(
      text: "\n15. POLICY ON DISHONORED CHEQUES\n",
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
    ),

    const TextSpan(
      text:
          "A service charge @ 2.6% of the cheque value per dishonoured cheque will be levied in case of dishonour of cheques issued against any invoice for the supplies made. The Company reserves the right to discontinue supplies if more than three (3) cheques are dishonoured. In case more than two (2) cheques are dishonoured during a financial year, the Company shall have the right to withdraw or reduce any discounts or scheme incentives offered from time to time and may also result in a downward revision of the credit ceiling offered to the Distributor.\n\n"
          "The Distributor shall honour each cheque on presentation, and no excuse will be considered. The Company shall have the absolute right to initiate any proceedings, including but not limited to proceedings under Section 138 of the Negotiable Instruments Act and any amendments thereof, in the event of dishonour of a cheque.\n\n",
      style: TextStyle(
        fontSize: 13.5,
        height: 1.6,
        color: Colors.black87,
      ),
    ),


    const TextSpan(
      text: "16. CONFIDENTIALITY\n",
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
    ),

    const TextSpan(
      text:
          "The Distributor recognizes and agrees that the information to which it has access as a result of this Agreement has significant commercial value, and that its unauthorized disclosure may result in substantial damages to the Company. Therefore, except when previously and expressly authorized by the Company, the Distributor agrees not to disclose such information, even after the termination or cancellation of this Agreement.\n\n",
      style: TextStyle(
        fontSize: 13.5,
        height: 1.6,
        color: Colors.black87,
      ),
    ),
  ],
),

TextSpan(
  children: [
    const TextSpan(
      text: "\n17. INDEMNITY\n",
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
    ),

    const TextSpan(
      text:
          "The Distributor shall indemnify and keep harmless at all times the Company and its officials and representatives from and/or against all claims, demands, actions, proceedings, fines, expenses, penalties, and other liabilities of whatsoever nature made or brought against the Company and its officials or representatives as a consequence of any non-compliance on the part of the Distributor.\n\n",
      style: TextStyle(
        fontSize: 13.5,
        height: 1.6,
        color: Colors.black87,
      ),
    ),

    const TextSpan(
      text: "18. FORCE MAJEURE\n",
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
    ),

    const TextSpan(
      text:
          "Neither party shall be held responsible for non-fulfilment of its respective obligations under this Agreement due to the occurrence of one or more force majeure events, including but not limited to acts of God, war, flood, earthquakes, strikes not confined to the premises of the party, lockouts beyond the control of the party claiming force majeure, or any other causes beyond the reasonable control of the parties.\n\n",
      style: TextStyle(
        fontSize: 13.5,
        height: 1.6,
        color: Colors.black87,
      ),
    ),
  ],
),

TextSpan(
  children: [
    const TextSpan(
      text: "\n19. WARRANTY\n",
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
    ),

    const TextSpan(
      text:
          "The Company manufactures the Products as per the highest available quality standards. The Products manufactured and sold by the Company are duly tested and are suitable for the purpose recommended, if correctly applied in conformity with the label claim/instructions/leaflet. However, since the Company cannot exercise sufficient control over the end use or application by the user, the Company accepts no responsibility for any damage arising directly or indirectly from their inappropriate use. The Company shall not be responsible for any legal action initiated by the Department of Agriculture against the Company in the Distributor’s designated area due to inappropriate use of the Products.\n\n",
      style: TextStyle(
        fontSize: 13.5,
        height: 1.6,
        color: Colors.black87,
      ),
    ),

    const TextSpan(
      text: "20. TRADEMARKS\n",
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
    ),

    const TextSpan(
      text:
          "The Distributor shall not use or be deemed to have the right to use any trademark, trade name, colour scheme, or legend of the Company under which the Products are sold to the Distributor. Upon termination of this Agreement, the Distributor shall immediately discontinue the use, in any manner whatsoever, of all such trademarks, trade names, designs, colour schemes, or legends.\n\n",
      style: TextStyle(
        fontSize: 13.5,
        height: 1.6,
        color: Colors.black87,
      ),
    ),
  ],
),

TextSpan(
  children: [
    const TextSpan(
      text: "\n21. PRINCIPAL TO PRINCIPAL AGREEMENT\n",
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
    ),

    const TextSpan(
      text:
          "This Agreement is on a principal to principal basis and Distributor shall not in any way represent itself to be a Company’s agent. Company shall not be liable for any act or any omission on Distributor’s part. Distributor shall give an undertaking that it will market the Products supplied to it by Company and it shall not alter the labels of the containers or packages in any way and shall not deface, remove, obliterate or in any manner modify or alter the Trade Marks, grade indications and other matters appearing thereon.\n\n",
      style: TextStyle(
        fontSize: 13.5,
        height: 1.6,
        color: Colors.black87,
      ),
    ),

    const TextSpan(
      text: "22. DISPUTES AND JURISDICTION\n",
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
    ),

    TextSpan(
      text:
          "Any disputes arising between the Distributor and the Company shall be resolved by mutual discussion. Unresolved disputes, if any shall be referred to Arbitration by a sole Arbitrator to be appointed by the Company under the provisions of the Arbitration and Conciliation Act, 1996. The venue of Arbitration shall be _________. This Agreement shall be governed by the laws of India and subject to the jurisdiction of courts of ________.\n\n",
      style: TextStyle(
        fontSize: 13.5,
        height: 1.6,
        color: Colors.black87,
      ),
    ),

    const TextSpan(
      text:
          "IN WITHNESS WHEREOF the parties hereto have subscribed their hands to these presents on the day and month herein above first entered \n\n",
      style: TextStyle(
        fontSize: 13.5,
        height: 1.6,
        color: Colors.black87,
        fontWeight: FontWeight.w500,
      ),
    ),
  ],
),
TextSpan(
  children: [
    /// =======================
    /// 23. DUTIES / OBLIGATIONS OF DISTRIBUTOR
    /// =======================
    const TextSpan(
      text: "\n23. DUTIES / OBLIGATIONS OF DISTRIBUTOR\n",
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
    ),

    const TextSpan(
      text: "The Distributor shall:\n\n",
      style: TextStyle(
        fontSize: 13.5,
        height: 1.6,
        color: Colors.black87,
        fontWeight: FontWeight.w500,
      ),
    ),

    const TextSpan(
      text:
          "i) use its best efforts to sell and promote Products in the Territory, including (i) attendance by Distributor at trade shows at which Distributor shall promote the Products, (ii) listing the products in Distributor’s product lists and other marketing information.\n\n"
          "ii) protect Copyrights, Trade Marks and other proprietary rights of Company in the Products.\n\n"
          "iii) offer technical support of the products to its customers and to advise Company immediately if it is unable to respond to customer inquiries / complaints effectively.\n\n"
          "iv) Comply with all applicable laws and ordinances in performing its duties under this Agreement and in any of its dealings with Company or the Products. Distributor agrees that it will not export or re-export any products.\n\n"
          "v) sell the Products in compliance with the approved label claims.\n\n"
          "vi) not re sell the Products at prices higher than the maximum recommended retail prices stipulated by the Company from time to time.\n\n"
          "vii) when required by the Company, the distributor shall execute on its own behalf and or/on behalf of its associate/affiliate/subsidiary concerns guarantee/s in favour of the Company, in the form/s and for the amount/s determined by the Company and shall also renew such guarantee/s whenever due. Notwithstanding anything herein contained the Distributor shall furnish any additional Security, Bond or undertaking as may be required by the Company at its sole discretion.\n\n"
           "viii) being fully aware of the hazardous/toxic nature of the Products and shall undertake to comply with all statutory precautions and shall be solely responsible and liable for their safe custody at its storage points and their safe transportation and handling. Company shall not be liable or responsible for any loss, damage or injury incurred or suffered by the Distributor or any of its employee or workmen or contractor engage by it in the course of handling or transportation of the Products or otherwise however and the distributor shall at all times, indemnify and keep indemnified the Company from and against all claims, demands, fines, penalties, actions, proceedings and liabilities of whatsoever nature made, imposed, brought against or suffered by the Company by reason of any such loss, damage or injury aforesaid.\n\n"
      "ix) always maintain adequate stock during the term of this Agreement and shall submit Products inventory in detail to the Company within eight 8 (Eight) days from the end of each calendar month recording detail of the Inventory Products / stocked by the Distributor in the preceding colander month together with a statement showing the Products sold by it during such calendar month. The Distributor shall follow an annual marketing plan as per the requirement of the Company.\n\n"
      "x) from time to time advise the Company in writing of all local laws and regulations relating to the storage, sale and use of the Products.\n\n"
      "xi) observe and comply with all the applicable laws, orders, ordinances, notifications, rules, regulations, legislations or other enactments, or modifications thereof for the time being in force relating or in any wise appertaining to the performance by the Distributor of its duties and obligations under the Agreement. \n\n"
      "xii) maintain at his/its office / Shops / Godowns all Registers, books, Records as would be statutorily required under various laws and maintain infrastructure like computers/printer as may be required of him/it for facilitating the transfer of data/information to the Company.\n\n"
      "xiii) rotate the said Products on a first-in-first out basis. If any quantities of the said Products remain unsold and expired, then the same will be to the account of the Distributor only. The Distributor cannot force the Company to take back any expired stocks. \n\n"
      "xiv) not tamper with or in any way alter, modify, change, process, reprocess, adapt, or treat the Products and/or their packing and shall not sell / keep for sale or offer to sell/barter/ supply the said Products, as supplied by the Company, after the Expiry Date mentioned on the container, mark or label. \n\n"
      "xv) forthwith intimate the Company in the event of seizure of any Products by statutory Authority in the Territory and send all the documents in respect of the same. \n\n"
      "xvi) forthwith intimate the Company in the event of receipt of any Notice from the statutory Authority concerning misbranding etc. \n\n"
      "xvii) assist the Company in any matter as and when required by the Company in the Territory \n\n",
      style: TextStyle(
        fontSize: 13.5,
        height: 1.6,
        color: Colors.black87,
      ),
    ),
  ],
),

const TextSpan(
      text: "24. LEGAL REQUIREMENTS / COMPLIANCE\n",
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
    ),

    TextSpan(
      text:
          "Distributor shall be obliged to take all requisite registrations, licenses, permissions, etc., including but not limited to under the provisions of Seeds ACT-1966 & Seed act 1983,Insecticides Act,1968 & Rules framed there under, Fertilizer (Control) Orders, Legal Metrology Act, 2009 & Rules framed there under, Goods and Service Tax & Rules framed there under, any and all Central and State Acts or Rules which is mandatorily required for doing business for stocking, exhibiting, transporting, selling of the Products, before commencement of operations and submit copies of such registrations/licenses/permissions to the Company and should renew and keep the same valid from time to time. In case of any change of statutory provisions by way of any Acts, Order, Notifications etc. then it will be the sole responsibility of the Distributor to comply such provisions and to immediately intimate to the Company. Further, Distributor will also arrange a proper godown for storage of the said products and if any storage license is necessary such license from the concerned authority shall also be obtained by the Distributor in its own name and at its own cost.\n\n",
      style: TextStyle(
        fontSize: 13.5,
        height: 1.6,
        color: Colors.black87,
      ),
    ),


    TextSpan(
  children: [

    const TextSpan(
      text:
          "\n25. PROHIBITION AGAINST RE-FORMULATION OF THE PRODUCTS\n\n",
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
    ),

    const TextSpan(
      text:
          "Distributor under no circumstances breaks open the packages, containing the Products and re-sell them in their existing form or re-formulated, mixed or blended with any other goods.\n\n",
      style: TextStyle(
        fontSize: 13.5,
        height: 1.6,
        color: Colors.black87,
      ),
    ),

    const TextSpan(
      text: "26. PROHIBITION AGAINST COMPETITIVE MANUFACTURE\n\n",
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
    ),

    const TextSpan(
      text:
          "Distributor undertake not to, directly or indirectly, manufacture the Products or any of them by itself or through any third party / related party.\n\n",
      style: TextStyle(
        fontSize: 13.5,
        height: 1.6,
        color: Colors.black87,
      ),
    ),


    const TextSpan(
      text: "27. ASSIGNMENT:-\n\n",
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
    ),

    const TextSpan(
      text:
          "Distributor shall not assign, delegate or transfer any of the rights, duties or obligations under this Agreement without Company’s prior written consent.\n\n",
      style: TextStyle(
        fontSize: 13.5,
        height: 1.6,
        color: Colors.black87,
      ),
    ),


    const TextSpan(
      text: "28. NOTICE\n\n",
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
    ),

    const TextSpan(
      text:
          "Distributor shall forthwith inform Company of any change in its status (Proprietary, Partnership, Company etc.) location, telephone or fax number by giving written notice of such change.\n\n",
      style: TextStyle(
        fontSize: 13.5,
        height: 1.6,
        color: Colors.black87,
      ),
    ),
  ],
),
  
  TextSpan(
  children: [
    const TextSpan(
      text: "\n29. TERMINATION:-\n\n",
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
    ),

    const TextSpan(
      text:
          "a) Company reserves the right to terminate this Agreement by giving 30 (Thirty) days’ notice in writing without assigning any reason. Distributor also has right to terminate this Agreement by giving 90 (Ninety) days’ notice subject to the entire outstanding payments being cleared along with interest, if any, pertaining to all the supplies made to Distributor.\n\n"
          
          "b) Company shall be entitled to terminate this Agreement forthwith without any notice if Distributor is found to be violating the terms & conditions of this Agreement including dishonour of cheque or non – payment of any cheque / Invoice amount.\n\n"
          
          "c) Any termination or expiration of this Agreement shall be without prejudice to any claim, remedy or right of action, previously accrued to either party against the other. Provided further Company shall not be liable or responsible for payment of any compensation to the Distributor on this Agreement being terminated as per the provisions herein above.\n\n"
          
          "d) Upon expiration or termination of this Agreement, the Distributor shall forthwith return to the Company all Samples, display, photographs, brochures, and other printed sales promotional material and literature and other property to the Company. The Distributor further agrees to remove all signs or evidences of his/its relationship with Company on such expiration or termination.\n\n"
          
          "e) Upon termination of this Agreement for any reason the Company shall make and prepare a final account in respect of its dealings with the Distributor and shall submit such account statement in duplicate to the Distributor, any amount to be due payable under such account by the Distributor to Company shall be paid by Distributor within 8 (Eight) days from the date of submission of such account to the Distributor. The final account prepared by Company as aforesaid shall be final and binding upon the Distributor and shall not be called in question, except for any manifest error which may be apparent on the face thereof.\n\n"
          
          "f)Any notice contemplated hereunder shall be deemed to be properly made if served on its last known address in Distributor’s record.\n\n",
      style: TextStyle(
        fontSize: 13.5,
        height: 1.6,
        color: Colors.black87,
      ),
    ),
  ],
),

TextSpan(
  children: [
    const TextSpan(
      text: "\n30. DISPUTES AND JURISDICTION\n\n",
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
    ),

    const TextSpan(
      text:
          "Any disputes arising between the Distributor and the Company shall be resolved by mutual discussion. Unresolved disputes, if any shall be referred to Arbitration by a sole Arbitrator to be appointed by the Company under the provisions of the Arbitration and Conciliation Act, 1996. The venue of Arbitration shall be . This Agreement shall be governed by the laws of India and subject to the jurisdiction of courts of .\n\n",
      style: TextStyle(
        fontSize: 13.5,
        height: 1.6,
        color: Colors.black87,
      ),
    ),

    const TextSpan(
      text:
          "IN WITHNESS WHEREOF the parties hereto have subscribed their hands to these presents on the day and month herein above first entered\n\n",
      style: TextStyle(
        fontSize: 13.5,
        height: 1.6,
        fontWeight: FontWeight.w500,
        color: Colors.black87,
      ),
    ),



TextSpan(
  children: [
    /// FIRST BLOCK
    const TextSpan(text: "SIGNED and DELLIVERED for and on ", style: normal),
    const TextSpan(text: "JAMIDARA SEEDS CORPORATION", style: bold),
    const TextSpan(text: "\n\nBehalf of the with named Company ", style: normal),
    const TextSpan(text: "JAMIDARA SEEDS CORPORATION", style: bold),
    const TextSpan(
      text:
          "\n\nThrough its M.D:– Supply Chain_________________________________\n\n"
          "GM – Supply Chain )\n\n"
          "In the presence of (witnesses)\n\n"
          "1. ____________________________________\n\n"
          "2. ____________________________________\n\n",
      style: normal,
    ),

    /// SECOND BLOCK
    const TextSpan(text: "SIGNED and DELIVERED for and on ", style: normal),
    const TextSpan(text: "JAMIDARA SEEDS CORPORATION", style: bold),
    const TextSpan(text: "\n\nBehalf of the with named Company ", style: normal),
    const TextSpan(text: "JAMIDARA SEEDS CORPORATION", style: bold),
    const TextSpan(
      text:
          "\n\nThrough its M.D – Supply Chain\n\n"
          "GM – Supply Chain\n\n"
          "In the presence of (witnesses)\n\n"
          "1. ____________________\n\n"
          "2. ____________________\n\n",
      style: normal,
    ),
  ],
),

   TextSpan(
  children: [
    const TextSpan(
      text:
          "SIGNED and DELIVERED for and on For\n\n"
          "Behalf of the with named Distributor\n\n"
          "Through its PROPRIETOR\n\n"
          "______________________\n\n"
          "Name:",
      style: normal,
    ),

    ///  BOLD COMPANY NAME
    const TextSpan(
      text: "JAMIDARA SEEDS CORPORATION",
      style: bold,
    ),

    const TextSpan(
      text:
          "\n\nDesignation: PROPRIETOR\n\n"
          "In the presence of (witnesses)\n\n"
          "1. ____________________\n\n"
          "2. ____________________\n\n",
      style: normal,
    ),
  ],
),
  ],
),
      
      

      

        /// Hindi Terms (no highlight needed)
        const TextSpan(
          text: '''
TERMS AND CONDITIONS

1. कंपनी के खाते में भुगतान जमा होने के पश्चात 60 दिनों के भीतर माल उठाना अनिवार्य होगा। 60 दिनों के बाद बकाया राशि पर 24% वार्षिक ब्याज लागू किया जाएगा।

2. ₹50,000 तक के ऑर्डर पर ₹500 अतिरिक्त शुल्क लिया जाएगा। ₹50,000 से अधिक के ऑर्डर पर प्रत्येक ₹1000 पर ₹10 अतिरिक्त शुल्क देय होगा।

3. यदि माल कूरियर/परिवहन के माध्यम से भेजा जाता है, तो उसका भाड़ा (फ्रेट चार्ज) वितरक द्वारा वहन किया जाएगा।

4. माल भेजने की समस्त जिम्मेदारी वितरक की होगी। इस संबंध में कंपनी की कोई जिम्मेदारी नहीं होगी।

5. कूरियर/परिवहन के दौरान माल में किसी भी प्रकार की क्षति, देरी या हानि के लिए कंपनी उत्तरदायी नहीं होगी।

6. केवल सीलबंद (Sealed) पैक ही वापसी के लिए स्वीकार किए जाएंगे। पैक पर कंपनी का मूल लेबल होना अनिवार्य है।

7. किसी भी स्थिति में जमा राशि का नकद/ऑनलाइन रिफंड नहीं दिया जाएगा। वापसी की स्थिति में केवल उसी माल का समायोजन अगले वर्ष किया जाएगा।

8. माल कंपनी की प्रचलित नीति एवं रेट के अनुसार ही उपलब्ध कराया जाएगा। वितरक को प्रत्येक स्थिति में कंपनी की नीति का पालन करना अनिवार्य होगा।

9. किसी भी प्रकार के विवाद की स्थिति में कंपनी का निर्णय अंतिम एवं मान्य होगा।

10. क्षेत्र (Area) का निर्धारण कंपनी द्वारा किया जाएगा, जो सभी पक्षों पर बाध्यकारी होगा।
''',
        ),
        const TextSpan(
          text:
              'उपरोक्त सभी नियम एवं शर्तें दोनों पक्षों द्वारा स्वीकार की जाती हैं।',
        ),
      ],
    );
  }
}
