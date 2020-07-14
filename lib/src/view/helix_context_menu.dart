import 'dart:html';

import 'package:built_collection/built_collection.dart';

import '../state/context_menu.dart';
import '../state/dialog.dart';
import '../state/grid.dart';
import '../state/grid_position.dart';
import '../state/position3d.dart';
import '../state/helix.dart';
import '../app.dart';
import '../actions/actions.dart' as actions;
import '../util.dart' as util;

List<ContextMenuItem> context_menu_helix(Helix helix, bool helix_change_apply_to_all) {
  Future<void> dialog_helix_adjust_length() async {
    int helix_idx = helix.idx;

    var dialog = Dialog(title: 'adjust helix length', items: [
      DialogNumber(label: 'minimum', value: helix.min_offset),
      DialogNumber(label: 'maximum', value: helix.max_offset),
      DialogCheckbox(label: 'apply to all helices', value: helix_change_apply_to_all),
    ]);
    List<DialogItem> results = await util.dialog(dialog);
    if (results == null) return;

    int min_offset = (results[0] as DialogNumber).value;
    int max_offset = (results[1] as DialogNumber).value;
    bool apply_to_all = (results[2] as DialogCheckbox).value;

    if (min_offset >= max_offset) {
      window.alert('minimum offset ${min_offset} must be strictly less than maximum offset, '
          'but maximum offset is ${max_offset}');
      return;
    }

    if (apply_to_all) {
      app.dispatch(actions.HelixOffsetChangeAll(min_offset: min_offset, max_offset: max_offset));
    } else {
      app.dispatch(
          actions.HelixOffsetChange(helix_idx: helix_idx, min_offset: min_offset, max_offset: max_offset));
    }
  }

  Future<void> dialog_helix_adjust_roll() async {
    int helix_idx = helix.idx;

    var dialog = Dialog(title: 'adjust helix roll (degrees)', items: [
      DialogFloatingNumber(label: 'roll', value: helix.roll),
    ]);
    List<DialogItem> results = await util.dialog(dialog);
    if (results == null) return;

    double roll = (results[0] as DialogFloatingNumber).value;
    roll = roll % 360;

    app.dispatch(actions.HelixRollSet(helix_idx: helix_idx, roll: roll));
  }

  Future<void> dialog_helix_adjust_major_tick_marks() async {
    int helix_idx = helix.idx;
    Grid grid = helix.grid;

    int default_regular_distance;
    List<int> default_periodic_distances;
    int default_start = helix.major_tick_start;
    if (helix.has_major_tick_distance()) {
      default_regular_distance = helix.major_tick_distance;
      default_periodic_distances = [default_regular_distance];
    } else if (helix.has_major_tick_periodic_distances()) {
      default_regular_distance = helix.major_tick_periodic_distances.first;
      default_periodic_distances = helix.major_tick_periodic_distances.toList();
    } else {
      default_regular_distance = grid.default_major_tick_distance();
      default_periodic_distances = [default_regular_distance];
    }

    int regular_spacing_enabled_idx = 0;
    int regular_spacing_distance_idx = 1;
    int major_tick_start_idx = 2;
    int periodic_spacing_enabled_idx = 3;
    int periodic_spacing_distances_idx = 4;
    int major_ticks_enabled_idx = 5;
    int major_ticks_distances_idx = 6;
    int apply_to_all_idx = 7;
    int apply_to_some_idx = 8;
    int apply_to_some_helices_idx = 9;
    List<DialogItem> items = List<DialogItem>(10);
    items[regular_spacing_enabled_idx] =
        DialogCheckbox(label: 'regular spacing', value: helix.has_major_tick_distance());
    items[regular_spacing_distance_idx] =
        DialogNumber(label: 'regular distance', value: default_regular_distance);
    items[major_tick_start_idx] = DialogNumber(label: 'starting major tick', value: default_start);
    items[periodic_spacing_enabled_idx] =
        DialogCheckbox(label: 'periodic spacing', value: helix.has_major_tick_periodic_distances());
    items[periodic_spacing_distances_idx] =
        DialogText(label: 'periodic distances', value: "${default_periodic_distances.join(' ')}");
    items[major_ticks_enabled_idx] =
        DialogCheckbox(label: 'explicit list of major tick spacing', value: helix.has_major_ticks());
    items[major_ticks_distances_idx] = DialogText(
        label: 'distances (space-separated)',
        value: helix.major_ticks == null ? '' : util.deltas(helix.major_ticks).join(' '));
    items[apply_to_all_idx] = DialogCheckbox(label: 'apply to all', value: helix_change_apply_to_all);
    items[apply_to_some_idx] = DialogCheckbox(label: 'apply to some', value: helix_change_apply_to_all);
    items[apply_to_some_helices_idx] = DialogText(label: 'helices (space-separated)', value: "");

    var dialog = Dialog(title: 'adjust helix tick marks', items: items, disable_when_off: {
      regular_spacing_distance_idx: [regular_spacing_enabled_idx],
      periodic_spacing_distances_idx: [periodic_spacing_enabled_idx],
      major_ticks_distances_idx: [major_ticks_enabled_idx],
    }, disable_when_on: {
      major_tick_start_idx: [major_ticks_enabled_idx],
    }, mutually_exclusive_checkbox_groups: [
      [regular_spacing_enabled_idx, periodic_spacing_enabled_idx, major_ticks_enabled_idx],
      [apply_to_all_idx, apply_to_some_idx],
    ]);

    List<DialogItem> results = await util.dialog(dialog);
    if (results == null) {
      return;
    }

    bool use_major_tick_distance = (results[regular_spacing_enabled_idx] as DialogCheckbox).value;
    bool use_major_tick_periodic_distances = (results[periodic_spacing_enabled_idx] as DialogCheckbox).value;
    bool use_major_ticks = (results[major_ticks_enabled_idx] as DialogCheckbox).value;
    if (!(use_major_tick_distance || use_major_tick_periodic_distances || use_major_ticks)) {
      return;
    }

    bool apply_to_all = (results[apply_to_all_idx] as DialogCheckbox).value;
    bool apply_to_some = (results[apply_to_some_idx] as DialogCheckbox).value;

    List<int> major_ticks = null;
    int major_tick_distance = null;
    List<int> major_tick_periodic_distances = [];

    int major_tick_start = (results[major_tick_start_idx] as DialogNumber).value;
    if (major_tick_start < helix.min_offset) {
      window.alert('''\
${major_tick_start} is not a valid major tick because it is less than the 
minimum offset ${helix.min_offset} of helix ${helix.min_offset}.''');
      return;
    }

    if (use_major_ticks) {
      String major_ticks_str = (results[major_ticks_distances_idx] as DialogText).value;
      major_ticks = parse_major_ticks_and_check_validity(major_ticks_str, helix, apply_to_all);
      if (major_ticks == null) {
        return;
      }
    } else if (use_major_tick_distance) {
      major_tick_distance = (results[regular_spacing_distance_idx] as DialogNumber).value;
      if (major_tick_distance <= 0) {
        window.alert('${major_tick_distance} is not a valid distance because it is not positive.');
        return;
      }
    } else if (use_major_tick_periodic_distances) {
      String periodic_distances_str = (results[periodic_spacing_distances_idx] as DialogText).value;
      major_tick_periodic_distances = parse_major_tick_distances_and_check_validity(periodic_distances_str);
      if (major_tick_periodic_distances == null) {
        return;
      }
    } else {
      throw AssertionError('should not be reachable');
    }

    actions.Action action;
    if (apply_to_all) {
      if (use_major_tick_distance) {
        action = actions.BatchAction([
          actions.HelixMajorTickDistanceChangeAll(major_tick_distance: major_tick_distance),
          actions.HelixMajorTickStartChangeAll(major_tick_start: major_tick_start),
        ]);
      } else if (use_major_tick_periodic_distances) {
        action = actions.BatchAction([
          actions.HelixMajorTickPeriodicDistancesChangeAll(
              major_tick_periodic_distances: major_tick_periodic_distances.build()),
          actions.HelixMajorTickStartChangeAll(major_tick_start: major_tick_start),
        ]);
      } else if (use_major_ticks) {
        action = actions.HelixMajorTicksChangeAll(major_ticks: major_ticks.build());
      } else {
        throw AssertionError('should not be reachable');
      }
    } else if (apply_to_some) {
      String helix_idxs_str = (results[apply_to_some_helices_idx] as DialogText).value;
      List<int> helix_idxs = parse_helix_idxs_and_check_validity(helix_idxs_str);
      List<actions.UndoableAction> all_actions = [];
      for (int this_helix_idx in helix_idxs) {
        if (use_major_tick_distance) {
          all_actions.addAll([
            actions.HelixMajorTickDistanceChange(
                helix_idx: this_helix_idx, major_tick_distance: major_tick_distance),
            actions.HelixMajorTickStartChange(helix_idx: this_helix_idx, major_tick_start: major_tick_start),
          ]);
        } else if (use_major_tick_periodic_distances) {
          all_actions.addAll([
            actions.HelixMajorTickPeriodicDistancesChange(
                helix_idx: this_helix_idx,
                major_tick_periodic_distances: major_tick_periodic_distances.build()),
            actions.HelixMajorTickStartChange(helix_idx: this_helix_idx, major_tick_start: major_tick_start),
          ]);
        } else if (use_major_ticks) {
          all_actions.add(
              actions.HelixMajorTicksChange(helix_idx: this_helix_idx, major_ticks: major_ticks.build()));
        } else {
          throw AssertionError('should not be reachable');
        }
      }
      action = actions.BatchAction(all_actions);
    } else {
      if (use_major_tick_distance) {
        action = actions.BatchAction([
          actions.HelixMajorTickDistanceChange(
              helix_idx: helix_idx, major_tick_distance: major_tick_distance),
          actions.HelixMajorTickStartChange(helix_idx: helix_idx, major_tick_start: major_tick_start),
        ]);
      } else if (use_major_tick_periodic_distances) {
        action = actions.BatchAction([
          actions.HelixMajorTickPeriodicDistancesChange(
              helix_idx: helix_idx, major_tick_periodic_distances: major_tick_periodic_distances.build()),
          actions.HelixMajorTickStartChange(helix_idx: helix_idx, major_tick_start: major_tick_start),
        ]);
      } else if (use_major_ticks) {
        action = actions.HelixMajorTicksChange(helix_idx: helix_idx, major_ticks: major_ticks.build());
      } else {
        throw AssertionError('should not be reachable');
      }
    }
    app.dispatch(action);
  }

  Future<void> dialog_helix_adjust_grid_position() async {
    var grid_position = helix.grid_position ?? GridPosition(0, 0);

    var dialog = Dialog(title: 'adjust helix grid position', items: [
      DialogNumber(label: 'h', value: grid_position.h),
      DialogNumber(label: 'v', value: grid_position.v),
    ]);

    List<DialogItem> results = await util.dialog(dialog);
    if (results == null) return;

    num h = (results[0] as DialogNumber).value;
    num v = (results[1] as DialogNumber).value;

    app.dispatch(actions.HelixGridPositionSet(helix: helix, grid_position: GridPosition(h, v)));
  }

  Future<void> dialog_helix_adjust_position() async {
    var position = helix.position ?? Position3D();

    var dialog = Dialog(title: 'adjust helix position', items: [
      DialogFloatingNumber(label: 'x', value: position.x),
      DialogFloatingNumber(label: 'y', value: position.y),
      DialogFloatingNumber(label: 'z', value: position.z),
    ]);

    List<DialogItem> results = await util.dialog(dialog);
    if (results == null) return;

    num x = (results[0] as DialogFloatingNumber).value;
    num y = (results[1] as DialogFloatingNumber).value;
    num z = (results[2] as DialogFloatingNumber).value;

    // TODO: (check validity)
    app.dispatch(actions.HelixPositionSet(
        helix_idx: helix.idx,
        position: Position3D(
          x: x,
          y: y,
          z: z,
        )));
  }

  helix_adjust_length() {
    app.disable_keyboard_shortcuts_while(dialog_helix_adjust_length);
  }

  helix_adjust_major_tick_marks() {
    app.disable_keyboard_shortcuts_while(dialog_helix_adjust_major_tick_marks);
  }

  helix_adjust_roll() {
    app.disable_keyboard_shortcuts_while(dialog_helix_adjust_roll);
  }

  helix_adjust_position() {
    app.disable_keyboard_shortcuts_while(dialog_helix_adjust_position);
  }

  helix_adjust_grid_position() {
    app.disable_keyboard_shortcuts_while(dialog_helix_adjust_grid_position);
  }

  ContextMenuItem context_menu_item_adjust_position = (helix.grid == Grid.none)
      ? ContextMenuItem(
          title: 'adjust position',
          on_click: helix_adjust_position,
        )
      : ContextMenuItem(
          title: 'adjust grid position',
          on_click: helix_adjust_grid_position,
        );

  return [
    ContextMenuItem(
      title: 'adjust length',
      on_click: helix_adjust_length,
    ),
    ContextMenuItem(
      title: 'adjust tick marks',
      on_click: helix_adjust_major_tick_marks,
    ),
    ContextMenuItem(
      title: 'adjust roll',
      on_click: helix_adjust_roll,
    ),
    context_menu_item_adjust_position,
  ];
}

List<int> parse_major_ticks_and_check_validity(String major_ticks_str, Helix helix, bool apply_to_all) {
  List<String> major_ticks_strs =
      major_ticks_str.trim().split(' ').where((token) => token.isNotEmpty).toList();
  List<int> major_ticks = [];
  for (var major_tick_str in major_ticks_strs) {
    int major_tick = int.tryParse(major_tick_str);
    if (major_tick == null) {
      window.alert('"${major_tick_str}" is not a valid integer');
      return null;
    } else if (major_tick <= 0 && major_ticks.isNotEmpty) {
      window.alert('''\
non-positive value ${major_tick} can only be used if it is the first element 
in the list, specifying where the first tick should be; all others must be 
positive offsets from the previous tick mark''');
      return null;
    } else {
      major_ticks.add(major_tick + (major_ticks.isEmpty ? 0 : major_ticks.last));
    }
  }

  int t = major_ticks.firstWhere((t) => t < helix.min_offset, orElse: () => null);
  if (t != null) {
    window.alert('major tick ${t} is less than minimum offset ${helix.min_offset}');
    return null;
  }

  // TODO: avoid global variable here if possible (move this logic to middleware)
  if (apply_to_all) {
    for (var other_helix in app.state.dna_design.helices.values) {
      t = major_ticks.firstWhere((t) => t < other_helix.min_offset, orElse: () => null);
      if (t != null) {
        window.alert('major tick ${t} is less than minimum offset ${other_helix.min_offset}');
        return null;
      }
    }
//      for (var other_helix in app.state.dna_design.helices.values) {
//        t = major_ticks.firstWhere((t) => t > other_helix.max_offset, orElse: () => null);
//        if (t != null) {
//          window.alert("major tick ${t} is greater than maximum offset ${other_helix.max_offset}, "
//              "so I'm only going up to the major tick just before that");
//        }
//      }
  }
  return major_ticks;
}

List<int> parse_major_tick_distances_and_check_validity(String major_tick_distances_str) {
  List<String> major_tick_distances_strs =
      major_tick_distances_str.trim().split(' ').where((token) => token.isNotEmpty).toList();
  List<int> major_tick_distances = [];
  for (var major_tick_distance_str in major_tick_distances_strs) {
    int major_tick_distance = int.tryParse(major_tick_distance_str);
    if (major_tick_distance == null) {
      window.alert('"${major_tick_distance_str}" is not a valid integer');
      return null;
    } else if (major_tick_distance <= 0) {
      window.alert('${major_tick_distance} is not a valid distance because it is not positive.');
      return null;
    } else {
      major_tick_distances.add(major_tick_distance);
    }
  }

  return major_tick_distances;
}

List<int> parse_helix_idxs_and_check_validity(String helix_idxs_str) {
  List<String> helix_idxs_strs = helix_idxs_str.trim().split(' ').where((token) => token.isNotEmpty).toList();
  List<int> helix_idxs = [];
  for (var helix_idx_str in helix_idxs_strs) {
    int helix_idx = int.tryParse(helix_idx_str);
    if (helix_idx == null) {
      window.alert('"${helix_idx}" is not a valid integer');
      return null;
    } else if (!app.state.dna_design.helices.keys.contains(helix_idx)) {
      // TODO: avoid global variable here if possible (move this logic to middleware)
      window.alert('${helix_idx} is not the index of any helix in this design');
      return null;
    } else {
      helix_idxs.add(helix_idx);
    }
  }

  return helix_idxs;
}