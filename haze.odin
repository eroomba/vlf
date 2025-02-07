package vlf

import "core:fmt"
import mem "core:mem"
import "core:strings"
import rl "vendor:raylib"
import mth "core:math"
import "core:math/rand"

haze_cols:f32 = 16
haze_rows:f32 = 9
haze_w:f32 = active_width / haze_cols
haze_h:f32 = active_height / haze_rows

VLF_Haze_Node :: struct {
    pos:rl.Vector2,
    nodes:[16]int
}

VLF_Haze_Formula :: struct {
    part1:int,
    part2:int,
    result_type:VLF_Element_Type,
    result_sub_type:string
}

vlf_haze := make([dynamic]VLF_Haze_Node)

vlf_haze_formulas := []VLF_Haze_Formula{
    VLF_Haze_Formula{ part1 = spki("a1"), part2 = spki("a2"), result_type = .Ort, result_sub_type = "A"},
    VLF_Haze_Formula{ part1 = spki("b1"), part2 = spki("b2"), result_type = .Ort, result_sub_type = "B"},
    VLF_Haze_Formula{ part1 = spki("g1"), part2 = spki("g2"), result_type = .Ort, result_sub_type = "G"},
    VLF_Haze_Formula{ part1 = spki("d1"), part2 = spki("d2"), result_type = .Ort, result_sub_type = "D"},
    VLF_Haze_Formula{ part1 = spki("d1"), part2 = spki("x"), result_type = .Ort, result_sub_type = "P"},
    VLF_Haze_Formula{ part1 = spki("d2"), part2 = spki("x"), result_type = .Ort, result_sub_type = "E"},
    VLF_Haze_Formula{ part1 = spki("u1"), part2 = spki("u2"), result_type = .Ort, result_sub_type = "U"},
    VLF_Haze_Formula{ part1 = spki("v"), part2 = spki("x"), result_type = .Ort, result_sub_type = "I"},
}

vlf_init_haze :: proc() {
    singles := []string{"a1","a2","b1","b2","g1","g2","u1","u2","v"}
    for j := 0; j < int(haze_rows); j += 1 {
        for i := 0; i < int(haze_cols); i += 1 {
            hx := f32(i) * haze_w
            hy := f32(j) * haze_h
            append(&vlf_haze, VLF_Haze_Node{
                pos = { hx, hy }
            })
            curr_idx := len(vlf_haze) - 1
            for spk in singles {
                (&vlf_haze[curr_idx])^.nodes[spki(spk)] = 1
            }
            (&vlf_haze[curr_idx])^.nodes[spki("d1")] = 2 + int(rand.float32() * 3)
            (&vlf_haze[curr_idx])^.nodes[spki("d2")] = 2 + int(rand.float32() * 3)
            (&vlf_haze[curr_idx])^.nodes[spki("x")] = 3
            (&vlf_haze[curr_idx])^.nodes[spki("o1")] = 20 + int(rand.float32() * 41)
            (&vlf_haze[curr_idx])^.nodes[spki("o2")] = 20 + int(rand.float32() * 41)
            (&vlf_haze[curr_idx])^.nodes[spki("o3")] = 20 + int(rand.float32() * 41)
        }
    }
}

vlf_haze_end :: proc() {
    delete(vlf_haze)
}

vlf_run_haze :: proc() {
    for i := 0; i < len(vlf_haze); i += 1 {
        for form in vlf_haze_formulas {
            if rand.float32() < 0.0001 && vlf_haze[i].nodes[form.part1] > 0 && vlf_haze[i].nodes[form.part2] > 0 {
                (&vlf_haze[i])^.nodes[form.part1] -= 1
                (&vlf_haze[i])^.nodes[form.part2] -= 1
                o_sub_type_key := strings.concatenate({"ort.",form.result_sub_type})
                
                o_x:f32 = mth.floor(rand.float32() * haze_w) + vlf_haze[i].pos.x
                o_y:f32 = mth.floor(rand.float32() * haze_h) + vlf_haze[i].pos.y
                o_vel:f32 = 0.5 + (rand.float32() * 2)
                o_dir:f32 = rand.float32() * 360

                if o_x < 0 {
                    o_x = 0
                } else if o_x > active_width {
                    o_x = active_width
                }

                if o_y < 0 {
                    o_y = 0
                } else if o_y > active_height {
                    o_y = active_height
                }

                o_id := vlf_build_id(.Ort)
                id_seed += 1
                append(&vlf_elems, VLF_Element{
                    id = o_id,
                    core = &vlf_cores[o_sub_type_key],
                    pos = {o_x, o_y },
                    vel = { o_vel, o_dir },
                    gen = step,
                    age = 1,
                    status = .Active,
                    life = vlf_cores[o_sub_type_key].maxlife,
                    maxlife = vlf_cores[o_sub_type_key].maxlife,
                    decay = vlf_cores[o_sub_type_key].decay,
                    complexity = 0,
                    num_vars = make(map[string]f32),
                    str_vars = make(map[string]string),
                    data = form.result_sub_type,
                    parent = "",
                    next = nil,
                    prev = nil
                })
            } 
        }
    }
}

vlf_haze_query :: proc(elem:^VLF_Element, check_types:[]string) -> [dynamic]^VLF_Haze_Node {
    ret_val := make([dynamic]^VLF_Haze_Node)
    start_c:f32 = mth.floor((elem^.pos.x - elem^.core.range) / haze_w)
    end_c:f32 = mth.floor((elem^.pos.x + elem^.core.range) / haze_w)
    start_r:f32 = mth.floor((elem^.pos.y - elem^.core.range) / haze_h)
    end_r:f32 = mth.floor((elem^.pos.y + elem^.core.range) / haze_h)

    if start_c < 0 {
        start_c = 0
    } else if start_c >= haze_cols {
        start_c = haze_cols
    }

    if end_c < 0 {
        end_c = 0
    } else if end_c >= haze_cols {
        end_c = haze_cols
    }

    if start_r < 0 {
        start_r = 0
    } else if start_r >= haze_rows {
        start_r = haze_rows
    }

    if end_r < 0 {
        end_r = 0
    } else if end_r >= haze_rows {
        end_r = haze_rows
    }

    for r:int = int(start_r); r <= int(end_r); r += 1 {
        for c:int = int(start_c); c <= int(end_c); c += 1 {
            h_idx:int = (r * int(haze_rows) + c)
            type_count:int = 0
            for cs in check_types {
                if vlf_haze[h_idx].nodes[spki(cs)] > 0 {
                    type_count += 1
                }
            }
            if type_count == len(check_types) {
                append(&ret_val, &vlf_haze[h_idx])
            }
        }
    }
    return ret_val
}

vlf_haze_query_2 :: proc(pos:rl.Vector2) -> map[string]int {
    ret_val := make(map[string]int)

    col:f32 = mth.floor(pos.x / haze_w)
    row:f32 = mth.floor(pos.y / haze_h)

    h_idx:int = int((row * haze_rows) + col)
    for s : = 1; s < len(vlf_spek_types); s += 1 {
        ss:string = vlf_spek_types[s]
        ret_val[ss] = vlf_haze[h_idx].nodes[spki(ss)]
    }

    return ret_val
}

vlf_haze_transact :: proc(pos:rl.Vector2, s_type:string, count:int) {
    h_c:f32 = mth.floor(pos.x / haze_w)
    h_r:f32 = mth.floor(pos.y / haze_h)
    h_idx:f32 = (h_r * haze_cols) + h_c
    if spki(s_type) < len(vlf_spek_types) {
        vlf_haze[int(h_idx)].nodes[spki(s_type)] += count
    }
}