import 'package:built_value/built_value.dart';
import 'package:built_collection/built_collection.dart';
import 'package:built_value/serializer.dart';

import 'serializers.dart';

part 'test.g.dart';

run() {
//  var child_builder = ChildBuilder();
//  child_builder.field_str = 'abc';
//  var child = child_builder.build();
//  print(child);

  var child = Child(field_str: 'abc');
  var children = [Child(field_str: 'def'), Child(field_str: 'xyz')].toBuiltList();
  var parent = Parent(field_int: 123, child: child, children: children);
  var parent_builder = parent.toBuilder();
  int field = parent_builder.field_int;
  Child ch = parent_builder.child.build();
  ListBuilder<Child> children_builder = parent_builder.children;
  Child grandchild = children_builder[0];
  children_builder[0] = Child(field_str: 'new child');
  var parent2 = parent_builder.build();
  print('parent  = $parent');
  print('parent2 = $parent2');
  print('field   = $field');
  print('ch      = $ch');
  print('children_builder      = ${children_builder}');
  print('grandchild      = ${grandchild}');
  print('identical(parent, parent2)? ${identical(parent, parent2)}');

  var child_builder = child.toBuilder();
  String field_str = child_builder.field_str;
  var child2 = child_builder.build();
  print('child       = $child');
  print('child2      = $child2');
  print('field_str   = $field_str');
  print('identical(child, child2)? ${identical(child, child2)}');
}

abstract class Parent with BuiltJsonSerializable implements Built<Parent, ParentBuilder> {
  int get field_int;

  Child get child;

  BuiltList<Child> get children;

  /************************ begin BuiltValue boilerplate ************************/

  factory Parent({int field_int, Child child, BuiltList<Child> children}) = _$Parent._;

  Parent._();

  static Serializer<Parent> get serializer => _$parentSerializer;

  @memoized
  int get hashCode;
}

abstract class Child with BuiltJsonSerializable implements Built<Child, ChildBuilder> {
  String get field_str;

  /************************ begin BuiltValue boilerplate ************************/
  factory Child({String field_str}) = _$Child._;

  Child._();

  static Serializer<Child> get serializer => _$childSerializer;

  @memoized
  int get hashCode;
}
