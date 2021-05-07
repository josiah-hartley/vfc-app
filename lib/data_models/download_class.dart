import 'package:dio/dio.dart';
import 'package:voices_for_christ/data_models/message_class.dart';

class Download {
  Message message;
  CancelToken cancelToken;
  int bytesReceived;
  int size;

  Download({
    this.message,
    this.cancelToken,
    this.bytesReceived,
    this.size,
  });
}