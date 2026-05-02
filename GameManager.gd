extends Node2D

enum GameState { TITLE, PLAYING, RESULT }
var current_state: GameState = GameState.TITLE

@onready var message_label: Label = $GameUI/Panel/MessageLabel
@onready var time_label: Label = $GameUI/TimeLabel
@onready var title_panel: Panel = $GameUI/TitlePanel
@onready var result_panel: Panel = $GameUI/ResultPanel
@onready var score_label: Label = $GameUI/ResultPanel/ScoreLabel
@onready var ship_button: Button = $GameUI/ShipButton

var element_scene = preload("res://Element.tscn")

var orders = [
	{
		"name": "水 (H2O)",
		"message": "店長「まずは基本だ！水（H2O）を作ってくれ！」",
		"sockets": {"Socket1": "H", "Socket2": "O", "Socket3": "H"}
	},
	{
		"name": "二酸化炭素 (CO2)",
		"message": "店長「よし！次は二酸化炭素（CO2）だ！」",
		"sockets": {"Socket1": "O", "Socket2": "C", "Socket3": "O"}
	}
]

var current_order_index: int = 0
var current_order: Dictionary

var time_left: float = 60.0
var score: int = 0

func _ready() -> void:
	_change_state(GameState.TITLE)

func _draw() -> void:
	if current_state == GameState.TITLE or current_order.is_empty():
		return
	var sockets = get_tree().get_nodes_in_group("sockets")
	for socket in sockets:
		# ソケットの位置にガイドの円を描画
		draw_circle(socket.position, 60.0, Color(0.2, 0.2, 0.2, 0.5))
		
		# ソケットに指定されている元素記号を描画
		if current_order["sockets"].has(socket.name):
			var req = current_order["sockets"][socket.name]
			draw_string(ThemeDB.fallback_font, socket.position + Vector2(-10, 10), req, HORIZONTAL_ALIGNMENT_CENTER, -1, 32, Color(1, 1, 1, 0.5))

func _change_state(new_state: GameState) -> void:
	current_state = new_state
	
	# いったんすべて非表示＆無効化
	title_panel.visible = false
	result_panel.visible = false
	ship_button.disabled = true
	time_label.visible = false
	
	match current_state:
		GameState.TITLE:
			title_panel.visible = true
		GameState.PLAYING:
			time_label.visible = true
			ship_button.disabled = false
			score = 0
			time_left = 60.0
			current_order_index = 0
			_load_order(current_order_index)
			queue_redraw()
		GameState.RESULT:
			result_panel.visible = true
			score_label.text = "出荷数: %d 個" % score
			message_label.text = "本日の営業は終了だ！"
			message_label.modulate = Color(1, 1, 1)
			queue_redraw()

func _process(delta: float) -> void:
	if current_state == GameState.PLAYING:
		time_left -= delta
		if time_left <= 0:
			time_left = 0
			_change_state(GameState.RESULT)
		time_label.text = "TIME: %d" % int(time_left)

func _on_start_button_pressed() -> void:
	_change_state(GameState.PLAYING)

func _on_retry_button_pressed() -> void:
	get_tree().reload_current_scene()

func _load_order(index: int) -> void:
	if index < orders.size():
		current_order = orders[index]
	else:
		# お題が尽きた場合は最初からループさせる
		current_order_index = 0
		current_order = orders[0]
		
	message_label.text = current_order["message"]
	message_label.modulate = Color(1, 1, 1)
	queue_redraw()
	
	# 既存のElementを消去
	var old_elements = get_tree().get_nodes_in_group("elements")
	for el in old_elements:
		el.queue_free()
		
	# お題に応じたElementを生成
	if current_state == GameState.PLAYING:
		var required_types = current_order["sockets"].values()
		var start_x = 200
		var spacing = 150
		for i in range(required_types.size()):
			var el = element_scene.instantiate()
			el.element_type = required_types[i]
			el.global_position = Vector2(start_x + (i * spacing), 450)
			# Socketsの兄弟であるElementsノードに追加
			if has_node("Elements"):
				$Elements.add_child(el)
			else:
				add_child(el)

func _on_ship_button_pressed() -> void:
	if current_state != GameState.PLAYING or current_order.is_empty():
		return
		
	var sockets = get_tree().get_nodes_in_group("sockets")
	var is_correct = true
	var target_sockets = current_order["sockets"]
	
	for socket in sockets:
		var socket_name = socket.name
		# そのソケットがお題に含まれているか
		if target_sockets.has(socket_name):
			# ステップ1: ソケットに元素がスナップしているか？
			if not socket.has_meta("attached_element") or socket.get_meta("attached_element") == null:
				is_correct = false
				break
				
			var element = socket.get_meta("attached_element")
			
			# ステップ3: 種類が一致しているか？
			if element.element_type != target_sockets[socket_name]:
				is_correct = false
				break
		else:
			# お題に含まれないソケットの場合
			if socket.has_meta("attached_element") and socket.get_meta("attached_element") != null:
				is_correct = false
				break
			
	if is_correct:
		_success_animation(sockets)
	else:
		_failure_animation(sockets)

func _success_animation(sockets: Array[Node]) -> void:
	message_label.text = "スポンッ！完璧だ！出荷完了！"
	message_label.modulate = Color(0.2, 1.0, 0.2)
	ship_button.disabled = true
	score += 1 # スコア加算
	
	var elements_to_free = []
	var tween = create_tween().set_parallel(true)
	for socket in sockets:
		if socket.has_meta("attached_element") and socket.get_meta("attached_element") != null:
			var element = socket.get_meta("attached_element")
			elements_to_free.append(element)
			tween.tween_property(element, "global_position:x", element.global_position.x + 500, 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			socket.remove_meta("attached_element")
			
	tween.chain().tween_callback(func():
		for element in elements_to_free:
			if is_instance_valid(element):
				element.queue_free()
		# 状態がPLAYINGのままなら次へ
		if current_state == GameState.PLAYING:
			current_order_index += 1
			_load_order(current_order_index)
			ship_button.disabled = false
	)

func _failure_animation(sockets: Array[Node]) -> void:
	message_label.text = "ガコンッ！形が違うぞ！やり直し！"
	message_label.modulate = Color(1.0, 0.2, 0.2)
	ship_button.disabled = true
	
	var press_machine = $PressMachine
	var original_press_y = press_machine.global_position.y
	var target_y = 300
	
	var tween = create_tween()
	tween.tween_property(press_machine, "global_position:y", target_y, 0.2).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	tween.tween_callback(func():
		_shake_camera()
		for socket in sockets:
			if socket.has_meta("attached_element") and socket.get_meta("attached_element") != null:
				var element = socket.get_meta("attached_element")
				element.scale.y = 0.1
	)
	tween.tween_interval(1.0)
	tween.tween_property(press_machine, "global_position:y", original_press_y, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func():
		for socket in sockets:
			if socket.has_meta("attached_element") and socket.get_meta("attached_element") != null:
				var element = socket.get_meta("attached_element")
				if is_instance_valid(element):
					# キューフリーせずに、スケールを戻して初期位置へ飛ばす（やり直し可能にする）
					element.scale.y = 1.0
					if "default_position" in element:
						var move_tween = create_tween()
						move_tween.tween_property(element, "global_position", element.default_position, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
				socket.remove_meta("attached_element")
		# 状態がPLAYINGのままならボタン復活
		if current_state == GameState.PLAYING:
			ship_button.disabled = false
			message_label.text = current_order["message"]
			message_label.modulate = Color(1, 1, 1)
	)

func _shake_camera() -> void:
	if not has_node("Camera2D"):
		return
	var camera = $Camera2D
	var shake_tween = create_tween()
	for i in range(10):
		var rand_offset = Vector2(randf_range(-15, 15), randf_range(-15, 15))
		shake_tween.tween_property(camera, "offset", rand_offset, 0.02)
	shake_tween.tween_property(camera, "offset", Vector2.ZERO, 0.02)
