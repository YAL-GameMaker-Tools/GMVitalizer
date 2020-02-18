/// @description Deletes every single tile and flushes tile cache

var l_layers = layer_get_all();
var l_layer_index = -1;
repeat (array_length_1d(l_layers)) {
	var l_layer = l_layers[++l_layer_index];
	var l_tile_list = global.__tile_elements[?layer_get_depth(l_layer)];
	var l_index = -1;
	if (l_tile_list != undefined && l_tile_list != -1) {
		repeat (ds_list_size(l_tile_list)) {
			layer_tile_destroy(l_tile_list[|++l_index]);
		}
	} else {
		var l_elements = layer_get_all_elements(l_layer);
		repeat (array_length_1d(l_elements)) {
			var l_el = l_elements[++l_index];
			if (layer_get_element_type(l_el) == layerelementtype_tile) {
				layer_tile_destroy(l_el);
			}
		}
	}
}
tile_cache_flush();
