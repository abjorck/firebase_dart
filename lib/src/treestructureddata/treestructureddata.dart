// Copyright (c) 2016, Rik Bellens. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

part of firebase.treestructureddata;

class TreeStructuredData extends TreeNode<Name, Value> {
  Value priority;

  TreeStructuredData(
      {Value priority, Value value, Filter<Name, TreeStructuredData> filter})
      : this._(value, new FilteredMap(filter ?? const QueryFilter()), priority);

  TreeStructuredData._(Value value,
      FilteredMap<Name, TreeStructuredData> children, Value priority)
      : priority = priority,
        super(
            value,
            children ??
                new FilteredMap<Name, TreeStructuredData>(
                    const QueryFilter())) {
    assert(children == null || children is FilteredMap);
    assert(this.children == null || this.children is FilteredMap);
  }

  TreeStructuredData.leaf(Value value, [Value priority])
      : this._(value, null, priority);

  TreeStructuredData.nonLeaf(Map<Name, TreeStructuredData> children,
      [Value priority])
      : this._(
            null,
            children is FilteredMap
                ? children
                : (new FilteredMap(const QueryFilter())..addAll(children)),
            priority);

  factory TreeStructuredData.fromJson(json, [priority]) {
    if (json == null) {
      return new TreeStructuredData();
    }
    if (json is! Map &&
        json is! bool &&
        json is! num &&
        json is! String &&
        json is! List) {
      try {
        json = json.toJson();
      } on NoSuchMethodError {}
    }

    if (json is Map && json.containsKey(".priority")) {
      priority = json[".priority"];
    }
    priority = priority == null ? null : new Value(priority);

    if (json is Map && json.containsKey(".value") && json[".value"] != null) {
      json = json[".value"];
    }

    if (json is List) json = json.asMap();
    if (json is! Map || json.containsKey(".sv")) {
      var value = new Value(json);
      return new TreeStructuredData.leaf(value, priority);
    }

    var children = new Map<Name, TreeStructuredData>.fromIterable(
        json.keys.where((k) => k is! String || !k.startsWith(".")),
        key: (k) => new Name(k.toString()),
        value: (k) => new TreeStructuredData.fromJson(json[k], null));

    return new TreeStructuredData.nonLeaf(children, priority);
  }

  @override
  TreeStructuredData clone() =>
      new TreeStructuredData._(value, children, priority);

  @override
  FilteredMap<Name, TreeStructuredData> get children => super.children;

  TreeStructuredData view(
          {Pair<Comparable, Comparable> start,
          Pair<Comparable, Comparable> end,
          int limit,
          bool reversed}) =>
      new TreeStructuredData._(
          value,
          children.filteredMapView(
              start: start, end: end, limit: limit, reversed: reversed),
          priority);

  TreeStructuredData withFilter(Filter<Name, TreeStructuredData> f) {
    if (children.filter == f ||
        (f == null && children.filter == const QueryFilter())) return this;
    return new TreeStructuredData(priority: priority, value: value, filter: f)
      ..children.addAll(children);
  }

  dynamic toJson([bool exportFormat = false]) {
    if (isNil) return null;
    var c = new Map<String, dynamic>.fromIterables(
        children.keys.map((k) => k.toString()),
        children.values.map((v) => v.toJson(exportFormat)));

    if (exportFormat && priority != null) {
      if (isLeaf) c = {".value": value.toJson()};
      return <String, dynamic>{".priority": priority.toJson()}..addAll(c);
    }
    return isLeaf ? value.toJson() : c;
  }

  @override
  bool operator ==(dynamic other) =>
      other is TreeStructuredData &&
      (isLeaf
          ? other.isLeaf && value == other.value
          : !other.isLeaf &&
              const MapEquality().equals(children, other.children));

  @override
  int get hashCode => quiver.hash2(value, const MapEquality().hash(children));

  @override
  String toString() => "TreeStructuredData[${toJson()}]";

  String get hash {
    var toHash = "";

    if (priority != null) {
      toHash += "priority:${priority._hashText}";
    }

    if (isLeaf) {
      toHash += value._hashText;
    }
    children.forEach((key, child) {
      toHash += ":${key.asString()}:${child.hash}";
    });
    return toHash == ""
        ? ""
        : base64.encode(sha1.convert(toHash.codeUnits).bytes);
  }
}

String _doubleToIEEE754String(num v) {
  var l = new Float64List.fromList([v.toDouble()]);
  var hex = "";
  for (int i = 0; i < 8; i++) {
    var b = l.buffer.asByteData().getUint8(i).toRadixString(16);
    if (b.length == 1) b = "0$b";
    hex = "$b$hex";
  }
  return hex;
}
