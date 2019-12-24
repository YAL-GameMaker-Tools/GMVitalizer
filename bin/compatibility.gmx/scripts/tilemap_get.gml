/// tilemap_get(tilemap_element_id, cell_x, cell_)
if (argument0) with (argument0) {
	var l_ts/*:gmv_tileset_t*/ = tileSet;
	if (!is_array(l_ts)) return -1;
	var l_x = 0|argument1; if (l_x < 0 || l_x >= tileCols) return -1;
	var l_y = 0|argument2; if (l_y < 0 || l_y >= tileRows) return -1;
	var l_tile = tile_layer_find(depth,
		x + (l_x + 0.5) * l_ts[gmv_tileset_t.tileWidth],
		y + (l_y + 0.5) * l_ts[gmv_tileset_t.tileHeight],
	); // aim at center since mirrored tiles might be weird
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
