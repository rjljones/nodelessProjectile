class_name NodelessProjectilesManager
extends Node3D

const ION_PROJECTILE_MAT = preload("res://scenes/projectiles/gun_projectiles/materials/ion_projectile_mat.tres")
const NEUTRON_PROJECTILE_MAT = preload("res://scenes/projectiles/gun_projectiles/materials/neutron_projectile_mat.tres")
const PARTICLE_PROJECTILE_MAT = preload("res://scenes/projectiles/gun_projectiles/materials/particle_projectile_mat.tres")
const PHOTON_PROJECTILE_MAT = preload("res://scenes/projectiles/gun_projectiles/materials/photon_projectile_mat.tres")
const PLASMA_PROJECTILE_MAT = preload("res://scenes/projectiles/gun_projectiles/materials/plasma_projectile_mat.tres")
const POSITRON_PROJECTILE_MAT = preload("res://scenes/projectiles/gun_projectiles/materials/positron_projectile_mat.tres")
const PULSE_PROJECTILE_MAT = preload("res://scenes/projectiles/gun_projectiles/materials/pulse_projectile_mat.tres")
const TACHYON_PROJECTILE_MAT = preload("res://scenes/projectiles/gun_projectiles/materials/tachyon_projectile_mat.tres")

@onready var plane_mesh = preload("res://assets/visual_effects/meshes/basic_projectile_billboard_mesh.tres")
var projectile_pools: Dictionary = {}
var hidden_transform: Transform3D = Transform3D(Basis.IDENTITY,Vector3(0.0,-40000,0.0))

func _ready() -> void:
	Bus.nodeless_projectiles = self
	create_multi_meshes()
	

var material_map: Dictionary = {}  # material, mmi

func create_multi_meshes():
	var materials = [
		ION_PROJECTILE_MAT, NEUTRON_PROJECTILE_MAT, 
		PARTICLE_PROJECTILE_MAT, PHOTON_PROJECTILE_MAT,
		PLASMA_PROJECTILE_MAT, POSITRON_PROJECTILE_MAT,
		PULSE_PROJECTILE_MAT, TACHYON_PROJECTILE_MAT
	]
	for mat in materials:
		var mmi = MultiMeshInstance3D.new()
		var mm = MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = plane_mesh
		mm.instance_count = 0  # start empty
		mmi.multimesh = mm
		mmi.material_override = mat
		add_child(mmi)
		material_map[mat] = mmi

func create_projectile_pool(pool_id: String, amount: int, mat: StandardMaterial3D, exclusion: SpaceshipBody, damage: Array):
	var mmi = material_map.get(mat)
	if not mmi:
		printerr("no mmi")
		return
	var current_count = mmi.multimesh.instance_count
	mmi.multimesh.instance_count += amount
	var projectile_data = []
	for i in amount:
		var idx = current_count + i
		mmi.multimesh.set_instance_transform(idx, Transform3D.IDENTITY)
		projectile_data.append({
		"active": false,
		"position": Vector3.ZERO,
		"direction": Vector3.ZERO,
		"lifetime": 0.0,
		"damage": damage,
		"exclusions": [exclusion],
		"material_index": idx
		})
	projectile_pools[pool_id] = {
	"multimesh_instance": mmi,
	"projectile_data": projectile_data,
	}


func fire_projectile(pool_id: String, from_position: Vector3, direction: Vector3) -> void:
	var mmi: MultiMeshInstance3D = projectile_pools[pool_id]["multimesh_instance"]
	for proj in projectile_pools[pool_id]["projectile_data"]:
		if proj["active"] == false:
			proj["active"] = true
			proj["position"] = from_position
			proj["direction"] = direction
			proj["lifetime"] = 3.0
			mmi.multimesh.set_instance_transform(
				proj["material_index"], Transform3D(Basis.IDENTITY, from_position))
			
			break
			

func _physics_process(delta: float) -> void:
	for pool_id in projectile_pools:
		var mmi: MultiMeshInstance3D = projectile_pools[pool_id]["multimesh_instance"]
		for proj in projectile_pools[pool_id]["projectile_data"]:
			if proj["active"] == true:
				var dir = -proj["direction"] * Data.PROJECTILE_BASE_SPEED * delta
				proj["position"] += dir
				proj["lifetime"] -= delta
				if proj["lifetime"] <= 0.0:
					mmi.multimesh.set_instance_transform(
						proj["material_index"], hidden_transform)
					proj["active"] = false
					continue
				mmi.multimesh.set_instance_transform(
					proj["material_index"], Transform3D(Basis.IDENTITY, proj["position"]))
				var ray_result = _perform_raycast(proj["position"], proj["direction"], proj["exclusions"])
				
				if not ray_result.is_empty():
					if ray_result.collider.has_method("damage"):
						ray_result.collider.call_deferred("damage", proj["damage"], 
							ray_result.position, ray_result.position, null, [])
					mmi.multimesh.set_instance_transform(
						proj["material_index"], hidden_transform)
					proj["active"] = false


func _perform_raycast(pos_from: Vector3, direction: Vector3,exclusions: Array) -> Dictionary:
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(
		pos_from, 
		pos_from + (direction * 8)
	)
	query.exclude = exclusions
	query.hit_from_inside = true
	return space_state.intersect_ray(query)
	


#class_name NodelessProjectilesManager
#extends Node3D
#
##THIS WORKS PERFECT HOWEVER I WANT TO TRY A MULTI MESH NOW AND COMPARE
## very tricky idea of nodeless projectiles to try and save performance
#
#const ION_PROJECTILE_MAT = preload("res://scenes/projectiles/gun_projectiles/materials/ion_projectile_mat.tres")
#const NEUTRON_PROJECTILE_MAT = preload("res://scenes/projectiles/gun_projectiles/materials/neutron_projectile_mat.tres")
#const PARTICLE_PROJECTILE_MAT = preload("res://scenes/projectiles/gun_projectiles/materials/particle_projectile_mat.tres")
#const PHOTON_PROJECTILE_MAT = preload("res://scenes/projectiles/gun_projectiles/materials/photon_projectile_mat.tres")
#const PLASMA_PROJECTILE_MAT = preload("res://scenes/projectiles/gun_projectiles/materials/plasma_projectile_mat.tres")
#const POSITRON_PROJECTILE_MAT = preload("res://scenes/projectiles/gun_projectiles/materials/positron_projectile_mat.tres")
#const PULSE_PROJECTILE_MAT = preload("res://scenes/projectiles/gun_projectiles/materials/pulse_projectile_mat.tres")
#const TACHYON_PROJECTILE_MAT = preload("res://scenes/projectiles/gun_projectiles/materials/tachyon_projectile_mat.tres")
#
##rid, position, direction, lifetime, hidden, damage,exclusions
#
##var projectile: Array = [
	##["rid",Vector3.ZERO,Vector3.ZERO, 3.0, false,[10.0,10.0],[exclusions]
##]
#@onready var plane_mesh = preload("res://assets/visual_effects/meshes/basic_projectile_billboard_mesh.tres")
#var projectile_pools: Dictionary = {}
#
#func _ready() -> void:
	#Bus.nodeless_projectiles = self
	#
#
#
#func create_projectile_pool(pool_id: String, amount: int, mat: StandardMaterial3D,exclusion: SpaceshipBody,damage: Array) -> void:
	#projectile_pools[pool_id] = []
	#for i in amount:
		#var new_projectile = RenderingServer.instance_create()
		#RenderingServer.instance_set_base(new_projectile,plane_mesh)
		#RenderingServer.instance_set_scenario(new_projectile,get_world_3d().scenario)
		#RenderingServer.instance_set_transform(new_projectile,Transform3D(Basis.IDENTITY, Vector3.ZERO))
		#RenderingServer.instance_set_visible(new_projectile,true)
		#RenderingServer.instance_geometry_set_material_override(new_projectile,mat)
		#RenderingServer.instance_geometry_set_visibility_range(new_projectile,0.0,Data.PROJECTILE_VISIBILITY_RANGE,0.0,0.0,RenderingServer.VISIBILITY_RANGE_FADE_SELF)
		#projectile_pools[pool_id].append([new_projectile,Vector3.ZERO,Vector3.ZERO,3.0,true,damage,[exclusion]])
#
#func fire_projectile(pool_id: String,from_position: Vector3, direction: Vector3) -> void:
	#for projectile in projectile_pools.get(pool_id):
		#if projectile[4] == true: #is hidden
			#RenderingServer.instance_set_visible(projectile[0],true)
			#RenderingServer.instance_set_transform(projectile[0],Transform3D(Basis.IDENTITY, from_position))
			#projectile[4] = false
			#projectile[1] = from_position
			#projectile[2] = direction
			##print(projectile)
			#break
#
#
#func _exit_tree() -> void:
	#for pool in projectile_pools:
		#for projectile in projectile_pools.get(pool):
			#RenderingServer.free_rid(projectile[0])
#
#
#func _physics_process(delta: float) -> void:
	#move_projectiles(delta)
	#ray_cast_projectiles()
	#
	#
#
	#
#func move_projectiles(delta: float) -> void:
	##for loop through the bullets set everything accordingly
	#for pool in projectile_pools:
		#for projectile in projectile_pools.get(pool):
			#if projectile[4] == false: #is not hidden
				#
				#var new_projectile_pos: Vector3 = projectile[1] + (-projectile[2] * Data.PROJECTILE_BASE_SPEED * delta)
				#RenderingServer.instance_set_transform(projectile[0],Transform3D(Basis.IDENTITY, 
															#new_projectile_pos))
				#projectile[1] = new_projectile_pos
				#
				#projectile[3] -= delta #lifetime
				#if projectile[3] <= 0.0:
					#RenderingServer.instance_set_visible(projectile[0],false)
					#projectile[4] = true
					#projectile[3] = 3.0
#
#func ray_cast_projectiles() -> void:
	##for loop again to physics server raycast
	#for pool in projectile_pools:
		#for projectile in projectile_pools.get(pool):
			#if projectile[4] == false: #is not hidden
				#var projectile_ray_result: Dictionary = _perform_raycast(projectile[1],projectile[2],projectile[6])
				#if projectile_ray_result.is_empty() == false:
					#
					#if projectile_ray_result.collider.has_method("damage"):
						#projectile_ray_result.collider.call_deferred("damage",projectile[5], projectile_ray_result.position, projectile_ray_result.position, null, [])    # damage()
	##
					#if projectile[3] <= 0.0:
						#RenderingServer.instance_set_visible(projectile[0],false)
						#projectile[4] = true
						#projectile[3] = 3.0
#
#
#func _perform_raycast(pos_from: Vector3, direction: Vector3,exclusions: Array) -> Dictionary:
	#var space_state = get_world_3d().direct_space_state
	#var query = PhysicsRayQueryParameters3D.create(
		#pos_from, 
		#pos_from + (direction * 8)
	#)
	#query.exclude = exclusions
	#query.hit_from_inside = true
	#return space_state.intersect_ray(query)
	#
