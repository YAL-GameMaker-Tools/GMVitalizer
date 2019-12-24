/// tileset_create(background, t_count, t_cols, t_width, t_height, t_sep_x, t_sep_y)
var l_background = argument0, l_count = argument1, l_cols = argument2, l_width = argument3, l_height = argument4, l_sep_x = argument5, l_sep_y = argument6;
enum gmv_tileset_t {
	tileBack,
	tileCount,
	tileCols,
	tileRows,
	tileWidth,
	tileHeight,
	tileSepX,
	tileSepY,
	tileMulX,
	tileMulY,
	sizeof,
};
var l_tileset/*:gmv_tileset_t*/ = array_create(gmv_tileset_t.sizeof);
l_tileset[@gmv_tileset_t.tileBack] = l_background;
l_tileset[@gmv_tileset_t.tileCount] = l_count;
l_tileset[@gmv_tileset_t.tileCols] = l_cols;
l_tileset[@gmv_tileset_t.tileRows] = ceil(l_count / l_cols);
l_tileset[@gmv_tileset_t.tileWidth] = l_width;
l_tileset[@gmv_tileset_t.tileHeight] = l_height;
l_tileset[@gmv_tileset_t.tileSepX] = l_sep_x;
l_tileset[@gmv_tileset_t.tileSepY] = l_sep_y;
l_tileset[@gmv_tileset_t.tileMulX] = l_sep_x * 2 + l_width;
l_tileset[@gmv_tileset_t.tileMulY] = l_sep_y * 2 + l_height;
return l_tileset;
