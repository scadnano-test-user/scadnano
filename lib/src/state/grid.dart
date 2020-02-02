import 'package:built_value/built_value.dart';
import 'package:built_collection/built_collection.dart';
import 'package:built_value/serializer.dart';

part 'grid.g.dart';

// see here for definitions of hex grid coordinate system: https://www.redblobgames.com/grids/hexagons/

// honeycomb_cadnano coordinate system:
//   https://github.com/UC-Davis-molecular-computing/scadnano-python-package/blob/master/misc/cadnano-format-specs/v2.txt

class Grid extends EnumClass {
  const Grid._(String name) : super(name);

  static const Grid square = _$square;
  static const Grid hex = _$hex;
  static const Grid honeycomb = _$honeycomb;
  static const Grid none = _$none;

  static BuiltSet<Grid> get values => _$values;
  static Grid valueOf(String name) => _$valueOf(name);

  String to_json() => name;

  bool is_none() => this == none;

  static Serializer<Grid> get serializer => _$gridSerializer;

  int default_major_tick_distance() => this == Grid.hex || this == Grid.honeycomb ? 7 : 8;
}

