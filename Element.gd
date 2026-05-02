extends Area2D

@export var snap_distance: float = 50.0

var dragging: bool = false
var snapped_socket: Node2D = null

func _ready() -> void:
	pass

func _input_event(viewport: Viewport, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_start_drag()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if not event.pressed: # 左クリックを離したとき
			if dragging:
				_stop_drag()

func _process(delta: float) -> void:
	if dragging:
		global_position = get_global_mouse_position()

func _start_drag() -> void:
	dragging = true
	z_index = 100 # ドラッグ中は最前面に表示
	
	# スナップ状態からのドラッグ開始なら、ソケットのメタデータをクリア
	if snapped_socket:
		if snapped_socket.has_meta("attached_element") and snapped_socket.get_meta("attached_element") == self:
			snapped_socket.remove_meta("attached_element")
		snapped_socket = null

func _stop_drag() -> void:
	dragging = false
	z_index = 0
	_snap_to_closest_socket()

func _snap_to_closest_socket() -> void:
	var sockets = get_tree().get_nodes_in_group("sockets")
	var closest_socket: Node2D = null
	var min_distance: float = snap_distance
	
	for socket in sockets:
		# 既に他の元素がスナップしている場合はスキップ
		if socket.has_meta("attached_element") and socket.get_meta("attached_element") != null:
			continue
			
		var distance = global_position.distance_to(socket.global_position)
		if distance <= min_distance:
			min_distance = distance
			closest_socket = socket
			
	if closest_socket:
		snapped_socket = closest_socket
		closest_socket.set_meta("attached_element", self) # ソケットに自身を登録
		
		# 滑らかに吸い付くアニメーション
		var tween = create_tween()
		tween.tween_property(self, "global_position", closest_socket.global_position, 0.1)\
			.set_trans(Tween.TRANS_SINE)\
			.set_ease(Tween.EASE_OUT)
