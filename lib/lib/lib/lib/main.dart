import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'database_helper.dart';
import 'rule_engine.dart';
import 'offline_transfer.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CardioApp());
}

class CardioApp extends StatelessWidget {
  const CardioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CardioApp',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const MainDashboard(),
    );
  }
}

class MainDashboard extends StatefulWidget {
  const MainDashboard({super.key});

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  List<Map<String, dynamic>> _patients = [];
  List<Map<String, dynamic>> _modules = [];
  String _qrData = 'CARDIO_INIT';
  bool _hasHTA = true;
  bool _isRamadan = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final patients = await DatabaseHelper.instance.getPatients();
    final modules = await DatabaseHelper.instance.getModules();
    setState(() {
      _patients = patients;
      _modules = modules;
      _updateQR();
    });
  }

  void _updateQR() {
    final activeModules = RuleEngine.evaluate(
      hasHTA: _hasHTA,
      hasCoronary: false,
      isRamadanPeriod: _isRamadan,
    );
    setState(() {
      _qrData = OfflineTransfer.generateQrPayload('PAT-DEMO-001', activeModules);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CardioApp - Tableau de Bord Consultation'),
        backgroundColor: Colors.blueGrey[900],
        foregroundColor: Colors.white,
      ),
      body: Row(
        children: [
          // Panneau Gauche : Sélection Médecin
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView(
                children: [
                  const Text('Profil Patient (Consultation)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  SwitchListTile(
                    title: const Text('Hypertension Artérielle (HTA)'),
                    value: _hasHTA,
                    onChanged: (val) {
                      setState(() { _hasHTA = val; _updateQR(); });
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Conseils Jeûne & Ramadan'),
                    value: _isRamadan,
                    onChanged: (val) {
                      setState(() { _isRamadan = val; _updateQR(); });
                    },
                  ),
                  const Divider(),
                  const Text('Modules activés dans la fiche :', style: TextStyle(fontWeight: FontWeight.bold)),
                  ..._modules.map((m) => ListTile(
                    leading: const Icon(Icons.check_circle, color: Colors.green),
                    title: Text(m['titre_fr']),
                    subtitle: Text(m['titre_ar'], textDirection: TextDirection.rtl),
                  )),
                ],
              ),
            ),
          ),
          const VerticalDivider(width: 1),
          // Panneau Droit : Transfert Hors-ligne (QR Code)
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.grey[100],
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Transfert Hors-Ligne', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  const Text('Faites scanner ce code au patient depuis son smartphone :', textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  QrImageView(
                    data: _qrData,
                    version: QrVersions.auto,
                    size: 220.0,
                  ),
                  const SizedBox(height: 15),
                  Chip(
                    label: Text('Jeton : ${_qrData.substring(0, 12)}...'),
                    backgroundColor: Colors.blue[100],
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
