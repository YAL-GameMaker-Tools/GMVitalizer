/// tilemap_get_at_pixel(tilemap_element_id, x, y)
if (argument0) with (argument0) {
	var l_ts/*:gmv_tileset_t*/ = tileSet;
	if (!is_array(l_ts)) return -1;
	//
	if (argument1 < x || argument1 >= x + tileCols * l_ts[gmv_tileset_t.tileWidth]
	|| argument2 < y || argument2 >= y + tileRows * l_ts[gmv_tileset_t.tileHeight]) return -1;
	//
	var l_tile = tile_layer_find(depth, argument1, argument2);
	if (l_tile < 0) return 0;
	//
	var l_result = ((tile_get_left(l_tile) - l_ts[gmv_tileset_t.tileSepX]) div l_ts[gmv_tileset_t.tileMulX]
		+ ((tile_get_top(l_tile) - l_ts[gmv_tileset_t.tileSepY]) div l_ts[gmv_tileset_t.tileMulY]) * l_ts[gmv_tileset_t.tileCols]
	) & gmv_tile.maskIndex;
	if (tile_get_xscale(l_tile) < 0) l_result |= gmv_tile.maskMirror;
	if (tile_get_yscale(l_tile) < 0) l_result |= gmv_tile.maskFlip;
	return l_result;
}
return -1;
