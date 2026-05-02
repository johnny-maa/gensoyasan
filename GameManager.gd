extends Node2D

@onready var message_label: Label = $GameUI/Panel/MessageLabel

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

func _ready() -> void:
	_load_order(current_order_index)

func _load_order(index: int) -> void:
	if index < orders.size():
		current_order = orders[index]
		message_label.text = current_order["message"]
		message_label.modulate = Color(1, 1, 1)
	else:
		message_label.text = "店長「今日の注文はすべて完了だ！お疲れ様！」"
		message_label.modulate = Color(1, 1, 0)
		$GameUI/ShipButton.disabled = true

func _on_ship_button_pressed() -> void:
	if current_order.is_empty():
		return
		
	var sockets = get_tree().get_nodes_in_group("sockets")
	var is_correct = true
	var target_sockets = current_order["sockets"]
	
	for socket in sockets:
		var socket_name = socket.name
		
		if target_sockets.has(socket_name):
			# 必要なソケットに Element がセットされているか
			if not socket.has_meta("attached_element") or socket.get_meta("attached_element") == null:
				is_correct = false
				break
			
			var element = socket.get_meta("attached_element")
			# Element の種類が一致しているか
			if element.element_type != target_sockets[socket_name]:
				is_correct = false
				break
		else:
			# このお題で不要なソケットに何か置かれていないか
			if socket.has_meta("attached_element") and socket.get_meta("attached_element") != null:
				is_correct = false
				break
			
	if is_correct:
		print("クリア！")
		message_label.text = "スポンッ！完璧だ！出荷完了！"
		message_label.modulate = Color(0.2, 1.0, 0.2)
		
		# 次のお題へ (1.5秒後に表示を更新)
		current_order_index += 1
		get_tree().create_timer(1.5).timeout.connect(func(): _load_order(current_order_index))
		
	else:
		message_label.text = "ガコンッ！形が違うぞ！やり直し！"
		message_label.modulate = Color(1.0, 0.2, 0.2)
