// screen/ocr_medicine_scanner.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';

class OcrMedicineScanner extends StatefulWidget {
  const OcrMedicineScanner({super.key});

  @override
  _OcrMedicineScannerState createState() => _OcrMedicineScannerState();
}

class _OcrMedicineScannerState extends State<OcrMedicineScanner> {
  File? _image;
  Map<String, String> extractedData = {};
  String qrData = "";

  final ImagePicker _picker = ImagePicker();
  final textRecognizer = TextRecognizer();

  List<String> medicineNames = [
    "Paracetamol",
    "Ibuprofen",
    "Amoxicillin",
    "Cetirizine",
    "Loperamide",
    "Mefenamic Acid",
    "Losartan",
    "Metformin",
    "Salbutamol",
    "Omeprazole",
    "Aspirin",
    "Cotrimoxazole",
    "Dextromethorphan",
    "Diphenhydramine",
    "Domperidone",
    "Hydroxyzine",
    "Ciprofloxacin",
    "Doxycycline",
    "Carbocisteine",
    "Ambroxol",
    "Clarithromycin",
    "Ranitidine",
    "Simvastatin",
    "Amlodipine",
    "Metoprolol",
    "Hydrochlorothiazide",
    "Candesartan",
    "Glibenclamide",
    "Levothyroxine",
    "Prednisone",
  ];

  Map<String, String> keywordMapping = {
    "Exp:": "Expiration Date",
    "Exp Date": "Expiration Date",
    "Exp.": "Expiration Date",
    "Expiring": "Expiration Date",
    "Expires": "Expiration Date",
    "Valid Until": "Expiration Date",
  };

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
      _processImage();
    }
  }

  Future<void> _processImage() async {
    if (_image == null) return;
    final inputImage = InputImage.fromFile(_image!);
    final RecognizedText recognizedText = await textRecognizer.processImage(
      inputImage,
    );

    Map<String, String> detectedData = {
      "Medicine Name": "",
      "Brand Name": "",
      "Item": "",
      "Milligram": "",
      "Type of Drug": "",
      "Expiration Date": "",
      "Quantity": "",
    };

    // Possible Expiration Date and other keywords
    Map<String, String> keywordMapping = {
      r"\bExp[:.]?\s*(\d{4}-\d{2}-\d{2}|\d{2}/\d{2}/\d{4})": "Expiration Date",
      r"\bExpires[:.]?\s*(\d{4}-\d{2}-\d{2}|\d{2}/\d{2}/\d{4})":
          "Expiration Date",
      r"\bValid Until[:.]?\s*(\d{4}-\d{2}-\d{2}|\d{2}/\d{2}/\d{4})":
          "Expiration Date",
      r"\bQty[:.]?\s*(\d+)": "Quantity",
      r"\bQuantity[:.]?\s*(\d+)": "Quantity",
      r"\bDose[:.]?\s*(\d+mg|\d+\s*mg)": "Milligram",
      r"\bDosage[:.]?\s*(\d+mg|\d+\s*mg)": "Milligram",
      r"\bStrength[:.]?\s*(\d+mg|\d+\s*mg)": "Milligram",
      r"\bType[:.]?\s*(\w+\s*\w*)": "Type of Drug",
      r"\bDrug Type[:.]?\s*(\w+\s*\w*)": "Type of Drug",
    };

    // Predefined Brand Names
    Map<String, String> brandNames = {
      "Paracetamol": "Biogesic",
      "Ibuprofen": "Advil",
      "Amoxicillin": "Amoxil",
      "Cetirizine": "Virlix",
      "Loperamide": "Imodium",
      "Mefenamic Acid": "Dolfenal",
      "Losartan": "Lifezar",
      "Metformin": "Glucophage",
      "Salbutamol": "Ventolin",
      "Omeprazole": "Losec",
    };

    // List of possible "Item" values
    List<String> itemTypes = [
      "Tablet",
      "Capsule",
      "Syrup",
      "Injection",
      "Cream",
      "Gel",
    ];

    for (TextBlock block in recognizedText.blocks) {
      for (TextLine line in block.lines) {
        String text = line.text.trim();

        // Hanapin gamit ang Regular Expressions
        for (String pattern in keywordMapping.keys) {
          RegExp regExp = RegExp(pattern, caseSensitive: false);
          Match? match = regExp.firstMatch(text);
          if (match != null) {
            detectedData[keywordMapping[pattern]!] = match.group(1) ?? "";
          }
        }

        // Hanapin ang Medicine Name at Brand Name
        for (String medicine in medicineNames) {
          if (text.contains(medicine)) {
            detectedData["Medicine Name"] = medicine;
            detectedData["Brand Name"] = brandNames[medicine] ?? "Unknown";
          }
        }

        // Hanapin kung anong uri ng gamot ito (Tablet, Capsule, etc.)
        for (String item in itemTypes) {
          if (text.contains(item)) {
            detectedData["Item"] = item;
          }
        }
      }
    }

    setState(() {
      extractedData = detectedData;
      qrData = extractedData.entries
          .map((e) => "${e.key}: ${e.value}")
          .join("\n");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Baramed Scanner")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_image != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.file(
                  _image!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children:
                      extractedData.entries.map((entry) {
                        return Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            title: Text(
                              entry.key,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              entry.value.isNotEmpty
                                  ? entry.value
                                  : "Not Detected",
                            ),
                            leading: Icon(
                              Icons.medication,
                              color: Colors.blueAccent,
                            ),
                          ),
                        );
                      }).toList(),
                ),
              ),
            ),
            if (qrData.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                "Generated QR Code",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              QrImageView(data: qrData, version: QrVersions.auto, size: 100),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: const Text("Gallery"),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text("Take Picture"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
