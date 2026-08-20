import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'dv_theme.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:flutter/services.dart';

class CreateWebsitePage extends StatefulWidget {
  const CreateWebsitePage({super.key});

  @override
  State<CreateWebsitePage> createState() => _CreateWebsitePageState();
}

class _CreateWebsitePageState extends State<CreateWebsitePage> {
  final TextEditingController siteNameController = TextEditingController();
  final TextEditingController vercelTokenController = TextEditingController();
  
  File? selectedHtmlFile;
  bool isDeploying = false;
  String statusLog = "";
  String? deployedUrl;
  double progressValue = 0.0;

  @override
  void initState() {
    super.initState();
  }

  Future<void> pickHtmlFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['html'],
      allowMultiple: false,
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        selectedHtmlFile = File(result.files.single.path!);
        statusLog = "✅ File HTML dipilih: ${path.basename(selectedHtmlFile!.path)}";
      });
    }
  }

  Future<void> deployToVercel() async {
    final siteName = siteNameController.text.trim();
    final vercelToken = vercelTokenController.text.trim();

    if (siteName.isEmpty) {
      setState(() {
        statusLog = "⚠️ Nama website wajib diisi!";
      });
      return;
    }

    if (vercelToken.isEmpty) {
      setState(() {
        statusLog = "⚠️ Token Vercel wajib diisi!";
      });
      return;
    }

    if (selectedHtmlFile == null) {
      setState(() {
        statusLog = "⚠️ Pilih file HTML terlebih dahulu!";
      });
      return;
    }

    setState(() {
      isDeploying = true;
      progressValue = 0.0;
      statusLog = "📤 Mengirim file ke Telegram...";
    });

    try {
      String htmlContent = await selectedHtmlFile!.readAsString();
      
      setState(() {
        progressValue = 0.3;
        statusLog = "🚀 Membuat project di Vercel...";
      });

      final projectResponse = await http.post(
        Uri.parse('https://api.vercel.com/v10/projects'),
        headers: {
          'Authorization': 'Bearer $vercelToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'name': siteName,
          'framework': 'static',
        }),
      );

      if (projectResponse.statusCode != 200 && projectResponse.statusCode != 201) {
        throw Exception('Gagal membuat project Vercel');
      }

      setState(() {
        progressValue = 0.6;
        statusLog = "📦 Mempersiapkan deployment...";
      });

      final deploymentPayload = {
        'name': siteName,
        'target': 'production',
        'files': [
          {
            'file': '/index.html',
            'data': htmlContent,
          }
        ],
      };

      setState(() {
        progressValue = 0.8;
        statusLog = "⚡ Sedang deploy ke Vercel...";
      });

      final deploymentResponse = await http.post(
        Uri.parse('https://api.vercel.com/v13/deployments'),
        headers: {
          'Authorization': 'Bearer $vercelToken',
          'Content-Type': 'application/json',
        },
        body: json.encode(deploymentPayload),
      );

      if (deploymentResponse.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(deploymentResponse.body);
        final String url = responseData['url'] ?? '$siteName.vercel.app';
        
        setState(() {
          progressValue = 1.0;
          deployedUrl = 'https://$url';
          statusLog = "✅ Website berhasil dideploy!";
          isDeploying = false;
        });
      } else {
        throw Exception('Deployment gagal');
      }
    } catch (e) {
      setState(() {
        statusLog = "❌ Error: $e";
        isDeploying = false;
        progressValue = 0.0;
      });
    }
  }

  void copyDeployedUrl() {
    if (deployedUrl != null) {
      Clipboard.setData(ClipboardData(text: deployedUrl!));
      setState(() {
        statusLog = "📋 URL berhasil disalin ke clipboard!";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DV.bg0,
      appBar: AppBar(
        title: ShaderMask(shaderCallback: (b) => DV.fireGradient.createShader(b), child: const Text("CREATE WEBSITE", style: TextStyle(color: Colors.white, fontFamily: "Orbitron", fontWeight: FontWeight.w800, fontSize: 14))), centerTitle: true,
        backgroundColor: DV.orange,
        iconTheme: const IconThemeData(color: DV.textPrimary),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            _buildInputCard(
              "Nama Website",
              siteNameController,
              Icons.web,
              "contoh: mywebsite",
            ),
            
            const SizedBox(height: 12),
            
            _buildInputCard(
              "Vercel Token",
              vercelTokenController,
              Icons.vpn_key,
              "Masukkan token Vercel Anda",
              isPassword: true,
            ),
            
            const SizedBox(height: 20),
            
            GestureDetector(
              onTap: isDeploying ? null : pickHtmlFile,
              child: Container(
                height: 180,
                decoration: BoxDecoration(
                  color: DV.bg1,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: selectedHtmlFile != null ? DV.orange : DV.bg2,
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      selectedHtmlFile != null ? Icons.check_circle : Icons.upload_file,
                      color: selectedHtmlFile != null ? DV.orange : DV.textHint,
                      size: 64,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      selectedHtmlFile != null 
                          ? path.basename(selectedHtmlFile!.path)
                          : "Tap untuk memilih file HTML",
                      style: TextStyle(
                        color: selectedHtmlFile != null ? Colors.white : DV.textHint,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (selectedHtmlFile != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          "Wajib bernama index.html",
                          style: TextStyle(color: DV.warning, fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: DV.bg1.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: DV.orange.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning_amber, color: DV.warning),
                      const SizedBox(width: 8),
                      const Text(
                        "📌 Syarat & Ketentuan",
                        style: TextStyle(color: DV.textPrimary, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildTerm("File wajib bernama index.html"),
                  _buildTerm("Dilarang upload konten ilegal"),
                  _buildTerm("Semua website bersifat publik"),
                  _buildTerm("Token Vercel Anda aman disimpan lokal"),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            if (isDeploying)
              Column(
                children: [
                  LinearProgressIndicator(
                    value: progressValue,
                    backgroundColor: DV.bg2,
                    color: DV.orange,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "${(progressValue * 100).toStringAsFixed(0)}%",
                    style: TextStyle(color: DV.textPrimary),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isDeploying ? null : deployToVercel,
                icon: isDeploying
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: DV.textPrimary,
                        ),
                      )
                    : const Icon(Icons.rocket_launch),
                label: Text(isDeploying ? "Sedang Deploy..." : "🚀 Deploy Sekarang"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: DV.orangeDark,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: DV.bg1,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: DV.orange.withOpacity(0.2)),
              ),
              child: Text(
                statusLog,
                style: const TextStyle(color: DV.textPrimary),
                textAlign: TextAlign.center,
              ),
            ),
            
            const SizedBox(height: 20),
            
            if (deployedUrl != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: DV.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: DV.success.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: DV.success),
                        const SizedBox(width: 8),
                        const Text(
                          "✅ Website Berhasil Dibuat!",
                          style: TextStyle(
                            color: DV.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: copyDeployedUrl,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: DV.bg0.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: DV.success.withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: SelectableText(
                                deployedUrl!,
                                style: const TextStyle(
                                  color: DV.textPrimary,
                                  fontSize: 14,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.copy, color: DV.success, size: 20),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: copyDeployedUrl,
                        icon: const Icon(Icons.copy),
                        label: const Text("Copy URL"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: DV.success,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            
            const SizedBox(height: 20),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: DV.bg1,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: DV.orange.withOpacity(0.1)),
              ),
              child: Column(
                children: [
                  const Text(
                    "✨ Powered by Ziferr Ganteng",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.telegram, color: DV.orange, size: 16),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                        },
                        child: const Text(
                          "Telegram: @sumpil666",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "© ${DateTime.now().year} Zifer",
                    style: TextStyle(color: DV.textHint, fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputCard(
    String label,
    TextEditingController controller,
    IconData icon,
    String hint, {
    bool isPassword = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DV.bg1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DV.orange.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: DV.orange, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(color: DV.textPrimary, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            style: const TextStyle(color: DV.textPrimary),
            obscureText: isPassword,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: DV.textHint),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: DV.orange.withOpacity(0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: DV.orange.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: DV.orange),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTerm(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.circle, size: 6, color: Colors.white70),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: DV.textSecondary, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}