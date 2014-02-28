// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library shelf.response;

import 'dart:async';
import 'dart:convert';

import 'package:collection/wrappers.dart';

/// The response returned by a [ShelfHandler].
abstract class ShelfResponse {
  /// The HTTP status code of the response.
  final int statusCode;

  /// The HTTP headers of the response.
  ///
  /// The value is immutable.
  final Map<String, String> headers;

  /// Creates a [ShelfResponse] with a [String] body.
  //TODO(kevmoo) Rework constructors to support many body types.
  factory ShelfResponse.string(int statusCode, Map<String, String> headers,
      String body) = _StringShelfResponse;

  ShelfResponse(this.statusCode, Map<String, String> headers) :
    // copy the source map to ensure headers are immutable
    this.headers = new UnmodifiableMapView(new Map.from(headers)) {
    assert(statusCode != null);
    assert(statusCode > 0);
  }

  /// Creates a [ShelfResponse] with a status code of `500`.
  ///
  /// The default value for [message] is "Internal Server Error".
  factory ShelfResponse.internalServerError([String message]) {
    if (message == null) message = 'Internal Server Error';
    return new _StringShelfResponse(500, {}, message);
  }

  /// Returns a [Stream] representing the body of the response.
  // TODO(kevmoo): expose the requsted encoding and instruct those who override
  //               `read` to ensure they send text correctly.
  Stream<List<int>> read();
}

class _StringShelfResponse extends ShelfResponse {
  final String body;

  _StringShelfResponse(int statusCode, Map<String, String> headers, this.body)
      : super(statusCode, headers);

  // TODO: no clue how to handle encoding correctly here..
  Stream<List<int>> read() => new Stream.fromIterable([UTF8.encode(body)]);
}
