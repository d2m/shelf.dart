// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library shelf.request_test;

import 'package:shelf/shelf.dart';
import 'package:unittest/unittest.dart';

void main() {
  group("contentLength", () {
    test("is null without a content-length header", () {
      var request = new Request("/", "", "GET", "", "1.1",
          Uri.parse("http://localhost/"), {});
      expect(request.contentLength, isNull);
    });

    test("comes from the content-length header", () {
      var request = new Request("/", "", "GET", "", "1.1",
          Uri.parse("http://localhost/"), {
        'content-length': '42'
      });
      expect(request.contentLength, 42);
    });
  });

  group("ifModifiedSince", () {
    test("is null without an If-Modified-Since header", () {
      var request = new Request("/", "", "GET", "", "1.1",
          Uri.parse("http://localhost/"), {});
      expect(request.ifModifiedSince, isNull);
    });

    test("comes from the Last-Modified header", () {
      var request = new Request("/", "", "GET", "", "1.1",
          Uri.parse("http://localhost/"), {
        'if-modified-since': 'Sun, 06 Nov 1994 08:49:37 GMT'
      });
      expect(request.ifModifiedSince,
          equals(DateTime.parse("1994-11-06 08:49:37z")));
    });
  });
}
