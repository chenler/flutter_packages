import 'dart:io';

import 'package:dio/dio.dart';

typedef OnErrorCallback =  Function(String msg, int code);
typedef GetAuthorizationHeader = String Function();

class HttpManager {
  final int _CONNECTION_TIMEOUT = 5000;
  final int _RECEIVE_TIMEOUT = 3000;
  static OnErrorCallback _onErrorCallback;
  static GetAuthorizationHeader _getAuthorizationHeader;

  static HttpManager _instance;
  Dio _dio;
  BaseOptions _options;

  static void Init(OnErrorCallback onErrorCallback, GetAuthorizationHeader getAuthorizationHeader) {
    _onErrorCallback = onErrorCallback;
    _getAuthorizationHeader = getAuthorizationHeader;
  }

  static HttpManager getInstance(String BaseUrl) {
    if (null == _instance) {
      _instance = new HttpManager(BaseUrl);
      return _instance;
    }
    return _instance;
  }


  HttpManager(String BaseUrl) {
    _options = new BaseOptions(
      baseUrl: BaseUrl,
      connectTimeout: _CONNECTION_TIMEOUT,
      receiveTimeout: _RECEIVE_TIMEOUT,
      headers: {
      },
      contentType: Headers.formUrlEncodedContentType,
      responseType: ResponseType.json
    );
    _dio = new Dio(_options);
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (RequestOptions options) {
        // 设置token
        var headers = options.headers;
        var token = _getAuthorizationHeader();
        print("get token:$token");
        if (!(null == token || token == "")) {
          headers[HttpHeaders.authorizationHeader] = token;
        }
        options.headers = headers;
        print("--> [${options.method}] ${options.uri} | data: ${options.data}");
        return options;
      },
      onResponse: (Response response) {
        print("<-- [${response.statusCode}] ${response.request.uri} | data: ${response.data} ");
        return response;
      },
      onError: (DioError e) {
        print("在错误之前的拦截信息");
        formatError(e);
        return e;
      }
    ));
  }
  
  get(url, {data, options, cancelToken}) async {
    Response response;
    try {
      response = await _dio.get(url, queryParameters: data, options: options, cancelToken: cancelToken);
      print("getHttp response: $response");
    } on DioError catch(e) {
      print('getHttp exception: $e');
      formatError(e);
    }
    return response;
  }

  post(url,{params,options,cancelToken}) async {
    Response response;
    try {
      response = await _dio.post(url, queryParameters: params,
          options: options,
          cancelToken: cancelToken);
      print('postHttp response: $response');
    } on DioError catch (e) {
      print('postHttp exception: $e');
      formatError(e);
    }
    return response;
  }

  //post Form请求
  postForm(url,{data,options,cancelToken}) async{
    Response response;
    try{
      response = await _dio.post(url,options: options,cancelToken: cancelToken,data: data);
      print('postHttp response: $response');
    }on DioError catch(e){
      print('postHttp exception: $e');
      formatError(e);
    }
    return response;
  }

  //下载文件
  downLoadFile(urlPath,savePath) async{
    Response response;
    try{
      response = await _dio.download(urlPath, savePath,onReceiveProgress: (int count,int total){
        print('$count $total');
      });
      print('downLoadFile response: $response');
    }on DioError catch(e){
      print('downLoadFile exception: $e');
      formatError(e);
    }
    return response;
  }

  //取消请求
  cancleRequests(CancelToken token){
    token.cancel("cancelled");
  }


  void formatError(DioError e) {
    if (e.type == DioErrorType.CONNECT_TIMEOUT) {
      print("连接超时");
      _onErrorCallback("连接服务器超时", 502);
    } else if (e.type == DioErrorType.SEND_TIMEOUT) {
      print("请求超时");
      _onErrorCallback("请求服务器超时", 502);
    } else if (e.type == DioErrorType.RECEIVE_TIMEOUT) {
      print("响应超时");
      _onErrorCallback("服务器响应超时", 502);
    } else if (e.type == DioErrorType.RESPONSE) {
      print("出现异常");
      _onErrorCallback("服务器出错", 500);
    } else if (e.type == DioErrorType.CANCEL) {
      print("请求取消");
      _onErrorCallback("请求已取消", 502);
    } else {
      _onErrorCallback("请求发生未知错误", 502);
      print("未知错误");
    }
  }
}