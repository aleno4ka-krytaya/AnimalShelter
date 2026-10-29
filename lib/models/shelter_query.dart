class ShelterQuery {
  final String search;
  final String? species;
  final String? status;
  final int? minAge;
  final int? maxAge;
  final String sortField;
  final bool sortAscending;
  final int page;
  final int size;
  final bool includeDeleted;

  const ShelterQuery({
    this.search = '',
    this.species,
    this.status,
    this.minAge,
    this.maxAge,
    this.sortField = 'name',
    this.sortAscending = true,
    this.page = 1,
    this.size = 10,
    this.includeDeleted = false,
  });

  static const _unset = Object();
  ShelterQuery copyWith({
    String? search,
    Object? species = _unset,
    Object? status = _unset,
    Object? minAge = _unset,
    Object? maxAge = _unset,
    String? sortField,
    bool? sortAscending,
    int? page,
    int? size,
    bool? includeDeleted,
  }) =>
      ShelterQuery(
        search: search ?? this.search,
        species: identical(species, _unset) ? this.species : species as String?,
        status: identical(status, _unset) ? this.status : status as String?,
        minAge: identical(minAge, _unset) ? this.minAge : minAge as int?,
        maxAge: identical(maxAge, _unset) ? this.maxAge : maxAge as int?,
        sortField: sortField ?? this.sortField,
        sortAscending: sortAscending ?? this.sortAscending,
        page: page ?? 1,
        size: size ?? this.size,
        includeDeleted: includeDeleted ?? this.includeDeleted,
      );
}
