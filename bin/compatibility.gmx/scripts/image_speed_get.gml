/// sprite_speed_get(id)
var l_inst = argument0;
var l_sprite = l_inst.sprite_index;
if (l_sprite >= 0 && l_sprite < sprite_speed_array_size) {
	return l_inst.image_speed / sprite_speed_array[l_sprite];
} else return l_inst.image_speed;
