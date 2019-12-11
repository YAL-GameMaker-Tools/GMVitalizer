/// layer_get_id_at_depth(depth)->array<layer>
var arr = array_create(0);
var found = 0;
with (obj_gmv_layer) {
	if (depth == argument0) arr[found++] = id;
}
return arr;