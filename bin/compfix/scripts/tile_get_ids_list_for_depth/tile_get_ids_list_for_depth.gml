/// @param depth
/// @param ?layer
/// @returns ds_list, or -1 (if layer==undefined and no layer exists at depth)
var _depth = argument[0];
var _layer = argument_count > 1 ? argument[1] : undefined;
_depth |= 0; // GMS2 depths are integers

var l_list = global.__tile_elements[?_depth];
if (l_list == undefined) {
	if (_layer == undefined) {
		_layer = tile_get_layer_for_depth(_depth, false);
		if (_layer == -1) {
			global.__tile_elements[?_depth] = -1;
			return -1;
		}
	}
	//
	l_list = ds_list_create();
	global.__tile_elements[?_depth] = l_list;
	//
	var l_array = layer_get_all_elements(_layer);
	var l_index = -1;
	repeat (array_length_1d(l_array)) {
		var l_el = l_array[++l_index];
		if (layer_get_element_type(l_el) == layerelementtype_tile) {
			ds_list_add(l_list, l_el);
		}
	}
}
return l_list;