//{ views
remap __view_get( e__VW.XView, $1 ) -> view_xview[$1]
remap __view_get( e__VW.YView, $1 ) -> view_yview[$1]
remap __view_get( e__VW.HView, $1 ) -> view_hview[$1]
remap __view_get( e__VW.WView, $1 ) -> view_wview[$1]
remap __view_get( e__VW.Angle, $1 ) -> view_angle[$1]
remap __view_get( e__VW.HBorder, $1 ) -> view_hborder[$1]
remap __view_get( e__VW.VBorder, $1 ) -> view_vborder[$1]
remap __view_get( e__VW.HSpeed, $1 ) -> view_hspeed[$1]
remap __view_get( e__VW.VSpeed, $1 ) -> view_vspeed[$1]
remap __view_get( e__VW.Object, $1 ) -> view_object[$1]
remap __view_get( e__VW.Visible, $1 ) -> view_visible[$1]
remap __view_get( e__VW.XPort, $1 ) -> view_xport[$1]
remap __view_get( e__VW.YPort, $1 ) -> view_yport[$1]
remap __view_get( e__VW.HPort, $1 ) -> view_hport[$1]
remap __view_get( e__VW.WPort, $1 ) -> view_wport[$1]
remap __view_get( e__VW.SurfaceID, $1 ) -> view_surface_id[$1]
//
remap __view_set( e__VW.XView, $1, $2 ) -> view_xview[$1] = $2
remap __view_set( e__VW.YView, $1, $2 ) -> view_yview[$1] = $2
remap __view_set( e__VW.HView, $1, $2 ) -> view_hview[$1] = $2
remap __view_set( e__VW.WView, $1, $2 ) -> view_wview[$1] = $2
remap __view_set( e__VW.Angle, $1, $2 ) -> view_angle[$1] = $2
remap __view_set( e__VW.HBorder, $1, $2 ) -> view_hborder[$1] = $2
remap __view_set( e__VW.VBorder, $1, $2 ) -> view_vborder[$1] = $2
remap __view_set( e__VW.HSpeed, $1, $2 ) -> view_hspeed[$1] = $2
remap __view_set( e__VW.VSpeed, $1, $2 ) -> view_vspeed[$1] = $2
remap __view_set( e__VW.Object, $1, $2 ) -> view_object[$1] = $2
remap __view_set( e__VW.Visible, $1, $2 ) -> view_visible[$1] = $2
remap __view_set( e__VW.XPort, $1, $2 ) -> view_xport[$1] = $2
remap __view_set( e__VW.YPort, $1, $2 ) -> view_yport[$1] = $2
remap __view_set( e__VW.HPort, $1, $2 ) -> view_hport[$1] = $2
remap __view_set( e__VW.WPort, $1, $2 ) -> view_wport[$1] = $2
remap __view_set( e__VW.SurfaceID, $1, $2 ) -> view_surface_id[$1] = $2
//}

//{ Simple camera
remap(stat) view_camera[$1] ${set} $2 -> view_set_camera($1, $2)
remap view_camera[$1] -> /*view_camera*/($1)
remap camera_get_view_x($1) -> view_xview[$1]
remap camera_get_view_y($1) -> view_yview[$1]
remap camera_get_view_width($1) -> view_wview[$1]
remap camera_get_view_height($1) -> view_hview[$1]
//}

//{ gpu
remap gpu_set_fog -> d3d_set_fog
remap gpu_set_blendmode -> draw_set_blend_mode
remap gpu_set_blendmode_ext -> draw_set_blend_mode_ext
remap gpu_set_texrepeat -> texture_set_repeat
remap gpu_set_texrepeat_ext -> texture_set_repeat_ext
remap gpu_set_blendenable -> draw_enable_alphablend
remap gpu_set_colourwriteenable -> draw_set_colour_write_enable
remap gpu_set_colorwriteenable -> draw_set_color_write_enable
remap gpu_set_alphatestenable -> draw_set_alpha_test
remap vertex_format_add_texcoord -> vertex_format_add_textcoord
//}

//{ instances
remap instance_destroy($1, $2) -> instance_destroy_ext($1, $2)
//}

#if gml["sprite_speed"]
remap(stat) $1.sprite_index = $2 -> sprite_index_set($1, $2)
remap(self,stat) sprite_index = $1 -> sprite_index_set(id, $1)

// why would you
//remap(stat) $1.sprite_index ${2:aop} $3 -> sprite_index_post(sprite_index_pre($1) ${2:op} $3)
//remap(self,stat) sprite_index ${1:aop} $2 -> sprite_index_post(sprite_index_pre(id) ${1:op} $2)

remap(stat) $1.image_speed ${2:aop} $3 -> image_speed_post(image_speed_pre($1) ${2:op} $3)
remap(stat) $1.image_speed ${set} $2 -> image_speed_set($1, $2)
remap(expr) $1.image_speed -> image_speed_get($1)

remap(self,stat) image_speed ${1:aop} $2 -> image_speed_post(image_speed_pre(id) ${1:op} $2)
remap(self,stat) image_speed ${set} $1 -> image_speed_set(id, $1)
remap(self,expr) image_speed -> image_speed_get(id)
#end

//{ misc
remap string_hash_to_newline($1) -> ($1)
remap array_create($1, $2) -> gmv_array_create($1, $2)
//}

//{ layers

//}