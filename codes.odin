package vlf

import "core:fmt"
import utf8 "core:unicode/utf8"
import "core:strings"
import "core:strconv"
import mth "core:math"
import rl "vendor:raylib"
import "core:math/rand"

Code_Bases := []string{
    "A",
    "B",
    "G",
    "D",
    "U",
    "X",
    "I"
}

Code_Params :: struct {
    speed:f32,
    complex:bool
}

get_code_params :: proc(code:string) -> Code_Params {
    ret_params := Code_Params{
        speed = 0,
        complex = false
    }

    if strings.contains(code,"ABGD") {
        ret_params.complex = true
    }

    if strings.contains(code,"ABG") {
        ret_params.speed += 2
    }

    if strings.contains(code,"BGD") {
        ret_params.speed += 3
    }

    if strings.contains(code,"GDA") {
        ret_params.speed += 4
    }

    return ret_params
}

