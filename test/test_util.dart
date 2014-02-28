// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library shelf.test_util;

import 'dart:async';

import 'package:shelf/shelf.dart';
import 'package:shelf/src/util.dart';

/// A simple, synchronous handler for [ShelfRequest].
///
/// By default, replies with a status code 200, empty headers, and
/// `Hello from ${request.pathInfo}`.
ShelfResponse syncHandler(ShelfRequest request, {int statusCode,
    Map<String, String> headers}) {
  if(statusCode == null) statusCode = 200;
  if(headers == null) headers = {};
  return new ShelfResponse.string(statusCode, headers,
      'Hello from ${request.pathInfo}');
}

/// Calls [syncHandler] and wraps the response in a [Future].
Future<ShelfResponse> asyncHandler(ShelfRequest request) =>
    new Future(() => syncHandler(request));

/// Makes a simple GET request to [handler] and returns the result.
Future<ShelfResponse> makeSimpleRequest(ShelfHandler handler) =>
    syncFuture(() => handler(_request));

final _request = new ShelfRequest('/', '', 'GET', '', '1.1', 0,
    Uri.parse('http://localhost/'), {});