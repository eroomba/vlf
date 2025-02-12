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

Haze_Node :: struct {
    pos:rl.Vector2,
    nodes:[16]int
}

Haze_Formula :: struct {
    part1:int,
    part2:int,
    result_type:Entity_Type,
    result_sub_type:string
}

haze := make([dynamic]Haze_Node)

haze_formulas := []Haze_Formula{
    Haze_Formula{ part1 = chmi("a1"), part2 = chmi("a2"), result_type = .Ort, result_sub_type = "A"},
    Haze_Formula{ part1 = chmi("b1"), part2 = chmi("b2"), result_type = .Ort, result_sub_type = "B"},
    Haze_Formula{ part1 = chmi("g1"), part2 = chmi("g2"), result_type = .Ort, result_sub_type = "G"},
    Haze_Formula{ part1 = chmi("d1"), part2 = chmi("d2"), result_type = .Ort, result_sub_type = "D"},
    Haze_Formula{ part1 = chmi("d1"), part2 = chmi("x"), result_type = .Ort, result_sub_type = "P"},
    Haze_Formula{ part1 = chmi("d2"), part2 = chmi("x"), result_type = .Ort, result_sub_type = "E"},
    Haze_Formula{ part1 = chmi("u1"), part2 = chmi("u2"), result_type = .Ort, result_sub_type = "U"},
    Haze_Formula{ part1 = chmi("v"), part2 = chmi("x"), result_type = .Ort, result_sub_type = "I"},
}

init_haze :: proc() {
    singles := []string{"a1","a2","b1","b2","g1","g2","u1","u2","v"}
    for j := 0; j < int(haze_rows); j += 1 {
        for i := 0; i < int(haze_cols); i += 1 {
            hx := f32(i) * haze_w
            hy := f32(j) * haze_h
            append(&haze, Haze_Node{
                pos = { hx, hy }
            })
            curr_idx := len(haze) - 1
            for spk in singles {
                (&haze[curr_idx])^.nodes[chmi(spk)] = 1
            }
            (&haze[curr_idx])^.nodes[chmi("d1")] = 2 + int(rand.float32() * 3)
            (&haze[curr_idx])^.nodes[chmi("d2")] = 2 + int(rand.float32() * 3)
            (&haze[curr_idx])^.nodes[chmi("x")] = 3
            (&haze[curr_idx])^.nodes[chmi("o1")] = 20 + int(rand.float32() * 41)
            (&haze[curr_idx])^.nodes[chmi("o2")] = 20 + int(rand.float32() * 41)
            (&haze[curr_idx])^.nodes[chmi("o3")] = 20 + int(rand.float32() * 41)
        }
    }
}

haze_end :: proc() {
    delete(haze)
}

haze_size_of :: proc() -> int {
    return len(haze) * size_of(Haze_Node)
}

run_haze :: proc() {
    for i := 0; i < len(haze); i += 1 {
        for form in haze_formulas {
            if rand.float32() < 0.0001 && haze[i].nodes[form.part1] > 0 && haze[i].nodes[form.part2] > 0 {
                (&haze[i])^.nodes[form.part1] -= 1
                (&haze[i])^.nodes[form.part2] -= 1
                o_sub_type_key := strings.concatenate({"ort.",form.result_sub_type})
                
                o_x:f32 = mth.floor(rand.float32() * haze_w) + haze[i].pos.x
                o_y:f32 = mth.floor(rand.float32() * haze_h) + haze[i].pos.y
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

                o_id := build_id(.Ort)
                append(&entities, Entity{
                    id = o_id,
                    core = &entity_cores[o_sub_type_key],
                    pos = {o_x, o_y },
                    vel = { o_vel, o_dir },
                    gen = step,
                    age = 1,
                    status = .Active,
                    life = entity_cores[o_sub_type_key].maxlife,
                    maxlife = entity_cores[o_sub_type_key].maxlife,
                    decay = entity_cores[o_sub_type_key].decay,
                    complexity = 0,
                    num_vars = make(map[string]f32),
                    str_vars = make(map[string]string),
                    data = form.result_sub_type,
                    parent = "",
                    owner = 0
                })
            } 
        }
    }
}

haze_query :: proc(ent:^Entity, check_types:[]string) -> [dynamic]^Haze_Node {
    ret_val := make([dynamic]^Haze_Node)
    start_c:f32 = mth.floor((ent^.pos.x - ent^.core.range) / haze_w)
    end_c:f32 = mth.floor((ent^.pos.x + ent^.core.range) / haze_w)
    start_r:f32 = mth.floor((ent^.pos.y - ent^.core.range) / haze_h)
    end_r:f32 = mth.floor((ent^.pos.y + ent^.core.range) / haze_h)

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
                if haze[h_idx].nodes[chmi(cs)] > 0 {
                    type_count += 1
                }
            }
            if type_count == len(check_types) {
                append(&ret_val, &haze[h_idx])
            }
        }
    }
    return ret_val
}

haze_query_2 :: proc(pos:rl.Vector2) -> map[string]int {
    ret_val := make(map[string]int)

    col:f32 = mth.floor(pos.x / haze_w)
    row:f32 = mth.floor(pos.y / haze_h)

    h_idx:int = int((row * haze_rows) + col)
    for s : = 1; s < len(chem_types); s += 1 {
        ss:string = chem_types[s]
        ret_val[ss] = haze[h_idx].nodes[chmi(ss)]
    }

    return ret_val
}

haze_transact :: proc(pos:rl.Vector2, chm_type:string, count:int) {
    h_c:f32 = mth.floor(pos.x / haze_w)
    h_r:f32 = mth.floor(pos.y / haze_h)
    if h_c < 0 {
        h_c = 0
    } else if h_c >= haze_cols {
        h_c = haze_cols - 1
    }
    if h_r < 0 {
        h_r = 0
    } else if h_r >= haze_rows {
        h_r = haze_rows - 1
    }
    h_idx:f32 = (h_r * haze_cols) + h_c
    if chmi(chm_type) < len(chem_types) {
        haze[int(h_idx)].nodes[chmi(chm_type)] += count
    }
}