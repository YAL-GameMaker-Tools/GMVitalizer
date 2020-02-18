/// @param depth
var l_list = tile_get_ids_list_for_depth(argument0);
if (l_list == -1) return [];
var l_count = ds_list_size(l_list);
var l_array = array_create(l_count, -1);
for (var l_index = 0; l_index < l_count; l_index++) {
	l_array[l_index] = l_list[|l_index];
}
return l_array;