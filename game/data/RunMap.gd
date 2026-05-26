class_name RunMap extends Resource

@export var nodes: Array[MapNode] = []
@export var current_node_id: int = -1   # -1 = noch nicht gestartet, am Start
@export var total_rows: int = 0

func get_node_by_id(id: int) -> MapNode:
	for n in nodes:
		if n.id == id:
			return n
	return null

func get_start_node() -> MapNode:
	for n in nodes:
		if n.type == MapNode.NodeType.START:
			return n
	return null

func get_nodes_in_row(row: int) -> Array[MapNode]:
	var result: Array[MapNode] = []
	for n in nodes:
		if n.row == row:
			result.append(n)
	return result

func reachable_nodes_from_current() -> Array[MapNode]:
	var current: MapNode = null
	if current_node_id == -1:
		current = get_start_node()
	else:
		current = get_node_by_id(current_node_id)
	if current == null:
		var empty: Array[MapNode] = []
		return empty
	var result: Array[MapNode] = []
	for conn_id in current.connections:
		var n: MapNode = get_node_by_id(conn_id)
		if n != null:
			result.append(n)
	return result

func move_to(node_id: int) -> void:
	# Markiert den Knoten als aktuell — completed wird erst nach Sieg gesetzt.
	current_node_id = node_id

func mark_current_completed() -> void:
	var n: MapNode = get_node_by_id(current_node_id)
	if n != null:
		n.completed = true

func current_node() -> MapNode:
	return get_node_by_id(current_node_id)
