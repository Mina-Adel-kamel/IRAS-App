import 'package:flutter/material.dart';

// ألوان الهوية البصرية لـ IRAS
const Color kPageBg     = Color(0xFF030810);
const Color kCardBg     = Color(0xFF070F1E); // المربع الداخلي
const Color kCardBorder = Color(0xFF0F1E35); // لون الحدود
const Color kAccent     = Color(0xFFCAF135); // لون IRAS الفسفوري
const Color kSubText    = Color(0xFF5C7A99); // النصوص الفرعية

class DocumentationScreen extends StatefulWidget {
  const DocumentationScreen({super.key});

  @override
  State<DocumentationScreen> createState() => _DocumentationScreenState();
}

class _DocumentationScreenState extends State<DocumentationScreen> {
  int _activeTabIndex = 0;

  final List<String> _tabs = [
    "Welcome",
    "Alert triage",
    "Alert Classification",
    "Alert Reporting",
    "Company information",
    "Asset Inventory"
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPageBg,
      body: Theme(
        data: Theme.of(context).copyWith(
          scrollbarTheme: ScrollbarThemeData(
            thumbColor: WidgetStateProperty.all(kAccent.withOpacity(0.7)), // شريط التمرير بلون IRAS
            thickness: WidgetStateProperty.all(4.0),
            radius: const Radius.circular(2),
          ),
        ),
        child: Scrollbar(
          thumbVisibility: true,
          child: SingleChildScrollView(
            primary: true,
            padding: const EdgeInsets.all(30.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // الهيدر الأساسي
                const Text(
                  "Documentation",
                  style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Guides & playbooks",
                  style: TextStyle(color: kSubText, fontSize: 13),
                ),
                const SizedBox(height: 25),

                // شريط التبويبات العلوي
                _buildTabBar(),
                const SizedBox(height: 25),

                // المربع الكبير (الحاوية الرئيسية للمحتوى) - نظام مربع داخل مربع
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(25.0),
                  decoration: BoxDecoration(
                    color: kCardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kCardBorder),
                  ),
                  child: _buildActiveTabContent(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // شريط التبويبات
  Widget _buildTabBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(_tabs.length, (index) {
          bool isActive = index == _activeTabIndex;
          return GestureDetector(
            onTap: () => setState(() => _activeTabIndex = index),
            child: Container(
              margin: const EdgeInsets.only(right: 20),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isActive ? kAccent : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Text(
                _tabs[index],
                style: TextStyle(
                  color: isActive ? Colors.white : kSubText,
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // محتوى التبويب النشط
  Widget _buildActiveTabContent() {
    switch (_activeTabIndex) {
      case 0: return _buildWelcome();
      case 1: return _buildAlertTriage();
      case 2: return _buildAlertClassification();
      case 3: return _buildAlertReporting();
      case 4: return _buildCompanyInformation();
      case 5: return _buildAssetInventory();
      default: return Container();
    }
  }

  // 1. Welcome
  Widget _buildWelcome() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title("Welcome"),
        _body("Get ready to step into the shoes of a Security Operations Center (SOC) analyst. This platform simulates real-world scenarios where you'll receive alerts, investigate them as needed, and take appropriate actions to resolve or close them."),
        _body("Since this is a simulation, alerts may not arrive in rapid succession — delays are intentional to mirror a realistic workflow and give you time to think through each case."),
        const SizedBox(height: 15),
        
        // مربع داخل مربع
        _innerContainer(
          title: "How to use this documentation",
          child: Column(
            children: [
              _bullet("Read the Alert triage guide to understand initial steps when an alert is received."),
              _bullet("Follow the Alert Classification guidance when marking alerts as True Positive or False Positive."),
              _bullet("Use the Alert Reporting guide to write clear, useful case reports."),
              _bullet("Refer to Company information and Asset Inventory when identifying impacted hosts or users."),
            ],
          ),
        ),
      ],
    );
  }

  // 2. Alert Triage
  Widget _buildAlertTriage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title("Alert triage"),
        _innerContainer(
          title: "Read Before You Begin",
          child: Column(
            children: [
              _bullet("Check out the Alert Triage Playbook described in this documentation."),
              _bullet("Assign the earliest alert to yourself to start the investigation."),
              _bullet("Review the alert details and any provided IOCs (IPs, domains, filenames)."),
              _bullet("Use the SIEM and Analyst VM tools to gather more context and evidence."),
            ],
          ),
        ),
        const SizedBox(height: 25),
        _subTitle("Alert Triage Playbook"),
        const SizedBox(height: 15),
        _body("1. Initial Alert Review:"),
        _bullet("Access the SOC Dashboard: Review the new alerts and their severity."),
        _bullet("Assign Alert to Yourself: Add the alert to your assigned list."),
        _bullet("Understand Alert Logic: Read the rule description and expected behavior."),
        _bullet("Review Alert Details: Check all attached IOCs and quick context."),
        const SizedBox(height: 15),
        _body("2. Investigate in the SIEM:"),
        _bullet("Access the SIEM: Query logs to build a timeline."),
        _bullet("Query Related Logs: Correlate endpoints, user, and network data."),
        _bullet("Use Analyst VM: Run lookups and threat-intel checks."),
        _bullet("Correlate: Verify whether activity is anomalous or expected."),
        const SizedBox(height: 15),
        _body("3. Resolution and Closure:"),
        _bullet("Decide on Classification: True Positive or False Positive."),
        _bullet("Write Case Report: Document evidence, actions, and recommendations."),
        _bullet("Escalate if Needed: If remediation is required (isolate host, password reset)."),
        _bullet("Close the Alert: Submit the case report and close in the dashboard."),
      ],
    );
  }

  // 3. Alert Classification
  Widget _buildAlertClassification() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title("Alert Classification"),
        _innerContainer(
          title: "True Positive",
          child: _body("Classification for confirmed unauthorized access or malicious activity — e.g., malware, credential theft, data exfiltration. True Positives normally require remediation such as host isolation, password rotation, or malware cleanup."),
        ),
        const SizedBox(height: 15),
        _innerContainer(
          title: "False Positive",
          child: _body("Classification for activity determined to be legitimate or benign (no malicious intent). False Positives are useful for tuning detection rules and improving coverage."),
        ),
        const SizedBox(height: 25),
        _subTitle("Classification Examples"),
        const SizedBox(height: 15),
        _body("Rule: \"Windows Account Brute Force\""),
        _bullet("True Positive: Repeated failed attempts from an external IP, followed by successful login from that IP."),
        _bullet("False Positive: A legitimate scheduled script performed password validations and triggered the rule."),
        const SizedBox(height: 15),
        _body("Rule: \"Login from Unfamiliar Location\""),
        _bullet("True Positive: Login from a foreign datacenter IP to a critical account."),
        _bullet("False Positive: User connecting via corporate VPN node in another region."),
        const SizedBox(height: 25),
        _subTitle("Alert Escalation"),
        _body("If the alert is a True Positive and requires immediate action, follow escalation procedures: notify SOC Lead, isolate affected hosts, and open a remediation incident in the tracker."),
      ],
    );
  }

  // 4. Alert Reporting
  Widget _buildAlertReporting() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title("Alert Reporting"),
        _body("Good reporting makes remediation and future detection easier. Include the following in every case report:"),
        const SizedBox(height: 10),
        _bullet("Who/What: The identities and assets affected."),
        _bullet("Where: The network location, host, or service impacted."),
        _bullet("When: Time range of the activity."),
        _bullet("IOCs: IPs, domains, file hashes, ports, and other indicators."),
        _bullet("Actions taken: Containment, eradication, and recovery steps."),
        const SizedBox(height: 25),
        _subTitle("Best Practice Reports"),
        _body("Include clear recommendations and context — e.g., \"Immediate isolation required: host X shows active C2 traffic at time Y.\""),
        const SizedBox(height: 15),
        _body("Example: True Positive — \"Windows Account Brute Force\""),
        _body("This activity is classified as a True Positive because multiple failed attempts from IP 211.219.22.213 ... (example text for the report body)."),
        const SizedBox(height: 15),
        _body("Example: False Positive — \"Windows Account Brute Force\""),
        _body("This activity is classified as a False Positive because investigation shows the user's account used an expired password and the failures are consistent with scheduled jobs."),
      ],
    );
  }

  // 5. Company Information (تم حل إيرور الـ TableRow هنا)
  Widget _buildCompanyInformation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title("Company information"),
        _body("Useful static information to reference during investigations."),
        const SizedBox(height: 20),
        
        _innerContainer(title: "Firewall", child: _body("Firewall: Firewall logs from company's main firewall. Use the firewall console for block/allow evidence.")),
        const SizedBox(height: 15),
        _innerContainer(title: "Analyst Workstation", child: _body("Analysts have access to the TryDetectThis VM via the Analyst VM portal. Use it for lookups and sandboxing suspicious files.")),
        const SizedBox(height: 25),
        
        _subTitle("Employees"),
        const SizedBox(height: 10),
        
        // جدول الموظفين بحدود واضحة ومحددة
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: kCardBorder),
          ),
          child: Table(
            border: TableBorder.all(color: kCardBorder, width: 1),
            children: [
              // السطر الأول (الهيدر) واخد لون خلفية غامق عن طريق الـ decoration
              TableRow(
                decoration: const BoxDecoration(
                  color: Color(0xFF040B14),
                ),
                children: [
                  _tableHeader("Name"), _tableHeader("Department"), _tableHeader("Email"), _tableHeader("Logged-in Host"), _tableHeader("IP Address"),
                ],
              ),
              _tableRow(["Ethan Johnson", "Editorial", "e.johnson@thetrydaily.thm", "win-3451", "10.20.2.1"]),
              _tableRow(["Julia Garcia", "Content", "j.garcia@thetrydaily.thm", "win-3452", "10.20.2.8"]),
              _tableRow(["Isabella Martinez", "Marketing", "i.martinez@thetrydaily.thm", "win-3453", "10.20.2.9"]),
            ],
          ),
        ),
      ],
    );
  }

  // 6. Asset Inventory
  Widget _buildAssetInventory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title("Asset Inventory"),
        _body("Known network ranges and asset purpose used for triage and containment decisions."),
        const SizedBox(height: 20),
        
        _subTitle("Network and Subnets"),
        const SizedBox(height: 10),
        
        // جدول الشبكات بحدود واضحة ومحددة
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: kCardBorder),
          ),
          child: Table(
            border: TableBorder.all(color: kCardBorder, width: 1),
            children: [
              TableRow(
                decoration: const BoxDecoration(
                  color: Color(0xFF040B14),
                ),
                children: [
                  _tableHeader("Purpose"), _tableHeader("Range"),
                ],
              ),
              _tableRow(["Office Network", "10.20.2.0/24"]),
            ],
          ),
        ),
        const SizedBox(height: 25),
        
        _innerContainer(
          title: "Hosts of interest",
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _body("win-3451 — Editor workstation (10.20.2.1)"),
              _body("win-3453 — Marketing (10.20.2.9)"),
              _body("trydetect-vm — Analyst VM (internal)"),
            ],
          ),
        ),
      ],
    );
  }

  // ── الأدوات المساعدة لبناء الشكل بالملي (Helper Widgets) ───────

  Widget _title(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
    );
  }

  Widget _subTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
    );
  }

  Widget _body(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.6)),
    );
  }

  // النقطة بداية السطر بالظبط وبلون IRAS
  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6, right: 8),
            child: Icon(Icons.circle, color: kAccent, size: 6), // نقطة بداية السطر بلون IRAS
          ),
          Expanded(
            child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.5)),
          ),
        ],
      ),
    );
  }

  // ويدجت المربع داخل مربع
  Widget _innerContainer({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kPageBg, // لون أغمق كأنه مربع داخل مربع
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: kAccent, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _tableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  TableRow _tableRow(List<String> cells) {
    return TableRow(
      children: cells.map((cell) => Padding(
        padding: const EdgeInsets.all(12.0),
        child: Text(cell, style: const TextStyle(color: Colors.white, fontSize: 12)),
      )).toList(),
    );
  }
}