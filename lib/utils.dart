// This is a collection of utility methods that are not explicitly
// exported by the package, but could be used by the dependants.

/// Given a [path] list, this method navigates through [data] and returns
/// the last path, or null otherwise.
///
/// e.g.:
/// ['my', 'key'] + {'my': {'key': 'Value!'}} = 'Value!'
Object? evaluate(Iterable<Object> path, Map<Object, dynamic>? data) {
  Object? object = data;
  for (final current in path) {
    if (object is Map && object.containsKey(current)) {
      object = object[current];
    } else {
      object = null;
      break;
    }
  }
  return object;
}
