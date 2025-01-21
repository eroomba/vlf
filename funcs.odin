package vlf

import "core:fmt"
import "core:strings"
import "core:strconv"
import mth "core:math"
import rl "vendor:raylib"
import "core:math/rand"

int_to_str :: proc(val: $T) -> string {
	return fmt.aprintf("%d", val)
}