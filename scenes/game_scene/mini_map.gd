class_name MiniMap
extends GridContainer


const CURRENT_COLOR = Color.DARK_VIOLET
const ADJACENT_COLOR = Color.DARK_VIOLET
const VISITED_COLOR = Color.LIGHT_GRAY


var visited_rooms = []


func refresh() -> void:
	visited_rooms = GameState.get_visited_rooms()
	_clear_map()
	_fill_map()


func _clear_map() -> void:
	for room in MapConfiguration.ROOM_CONNECTIONS.keys():
		_clear_room(
			_room_container(room)
		)


func _fill_map() -> void:
	_fill_visited_rooms()
	var room_number = GameState.get_current_room()
	_fill_current_room(room_number)
	_fill_adjacent_rooms(room_number)


func _clear_room(grid_container: GridContainer) -> void:
	for texture_rect: TextureRect in grid_container.get_children():
		texture_rect.modulate = Color.TRANSPARENT


func _fill_visited_rooms() -> void:
	for room_number in visited_rooms: 
		_fill_all_directions(_room_container(room_number), VISITED_COLOR)


func _fill_current_room(room_number: String) -> void:
	_fill_all_directions( 
		_room_container(room_number), 
		CURRENT_COLOR
	)


func _fill_adjacent_rooms(room_number: String) -> void:
	for direction: MapConfiguration.Direction in MapConfiguration.ROOM_CONNECTIONS[room_number]:
		var adjacent_room_number = MapConfiguration.ROOM_CONNECTIONS[room_number][direction]
		if adjacent_room_number in visited_rooms:
			_fill_room_direction(
				_room_container(adjacent_room_number),
				direction,
				ADJACENT_COLOR\
			)


func _fill_room_direction(grid_container: GridContainer, direction: MapConfiguration.Direction, color = ADJACENT_COLOR)-> void:
	if not grid_container: return

	var texture_rects := grid_container.get_children()
	var rects_to_fill: Array[Node] = []
	
	match direction:			
		MapConfiguration.Direction.DOWN:
			rects_to_fill.append(texture_rects[0])
			rects_to_fill.append(texture_rects[1])
		MapConfiguration.Direction.LEFT:
			rects_to_fill.append(texture_rects[1])
			rects_to_fill.append(texture_rects[3])
		MapConfiguration.Direction.UP:
			rects_to_fill.append(texture_rects[2])
			rects_to_fill.append(texture_rects[3])
		MapConfiguration.Direction.RIGHT:
			rects_to_fill.append(texture_rects[0])
			rects_to_fill.append(texture_rects[2])

	for rect: TextureRect in rects_to_fill:
		rect.modulate = color


func _fill_all_directions(room_container: GridContainer, color: Color) -> void:
	_fill_room_direction(room_container, MapConfiguration.Direction.UP, color)
	_fill_room_direction(room_container, MapConfiguration.Direction.DOWN, color)


func _room_container(room_number) -> GridContainer:
	return get_node_or_null("%GridContainer" + room_number)
