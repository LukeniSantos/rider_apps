import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class RequestAssistat {
  static Future<dynamic> getRequest(String url) async {
    http.Response response = await http.get(Uri.parse(url));

    try {
      if (response.statusCode == 200) {
        String jSonData = response.body;
        var decodeData = jsonDecode(jSonData);
        return decodeData;
      } else {
        return "Falhou";
      }
    } catch (e) {
      return "Falhou";
    }
  }
}
