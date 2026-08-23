// --- COPIE TOUT CE CODE CI-DESSOUS DANS TON FICHIER LIB/MAIN.DART ---
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'database_helper.dart'; // Assure-toi que ce fichier existe aussi dans lib/
import 'rule_engine.dart';    // Assure-toi que ce fichier existe aussi dans lib/
import 'offline_transfer.dart'; // Assure-toi que ce fichier existe aussi dans lib/

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
  bool _hasHTA = true; // Exemple de facteur de risque activé par défaut
  bool _isRamadan = true; // Exemple activé par défaut

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Initialise la base de données et charge les données démo
    final dbHelper = DatabaseHelper.instance;
    final patients = await dbHelper.getPatients();
    final modules = await dbHelper.getModules();
    
    // Si pas de données démo, on les insère (première fois)
    if (patients.isEmpty && modules.isEmpty) {
        await dbHelper.seedDatabase(); // Appelle la fonction de seed
        // Recharge les données après insertion
        final updatedPatients = await dbHelper.getPatients();
        final updatedModules = await dbHelper.getModules();
        setState(() {
            _patients = updatedPatients;
            _modules = updatedModules;
            _updateQR();
        });
    } else {
        setState(() {
          _patients = patients;
          _modules = modules;
          _updateQR();
        });
    }
  }

  void _updateQR() {
    // Le médecin sélectionne les critères, le moteur de règle choisit les modules
    final activeModules = RuleEngine.evaluate(
      hasHTA: _hasHTA,
      hasCoronary: false, // Exemple
      isRamadanPeriod: _isRamadan,
    );
    
    setState(() {
      // Génère le payload du QR Code
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
          // Panneau Gauche : Sélection Médecin & Liste des Modules
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView(
                children: [
                  const Text('Profil Patient (Consultation)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  // Section pour activer/désactiver les critères
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
                  const Text('Modules activés dans la fiche patient :', style: TextStyle(fontWeight: FontWeight.bold)),
                  // Affiche dynamiquement les modules sélectionnés
                  ..._modules.where((m) => RuleEngine.evaluate(hasHTA: _hasHTA, hasCoronary: false, isRamadanPeriod: _isRamadan).contains(m['id'])).map((m) => ListTile(
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
                  // Affiche le QR Code généré
                  QrImageView(
                    data: _qrData,
                    version: QrVersions.auto,
                    size: 220.0,
                    gapless: false,
                    embeddedImage: const AssetImage('assets/images/logo_heart.png'), // Optionnel
                    embeddedImageStyle: const QrEmbeddedImageStyle(size: Size(40, 40)),
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
