/// @param depth
/// @param create=true
var _depth = argument[0];
var _create = argument_count > 1 ? argument[1] : true;
_depth |= 0; // GMS2 depths are integers

// invalidate if a layer moved around/vanished
var l_layer = global.__tile_layers[?_depth];
if (l_layer != undefined && (!layer_exists(l_layer) || layer_get_depth(l_layer) != _depth)) {
	var l_elements = global.__tile_elements[?_depth];
	if (l_elements != undefined) ds_list_clear(l_elements);
	l_layer = undefined;
}

//
if (l_layer == undefined) {
	var l_all_layers = layer_get_all();
	var l_i = array_length_1d(l_all_layers);
	while (--l_i >= 0) {
		l_layer = l_all_layers[l_i];
		if (layer_get_depth(l_layer) == _depth) break;
	}
	if (l_i < 0) l_layer = _create ? layer_create(_depth, "auto_tile_layer_" + string(_depth)) : -1;
	global.__tile_layers[?_depth] = l_layer;
} else if (l_layer == -1 && _create) {
	l_layer = layer_create(_depth, "auto_tile_layer_" + string(_depth));
	global.__tile_layers[?_depth] = l_layer;
}

return l_layer;