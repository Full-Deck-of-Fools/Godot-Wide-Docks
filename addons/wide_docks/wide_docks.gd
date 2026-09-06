@tool
extends EditorPlugin

const MAIN_SPLIT_NAME: String = "DockHSplitMain"
const CENTER_SPLIT_NAME: String = "DockVSplitCenter"
const MIN_CENTER_WIDTH: float = 1.0

const META_ORIGINAL_CENTER_SPLIT_MAX: StringName = &"__wide_docks_v13_original_center_split_max"
const META_ORIGINAL_CENTER_CLIP: StringName = &"__wide_docks_v13_original_center_clip"

const META_LEGACY_CENTER_MAX: StringName = &"__wide_docks_original_maximum_size"
const META_LEGACY_CENTER_CLIP: StringName = &"__wide_docks_original_clip_contents"

var _main_split: SplitContainer = null
var _center_container: Control = null
var _center_split: Control = null

var _original_center_split_max: Vector2 = Vector2(-1.0, -1.0)
var _original_center_clip: bool = false

var _active_dragger_index: int = -1
var _active_center_index: int = -1
var _drag_start_pointer_x: float = 0.0
var _drag_start_center_width: float = 0.0

var _connected_draggers: Array[Control] = []
var _connected_callbacks: Array[Callable] = []
var _dragger_signature: Array[int] = []

var _refresh_pending: bool = false
var _sync_pending: bool = false

func _enter_tree() -> void:
	call_deferred("_install")

func _exit_tree() -> void:
	_disconnect_runtime_signals()
	_clear_active_drag()

	_main_split = null
	_center_container = null
	_center_split = null

func _disable_plugin() -> void:
	_restore_original_editor_state()

func _install() -> void:
	var editor_root: Control = EditorInterface.get_base_control()
	var found_main: Node = editor_root.find_child(
		MAIN_SPLIT_NAME,
		true,
		false
	)

	if found_main == null or not found_main is SplitContainer:
		push_warning(
			"Wide Docks: DockHSplitMain was not found as a SplitContainer."
		)
		return

	_main_split = found_main as SplitContainer

	var found_center_split: Node = _main_split.find_child(
		CENTER_SPLIT_NAME,
		true,
		false
	)

	if found_center_split == null or not found_center_split is Control:
		push_warning(
			"Wide Docks: DockVSplitCenter was not found."
		)
		_main_split = null
		return

	_center_split = found_center_split as Control

	var center_parent: Node = _center_split.get_parent()
	if center_parent == null or not center_parent is Control:
		push_warning(
			"Wide Docks: DockVSplitCenter has an unexpected parent."
		)
		_main_split = null
		_center_split = null
		return

	_center_container = center_parent as Control

	if _center_container.get_parent() != _main_split:
		push_warning(
			"Wide Docks: Editor hierarchy does not match Godot 4.7.2."
		)
		_main_split = null
		_center_split = null
		_center_container = null
		return

	_migrate_legacy_state()
	_capture_original_state()

	_center_container.clip_contents = true

	_connect_runtime_signals()
	_refresh_dragger_connections()

	_sync_cap_to_actual_center_width()

func _migrate_legacy_state() -> void:
	if not is_instance_valid(_center_container):
		return

	if _center_container.has_meta(META_LEGACY_CENTER_MAX):
		var old_max: Variant = _center_container.get_meta(
			META_LEGACY_CENTER_MAX
		)

		if old_max is Vector2:
			_center_container.custom_maximum_size = old_max as Vector2

		_center_container.remove_meta(META_LEGACY_CENTER_MAX)


func _capture_original_state() -> void:
	if not is_instance_valid(_center_split):
		return
	if not is_instance_valid(_center_container):
		return

	if _center_split.has_meta(META_ORIGINAL_CENTER_SPLIT_MAX):
		var stored_max: Variant = _center_split.get_meta(
			META_ORIGINAL_CENTER_SPLIT_MAX
		)

		if stored_max is Vector2:
			_original_center_split_max = stored_max as Vector2
	else:
		_original_center_split_max = _center_split.custom_maximum_size
		_center_split.set_meta(
			META_ORIGINAL_CENTER_SPLIT_MAX,
			_original_center_split_max
		)

	if _center_container.has_meta(META_ORIGINAL_CENTER_CLIP):
		_original_center_clip = bool(
			_center_container.get_meta(META_ORIGINAL_CENTER_CLIP)
		)
	elif _center_container.has_meta(META_LEGACY_CENTER_CLIP):
		_original_center_clip = bool(
			_center_container.get_meta(META_LEGACY_CENTER_CLIP)
		)
		_center_container.remove_meta(META_LEGACY_CENTER_CLIP)
		_center_container.set_meta(
			META_ORIGINAL_CENTER_CLIP,
			_original_center_clip
		)
	else:
		_original_center_clip = _center_container.clip_contents
		_center_container.set_meta(
			META_ORIGINAL_CENTER_CLIP,
			_original_center_clip
		)


func _connect_runtime_signals() -> void:
	if not is_instance_valid(_main_split):
		return
	if not is_instance_valid(_center_container):
		return

	var sort_callback: Callable = Callable(
		self,
		"_on_main_split_sorted"
	)
	if not _main_split.sort_children.is_connected(sort_callback):
		_main_split.sort_children.connect(sort_callback)

	var resize_callback: Callable = Callable(
		self,
		"_on_center_resized"
	)
	if not _center_container.resized.is_connected(resize_callback):
		_center_container.resized.connect(resize_callback)


func _disconnect_runtime_signals() -> void:
	_disconnect_dragger_connections()

	if is_instance_valid(_main_split):
		var sort_callback: Callable = Callable(
			self,
			"_on_main_split_sorted"
		)
		if _main_split.sort_children.is_connected(sort_callback):
			_main_split.sort_children.disconnect(sort_callback)

	if is_instance_valid(_center_container):
		var resize_callback: Callable = Callable(
			self,
			"_on_center_resized"
		)
		if _center_container.resized.is_connected(resize_callback):
			_center_container.resized.disconnect(resize_callback)


func _get_visible_main_children() -> Array[Control]:
	var result: Array[Control] = []

	if not is_instance_valid(_main_split):
		return result

	for child: Node in _main_split.get_children():
		if child is Control:
			var control: Control = child as Control

			if control.visible and not control.is_set_as_top_level():
				result.append(control)

	return result


func _get_dragger_signature() -> Array[int]:
	var result: Array[int] = []

	if not is_instance_valid(_main_split):
		return result

	var draggers: Array[Control] = _main_split.get_drag_area_controls()

	for dragger: Control in draggers:
		if is_instance_valid(dragger):
			result.append(int(dragger.get_instance_id()))

	return result


func _refresh_dragger_connections() -> void:
	_refresh_pending = false

	if not is_instance_valid(_main_split):
		return

	_disconnect_dragger_connections()

	var draggers: Array[Control] = _main_split.get_drag_area_controls()

	for dragger_index: int in range(draggers.size()):
		var dragger: Control = draggers[dragger_index]

		if not is_instance_valid(dragger):
			continue

		var callback: Callable = Callable(
			self,
			"_on_dragger_gui_input"
		).bind(dragger_index)

		if not dragger.gui_input.is_connected(callback):
			dragger.gui_input.connect(callback)

		_connected_draggers.append(dragger)
		_connected_callbacks.append(callback)

	_dragger_signature = _get_dragger_signature()


func _disconnect_dragger_connections() -> void:
	var count: int = mini(
		_connected_draggers.size(),
		_connected_callbacks.size()
	)

	for index: int in range(count):
		var dragger: Control = _connected_draggers[index]
		var callback: Callable = _connected_callbacks[index]

		if (
			is_instance_valid(dragger)
			and dragger.gui_input.is_connected(callback)
		):
			dragger.gui_input.disconnect(callback)

	_connected_draggers.clear()
	_connected_callbacks.clear()
	_dragger_signature.clear()


func _on_main_split_sorted() -> void:
	if _active_dragger_index >= 0:
		_latch_internal_center_to_actual_width()

	var current_signature: Array[int] = _get_dragger_signature()

	if current_signature == _dragger_signature:
		return

	if _refresh_pending:
		return

	_refresh_pending = true
	call_deferred("_refresh_dragger_connections")


func _latch_internal_center_to_actual_width() -> void:
	if not is_instance_valid(_center_container):
		return
	if not is_instance_valid(_center_split):
		return

	_set_internal_center_cap(
		maxf(MIN_CENTER_WIDTH, _center_container.size.x)
	)


func _on_dragger_gui_input(
	event: InputEvent,
	dragger_index: int
) -> void:
	if not is_instance_valid(_main_split):
		return
	if not is_instance_valid(_center_container):
		return
	if not is_instance_valid(_center_split):
		return

	if event is InputEventMouseButton:
		var button_event: InputEventMouseButton = (
			event as InputEventMouseButton
		)

		if button_event.button_index != MOUSE_BUTTON_LEFT:
			return

		if button_event.pressed:
			_try_begin_drag(
				dragger_index,
				button_event.global_position.x
			)
		elif _active_dragger_index == dragger_index:
			call_deferred("_finish_drag_after_native_release")

	elif event is InputEventMouseMotion:
		if _active_dragger_index != dragger_index:
			return

		var motion_event: InputEventMouseMotion = (
			event as InputEventMouseMotion
		)

		_update_cap_for_pointer_x(
			motion_event.global_position.x
		)


func _try_begin_drag(
	dragger_index: int,
	pointer_x: float
) -> void:
	var visible_children: Array[Control] = _get_visible_main_children()
	var center_index: int = visible_children.find(_center_container)

	if center_index < 0:
		return

	var touches_left_edge: bool = dragger_index == center_index - 1
	var touches_right_edge: bool = dragger_index == center_index

	if not touches_left_edge and not touches_right_edge:
		return

	_active_dragger_index = dragger_index
	_active_center_index = center_index
	_drag_start_pointer_x = pointer_x
	_drag_start_center_width = _center_container.size.x

	_set_internal_center_cap(_drag_start_center_width)


func _update_cap_for_pointer_x(pointer_x: float) -> void:
	if _active_dragger_index < 0:
		return
	if _active_center_index < 0:
		return

	var delta_x: float = pointer_x - _drag_start_pointer_x

	if _main_split.is_layout_rtl():
		delta_x = -delta_x

	var requested_width: float = _drag_start_center_width

	if _active_dragger_index == _active_center_index - 1:
		requested_width -= delta_x
	elif _active_dragger_index == _active_center_index:
		requested_width += delta_x
	else:
		return

	requested_width = clampf(
		requested_width,
		MIN_CENTER_WIDTH,
		maxf(MIN_CENTER_WIDTH, _main_split.size.x)
	)

	_set_internal_center_cap(requested_width)


func _set_internal_center_cap(width: float) -> void:
	if not is_instance_valid(_center_split):
		return
	if not is_instance_valid(_center_container):
		return

	var requested_width: float = maxf(MIN_CENTER_WIDTH, width)
	var new_max: Vector2 = _original_center_split_max

	if _original_center_split_max.x >= 0.0:
		new_max.x = minf(
			requested_width,
			_original_center_split_max.x
		)
	else:
		new_max.x = requested_width

	if _center_split.custom_maximum_size == new_max:
		return

	_center_split.custom_maximum_size = new_max

	_center_container.update_minimum_size()


func _finish_drag_after_native_release() -> void:
	_clear_active_drag()
	_sync_cap_to_actual_center_width()


func _clear_active_drag() -> void:
	_active_dragger_index = -1
	_active_center_index = -1
	_drag_start_pointer_x = 0.0
	_drag_start_center_width = 0.0


func _on_center_resized() -> void:
	if _active_dragger_index >= 0:
		return

	if _sync_pending:
		return

	_sync_pending = true
	call_deferred("_sync_cap_to_actual_center_width")


func _sync_cap_to_actual_center_width() -> void:
	_sync_pending = false

	if not is_instance_valid(_center_container):
		return
	if not is_instance_valid(_center_split):
		return

	_set_internal_center_cap(
		maxf(MIN_CENTER_WIDTH, _center_container.size.x)
	)


func _restore_original_editor_state() -> void:
	_disconnect_runtime_signals()

	if is_instance_valid(_center_split):
		_center_split.custom_maximum_size = _original_center_split_max

		if _center_split.has_meta(META_ORIGINAL_CENTER_SPLIT_MAX):
			_center_split.remove_meta(
				META_ORIGINAL_CENTER_SPLIT_MAX
			)

	if is_instance_valid(_center_container):
		_center_container.clip_contents = _original_center_clip

		if _center_container.has_meta(META_ORIGINAL_CENTER_CLIP):
			_center_container.remove_meta(
				META_ORIGINAL_CENTER_CLIP
			)

		if _center_container.has_meta(META_LEGACY_CENTER_MAX):
			var old_max: Variant = _center_container.get_meta(
				META_LEGACY_CENTER_MAX
			)

			if old_max is Vector2:
				_center_container.custom_maximum_size = (
					old_max as Vector2
				)

			_center_container.remove_meta(
				META_LEGACY_CENTER_MAX
			)

		if _center_container.has_meta(META_LEGACY_CENTER_CLIP):
			_center_container.remove_meta(
				META_LEGACY_CENTER_CLIP
			)

		_center_container.update_minimum_size()

	if is_instance_valid(_main_split):
		_main_split.queue_sort()

	_clear_active_drag()
