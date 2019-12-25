/// layer_get_id(layer_name)
var s = string_lower(argument0);
with (obj_gmv_layer) {
	if (nameLQ == s) return id;
}
return -1;
