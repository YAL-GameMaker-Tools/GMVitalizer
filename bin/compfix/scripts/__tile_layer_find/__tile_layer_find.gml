/// @param depth The depth of the tile to be found.
/// @param x The x position to check.
/// @param y The y position to check.
/// @returns {layer_tile}
var _depth = argument0, _x = argument1, _y = argument2;
var l_layer = tile_get_layer_for_depth(_depth, false);
if (l_layer == -1) return -1;
var l_tile_list = tile_get_ids_list_for_depth(_depth, l_layer);
var l_tile_index = -1;
repeat (ds_list_size(l_tile_list)) {
	var l_tile = l_tile_list[|++l_tile_index];
	var l_sx = layer_tile_get_xscale(l_tile);
	var l_sy = layer_tile_get_yscale(l_tile);
	if (l_sx >= 0 && l_sy >= 0) {
		var l_tx = layer_tile_get_x(l_tile);
		if (_x < l_tx) continue;
		var l_ty = layer_tile_get_y(l_tile);
		if (_y < l_ty) continue;
		//
		var l_region = global.__tile_regions[?l_tile];
		if (l_region == undefined) {
			l_region = layer_tile_get_region(l_tile);
			if (array_length_1d(l_region)) {
				global.__tile_regions[?l_tile] = l_region;
			} else continue;
		}
		//
		if(_x - l_tx < l_region[2] * l_sx
		&& _y - l_ty < l_region[3] * l_sy
		) return l_tile;
	}
}
return -1;