/// layer_tilemap_get_id(layer_id)
var l_layer = argument0;
if (is_string(l_layer)) {
	l_layer = layer_get_id(l_layer);
}
if (l_layer) with (l_layer) {
	with (obj_gmv_layer_tilemap) {
		if (depth == other.depth) return id;
	}
}
return -1;
