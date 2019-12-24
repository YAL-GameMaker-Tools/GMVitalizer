/// layer_tilemap_create(layer_id, x, y, tileset, cols, rows)
var l_layer = argument0, l_x = argument1, l_y = argument2, l_tileset = argument3, l_cols = argument4, l_rows = argument5;
with (instance_create_layer(l_x, l_y, l_layer, obj_gmv_layer_tilemap)) {
	tileSet = l_tileset;
	tileCols = l_cols;
	tileRows = l_rows;
	return id;
}
return -1;

enum gmv_tile {
	maskInherit = 1 << 31,
	maskRotate = 1 << 30,
	maskFlip = 1 << 29,
	maskMirror = 1 << 28,
	maskIndex = (1 << 19) - 1,
};
