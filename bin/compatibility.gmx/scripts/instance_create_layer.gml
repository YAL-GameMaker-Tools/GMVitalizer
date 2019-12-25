/// instance_create_depth(x, y, layer, obj)

// turns out we want layer set before Create too, whoops
var l_layer = argument2;
if (is_string(l_layer)) {
	l_layer = layer_get_id(l_layer);
}
if (l_layer) with (l_layer) {
	with (instance_create(argument0, argument1, obj_gmv_blank)) {
		layer = other.id;
		var l_depth = object_get_depth(argument3);
		object_set_depth(argument3, argument2);
		instance_change(argument3, true);
		object_set_depth(argument3, l_depth);
		return id;
	}
}
//
var l_error = "instance_create_layer :: specified layer `" + string(argument2) + "` does not exist"
l_error += chr(13) + chr(10) + "Available layers:"
with (obj_gmv_layer) {
	l_error += chr(13) + chr(10) + "`" + string(name) + "`";
}
show_error(l_error, true);
return noone;
