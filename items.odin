package vlf

import "core:fmt"
import "core:strings"
import "core:strconv"
import mth "core:math"
import rl "vendor:raylib"
import "core:math/rand"

vlf_item :: struct {
	id:string,
	src:vlf_src,
	kind:vlf_kind,
	key:string,
	pos:rl.Vector2,
	vel:rl.Vector2,
	weight:f32,
	vars:map[string]f32,
	status:vlf_status,
	code:string,
	parent:string
}

vlf_item_key :: proc(item:vlf_item) -> string {
	return vlf_key(item.src, item.kind)
}

vlf_key :: proc(src:vlf_src,kind:vlf_kind) -> string {
	return strings.concatenate({vlf_src_name(src),vlf_kind_name(kind)})
}

init_item :: proc(id:string, src:vlf_src, kind:vlf_kind, pos:rl.Vector2, vel:rl.Vector2, vars:map[string]f32, code:string = "", parent:string = "") -> vlf_item {
	i_key:string = vlf_key(src,kind)

	i_weight:f32 = 0
	i_vars := vars

	switch kind {
		case .EMPTY:
		case .BASE:
			i_weight = 1.001
			i_vars["width"] = 5
		case .CODE:
		case .STRAND:
			i_weight = 1.01
		case .PROTO:
			switch src {
				case .ANM:
					i_weight = 1.1
				case .VGT:
					i_weight = 1.05
				case .SYN:
					i_weight = 1.2
				case .NAT:
					i_weight = 0
			}
		case .HUSK:
			i_weight = 1.001
			i_vars["width"] = 5
		case .EXTRA:
	}

	return vlf_item{
		id = id,
		src = src,
		kind = kind,
		key = i_key,
		weight = i_weight,
		vars = i_vars,
		pos = pos,
		vel = vel,
		status = vlf_status.ACTIVE,
		code = code,
		parent = parent
	}
}


