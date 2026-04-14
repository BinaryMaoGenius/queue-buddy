import 'package:http/http.dart' as http;

void main() async {
  final url = "https://router.huggingface.co/hf-inference/models/openai/whisper-tiny";
  final token = "YOUR_HF_TOKEN_HERE";
  
  final dummyWav = <int>[82, 73, 70, 70, 36, 0, 0, 0, 87, 65, 86, 69, 102, 109, 116, 32, 16, 0, 0, 0, 1, 0, 1, 0, 64, 31, 0, 0, 64, 31, 0, 0, 1, 0, 8, 0, 100, 97, 116, 97, 0, 0, 0, 0];
  
  try {
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/octet-stream',
        'Authorization': 'Bearer $token',
      },
      body: dummyWav,
    );
    print("Status: ${response.statusCode}");
    print("Body: ${response.body.length > 200 ? response.body.substring(0, 200) : response.body}");
  } catch (e) {
    print("Exception: $e");
  }
}
