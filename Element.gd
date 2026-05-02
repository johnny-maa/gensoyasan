extends Area2D

@export var snap_distance: float = 100.0 # スナップ判定を広げて遊びやすくする
@export var element_type: String = "":
	set(value):
		element_type = value
		if is_inside_tree() and has_node("Label"):
			$Label.text = value + " ( ᐛ )"

var dragging: bool = false
var snapped_socket: Node2D = null
var default_position: Vector2

func _ready() -> void:
	# 初期位置を記憶しておく
	default_position = global_position
	add_to_group("elements") # グループに追加
	if has_node("Label"):
		$Label.text = element_type + " ( ᐛ )"

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
	else:
		# どのソケットにもスナップしなかった場合は元の位置に戻す（視覚的なフィードバック）
		var tween = create_tween()
		tween.tween_property(self, "global_position", default_position, 0.2)\
			.set_trans(Tween.TRANS_BACK)\
			.set_ease(Tween.EASE_OUT)
