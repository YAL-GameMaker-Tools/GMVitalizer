/// @returns {array}
gml_pragma("global", @'
	global.__tile_get_ids__list = ds_list_create();
');

//
var l_acc_list = global.__tile_get_ids__list;
ds_list_clear(l_acc_list);

//
var l_layers = layer_get_all();
var l_layer_index = -1;
repeat (array_length_1d(l_layers)) {
	var l_layer = l_layers[++l_layer_index];
	var l_tile_list = tile_get_ids_list_for_depth(layer_get_depth(l_layer), l_layer);
	var l_tile_index = -1;
	repeat (ds_list_size(l_tile_list)) {
		ds_list_add(l_acc_list, l_tile_list[|++l_tile_index]);
	}
}

//
var l_count = ds_list_size(l_acc_list);
var l_result;
if (l_count > 0) {
	l_result = array_create(l_count, -1);
	for (var l_tile_index = 0; l_tile_index < l_count; l_tile_index++) {
		l_result[l_tile_index] = l_acc_list[|l_tile_index];
	}
} else l_result = [-1];// legacy feature
ds_list_clear(l_acc_list);

return l_result;