package vlf

import mth "core:math"
import rl "vendor:raylib"
import "core:math/rand"

chems := []string{
    "a-1",
    "a-2",
    "b02",
    "b35",
    "Ga",
    "Gb",
    "d_0",
    "d_1",
    "u.x",
    "u.y",
    "K1a",
    "K2f",
    "K9e",
    "Q₃",
    "Q₇",
    "Qⁿ"
}

Haze_Formula :: struct {
    part1:int,
    part2:int,
    type:Entity_Type,
    sub_type:string
}

haze_formulas := []Haze_Formula{
    Haze_Formula{ 0, 1, .Base, "A" },
    Haze_Formula{ 2, 3, .Base, "B" },
    Haze_Formula{ 4, 5, .Base, "G" },
    Haze_Formula{ 6, 7, .Base, "D" },
    Haze_Formula{ 8, 9, .Base, "U" },
    Haze_Formula{ 10, 11, .Base, "I" },
    Haze_Formula{ 10, 12, .Base, "X" },
    Haze_Formula{ 11, 12, .Base, "O" }
}

haze_cols:f32 = 16
haze_rows:f32 = 9
haze_count:f32 = haze_cols * haze_rows 
haze_w := active_width / haze_cols
haze_h := active_height / haze_rows
haze:[16 * 9][16]int

chem_idx :: proc(name:string) -> int {
    for i in 0..<len(chems) {
        if chems[i] == name {
            return i
        }
    }
    return -1
}

haze_set :: proc(idx:int, chem:string, val:int) {
    ci := chem_idx(chem)
    if ci >= 0 {
        haze[idx][ci] = val
    }
}

haze_init :: proc() {
    for i in 0..<int(haze_count) {
        small_set := []string{
            "a-1",
            "a-2",
            "b02",
            "b35",
            "Ga",
            "Gb",
            "d_0",
            "d_1",
            "u.x",
            "u.y",
            "K1a",
            "K2f",
            "K9e"
        }
        for c in small_set {
            haze_set(i, c, int(1 + mth.floor(rand.float32() * 3)))
        }
        haze_set(i, "Q₃", 20 + int(1 + mth.floor(rand.float32() * 40)))
        haze_set(i, "Q₇", 20 + int(1 + mth.floor(rand.float32() * 40)))
        haze_set(i, "Qⁿ", 20 + int(1 + mth.floor(rand.float32() * 40)))
    }

}

run_haze :: proc() {
    for i in 0..<int(haze_count) {
        for f in haze_formulas {
            if rand.float32() > 0.99990 && haze[i][f.part1] > 0 && haze[i][f.part2] > 0  {
                haze[i][f.part1] -= 1
                haze[i][f.part2] -= 1
                h_r:f32 = mth.floor(f32(i) / haze_cols)
                h_c:f32 = f32(i) - (h_r * haze_cols)
                h_x:f32 = h_c * haze_w
                h_y:f32 = h_r * haze_h
                h_pos:rl.Vector2 = { h_x + mth.floor(rand.float32() * haze_w), h_y + mth.floor(rand.float32() * haze_h) }
                h_dir:f32 = rand.float32() * 360
                h_vel:f32 = 0.5 + (rand.float32() * 1)
                _ = entities_add(.Active, f.type, f.sub_type, h_pos, { h_vel, h_dir }, h_dir, 0, f.sub_type)
            }
        }
    }
}

haze_query :: proc() {

}