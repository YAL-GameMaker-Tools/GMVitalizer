/// instance_destroy_ext(instance, perform_event)
// Note: cleanup event replacement is specified in VitObject.hx
var q = argument0;
if (!argument1) {
	with (q) {
		event_perform(ev_alarm, 99);
		instance_destroy(id, false);
		exit;
	}
	instance_activate_object(q);
	with (q) {
		event_perform(ev_alarm, 99);
		instance_destroy(id, false);
		exit;
	}
	instance_destroy(q, false);
} else {
	instance_destroy(q);
}