var _tile = argument0;
if (!ds_map_empty(global.__tile_elements)) {
	var l_elements = global.__tile_elements[?layer_get_depth(layer_get_element_layer(_tile))];
	if (l_elements != undefined) {
		var l_index = ds_list_find_index(l_elements, _tile);
		if (l_index >= 0) ds_list_delete(l_elements, l_index);
	}
}
ds_map_delete(global.__tile_regions, _tile);
layer_tile_destroy(_tile);