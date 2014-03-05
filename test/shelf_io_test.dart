// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library shelf_io_test;

import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:scheduled_test/scheduled_test.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

import 'test_util.dart';

void main() {
  test('sync handler returns a value to the client', () {
    _scheduleServer(syncHandler);

    return _scheduleRequest().then((response) {
      expect(response.statusCode, HttpStatus.OK);
      expect(response.body, 'Hello from /');
    });
  });

  test('async handler returns a value to the client', () {
    _scheduleServer(asyncHandler);

    return _scheduleRequest().then((response) {
      expect(response.statusCode, HttpStatus.OK);
      expect(response.body, 'Hello from /');
    });
  });

  test('sync null response leads to a 500', () {
    _scheduleServer((request) => null);

    return _scheduleRequest().then((response) {
      expect(response.statusCode, HttpStatus.INTERNAL_SERVER_ERROR);
      expect(response.body, 'Internal Server Error');
    });
  });

  test('async null response leads to a 500', () {
    _scheduleServer((request) => new Future.value(null));

    return _scheduleRequest().then((response) {
      expect(response.statusCode, HttpStatus.INTERNAL_SERVER_ERROR);
      expect(response.body, 'Internal Server Error');
    });
  });

  test('thrown error leads to a 500', () {
    _scheduleServer((request) {
      throw new UnsupportedError('test');
    });

    return _scheduleRequest().then((response) {
      expect(response.statusCode, HttpStatus.INTERNAL_SERVER_ERROR);
      expect(response.body, 'Internal Server Error');
    });
  });

  test('async error leads to a 500', () {
    _scheduleServer((request) {
      return new Future.error('test');
    });

    return _scheduleRequest().then((response) {
      expect(response.statusCode, HttpStatus.INTERNAL_SERVER_ERROR);
      expect(response.body, 'Internal Server Error');
    });
  });

  test('ShelfRequest is populated correctly', () {
    var path = '/foo/bar?qs=value#anchor';

    _scheduleServer((request) {
      expect(request.contentLength, 0);
      expect(request.method, 'GET');

      var expectedUrl = 'http://localhost:$_serverPort$path';
      expect(request.requestedUri, Uri.parse(expectedUrl));

      expect(request.pathInfo, '/foo/bar');
      expect(request.pathSegments, ['foo', 'bar']);
      expect(request.protocolVersion, '1.1');
      expect(request.queryString, 'qs=value');
      expect(request.scriptName, '');

      return syncHandler(request);
    });

    return schedule(() => http.get('http://localhost:$_serverPort$path'))
        .then((response) {
      expect(response.statusCode, HttpStatus.OK);
      expect(response.body, 'Hello from /foo/bar');
    });
  });

  test('custom response headers are received by the client', () {
    _scheduleServer((request) {
      return new ShelfResponse.ok('Hello from /', headers: {
        'test-header': 'test-value',
        'test-list': 'a, b, c'
      });
    });

    return _scheduleRequest().then((response) {
      expect(response.statusCode, HttpStatus.OK);
      expect(response.headers['test-header'], 'test-value');
      expect(response.body, 'Hello from /');
    });
  });

  test('custom status code is received by the client', () {
    _scheduleServer((request) {
      return new ShelfResponse(299, body: 'Hello from /');
    });

    return _scheduleRequest().then((response) {
      expect(response.statusCode, 299);
      expect(response.body, 'Hello from /');
    });
  });

  test('custom request headers are received by the handler', () {
    _scheduleServer((request) {
      expect(request.headers, containsPair('custom-header', 'client value'));
      return syncHandler(request);
    });

    var headers = {
      'custom-header': 'client value'
    };

    return _scheduleRequest(headers: headers).then((response) {
      expect(response.statusCode, HttpStatus.OK);
      expect(response.body, 'Hello from /');
    });
  });
}

int _serverPort;

Future _scheduleServer(ShelfHandler handler) {
  return schedule(() => shelf_io.serve(handler, 'localhost', 0).then((server) {
    currentSchedule.onComplete.schedule(() {
      _serverPort = null;
      return server.close(force: true);
    });

    _serverPort = server.port;
  }));
}

Future<http.Response> _scheduleRequest({Map<String, String> headers}) {
  if (headers == null) headers = {};

  return schedule(() =>
      http.get('http://localhost:$_serverPort/', headers: headers));
}
