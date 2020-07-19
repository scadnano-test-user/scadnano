import 'dart:html';

import 'package:redux/redux.dart';

import '../state/grid_position.dart';
import '../actions/actions.dart' as actions;
import '../util.dart' as util;
import '../state/app_state.dart';

/// Check whether user wants to remove helix that has strands on it.
helix_grid_offsets_middleware(Store<AppState> store, dynamic action, NextDispatcher next) {
  if (action is actions.GridChange && !action.grid.is_none() && store.state.design.grid.is_none()) {
    Map<int, GridPosition> new_grid_positions_map = {
      for (var helix in store.state.design.helices.values)
        helix.idx: util.position3d_to_grid(helix.position, action.grid)
    };
    Set<GridPosition> new_grid_positions_set = Set<GridPosition>.from(new_grid_positions_map.values);
    // if lengths don't match, there's a duplicate grid position
    if (new_grid_positions_set.length != new_grid_positions_map.length) {
      List<int> idxs = new_grid_positions_map.keys.toList();
      for (int i1 = 0; i1 < idxs.length; i1++) {
        for (int i2 = i1 + 1; i2 < idxs.length; i2++) {
          var h1idx = idxs[i1];
          var h2idx = idxs[i2];
          var gp1 = new_grid_positions_map[h1idx];
          var gp2 = new_grid_positions_map[h2idx];
          if (gp1 == gp2) {
            var helices = store.state.design.helices;
            var pos1 = helices[h1idx].position3d();
            var pos2 = helices[h2idx].position3d();
            var msg = '''\
This design cannot be automatically converted to the ${action.grid.name} grid.
Two helices, with idx values ${h1idx} and ${h2idx}, have positions that are
both closest to grid position (${gp1.h}, ${gp1.v}). They have positions
(${pos1.x}, ${pos1.y}, ${pos1.z}) and 
(${pos2.x}, ${pos2.y}, ${pos2.z}), respectively.
''';
            window.alert(msg);
            return;
          }
        }
      }
    }
  }
  next(action);
}

String message_too_small(int helix_idx, int proposed_offset, int offset_of_strand) {
  return 'Cannot set minimum offset to ${proposed_offset} on helix $helix_idx '
      'because there is a strand on that helix with offset ${offset_of_strand}. '
      'Please choose a smaller minimum offset or delete the strand.';
}

String message_too_large(int helix_idx, int proposed_offset, int offset_of_strand) {
  return 'Cannot set maximum offset to ${proposed_offset} on helix $helix_idx '
      'because there is a strand on that helix with offset ${offset_of_strand}. '
      'Please choose a larger maximum offset or delete the strand.';
}
