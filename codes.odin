#+feature dynamic-literals
package vlf

import "core:fmt"
import "core:strings"
import "core:strconv"
import mth "core:math"
import rl "vendor:raylib"
import "core:math/rand"

vlf_run_codes :: proc(item:^vlf_item) {
    
    for i := 0; i < len(item.code); i += 1 {
       if i <= len(item.code) - 3 {
            r_code := item.code[i:i+3]

            switch r_code {

                case "AAA":
                    vlf_code_move(item)
                case "AAB":
                    vlf_code_inc_speed(item)

            }
       }    
    }

}

vlf_code_move :: proc(item:^vlf_item) {
    if !("speed" in item.vars) {
        item^.vars["speed"] = 0.5
    }
    speed := item.vars["speed"]

    item^.vel.x = speed
}

vlf_code_inc_speed :: proc(item:^vlf_item) {
    if ("speed" in item.vars) {
        item^.vel.x *= 3
    }
}