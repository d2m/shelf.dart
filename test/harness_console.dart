// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*
 * This file imports all individual tests files and allows them to be run
 * all at once.
 *
 * It also exposes `testCore` which is used by `hop_runner` to rust tests via
 * Hop.
 */
library harness_console;

import 'package:unittest/unittest.dart';

import 'create_middleware_test.dart' as create_middleware;
import 'log_middleware_test.dart' as log_middleware;
import 'media_type_test.dart' as media_type;
import 'response_test.dart' as response;
import 'shelf_io_test.dart' as shelf_io;
import 'shelf_stack_test.dart' as shelf_stack;
import 'string_scanner_test.dart' as string_scanner;

void main() {
  groupSep = ' - ';

  group('createMiddleware', create_middleware.main);
  group('logRequests', log_middleware.main);
  group('MediaType', media_type.main);
  group('ShelfResponse', response.main);
  group('shelf_io', shelf_io.main);
  group('ShelfStack', shelf_stack.main);
  group('StringScanner', string_scanner.main);
}