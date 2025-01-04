extends Node

var total_rings = 0
var collected_rings = 0
@onready var finish_area = $"../FinishArea"

func _ready():
	# Count total rings
	total_rings = $"../TorusRings".get_child_count()
	
	# Connect all ring signals
	for ring in $"../TorusRings".get_children():
		ring.ring_collected.connect(_on_ring_collected)
	
	# Connect finish area
	finish_area.body_entered.connect(_on_finish_area_entered)
	
	# Disable finish area initially
	finish_area.monitoring = false

func _on_ring_collected():
	collected_rings += 1
	if collected_rings >= total_rings:
		# Enable finish area when all rings collected
		finish_area.monitoring = true
		# Maybe add visual indicator that finish is available

func _on_finish_area_entered(body):
	if body.is_in_group("player"):
		# Level complete!
		get_tree().change_scene_to_file("res://Scenes/UI/main_menu.tscn")
		# Add your level completion code here



	pass # Replace with function body.
