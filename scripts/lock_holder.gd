extends Node2D

signal remove_lock

var lock_pieces = []
var width = 8
var height = 10
var licorice = preload("res://scenes/licorice.tscn") # Моя ледяная фигура равна моей ледяной сцене
func _ready(): # Значение функции редди для ледяных кусков
	pass

func make_2d_array():# Это двумерный массив -Название функции и открываем-выполняем её
	var array = []# Временная переменная равная пустому
	for i in width:# ширина
		array.append([])# # Взять массив и добавить в конец к нему целый другой массив
		for j in height:# высота
			array[i].append(null);# Взять массив и ничего не добавить-он пустой
	return array;# И не возвращать


func _on_grid_make_lock(board_position):
	if lock_pieces.size() == 0:
		lock_pieces = make_2d_array()
	var current = licorice.instance()
	add_child(current)
	current.position = Vector2(board_position.x * 168 + 126, -board_position.y * 168 + 1880) # координата и Размер по X и по Y
	lock_pieces[board_position.x][board_position.y] = current

func _on_grid_damage_lock(board_position):
	if lock_pieces[board_position.x][board_position.y] != null:
		lock_pieces[board_position.x][board_position.y].take_damage(1)
		if lock_pieces[board_position.x][board_position.y].health == 0:
			lock_pieces[board_position.x][board_position.y].queue_free()
			lock_pieces[board_position.x][board_position.y] = null
			emit_signal("remove_lock", board_position)

