extends Node2D

export (int) var health # здоровье льда

func _ready():
	
	
	pass # Replace with function body.
	
func take_damage(damage):
	health -= damage
	# Can add damage effect here - можно добавить эффект урона сюда- частицв взрыв и всякое такое можно добавить позже или даже спрайт
