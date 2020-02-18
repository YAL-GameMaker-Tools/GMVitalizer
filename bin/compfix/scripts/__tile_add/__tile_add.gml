/// @description Adds a new tile to the room.
/// @param background The background asset from which the new tile will be extracted.
/// @param left The x coordinate of the left of the new tile, relative to the background asset's top left corner.
/// @param top The y coordinate of the top of the new tile, relative to the background assets top left corner.
/// @param width The width of the tile.
/// @param height The height of the tile.
/// @param x The x position in the room to place the tile.
/// @param y The y position in the room to place the tile.
/// @param depth The depth at which to place the tile.
/// @returns {number} resource name for the new tile
var _back = argument0, _left = argument1, _top = argument2, _width = argument3, _height = argument4, _x = argument5, _y = argument6, _depth = argument7;
_depth |= 0; // GMS2 depths are integers

var l_layer = tile_get_layer_for_depth(_depth);
var l_tile = layer_tile_create(l_layer, _x, _y, _back, _left, _top, _width, _height);
//global.__tile_rects[?l_tile] = [_left, _top, _width, _height];

//
var l_elements = global.__tile_elements[?_depth];
if (l_elements != undefined) {
	if (l_elements == -1) {
		// we were asked for tile IDs in past, so init those
		l_elements = tile_get_ids_list_for_depth(_depth, l_layer);
	}
	ds_list_add(l_elements, l_tile);
}

return l_tile;