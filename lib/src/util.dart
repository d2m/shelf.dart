// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library shelf.util;

import 'dart:async';

import 'package:stack_trace/stack_trace.dart';

/// Like [Future.sync], but wraps the Future in [Chain.track] as well.
Future syncFuture(callback()) => Chain.track(new Future.sync(callback));

const _WEEKDAYS = const ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
const _MONTHS = const ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug",
    "Sep", "Oct", "Nov", "Dec"];

/// Return a HTTP-formatted string representation of [date].
///
/// This follows [RFC 822](http://tools.ietf.org/html/rfc822) as updated by [RFC
/// 1123](http://tools.ietf.org/html/rfc1123).
String formatHttpDate(DateTime date) {
  date = date.toUtc();
  var buffer = new StringBuffer()
      ..write(_WEEKDAYS[date.weekday - 1])
      ..write(", ")
      ..write(date.day.toString())
      ..write(" ")
      ..write(_MONTHS[date.month - 1])
      ..write(" ")
      ..write(date.year.toString())
      ..write(date.hour < 9 ? " 0" : " ")
      ..write(date.hour.toString())
      ..write(date.minute < 9 ? ":0" : ":")
      ..write(date.minute.toString())
      ..write(date.second < 9 ? ":0" : ":")
      ..write(date.second.toString())
      ..write(" GMT");
  return buffer.toString();
}
