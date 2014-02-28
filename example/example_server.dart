// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;

void main() {
  var handler = const ShelfStack().addMiddleware(logRequests())
      .addHandler(_echoRequest);

  io.serve(handler, 'localhost', 8080).then((server) {
    print('Serving at http://${server.address.host}:${server.port}');
  });
}


ShelfResponse _echoRequest(ShelfRequest request) {
  return new ShelfResponse.string(200, const {},
      'Request for "${request.pathInfo}"');
}
