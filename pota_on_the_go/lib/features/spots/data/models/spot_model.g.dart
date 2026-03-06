// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'spot_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetSpotModelCollection on Isar {
  IsarCollection<SpotModel> get spotModels => this.collection();
}

const SpotModelSchema = CollectionSchema(
  name: r'SpotModel',
  id: -2749345920550038888,
  properties: {
    r'activator': PropertySchema(
      id: 0,
      name: r'activator',
      type: IsarType.string,
    ),
    r'band': PropertySchema(id: 1, name: r'band', type: IsarType.string),
    r'frequency': PropertySchema(
      id: 2,
      name: r'frequency',
      type: IsarType.string,
    ),
    r'mode': PropertySchema(id: 3, name: r'mode', type: IsarType.string),
    r'reference': PropertySchema(
      id: 4,
      name: r'reference',
      type: IsarType.string,
    ),
    r'spotId': PropertySchema(id: 5, name: r'spotId', type: IsarType.long),
    r'spotTime': PropertySchema(
      id: 6,
      name: r'spotTime',
      type: IsarType.dateTime,
    ),
  },
  estimateSize: _spotModelEstimateSize,
  serialize: _spotModelSerialize,
  deserialize: _spotModelDeserialize,
  deserializeProp: _spotModelDeserializeProp,
  idName: r'id',
  indexes: {
    r'spotId': IndexSchema(
      id: -1380009023998224465,
      name: r'spotId',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'spotId',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
    r'reference': IndexSchema(
      id: -1595278990251664236,
      name: r'reference',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'reference',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},
  getId: _spotModelGetId,
  getLinks: _spotModelGetLinks,
  attach: _spotModelAttach,
  version: '3.1.0+1',
);

int _spotModelEstimateSize(
  SpotModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.activator.length * 3;
  bytesCount += 3 + object.band.length * 3;
  bytesCount += 3 + object.frequency.length * 3;
  bytesCount += 3 + object.mode.length * 3;
  bytesCount += 3 + object.reference.length * 3;
  return bytesCount;
}

void _spotModelSerialize(
  SpotModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.activator);
  writer.writeString(offsets[1], object.band);
  writer.writeString(offsets[2], object.frequency);
  writer.writeString(offsets[3], object.mode);
  writer.writeString(offsets[4], object.reference);
  writer.writeLong(offsets[5], object.spotId);
  writer.writeDateTime(offsets[6], object.spotTime);
}

SpotModel _spotModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = SpotModel();
  object.activator = reader.readString(offsets[0]);
  object.band = reader.readString(offsets[1]);
  object.frequency = reader.readString(offsets[2]);
  object.id = id;
  object.mode = reader.readString(offsets[3]);
  object.reference = reader.readString(offsets[4]);
  object.spotId = reader.readLong(offsets[5]);
  object.spotTime = reader.readDateTime(offsets[6]);
  return object;
}

P _spotModelDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readLong(offset)) as P;
    case 6:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _spotModelGetId(SpotModel object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _spotModelGetLinks(SpotModel object) {
  return [];
}

void _spotModelAttach(IsarCollection<dynamic> col, Id id, SpotModel object) {
  object.id = id;
}

extension SpotModelByIndex on IsarCollection<SpotModel> {
  Future<SpotModel?> getBySpotId(int spotId) {
    return getByIndex(r'spotId', [spotId]);
  }

  SpotModel? getBySpotIdSync(int spotId) {
    return getByIndexSync(r'spotId', [spotId]);
  }

  Future<bool> deleteBySpotId(int spotId) {
    return deleteByIndex(r'spotId', [spotId]);
  }

  bool deleteBySpotIdSync(int spotId) {
    return deleteByIndexSync(r'spotId', [spotId]);
  }

  Future<List<SpotModel?>> getAllBySpotId(List<int> spotIdValues) {
    final values = spotIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'spotId', values);
  }

  List<SpotModel?> getAllBySpotIdSync(List<int> spotIdValues) {
    final values = spotIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'spotId', values);
  }

  Future<int> deleteAllBySpotId(List<int> spotIdValues) {
    final values = spotIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'spotId', values);
  }

  int deleteAllBySpotIdSync(List<int> spotIdValues) {
    final values = spotIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'spotId', values);
  }

  Future<Id> putBySpotId(SpotModel object) {
    return putByIndex(r'spotId', object);
  }

  Id putBySpotIdSync(SpotModel object, {bool saveLinks = true}) {
    return putByIndexSync(r'spotId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllBySpotId(List<SpotModel> objects) {
    return putAllByIndex(r'spotId', objects);
  }

  List<Id> putAllBySpotIdSync(
    List<SpotModel> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'spotId', objects, saveLinks: saveLinks);
  }
}

extension SpotModelQueryWhereSort
    on QueryBuilder<SpotModel, SpotModel, QWhere> {
  QueryBuilder<SpotModel, SpotModel, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<SpotModel, SpotModel, QAfterWhere> anySpotId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'spotId'),
      );
    });
  }
}

extension SpotModelQueryWhere
    on QueryBuilder<SpotModel, SpotModel, QWhereClause> {
  QueryBuilder<SpotModel, SpotModel, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<SpotModel, SpotModel, QAfterWhereClause> idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<SpotModel, SpotModel, QAfterWhereClause> idGreaterThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<SpotModel, SpotModel, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<SpotModel, SpotModel, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(
          lower: lowerId,
          includeLower: includeLower,
          upper: upperId,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<SpotModel, SpotModel, QAfterWhereClause> spotIdEqualTo(
    int spotId,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'spotId', value: [spotId]),
      );
    });
  }

  QueryBuilder<SpotModel, SpotModel, QAfterWhereClause> spotIdNotEqualTo(
    int spotId,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'spotId',
                lower: [],
                upper: [spotId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'spotId',
                lower: [spotId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'spotId',
                lower: [spotId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'spotId',
                lower: [],
                upper: [spotId],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<SpotModel, SpotModel, QAfterWhereClause> spotIdGreaterThan(
    int spotId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'spotId',
          lower: [spotId],
          includeLower: include,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<SpotModel, SpotModel, QAfterWhereClause> spotIdLessThan(
    int spotId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'spotId',
          lower: [],
          upper: [spotId],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<SpotModel, SpotModel, QAfterWhereClause> spotIdBetween(
    int lowerSpotId,
    int upperSpotId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'spotId',
          lower: [lowerSpotId],
          includeLower: includeLower,
          upper: [upperSpotId],
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<SpotModel, SpotModel, QAfterWhereClause> referenceEqualTo(
    String reference,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'reference', value: [reference]),
      );
    });
  }

  QueryBuilder<SpotModel, SpotModel, QAfterWhereClause> referenceNotEqualTo(
    String reference,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'reference',
                lower: [],
                upper: [reference],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'reference',
                lower: [reference],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'reference',
                lower: [reference],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'reference',
                lower: [],
                upper: [reference],
                includeUpper: false,
              ),
            );
      }
    });
  }
}

extension SpotModelQueryFilter
    on QueryBuilder<SpotModel, SpotModel, QFilterCondition> {
  QueryBuilder<SpotModel, SpotModel, QAfterFilterCondition> activatorEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'activator',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SpotModel, SpotModel, QAfterFilterCondition>
  activatorGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'activator',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SpotModel, SpotModel, QAfterFilterCondition> activatorLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'activator',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SpotModel, SpotModel, QAfterFilterCondition> activatorBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'activator',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SpotModel, SpotModel, QAfterFilterCondition> activatorStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'activator',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SpotModel, SpotModel, QAfterFilterCondition> activatorEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'activator',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SpotModel, SpotModel, QAfterFilterCondition> activatorContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'activator',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SpotModel, SpotModel, QAfterFilterCondition> activatorMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'activator',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SpotModel, SpotModel, QAfterFilterCondition> activatorIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'activator', value: ''),
      );
    });
  }

  QueryBuilder<SpotModel, SpotModel, QAfterFilterCondition>
  activatorIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'activator', value: ''),
      );
    });
  }

  QueryBuilder<SpotModel, SpotModel, QAfterFilterCondition> bandEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'band',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SpotModel, SpotModel, QAfterFilterCondition> bandGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'band',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SpotModel, SpotModel, QAfterFilterCondition> bandLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'band',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SpotModel, SpotModel, QAfterFilterCondition> bandBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'band',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SpotModel, SpotModel, QAfterFilterCondition> bandStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'band',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SpotModel, SpotModel, QAfterFilterCondition> bandEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'band',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SpotModel, SpotModel, QAfterFilterCondition> bandContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'band',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SpotModel, SpotModel, QAfterFilterCondition> bandMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'band',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SpotModel, SpotModel, QAfterFilterCondition> bandIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'band', value: ''),
      );
    });
  }

  QueryBuilder<SpotModel, SpotModel, QAfterFilterCondition> bandIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'band', value: ''),
      );
    });
  }

  QueryBuilder<SpotModel, SpotModel, QAfterFilterCondition> frequencyEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'frequency',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SpotModel, SpotModel, QAfterFilterCondition>
  frequencyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'frequency',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SpotModel, SpotModel, QAfterFilterCondition> frequencyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'frequency',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SpotModel, SpotModel, QAfterFilterCondition> frequencyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'frequency',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SpotModel, SpotModel, QAfterFilterCondition> frequencyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'frequency',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SpotModel, SpotModel, QAfterFilterCondition> frequencyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'frequency',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SpotModel, SpotModel, QAfterFilterCondition> frequencyContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'frequency',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SpotModel, SpotModel, QAfterFilterCondition> frequencyMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'frequency',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SpotModel, SpotModel, QAfterFilterCondition> frequencyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'frequency', value: ''),
      );
    });
  }

  QueryBuilder<SpotModel, SpotModel, QAfterFilterCondition>
  frequencyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'frequency', value: ''),
      );
    });
  }

  QueryBuilder<SpotModel, SpotModel, QAfterFilterCondition> idEqualTo(
    Id value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<SpotModel, SpotModel, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SpotModel, SpotModel, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SpotModel, SpotModel, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'id',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<SpotModel, SpotModel, QAfterFilterCondition> modeEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'mode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SpotModel, SpotModel, QAfterFilterCondition> modeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'mode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SpotModel, SpotModel, QAfterFilterCondition> modeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'mode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SpotModel, SpotModel, QAfterFilterCondition> modeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'mode',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SpotModel, SpotModel, QAfterFilterCondition> modeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'mode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SpotModel, SpotModel, QAfterFilterCondition> modeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'mode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SpotModel, SpotModel, QAfterFilterCondition> modeContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'mode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SpotModel, SpotModel, QAfterFilterCondition> modeMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'mode',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SpotModel, SpotModel, QAfterFilterCondition> modeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'mode', value: ''),
      );
    });
  }

  QueryBuilder<SpotModel, SpotModel, QAfterFilterCondition> modeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'mode', value: ''),
      );
    });
  }

  QueryBuilder<SpotModel, SpotModel, QAfterFilterCondition> referenceEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'reference',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SpotModel, SpotModel, QAfterFilterCondition>
  referenceGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'reference',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SpotModel, SpotModel, QAfterFilterCondition> referenceLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'reference',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SpotModel, SpotModel, QAfterFilterCondition> referenceBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'reference',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SpotModel, SpotModel, QAfterFilterCondition> referenceStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'reference',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SpotModel, SpotModel, QAfterFilterCondition> referenceEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'reference',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SpotModel, SpotModel, QAfterFilterCondition> referenceContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'reference',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SpotModel, SpotModel, QAfterFilterCondition> referenceMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'reference',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SpotModel, SpotModel, QAfterFilterCondition> referenceIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'reference', value: ''),
      );
    });
  }

  QueryBuilder<SpotModel, SpotModel, QAfterFilterCondition>
  referenceIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'reference', value: ''),
      );
    });
  }

  QueryBuilder<SpotModel, SpotModel, QAfterFilterCondition> spotIdEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'spotId', value: value),
      );
    });
  }

  QueryBuilder<SpotModel, SpotModel, QAfterFilterCondition> spotIdGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'spotId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SpotModel, SpotModel, QAfterFilterCondition> spotIdLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'spotId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SpotModel, SpotModel, QAfterFilterCondition> spotIdBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'spotId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<SpotModel, SpotModel, QAfterFilterCondition> spotTimeEqualTo(
    DateTime value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'spotTime', value: value),
      );
    });
  }

  QueryBuilder<SpotModel, SpotModel, QAfterFilterCondition> spotTimeGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'spotTime',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SpotModel, SpotModel, QAfterFilterCondition> spotTimeLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'spotTime',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SpotModel, SpotModel, QAfterFilterCondition> spotTimeBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'spotTime',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension SpotModelQueryObject
    on QueryBuilder<SpotModel, SpotModel, QFilterCondition> {}

extension SpotModelQueryLinks
    on QueryBuilder<SpotModel, SpotModel, QFilterCondition> {}

extension SpotModelQuerySortBy on QueryBuilder<SpotModel, SpotModel, QSortBy> {
  QueryBuilder<SpotModel, SpotModel, QAfterSortBy> sortByActivator() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'activator', Sort.asc);
    });
  }

  QueryBuilder<SpotModel, SpotModel, QAfterSortBy> sortByActivatorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'activator', Sort.desc);
    });
  }

  QueryBuilder<SpotModel, SpotModel, QAfterSortBy> sortByBand() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'band', Sort.asc);
    });
  }

  QueryBuilder<SpotModel, SpotModel, QAfterSortBy> sortByBandDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'band', Sort.desc);
    });
  }

  QueryBuilder<SpotModel, SpotModel, QAfterSortBy> sortByFrequency() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'frequency', Sort.asc);
    });
  }

  QueryBuilder<SpotModel, SpotModel, QAfterSortBy> sortByFrequencyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'frequency', Sort.desc);
    });
  }

  QueryBuilder<SpotModel, SpotModel, QAfterSortBy> sortByMode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mode', Sort.asc);
    });
  }

  QueryBuilder<SpotModel, SpotModel, QAfterSortBy> sortByModeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mode', Sort.desc);
    });
  }

  QueryBuilder<SpotModel, SpotModel, QAfterSortBy> sortByReference() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reference', Sort.asc);
    });
  }

  QueryBuilder<SpotModel, SpotModel, QAfterSortBy> sortByReferenceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reference', Sort.desc);
    });
  }

  QueryBuilder<SpotModel, SpotModel, QAfterSortBy> sortBySpotId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'spotId', Sort.asc);
    });
  }

  QueryBuilder<SpotModel, SpotModel, QAfterSortBy> sortBySpotIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'spotId', Sort.desc);
    });
  }

  QueryBuilder<SpotModel, SpotModel, QAfterSortBy> sortBySpotTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'spotTime', Sort.asc);
    });
  }

  QueryBuilder<SpotModel, SpotModel, QAfterSortBy> sortBySpotTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'spotTime', Sort.desc);
    });
  }
}

extension SpotModelQuerySortThenBy
    on QueryBuilder<SpotModel, SpotModel, QSortThenBy> {
  QueryBuilder<SpotModel, SpotModel, QAfterSortBy> thenByActivator() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'activator', Sort.asc);
    });
  }

  QueryBuilder<SpotModel, SpotModel, QAfterSortBy> thenByActivatorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'activator', Sort.desc);
    });
  }

  QueryBuilder<SpotModel, SpotModel, QAfterSortBy> thenByBand() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'band', Sort.asc);
    });
  }

  QueryBuilder<SpotModel, SpotModel, QAfterSortBy> thenByBandDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'band', Sort.desc);
    });
  }

  QueryBuilder<SpotModel, SpotModel, QAfterSortBy> thenByFrequency() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'frequency', Sort.asc);
    });
  }

  QueryBuilder<SpotModel, SpotModel, QAfterSortBy> thenByFrequencyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'frequency', Sort.desc);
    });
  }

  QueryBuilder<SpotModel, SpotModel, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<SpotModel, SpotModel, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<SpotModel, SpotModel, QAfterSortBy> thenByMode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mode', Sort.asc);
    });
  }

  QueryBuilder<SpotModel, SpotModel, QAfterSortBy> thenByModeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mode', Sort.desc);
    });
  }

  QueryBuilder<SpotModel, SpotModel, QAfterSortBy> thenByReference() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reference', Sort.asc);
    });
  }

  QueryBuilder<SpotModel, SpotModel, QAfterSortBy> thenByReferenceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reference', Sort.desc);
    });
  }

  QueryBuilder<SpotModel, SpotModel, QAfterSortBy> thenBySpotId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'spotId', Sort.asc);
    });
  }

  QueryBuilder<SpotModel, SpotModel, QAfterSortBy> thenBySpotIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'spotId', Sort.desc);
    });
  }

  QueryBuilder<SpotModel, SpotModel, QAfterSortBy> thenBySpotTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'spotTime', Sort.asc);
    });
  }

  QueryBuilder<SpotModel, SpotModel, QAfterSortBy> thenBySpotTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'spotTime', Sort.desc);
    });
  }
}

extension SpotModelQueryWhereDistinct
    on QueryBuilder<SpotModel, SpotModel, QDistinct> {
  QueryBuilder<SpotModel, SpotModel, QDistinct> distinctByActivator({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'activator', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SpotModel, SpotModel, QDistinct> distinctByBand({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'band', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SpotModel, SpotModel, QDistinct> distinctByFrequency({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'frequency', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SpotModel, SpotModel, QDistinct> distinctByMode({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'mode', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SpotModel, SpotModel, QDistinct> distinctByReference({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'reference', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SpotModel, SpotModel, QDistinct> distinctBySpotId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'spotId');
    });
  }

  QueryBuilder<SpotModel, SpotModel, QDistinct> distinctBySpotTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'spotTime');
    });
  }
}

extension SpotModelQueryProperty
    on QueryBuilder<SpotModel, SpotModel, QQueryProperty> {
  QueryBuilder<SpotModel, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<SpotModel, String, QQueryOperations> activatorProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'activator');
    });
  }

  QueryBuilder<SpotModel, String, QQueryOperations> bandProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'band');
    });
  }

  QueryBuilder<SpotModel, String, QQueryOperations> frequencyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'frequency');
    });
  }

  QueryBuilder<SpotModel, String, QQueryOperations> modeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'mode');
    });
  }

  QueryBuilder<SpotModel, String, QQueryOperations> referenceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'reference');
    });
  }

  QueryBuilder<SpotModel, int, QQueryOperations> spotIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'spotId');
    });
  }

  QueryBuilder<SpotModel, DateTime, QQueryOperations> spotTimeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'spotTime');
    });
  }
}
