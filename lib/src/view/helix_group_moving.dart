import 'dart:math';

import 'package:over_react/over_react.dart';
import 'package:react/react_client.dart';
import 'package:built_collection/built_collection.dart';
import 'package:scadnano/src/state/position3d.dart';

import '../state/group.dart';
import '../state/geometry.dart';
import 'design_main_helix.dart';
import '../state/helix.dart';
import 'pure_component.dart';
import '../extension_methods.dart';

part 'helix_group_moving.over_react.g.dart';

UiFactory<HelixGroupMovingProps> HelixGroupMoving = _$HelixGroupMoving;

mixin HelixGroupMovingProps on UiProps {
  BuiltMap<int, Helix> helices;
  HelixGroup group;
  Point<num> translation;
  String group_name;
  BuiltMap<String, BuiltList<int>> helix_idxs_in_group;
  BuiltSet<int> side_selected_helix_idxs;
  bool only_display_selected_helices;
  bool show_dna;
  Geometry geometry;
  bool show_helix_circles;
}

class HelixGroupMovingComponent extends UiComponent2<HelixGroupMovingProps> with PureComponent {
  @override
  render() {
    if (props.helices.isEmpty) {
      return null;
    }
    BuiltSet<int> side_selected_helix_idxs = props.side_selected_helix_idxs;
    bool only_display_selected_helices = props.only_display_selected_helices;
    var helix_idxs_in_group = props.helix_idxs_in_group[props.group_name];

    if (helix_idxs_in_group.isEmpty) {
      return null;
    }

    var children = [];
    for (int helix_idx in helix_idxs_in_group) {
      var helix = props.helices[helix_idx];

      if (only_display_selected_helices && side_selected_helix_idxs.contains(helix.idx) ||
          !only_display_selected_helices) {
        children.add((DesignMainHelix()
          ..helix = helix
          ..geometry = props.geometry
          ..show_dna = props.show_dna
          ..show_helix_circles = props.show_helix_circles
          ..helix_change_apply_to_all = false
          ..display_base_offsets_of_major_ticks = false
          ..display_major_tick_widths = false
          ..key = helix.idx.toString())());
      }
    }

    var new_position = Position3D(x: props.translation.x, y:props.translation.x, z: props.group.position.z);
    var new_group = props.group.rebuild((b) => b..position.replace(new_position));
    var transform = new_group.transform_str(props.geometry);

    return (Dom.g()
      ..className = 'helix-group-moving-${props.group_name}'
      ..transform = transform
      ..key = '${props.group_name}')(children);
  }
}
