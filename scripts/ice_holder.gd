extends Node2D

var ice_pieces = []
var width = 8
var height = 10
var ice = preload("res://scenes/ice.tscn") # Моя ледяная фигура равна моей ледяной сцене
func _ready(): # Значение функции редди для ледяных кусков
	pass

func make_2d_array():# Это двумерный массив -Название функции и открываем-выполняем её
	var array = []# Временная переменная равная пустому
	for i in width:# ширина
		array.append([])# # Взять массив и добавить в конец к нему целый другой массив
		for j in height:# высота
			array[i].append(null);# Взять массив и ничего не добавить-он пустой
	return array;# И не возвращать
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass



func _on_grid_make_ice(board_position):
	if ice_pieces.size() == 0:
		ice_pieces = make_2d_array()
	var current = ice.instance()
	add_child(current)
	current.position = Vector2(board_position.x * 168 + 126, -board_position.y * 168 + 1880) # координата и Размер по X и по Y
	ice_pieces[board_position.x][board_position.y] = current

func _on_grid_damage_ice(board_position):
	if ice_pieces[board_position.x][board_position.y] != null:
		ice_pieces[board_position.x][board_position.y].take_damage(1)
		if ice_pieces[board_position.x][board_position.y].health == 0:
			ice_pieces[board_position.x][board_position.y].queue_free()
			ice_pieces[board_position.x][board_position.y] = null

