/// tilemap_set(tilemap_element_id, tiledata, xcell, ycell)
if (argument0) with (argument0) {
	var l_ts/*:gmv_tileset_t*/ = tileSet;
	if (!is_array(l_ts)) return -1;
	var l_x = 0|argument2; if (l_x < 0 || l_x >= tileCols) return -1;
	var l_y = 0|argument3; if (l_y < 0 || l_y >= tileRows) return -1;
	var l_tw = l_ts[gmv_tileset_t.tileWidth];
	var l_th = l_ts[gmv_tileset_t.tileHeight];
	var l_tile = tile_layer_find(depth,
		x + (l_x + 0.5) * l_tw,
		y + (l_y + 0.5) * l_th,
	); // aim at center since mirrored tiles might be weird
	//
	var l_td = argument1;
	var l_tl = l_ts[gmv_tileset_t.tileSepX] + (l_td mod l_tc) * l_ts[gmv_tileset_t.tileMulX];
	var l_tt = l_ts[gmv_tileset_t.tileSepY] + (l_td div l_tc) * l_ts[gmv_tileset_t.tileMulY];
	var l_tx = x + l_x * l_tw;
	var l_ty = y + l_y * l_th;
	var l_zx = (l_td & gmv_tile.maskMirror) != 0;
	var l_zy = (l_td & gmv_tile.maskFlip) != 0;
	if (l_zx) l_tx += l_tw;
	if (l_zy) l_ty += l_th;
	//
	if (l_tile < 0) {
		// new tile
		l_tile = tile_add(l_ts[gmv_tileset_t.tileBack], l_tl, l_tt, l_tw, l_th, l_tx, l_ty, depth);
	} else {
		// mod tile
		var l_tk = l_td & gmv_tile.maskIndex;
		var l_tc = l_ts[gmv_tileset_t.tileCols];
		tile_set_region(l_tile, l_tl, l_tt, l_tw, l_th);
		tile_set_position(l_tile, l_tx, l_ty);
	}
	tile_set_scale(l_tile, 1 - l_zx * 2, 1 - l_zy * 2);
	//
	return true;
}
return false;
