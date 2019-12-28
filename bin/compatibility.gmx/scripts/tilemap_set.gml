/// tilemap_set(tilemap_element_id, tiledata, xcell, ycell)
if (argument0) with (argument0) {
	var l_ts/*:gmv_tileset_t*/ = tileSet;
	if (!is_array(l_ts)) return -1;
	var l_x = 0|argument2; if (l_x < 0 || l_x >= tileCols) return -1;
	var l_y = 0|argument3; if (l_y < 0 || l_y >= tileRows) return -1;
	var l_tw = l_ts[gmv_tileset_t.tileWidth];
	var l_th = l_ts[gmv_tileset_t.tileHeight];
	return tilemap_set_at_pixel(argument0, argument1,
		x + (l_x + 0.5) * l_tw, y + (l_y + 0.5) * l_th
	); // aim at center since mirrored tiles might be weird
}
return false;
