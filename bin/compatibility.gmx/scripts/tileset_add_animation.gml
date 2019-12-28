/// tileset_add_animation(tileset, ...frames)
var l_tileset/*:gmv_tileset_t*/ = argument[0];
l_tileset[@gmv_tileset_t.tilesetHasAnim] = true;
var l_tileIsAnimated = l_tileset[gmv_tileset_t.tileIsAnimated];
var l_tileCycles = l_tileset[gmv_tileset_t.tileCycles];
var l_till = argument_count - 1;
for (var l_i = 1; l_i <= l_till; l_i++) {
	var l_tile = argument[l_i];
	l_tileIsAnimated[@l_tile] = true;
	if (l_i == l_till) {
		l_tileCycles[@l_tile] = argument[1];
	} else {
		l_tileCycles[@l_tile] = argument[l_i + 1];
	}
}
