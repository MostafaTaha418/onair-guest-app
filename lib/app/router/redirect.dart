final class RedirectContext {
  const RedirectContext({required this.location});
  final String location;
}

/// Story-specific guards are added with their routes in later phases.
String? resolveRedirect(RedirectContext context) => null;
