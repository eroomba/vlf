package vlf

import "core:fmt"
import "core:strings"
import "core:strconv"
import mth "core:math"
import rl "vendor:raylib"
import "core:math/rand"

vlf_src :: enum {
	NAT,
	ANM,
	VGT,
	SYN
}

vlf_src_name :: proc(src:vlf_src) -> string {
	switch src {
		case .NAT:
			return "Natural"
		case .ANM:
			return "Animal"
		case .VGT:
			return "Vegetable"
		case .SYN:
			return "Synthetic"
	}
	return "Unknown"
}

vlf_kind :: enum {
	EMPTY,
	BASE,
	CODE,
	STRAND,
	PROTO,
	HUSK,
	EXTRA
}

vlf_kind_name :: proc(kind:vlf_kind) -> string {
	switch kind {
		case .EMPTY:
			return "Empty"
		case .BASE:
			return "Base"
		case .CODE:
			return "Code"
		case .STRAND:
			return "Strand"
		case .PROTO:
			return "Proto"
		case .HUSK:
			return "Husk"
		case .EXTRA:
			return "Extra"
	}
	return "None"
}

vlf_status :: enum {
	ACTIVE,
	INACTIVE,
	REMOVED
}