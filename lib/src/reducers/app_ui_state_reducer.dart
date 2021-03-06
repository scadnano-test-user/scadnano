import 'dart:math';

import 'package:built_collection/built_collection.dart';
import 'package:redux/redux.dart';
import 'package:scadnano/src/state/helix_group_move.dart';
import '../reducers/context_menu_reducer.dart';
import '../state/example_designs.dart';
import '../state/grid_position.dart';
import '../state/local_storage_design_choice.dart';

import '../state/app_state.dart';
import '../state/app_ui_state.dart';
import '../state/app_ui_state_storables.dart';
import '../state/mouseover_data.dart';
import '../reducers/select_mode_state_reducer.dart';
import '../reducers/edit_modes_reducer.dart';
import '../actions/actions.dart' as actions;
import 'dialog_reducer.dart';
import 'domains_move_reducer.dart';
import 'helix_group_move_reducer.dart';
import 'strand_creation_reducer.dart';
import 'strands_move_reducer.dart';
import 'util_reducer.dart';
import 'selection_reducer.dart';
import 'mouseover_datas_reducer.dart';

////////////////////////////////////////////////////////////////////////////////////////////////////////
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// ui state local reducer
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

AppUIState ui_state_local_reducer(AppUIState ui_state, action) => ui_state.rebuild((u) => u
  ..storables.replace(app_ui_state_storable_local_reducer(ui_state.storables, action))
  ..changed_since_last_save = changed_since_last_save_reducer(ui_state.changed_since_last_save, action)
  ..potential_crossover_is_drawing =
      drawing_potential_crossover_reducer(ui_state.potential_crossover_is_drawing, action)
  ..dna_ends_are_moving = moving_dna_ends_reducer(ui_state.dna_ends_are_moving, action)
  ..helix_group_is_moving = helix_group_is_moving_reducer(ui_state.helix_group_is_moving, action)
  ..strands_move = strands_move_local_reducer(ui_state.strands_move, action)?.toBuilder()
  ..domains_move = domains_move_local_reducer(ui_state.domains_move, action)?.toBuilder()
  ..side_view_grid_position_mouse_cursor =
      side_view_mouse_grid_pos_reducer(ui_state.side_view_grid_position_mouse_cursor, action)?.toBuilder()
  ..side_view_position_mouse_cursor =
      side_view_position_mouse_cursor_reducer(ui_state.side_view_position_mouse_cursor, action)
  ..context_menu = context_menu_reducer(ui_state.context_menu, action)?.toBuilder()
  ..dialog = dialog_reducer(ui_state.dialog, action)?.toBuilder()
  ..helix_change_apply_to_all = helix_change_apply_to_all_reducer(ui_state.helix_change_apply_to_all, action)
  ..example_designs.replace(
      TypedReducer<ExampleDesigns, actions.ExampleDesignsLoad>(example_designs_idx_set_reducer)(
          ui_state.example_designs, action))
  ..assign_complement_to_bound_strands_default =
      TypedReducer<bool, actions.AssignDNA>(assign_complement_to_bound_strands_default_reducer)(
          ui_state.assign_complement_to_bound_strands_default, action)
  ..warn_on_change_strand_dna_assign_default =
      TypedReducer<bool, actions.AssignDNA>(warn_on_change_strand_dna_assign_default_reducer)(
          ui_state.warn_on_change_strand_dna_assign_default, action)
  ..mouseover_datas.replace(mouseover_data_reducer(ui_state.mouseover_datas, action))
  ..dna_sequence_png_uri = dna_sequence_png_uri_reducer(ui_state.dna_sequence_png_uri, action)
  ..disable_png_cache_until_action_completes =
      disable_png_cache_until_action_completes(ui_state.disable_png_cache_until_action_completes, action)
  ..is_zoom_above_threshold = is_zoom_above_threshold_reducer(ui_state.is_zoom_above_threshold, action));

bool helix_change_apply_to_all_reducer(bool helix_change_apply_to_all, action) {
  if (action is actions.HelixMajorTickDistanceChange ||
      action is actions.HelixMajorTicksChange ||
      action is actions.HelixOffsetChange) {
    return false;
  } else if (action is actions.HelixMajorTickDistanceChangeAll ||
      action is actions.HelixMajorTicksChangeAll ||
      action is actions.HelixOffsetChangeAll) {
    return true;
  } else {
    return helix_change_apply_to_all;
  }
}

Reducer<bool> drawing_potential_crossover_reducer = combineReducers([
  TypedReducer<bool, actions.PotentialCrossoverCreate>(potential_crossover_create_app_ui_state_reducer),
  TypedReducer<bool, actions.PotentialCrossoverRemove>(potential_crossover_remove_app_ui_state_reducer),
]);

Reducer<bool> moving_dna_ends_reducer = combineReducers([
  TypedReducer<bool, actions.DNAEndsMoveStart>(dna_ends_move_start_app_ui_state_reducer),
  TypedReducer<bool, actions.DNAEndsMoveStop>(dna_ends_move_stop_app_ui_state_reducer),
]);

Reducer<bool> helix_group_is_moving_reducer = combineReducers([
  TypedReducer<bool, actions.HelixGroupMoveStart>(helix_group_move_start_app_ui_state_reducer),
  TypedReducer<bool, actions.HelixGroupMoveStop>(helix_group_move_stop_app_ui_state_reducer),
]);

bool potential_crossover_create_app_ui_state_reducer(bool _, actions.PotentialCrossoverCreate action) => true;

bool potential_crossover_remove_app_ui_state_reducer(bool _, actions.PotentialCrossoverRemove action) =>
    false;

bool dna_ends_move_start_app_ui_state_reducer(bool _, actions.DNAEndsMoveStart action) => true;

bool dna_ends_move_stop_app_ui_state_reducer(bool _, actions.DNAEndsMoveStop action) => false;

bool helix_group_move_start_app_ui_state_reducer(bool _, actions.HelixGroupMoveStart action) => true;

bool helix_group_move_stop_app_ui_state_reducer(bool _, actions.HelixGroupMoveStop action) => false;

bool show_dna_reducer(bool _, actions.ShowDNASet action) => action.show;

bool show_modifications_reducer(bool _, actions.ShowModificationsSet action) => action.show;

bool modification_display_connector_reducer(bool _, actions.SetModificationDisplayConnector action) =>
    action.show;

num modification_font_size_reducer(num _, actions.ModificationFontSizeSet action) => action.font_size;

num major_tick_offset_font_size_reducer(num _, actions.MajorTickOffsetFontSizeSet action) => action.font_size;

num major_tick_width_font_size_reducer(num _, actions.MajorTickWidthFontSizeSet action) => action.font_size;

bool show_mismatches_reducer(bool _, actions.ShowMismatchesSet action) => action.show;

bool invert_yz_reducer(bool _, actions.InvertYZSet action)
{print('setting invert_yz to ${action.invert_yz}'); return action.invert_yz;}
//=> action.invert_yz;

bool warn_on_exit_if_unsaved_reducer(bool _, actions.WarnOnExitIfUnsavedSet action) => action.warn;

bool show_helix_circles_main_view_reducer(bool _, actions.ShowHelixCirclesMainViewSet action) =>
    action.show_helix_circles_main_view;

bool show_grid_coordinates_side_view_reducer(bool _, actions.ShowGridCoordinatesSideViewSet action) =>
    action.show_grid_coordinates_side_view;

bool display_base_offsets_of_major_ticks_reducer(bool _, actions.DisplayMajorTicksOffsetsSet action) =>
    action.show;

bool display_base_offsets_of_major_ticks_only_first_helix_reducer(
        bool _, actions.SetDisplayBaseOffsetsOfMajorTicksOnlyFirstHelix action) =>
    action.show;

bool display_major_tick_widths_all_helices_reducer(
        bool _, actions.SetDisplayMajorTickWidthsAllHelices action) =>
    action.show;

bool display_major_tick_widths_reducer(bool _, actions.SetDisplayMajorTickWidths action) => action.show;

bool strand_paste_keep_color_reducer(bool _, actions.StrandPasteKeepColorSet action) => action.keep;

bool center_on_load_reducer(bool _, actions.AutofitSet action) => action.autofit;

bool show_editor_reducer(bool _, actions.SetShowEditor action) => action.show;

bool only_display_selected_helices_reducer(bool _, actions.SetOnlyDisplaySelectedHelices action) =>
    action.only_display_selected_helices;

bool default_crossover_type_scaffold_for_setting_helix_rolls_reducer(
        bool _, actions.DefaultCrossoverTypeForSettingHelixRollsSet action) =>
    action.scaffold;

bool default_crossover_type_staple_for_setting_helix_rolls_reducer(
        bool _, actions.DefaultCrossoverTypeForSettingHelixRollsSet action) =>
    action.staple;

bool assign_complement_to_bound_strands_default_reducer(bool _, actions.AssignDNA action) =>
    action.assign_complements;

bool warn_on_change_strand_dna_assign_default_reducer(bool _, actions.AssignDNA action) =>
    action.warn_on_change;

Reducer<bool> show_mousever_rect_reducer = combineReducers([
  TypedReducer<bool, actions.ShowMouseoverRectSet>(show_mouseover_rect_set_reducer),
  TypedReducer<bool, actions.ShowMouseoverRectToggle>(show_mouseover_rect_toggle_reducer),
]);

bool show_mouseover_rect_set_reducer(bool prev_show, actions.ShowMouseoverRectSet action) => action.show;

bool show_mouseover_rect_toggle_reducer(bool prev_show, actions.ShowMouseoverRectToggle action) => !prev_show;

Reducer<bool> changed_since_last_save_reducer = combineReducers([
  TypedReducer<bool, actions.UndoableAction>(changed_since_last_save_undoable_action_reducer),
  TypedReducer<bool, actions.SaveDNAFile>(changed_since_last_save_just_saved_reducer),
]);

LocalStorageDesignChoice local_storage_design_choice_reducer(
        LocalStorageDesignChoice _, actions.LocalStorageDesignChoiceSet action) =>
    action.choice.period_seconds > 0 ? action.choice : action.choice.change_period(1);

bool changed_since_last_save_undoable_action_reducer(
        bool changed_since_last_save, actions.UndoableAction action) =>
    true;

bool changed_since_last_save_just_saved_reducer(bool changed_since_last_save, actions.SaveDNAFile action) =>
    false;

Reducer<BuiltList<MouseoverData>> mouseover_data_reducer = combineReducers([
  TypedReducer<BuiltList<MouseoverData>, actions.MouseoverDataClear>(mouseover_data_clear_reducer),
]);

ExampleDesigns example_designs_idx_set_reducer(
        ExampleDesigns example_designs, actions.ExampleDesignsLoad action) =>
    example_designs.rebuild((b) => b..selected_idx = action.selected_idx);

///////////////////////////////////////////////////////////////////////////////////////////////////
// storables global reducer

AppUIStateStorables app_ui_state_storable_global_reducer(
    AppUIStateStorables storables, AppState state, action) {
  // forgot why we made special case for this, but it seems appropriate since it's updating the whole
  // storables object and not just slices
  if (action is actions.SetAppUIStateStorable) {
    AppUIStateStorables storables = action.storables;
    if (!state.design.groups.containsKey(action.storables.displayed_group_name)) {
      // if displayed_group_name does not exist, must pick a new one
      storables = storables.rebuild((b) => b..displayed_group_name = state.design.groups.keys.first);
    }
    return storables;
  }

  return storables.rebuild((b) => b
    ..side_selected_helix_idxs
        .replace(side_selected_helices_global_reducer(storables.side_selected_helix_idxs, state, action))
    ..displayed_group_name =
        TypedGlobalReducer<String, AppState, actions.GroupRemove>(displayed_group_name_group_remove_reducer)(
            storables.displayed_group_name, state, action));
}

// If we remove the current displayed group, we've got to pick something else to display next
String displayed_group_name_group_remove_reducer(String _, AppState state, actions.GroupRemove __) =>
    state.design.groups.keys.first;

///////////////////////////////////////////////////////////////////////////////////////////////////
// storables local reducer
AppUIStateStorables app_ui_state_storable_local_reducer(AppUIStateStorables storables, action) {
  return storables.rebuild((b) => b
    ..side_selected_helix_idxs
        .replace(side_selected_helices_reducer(storables.side_selected_helix_idxs, action))
    ..displayed_group_name = displayed_group_name_reducer(storables.displayed_group_name, action)
    ..select_mode_state.replace(select_mode_state_reducer(storables.select_mode_state, action))
    ..edit_modes.replace(edit_modes_reducer(storables.edit_modes, action))
    ..show_dna = TypedReducer<bool, actions.ShowDNASet>(show_dna_reducer)(storables.show_dna, action)
    ..show_modifications = TypedReducer<bool, actions.ShowModificationsSet>(show_modifications_reducer)(
        storables.show_modifications, action)
    ..modification_display_connector =
        TypedReducer<bool, actions.SetModificationDisplayConnector>(modification_display_connector_reducer)(
            storables.modification_display_connector, action)
    ..modification_font_size = TypedReducer<num, actions.ModificationFontSizeSet>(modification_font_size_reducer)(
        storables.modification_font_size, action)
    ..major_tick_offset_font_size = TypedReducer<num, actions.MajorTickOffsetFontSizeSet>(major_tick_offset_font_size_reducer)(
        storables.major_tick_offset_font_size, action)
    ..major_tick_width_font_size = TypedReducer<num, actions.MajorTickWidthFontSizeSet>(major_tick_width_font_size_reducer)(
        storables.major_tick_width_font_size, action)
    ..show_mismatches = TypedReducer<bool, actions.ShowMismatchesSet>(show_mismatches_reducer)(
        storables.show_mismatches, action)
    ..invert_yz = TypedReducer<bool, actions.InvertYZSet>(invert_yz_reducer)(storables.invert_yz, action)
    ..warn_on_exit_if_unsaved = TypedReducer<bool, actions.WarnOnExitIfUnsavedSet>(warn_on_exit_if_unsaved_reducer)(
        storables.warn_on_exit_if_unsaved, action)
    ..show_helix_circles_main_view = TypedReducer<bool, actions.ShowHelixCirclesMainViewSet>(show_helix_circles_main_view_reducer)(
        storables.show_helix_circles_main_view, action)
    ..show_grid_coordinates_side_view =
        TypedReducer<bool, actions.ShowGridCoordinatesSideViewSet>(show_grid_coordinates_side_view_reducer)(storables.show_grid_coordinates_side_view, action)
    ..local_storage_design_choice = TypedReducer<LocalStorageDesignChoice, actions.LocalStorageDesignChoiceSet>(local_storage_design_choice_reducer)(storables.local_storage_design_choice, action).toBuilder()
    ..strand_paste_keep_color = TypedReducer<bool, actions.StrandPasteKeepColorSet>(strand_paste_keep_color_reducer)(storables.strand_paste_keep_color, action)
    ..autofit = TypedReducer<bool, actions.AutofitSet>(center_on_load_reducer)(storables.autofit, action)
    ..show_editor = TypedReducer<bool, actions.SetShowEditor>(show_editor_reducer)(storables.show_editor, action)
    ..display_base_offsets_of_major_ticks = TypedReducer<bool, actions.DisplayMajorTicksOffsetsSet>(display_base_offsets_of_major_ticks_reducer)(storables.display_base_offsets_of_major_ticks, action)
    ..display_base_offsets_of_major_ticks_only_first_helix = TypedReducer<bool, actions.SetDisplayBaseOffsetsOfMajorTicksOnlyFirstHelix>(display_base_offsets_of_major_ticks_only_first_helix_reducer)(storables.display_base_offsets_of_major_ticks_only_first_helix, action)
    ..display_major_tick_widths = TypedReducer<bool, actions.SetDisplayMajorTickWidths>(display_major_tick_widths_reducer)(storables.display_major_tick_widths, action)
    ..display_major_tick_widths_all_helices = TypedReducer<bool, actions.SetDisplayMajorTickWidthsAllHelices>(display_major_tick_widths_all_helices_reducer)(storables.display_major_tick_widths_all_helices, action)
    ..only_display_selected_helices = TypedReducer<bool, actions.SetOnlyDisplaySelectedHelices>(only_display_selected_helices_reducer)(storables.only_display_selected_helices, action)
    ..default_crossover_type_scaffold_for_setting_helix_rolls = TypedReducer<bool, actions.DefaultCrossoverTypeForSettingHelixRollsSet>(default_crossover_type_scaffold_for_setting_helix_rolls_reducer)(storables.default_crossover_type_scaffold_for_setting_helix_rolls, action)
    ..default_crossover_type_staple_for_setting_helix_rolls = TypedReducer<bool, actions.DefaultCrossoverTypeForSettingHelixRollsSet>(default_crossover_type_staple_for_setting_helix_rolls_reducer)(storables.default_crossover_type_staple_for_setting_helix_rolls, action));
}

Reducer<String> displayed_group_name_reducer = combineReducers([
  TypedReducer<String, actions.GroupDisplayedChange>(displayed_group_name_change_displayed_group_reducer),
  TypedReducer<String, actions.GroupChange>(displayed_group_name_change_name_reducer),
]);

String displayed_group_name_change_displayed_group_reducer(String _, actions.GroupDisplayedChange action) =>
    action.group_name;

String displayed_group_name_change_name_reducer(String displayed_group_name, actions.GroupChange action) =>
    displayed_group_name == action.old_name ? action.new_name : displayed_group_name;

///////////////////////////////////////////////////////////////////////////////////////////////////
// svg-png-caching

String load_dna_sequence_image_uri(String _, actions.LoadDnaSequenceImageUri action) {
  return action.uri;
}

Reducer<String> dna_sequence_png_uri_reducer = combineReducers([
  TypedReducer<String, actions.LoadDnaSequenceImageUri>(load_dna_sequence_image_uri),
]);

actions.Action set_disable_png_cache_until_action_completes(
    actions.Action _, actions.SetDisablePngCacheUntilActionCompletes action) {
  return action.disable_png_cache_until_action_completes;
}

Reducer<actions.Action> disable_png_cache_until_action_completes = combineReducers(([
  TypedReducer<actions.Action, actions.SetDisablePngCacheUntilActionCompletes>(
    set_disable_png_cache_until_action_completes,
  )
]));

bool set_is_zoom_above_threshold(bool _, actions.SetIsZoomAboveThreshold action) {
  return action.is_zoom_above_threshold;
}

Reducer<bool> is_zoom_above_threshold_reducer =
    combineReducers([TypedReducer<bool, actions.SetIsZoomAboveThreshold>(set_is_zoom_above_threshold)]);

///////////////////////////////////////////////////////////////////////////////////////////////////
// side view mouse position/grid position reducers

Reducer<GridPosition> side_view_mouse_grid_pos_reducer = combineReducers([
  TypedReducer<GridPosition, actions.MouseGridPositionSideUpdate>(side_view_mouse_grid_pos_update_reducer),
  TypedReducer<GridPosition, actions.MouseGridPositionSideClear>(side_view_mouse_grid_pos_clear_reducer),
]);

GridPosition side_view_mouse_grid_pos_update_reducer(
        GridPosition _, actions.MouseGridPositionSideUpdate action) =>
    action.grid_position;

GridPosition side_view_mouse_grid_pos_clear_reducer(
        GridPosition _, actions.MouseGridPositionSideClear action) =>
    null;

Reducer<Point<num>> side_view_position_mouse_cursor_reducer = combineReducers([
  TypedReducer<Point<num>, actions.MousePositionSideUpdate>(side_view_mouse_pos_update_reducer),
  TypedReducer<Point<num>, actions.MousePositionSideClear>(side_view_mouse_pos_clear_reducer),
]);

Point<num> side_view_mouse_pos_update_reducer(Point<num> _, actions.MousePositionSideUpdate action) =>
    action.svg_pos;

Point<num> side_view_mouse_pos_clear_reducer(Point<num> _, actions.MousePositionSideClear action) => null;

/////////////////////////////////////////////////////////////////////////////////////////////////////////
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// ui state global reducer
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

AppUIState ui_state_global_reducer(AppUIState ui_state, AppState state, action) => ui_state.rebuild((u) => u
  ..storables.replace(app_ui_state_storable_global_reducer(ui_state.storables, state, action))
  ..selectables_store.replace(selectables_store_reducer(ui_state.selectables_store, state, action))
  ..mouseover_datas.replace(mouseover_datas_global_reducer(ui_state.mouseover_datas, state, action))
  ..strands_move = strands_move_global_reducer(ui_state.strands_move, state, action)?.toBuilder()
  ..domains_move = domains_move_global_reducer(ui_state.domains_move, state, action)?.toBuilder()
  ..strand_creation = strand_creation_global_reducer(ui_state.strand_creation, state, action)?.toBuilder());

GlobalReducer<BuiltList<MouseoverData>, AppState> mouseover_datas_global_reducer = combineGlobalReducers([
  TypedGlobalReducer<BuiltList<MouseoverData>, AppState, actions.HelixRollSetAtOther>(
      helix_rotation_set_at_other_mouseover_reducer),
  TypedGlobalReducer<BuiltList<MouseoverData>, AppState, actions.MouseoverDataUpdate>(
      mouseover_data_update_reducer),
]);
