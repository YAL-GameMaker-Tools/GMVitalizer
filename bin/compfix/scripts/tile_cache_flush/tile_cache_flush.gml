/// To be called on room end or other room context changes
gml_pragma("global", @'
	global.__tile_layers = ds_map_create();
	global.__tile_elements = ds_map_create();
	global.__tile_regions = ds_map_create();
');
ds_map_clear(global.__tile_layers);
ds_map_clear(global.__tile_regions);

//
var l_count = ds_map_size(global.__tile_elements);
if (l_count) {
	var l_depth = ds_map_find_first(global.__tile_elements);
	repeat (l_count) {
		var l_list = global.__tile_elements[?l_depth];
		if (l_list != -1) ds_list_destroy(l_list);
		l_depth = ds_map_find_next(global.__tile_elements, l_depth);
	}
	ds_map_clear(global.__tile_elements);
}