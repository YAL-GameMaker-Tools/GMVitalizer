/// @param x
/// @param y
/// @param width
/// @param height
/// @param angle
var xx = argument0, yy = argument1, w = argument2, h = argument3, a = argument4;
var mv = matrix_build_lookat(
	xx+w/2, yy+h/2, -16000,
	xx+w/2, yy+h/2, 0,
	dsin(-a), dcos(-a), 0
);
var mp = matrix_build_projection_ortho(w, h, 1, 32000);
var c = camera_get_active();
camera_set_view_mat(c, mv);
camera_set_proj_mat(c, mp);
camera_apply(c);