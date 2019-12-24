/// tilemap_get_cell_y_at_pixel(tilemap_element_id, x, y)
if (argument0) with (argument0) {
	var l_tileset/*:gmv_tileset_t*/ = tileSet;
	if (!is_array(l_tileset)) return -1;
	var l_x = (argument1 - x) / l_tileset[gmv_tileset_t.tileWidth];
	var l_y = (argument2 - y) / l_tileset[gmv_tileset_t.tileHeight];
	if (l_x < 0 || l_x >= tileCols || l_y < 0 || l_y >= tileRows) return -1;
	return 0|l_y;
}
return -1;