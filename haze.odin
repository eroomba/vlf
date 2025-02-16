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

Haze_Formula :: struct {
    part1:int,
    part2:int,
    result_type:Entity_Type,
    result_sub_type:string
}

haze := make([dynamic][16]int)
haze_saturation := []int{
    0, // n/a
    30, // a1
    30, // a2
    30, // b1
    30, // b2
    30, // g1
    30, // g2
    50, // d1
    50, // d2
    40, // u1
    40, // u2
    50, // x
    120, // o1
    140, // o2
    140, // o3
    50, // v
}

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
            val:[16]int = 0
            append(&haze, val)
            curr_idx := len(haze) - 1
            for spk in singles {
                haze[curr_idx][chmi(spk)] = 1
            }
            haze[curr_idx][chmi("d1")] = 2 + int(rand.float32() * 3)
            haze[curr_idx][chmi("d2")] = 2 + int(rand.float32() * 3)
            haze[curr_idx][chmi("x")] = 2
            haze[curr_idx][chmi("o1")] = 10 + int(rand.float32() * 21)
            haze[curr_idx][chmi("o2")] = 10 + int(rand.float32() * 21)
            haze[curr_idx][chmi("o3")] = 10 + int(rand.float32() * 21)
        }
    }
}

haze_end :: proc() {
    delete(haze)
}

haze_size_of :: proc() -> int {
    return len(haze) * size_of([16]int)
}

run_haze :: proc() {
    for i := 0; i < len(haze); i += 1 {
        c_row:int = int(mth.floor(f32(i) / f32(haze_cols)))
        c_col:int = i - (c_row * int(haze_cols))
        for form in haze_formulas {
            if rand.float32() < 0.0001 && haze[i][form.part1] > 0 && haze[i][form.part2] > 0 {
                haze[i][form.part1] -= 1
                haze[i][form.part2] -= 1
                o_sub_type_key := strings.concatenate({"ort.",form.result_sub_type})
                
                h_y:f32 = mth.floor(f32(i) / haze_cols)
                h_x:f32 = f32(i) - (h_y * haze_cols)
                h_y *= haze_h
                h_x *= haze_w
                o_x:f32 = mth.floor(rand.float32() * haze_w) + h_x
                o_y:f32 = mth.floor(rand.float32() * haze_h) + h_y
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
                entities[o_id] = Entity{
                    id = o_id,
                    core = &entity_cores[o_sub_type_key],
                    pos = {o_x, o_y },
                    vel = { o_vel, o_dir },
                    dir = 0,
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
                }
            } 
        }

        for c in 0..<len(haze[i]) {
            if haze[i][c] > haze_saturation[c] {

                s_col := c_col - 1 < 0 ? 0 : c_col - 1 
                e_col := c_col + 1 >= int(haze_cols) ? int(haze_cols) - 1 : c_col + 1
                s_row := c_row - 1 < 0 ? 0 : c_row - 1 
                e_row := c_row + 1 >= int(haze_rows) ? int(haze_rows) - 1 : c_row + 1

                rem_amount:int = int(mth.ceil(f32(haze_saturation[c]) * 0.05))
                if rem_amount < 2 {
                    rem_amount = 2
                }

                for ii := s_col; ii <= e_col; ii += 1 {
                    for jj := s_row; jj <= e_row; jj += 1 {
                        cd_idx := (jj * int(haze_cols)) + ii
                        if !(ii == c_col && jj == c_row) && haze[cd_idx][c] + rem_amount < haze_saturation[c] * 2 {
                            haze[cd_idx][c] += rem_amount
                            haze[i][c] = haze[i][c] - rem_amount < 0 ? 0 : haze[i][c] - rem_amount
                        }
                    }
                }
            }
        }
    }
}

haze_query :: proc(ent:^Entity, check_types:[]string) -> [dynamic][16]int {
    ret_val := make([dynamic][16]int)
    start_c:f32 = mth.floor((ent.pos.x - ent.core.range) / haze_w)
    end_c:f32 = mth.floor((ent.pos.x + ent.core.range) / haze_w)
    start_r:f32 = mth.floor((ent.pos.y - ent.core.range) / haze_h)
    end_r:f32 = mth.floor((ent.pos.y + ent.core.range) / haze_h)

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
                if haze[h_idx][chmi(cs)] > 0 {
                    type_count += 1
                }
            }
            if type_count == len(check_types) {
                append(&ret_val, haze[h_idx])
            }
        }
    }
    return ret_val
}

haze_query_2 :: proc(pos:rl.Vector2) -> map[string]int {
    ret_val := make(map[string]int)

    col:f32 = mth.floor(pos.x / haze_w)
    row:f32 = mth.floor(pos.y / haze_h)

    h_idx:int = int((row * haze_cols) + col)
    for s : = 1; s < len(chem_types); s += 1 {
        ss:string = chem_types[s]
        ret_val[ss] = haze[h_idx][chmi(ss)]
    }

    return ret_val
}

haze_transact :: proc(pos:rl.Vector2, chm_type:string, count:int) {
    h_r:f32 = mth.floor(pos.y / haze_h)
    h_c:f32 = mth.floor(pos.x / haze_w)
    if (h_r < 0) {
        h_r = 0
    } else if h_r >= haze_rows {
        h_r = haze_rows - 1
    }
    if (h_c < 0) {
        h_c = 0
    } else if h_c >= haze_cols {
        h_c = haze_cols - 1
    }

    h_idx:int = int((h_r * haze_cols) + h_c)
    c_idx:int = chmi(chm_type)

    if c_idx < len(chem_types) && c_idx >= 0 {
        if haze[h_idx][c_idx] + count > haze_saturation[c_idx] * 2 {
            haze[h_idx][c_idx] = haze_saturation[c_idx] * 2
        } else if haze[h_idx][c_idx] + count < 0 {
            haze[h_idx][c_idx] = 0
        } else {
            haze[h_idx][c_idx] += count
        }
    }
}