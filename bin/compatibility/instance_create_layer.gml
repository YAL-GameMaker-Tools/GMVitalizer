/// instance_create_depth(x, y, layer, obj)

// turns out we want layer set before Create too, whoops
var l_layer = argument2;
if (is_string(l_layer)) {
	l_layer = layer_get_id(l_layer);
}
if (l_layer) with (l_layer) {
	with (instance_create(argument0, argument1, obj_gmv_blank)) {
		depth = other.depth;
		layer = other.id;
		instance_change(argument3, true);
		return id;
	}
}
show_error("Couldn't find layer `" + string(argument2) + "`", true);