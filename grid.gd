extends Node2D

# State Machine-Конечный автомат
enum {wait, move}
var state

# Grid Variables-переменные сетки
export (int) var width; # Переменные ширины
export (int) var height; # Переменные высоты
export (int) var x_start;
export (int) var y_start;
export (int) var offset;
export (int) var y_offset; # отскок камней при появлении

# Obstacle Stuff-препятствия всякие
export (PoolVector2Array) var empty_spaces # Преобразование вектора в массив а это - "пустые места"
export (PoolVector2Array) var ice_spaces # Экспорт вектора пула в массив- "Лед"
export (PoolVector2Array) var lock_spaces # Экспорт вектора пула в массив- "Локрица- та что Цепи"

# Obstacle Signals - сигнал препятствий
signal make_ice # сигнал что бы сделать лед
signal damage_ice # Этот сигнал будет срабатывать каждый раз когда я уничтожаю какой либо элемент - поврежденный лед-он будет передавать информацию контейнеру какие контейнеры поврежденны
signal make_lock
signal damage_lock
# показываем адресс камней и предварительная загрузка сцен камней в память из папки scenes- в .tscn формате 
# на один камень у меня меньше
var possible_pieces = [
preload("res://scenes/blue_piece.tscn"),
preload("res://scenes/green_piece.tscn"),
preload("res://scenes/pink_piece.tscn"),
preload("res://scenes/red_piece.tscn"),
preload("res://scenes/yellow_piece.tscn")
] # И предварительно сохраниили их


var all_pieces = []; # начало массива равный пустому массиву array всех камней

# глобальная переменная для возврата
var piece_one = null
var piece_two = null # обе переменные по умолчанию на ноль выставляем
var last_place = Vector2(0,0) # последнее место ветора равно нулю
var last_direction = Vector2(0,0)# Так же сохраняем направление вектора
var move_checked = false# Логическая переменная для возврата-проверенно на ход, значение по умолчанию

# Первое касание first_touch по piece определение координат и завершающее касание final_touch
var first_touch = Vector2(0, 0);
var final_touch = Vector2(0, 0);
var controlling = false; # В наших переменных касания Создаем переключатель управления сеткой. пытаюсь ли я управлять сеткой или нет.Назовем CONTROLLING, который включается когда мы пытаемся управлять эллементами.И выключается после управления эллементом.

func _ready(): # Переменная State теперь отвечает за остановку игры.
	state = move # Как только игра запускает игрок может двигаться
	randomize();
	all_pieces = make_2d_array();
	spawn_pieces();
	spawn_ice()
	spawn_locks()

func restricted_fill(place): # Функция проверки неподвижности, ограниченным движением -restricted_fill- находится ли заданная позиция в какой-либо из этих неперемещаемых областей.- check_non_movable -проверка отсутствия перемещений
	# Check the empty pieces - проверьте наличие пустых ячеек
	if is_in_array(empty_spaces, place): # Указываем какой эллемент мы хотим проверить
		return true
	return false # не получив истину то я верну ложь

func restricted_move(place): # Функция ограничения перемещения камней в LOCKS
	#Check the licorice pieces - проверим детали из лакрицы
	if is_in_array(lock_spaces, place):
		return true
	return false

func is_in_array(array, item):
	for i in array.size(): # Сначала проходим по всем пустым местам
		if array[i] == item: # Пустые места которые равны, те совпадает ли это конкретное место в пустых местах с вектором столбца
			return true # если это так то я верну истинну
	return false # не получив истину то я верну ложь

func make_2d_array():# Это двумерный массив -Название функции и открываем-выполняем её
	var array = []# Временная переменная равная пустому
	for i in width:# ширина
		array.append([])# # Взять массив и добавить в конец к нему целый другой массив
		for j in height:# высота
			array[i].append(null);# Взять массив и ничего не добавить-он пустой
	return array;# И не возвращать

func spawn_pieces(): # Размещение Pieces на сетке
	for i in width:
		for j in height:
			if !restricted_fill(Vector2(i,j)):
				# Мы выберем случайное число c округлением в меньшую сторону 0-1-2-3-4 (наши piece) и сохраним его
				var rand = floor(rand_range(0, possible_pieces.size()));
				var piece = possible_pieces[rand].instance();
				var loops = 0;
				while(match_at(i, j, piece.color) && loops < 100):
					rand = floor(rand_range(0, possible_pieces.size()));
					loops += 1;
					piece = possible_pieces[rand].instance();
				# экземпляр эллемента
				
				add_child(piece);
				piece.position = grid_to_pixel(i, j);
				all_pieces[i][j] = piece;

func spawn_ice():
	for i in ice_spaces.size():
		emit_signal("make_ice", ice_spaces[i])

func spawn_locks():
	for i in lock_spaces.size():
		emit_signal("make_lock", lock_spaces[i])

func match_at(i, j, color):# мы создаем проверку столбца слева и проверку строки вниз. Если появляются совпадения то Tru и рандом загадывает новое число, если Falce то число не совпадает и загадывается слудюущий камень
	
		if i > 1: # Если слева есть столбик, то начинается проверка значения слева
			if all_pieces[i - 1][j] != null && all_pieces[i - 2][j] != null:
				if all_pieces[i - 1][j].color == color && all_pieces[i - 2][j].color == color:
					return true;
		if j > 1: # Если есть строка снизу, то продолжает придумывать новые камни без совпадений три в ряд выше
			if all_pieces[i][j-1] != null && all_pieces[i][j-2] != null:
				if all_pieces[i ][j-1].color == color && all_pieces[i][j-2].color == color:
					return true;

func grid_to_pixel(column, row): # столбец и строка и объявляем две новые переменные, для расстоновки по пикселям
	var new_x = x_start + offset * column; # столбец умноженный на смещение плюс стартовая точка по X
	var new_y = y_start + -offset * row;# строка умноженная на смещение прибавленная к стартовой точке по Y
	return Vector2(new_x, new_y) # Вспомогательная функция преобразования координат сетки в координаты пикселя

func pixel_to_grid(pixel_x, pixel_y): # для кликанья по pieces (игровые ккамни) преобразуем пиксели в координаты сетки, указывая координаты пикселя pixel_x и pixel_y
	var new_x = round((pixel_x - x_start) / offset); # эта функция будет брать координаты и преобразоовывать их в координаты сетки и сохраняем новое значение Х
	var new_y = round((pixel_y - y_start) / -offset); # Тоже самое только по Y- ROUND округляет эти показатели
	return Vector2(new_x, new_y);# Теперь мы берем два вектора и возвращаем их
	pass;

func is_in_grid(grid_position): # метод для определения границ сетки- размещаем между сеткой(выше) и сенсорным вводом(ниже) где- is_in_grid -"column" это колонка а "row" ряд.ЭТА функция для понимания находится ли какой либо конкретный столбец или строка внутри сетки-это нужно для того что бы кликая за пределами сетки данные не считывались как будто мы щелкнули на pieces. Это нужно для того чтобы клик несрабатывал за пределами игрового поля.
	if grid_position.x >= 0 && grid_position.x < width: # теперь мы проверяем, что столбец "column" > больше или = равен нулю && и меньше ширины < "width", 
		if grid_position.y >= 0 && grid_position.y < height: # а также я хочу убедиться, что строка "row" > больше или =равна НУЛЮ && и меньше высоты < "height"
			return true; # и я ее тогда верну return если одно из этих условий не выполняется -True- ВЕРНО!
	return false; # если ни одно из этих условий не выполняется (тоесть находится ВНЕ сетки) я верну False - ЛОЖНО/. Если касание происходит вне сетки просто возвращаем.

func touch_input():# Функция ввода касания
	if Input.is_action_just_pressed("ui_touch"): # первое касание
		if is_in_grid(pixel_to_grid(get_global_mouse_position().x, get_global_mouse_position().y)): # глобальная позиция по оси Х меняем пиксельное деградирование на сетку что бы получить позицию мыши
			first_touch = pixel_to_grid(get_global_mouse_position().x, get_global_mouse_position().y);
			controlling = true
	if Input.is_action_just_released("ui_touch"): # Теперь мы берем первое действие
		if is_in_grid(pixel_to_grid(get_global_mouse_position().x, get_global_mouse_position().y)) && controlling: # если она находится в сетке и я хочу проверить позицию в сетке и они уже управляли "controlling"
			controlling = false;
			final_touch = pixel_to_grid(get_global_mouse_position().x, get_global_mouse_position().y)
			touch_difference(first_touch, final_touch);

func swap_pieces(column, row, direction):# метод меняющий местами две части, выбираем "pieces" и направление вверх вниз влево или вправо "direction". Ищем pieces используя столбец и строку
	var first_piece = all_pieces [column][row]; # ищем фигуру в массиве, которую хотим поменять местами, объявляем переменную для хранения первой фигуры "first_pieces" и эта фигура ровна column and row
	var other_piece = all_pieces [column + direction.x][row + direction.y]; # присваеваем значение другой фигуре "other_piece" она ровняетс столбцу и строке всех фигур, так же прописывем ей направление
	if first_piece != null && other_piece != null:# Если первый эллемент не равен нулю и другой эллемент не равен нулю, то я могу сделать все остальное
		if !restricted_move(Vector2(column, row)) and !restricted_move(Vector2(column, row) + direction):
			store_info(first_piece, other_piece, Vector2(column, row), direction) # Нужно убедиться что оба эллемента не равны нулю
			state = wait # теперь мы находимся в состоянии ожидания и не можем двигаться пока не переместятся фигуры
			all_pieces[column][row] = other_piece; # теперь поскольку обе фигуры находятся в памяти я их поменяю местами, указываю что все фигуры в столбце и строке равны другой фигуре, тоесть 
			all_pieces[column + direction.x][row + direction.y] = first_piece; # перемещаем другую фигуру туда, где была первая по направлению X Y в сетке
			first_piece.move(grid_to_pixel(column + direction.x, row + direction.y)) # позиция фигуры равна ее новой позиции в столбце и строке, а ее новая позиция в столбце и строке будет перемещенна по пикселям
			other_piece.move(grid_to_pixel(column, row)) # а позиция другой фигуры равна координатам X Y попикселям. Позже мы все поменяли на функцию MOVE описанную в Piece.gd
			if !move_checked:
				find_matches()

func store_info(first_piece, other_piece, place, direction): # Функция по хранению информации перемещаемых нами фигур в столбце и строке и направление
	piece_one = first_piece
	piece_two = other_piece
	last_place = place
	last_direction = direction
	pass

func swap_back(): # Функция для обмена фигурами и возвратом обмена, если ряд не собирается
	# Move the previously swapped pieces back to the previos place- Переместите ранее поменявшиеся местами фигуры обратно на прежнее место.
	if piece_one != null && piece_two != null:
		swap_pieces(last_place.x, last_place.y, last_direction)
	state = move
	move_checked = false
	pass

func touch_difference(grid_1, grid_2): # создадим функцию которая и будет перемещать какой эллемент и в каком направлении. "touch_difference" разница касаний. Она будет принимать два аргумента- разница 1 "grid_1" при первом касании и при отпускании тапа разница 2 "grid_2"
	var difference = grid_2 - grid_1; # переменная-которая будет разницей между этими двумя значениями "difference" и она будет равна разница 2 минус разница 1
	if abs(difference.x) > abs(difference.y): # если разница X по абсолютному значению больше чем абсолютное значение разницы по оси Y то нужно определиться двигаться влево или вправо
		if difference.x > 0: # если разница по оси X больше нуля-это значит что разница больше нуля те положительная, 
			swap_pieces(grid_1.x, grid_1.y, Vector2(1, 0)); # поэтому нам нужно двигаться вправо --> затем меняем местами эллементы
		elif difference.x < 0: # если разница по оси Х меньше 0, то
			swap_pieces(grid_1.x, grid_1.y, Vector2(-1, 0)); # То двигаем влево
	elif abs(difference.y) > abs(difference.x): # если абсолютное значение разницы Y больше абсолютного значения разных стеков-то есть если они равны, мы ничего не делаем.
		if difference.y > 0: # если разница Y больше 0, то 
			swap_pieces(grid_1.x, grid_1.y, Vector2(0, 1)); # двигаем вверх
		elif difference.y < 0: # если разница Y меньше нуля, то
			swap_pieces(grid_1.x, grid_1.y, Vector2(0, -1)); # двигаем вниз

func _process(_delta):
	if state == move:
		touch_input();

func find_matches(): # добавим переменную к фигуре и добавляем метод внутри эллемента модуль определяющий совпадения-Find Matches - найти совпадения
	for i in width:
		for j in height: # перебираем всю доску по ширине и высоте
			if all_pieces[i][j] != null: # если все фигуры не равны нулю, то мы их проверяем
				var current_color = all_pieces[i][j].color
				if i > 0 && i < width - 1: # проверяем совпадения по ширине
					if !is_piece_null(i-1, j) && all_pieces[i+1][j] != null:
						if all_pieces[i - 1][j].color == current_color && all_pieces[i + 1][j].color == current_color:
							match_and_dim(all_pieces[i-1][j])
							match_and_dim(all_pieces[i][j])
							match_and_dim(all_pieces[i+1][j])
				if j > 0 && j < height - 1: # проверяем совпадения по ВЫСОТЕ
					if all_pieces[i][j-1] != null && all_pieces[i][j+1] != null:
						if all_pieces[i][j - 1].color == current_color && all_pieces[i][j + 1].color == current_color:
							match_and_dim(all_pieces[i][j-1])
							match_and_dim(all_pieces[i][j])
							match_and_dim(all_pieces[i][j + 1])
	get_parent().get_node("destroy_timer").start() # Вызываем эллемент дестрой таймер

func is_piece_null(column, row):
	if all_pieces[column][row] == null:
		return true
	return false

func match_and_dim(item):
	item.matched = true
	item.dim()

func destroy_matched():# Дестрой матч будет проходить по всем эллементам и уничтожать 3 фигуры в ряд!
	var was_matched = false # маленькая функция сообщающая было ли совпадение или нет
	for i in width: # Ширины
		for j in height: # И высоты
			if all_pieces[i][j] != null:
				if all_pieces[i][j].matched:
					damage_special(i, j)
					was_matched = true
					all_pieces[i][j].queue_free()
					all_pieces[i][j] = null
	move_checked = true # проверили переместим фигуры и возвращаем состояние на "перемещение" этой переменной
	if was_matched: # Теперь когда выйдем из всех эих циклов, ставим таймер коллапс только если был найден подходящий эллемент
		get_parent().get_node("collapse_timer").start()
	else: # Если небыло найденно подходящего эллемента мы используем метод свапп бэк
		swap_back()

func damage_special(column, row):
	emit_signal("damage_ice", Vector2(column,row))
	emit_signal("damage_lock", Vector2(column,row))

func collapse_columns(): # Функция "сворачивания столбцов" - будет опускать камни на появившиеся пустоты после схлопывания под ними
	for i in width: # для ширины
		for j in height: # и для высоты
			if all_pieces[i][j] == null && !restricted_fill(Vector2(i,j)): # нашли старый эллемент и коэфицент не ограниченного перемещения - restricted_movement
				for k in range(j + 1, height): # создаем переменную "К" в диапазоне-range с единицы выше и будем двигаться со значением "J" пока не достигнем высоты
					if all_pieces[i][k] != null: # теперь мы проверим не является ли это значение неизвестным, если значение all нулевое 
						all_pieces[i][k].move(grid_to_pixel(i, j)) # то мы move-переместим его на пустое место
						all_pieces[i][j] = all_pieces[i][k] # затем мы сбросим значение переменной что бы оно соответствовало
						all_pieces[i][k] = null # пустое место должно соответствовать
						break # выходим из цикла
	get_parent().get_node("refill_timer").start() # И запуская функцию.

func refill_columns(): # проходимся по всему циклу и если находим пустое место создаем эллемент и проверяем его на совпадения
	for i in width: # по ширине
		for j in height: # по высоте
			if all_pieces[i][j] == null && !restricted_fill(Vector2(i,j)): # Посмотреть заполнение столбцов и если i j всех эллементов равен нулю или проверка вектором неограниченного движения
				# Мы выберем случайное число c округлением в меньшую сторону 0-1-2-3-4 (наши piece) и сохраним его
				var rand = floor(rand_range(0, possible_pieces.size())); 
				var piece = possible_pieces[rand].instance();
				var loops = 0;
				while(match_at(i, j, piece.color) && loops < 100):
					rand = floor(rand_range(0, possible_pieces.size()));
					loops += 1;
					piece = possible_pieces[rand].instance();
				# экземпляр эллемента
				add_child(piece);
				piece.position = grid_to_pixel(i, j - y_offset); # оффсет- отскок новых камней
				piece.move(grid_to_pixel(i,j)) # перемещение в свою фактическую позицию
				all_pieces[i][j] = piece;
	after_refill()

func after_refill(): # Функция будет собирать все фигуры и проверять их на совпадение, если есть то запустит таймер _destroy_ уничтожения фигур и их обрушение. А если совпадений не найденно запустит снова ход игрока
	for i in width:
		for j in height:
			if all_pieces[i][j] != null:
				if match_at(i, j, all_pieces[i][j].color): # отправляем к функции проверки совпадений
					find_matches()
					get_parent().get_node("destroy_timer").start() # и если это так мы отправляем на уничтожение камни
					return
	state = move
	move_checked = false

func _on_destroy_timer_timeout(): # Подключенный метод уничтожающий камни
	destroy_matched()

func _on_collapse_timer_timeout(): # Подключенный метод collaps_timer опускающий камни вниз на пустые места- создаем там деталь, которая не будет иметь совпадений
	collapse_columns()

func _on_refill_timer_timeout(): # Подключенный метод восполнения камней после обрушения в пустых местах
	refill_columns()

func _on_lock_holder_remove_lock(place):
	for i in range(lock_spaces.size() -1, -1, -1):
		if lock_spaces[i] == place:
			lock_spaces.remove(i)
