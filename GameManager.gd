extends Node2D

@onready var message_label: Label = $GameUI/Panel/MessageLabel

func _ready() -> void:
	pass

func _on_ship_button_pressed() -> void:
	var sockets = get_tree().get_nodes_in_group("sockets")
	var all_filled = true
	
	for socket in sockets:
		if not socket.has_meta("attached_element") or socket.get_meta("attached_element") == null:
			all_filled = false
			break
			
	if all_filled:
		message_label.text = "スポンッ！完璧だ！出荷完了！"
		message_label.modulate = Color(0.2, 1.0, 0.2) # 緑っぽくする
	else:
		message_label.text = "ガコンッ！形が違うぞ！やり直し！"
		message_label.modulate = Color(1.0, 0.2, 0.2) # 赤っぽくする
