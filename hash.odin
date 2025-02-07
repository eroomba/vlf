package vlf

import "core:fmt"
import mth "core:math"
import rl "vendor:raylib"

VLF_Hash_Item :: struct {
    items:[dynamic]^VLF_Element
}

hash_hw:f32
hash_cols:f32
hash_rows:f32

hash:[dynamic]([dynamic]VLF_Hash_Item)

vlf_init_hash :: proc() {
    hash_hw = mth.floor(active_height / 10)
    hash_cols = mth.ceil(active_width / hash_hw)
    hash_rows = mth.ceil(active_height / hash_hw)
}

vlf_hash_end :: proc() {
    delete(hash)
}

vlf_build_hash :: proc() {
    clear(&hash)
    for i := 0; i < int(hash_cols); i += 1 {
        append(&hash, make([dynamic]VLF_Hash_Item))
        for j := 0; j < int(hash_rows); j += 1 {
            append(&hash[i], VLF_Hash_Item{
                items = make([dynamic]^VLF_Element)
            })
        }
    }
    for &elem in vlf_elems {
        vlf_hash_add(&elem)
    }
}

vlf_hash_add :: proc(elem:^VLF_Element) {
    col:f32 = mth.floor(elem.pos.x / hash_hw)
    row:f32 =  mth.floor(elem.pos.y / hash_hw)
    if (col >= 0 && col < hash_cols && row >=0 && row < hash_rows) {
        append(&(hash[int(col)][int(row)].items), elem)
    } 
}

vlf_hash_find :: proc(elem:^VLF_Element, e_types:bit_set[VLF_Element_Type] = {}) -> [dynamic]^VLF_Element {
    found := make([dynamic]^VLF_Element)

    col:f32 = mth.floor(elem^.pos.x / hash_hw)
    row:f32 = mth.floor(elem^.pos.y / hash_hw)
    col_s := mth.floor((elem^.pos.x - elem^.core.range) / hash_hw)
    col_e := mth.floor((elem^.pos.x + elem^.core.range) / hash_hw)
    row_s := mth.floor((elem^.pos.y - elem^.core.range) / hash_hw)
    row_e := mth.floor((elem^.pos.y + elem^.core.range) / hash_hw)

    if col_s < 0 {
        col_s = 0
    } else if col_s >= hash_cols {
        col_s = hash_cols - 1
    }

    if col_e < 0 {
        col_e = 0
    } else if col_e >= hash_cols {
        col_e = hash_cols - 1
    }

    if row_s < 0 {
        row_s = 0
    } else if row_s >= hash_rows {
        row_s = hash_rows - 1
    }

    if row_e < 0 {
        row_e = 0
    } else if row_e >= hash_rows {
        row_e = hash_rows - 1 
    }

    for i:int = int(col_s); i <= int(col_e); i += 1 {
        for j:int = int(row_s); j <= int(row_e); j += 1 {
            for k := 0; k < len(hash[i][j].items); k += 1 {
                chk := hash[i][j].items[k]
                if chk^.id != elem^.id && chk.status == .Active && (card(e_types) == 0 || chk^.core.e_type in e_types) {
                    dist := rl.Vector2Distance(elem^.pos, chk^.pos)
                    if dist < elem^.core.range {
                        append(&found, &(chk^))
                    }
                }
            }
        }
    }

    return found
}

vlf_hash_find_2 :: proc(pos:rl.Vector2, range:f32) -> [dynamic]^VLF_Element {
    found := make([dynamic]^VLF_Element)

    col:f32 = mth.floor(pos.x / hash_hw)
    row:f32 = mth.floor(pos.y / hash_hw)
    col_s := mth.floor((pos.x -range) / hash_hw)
    col_e := mth.floor((pos.x + range) / hash_hw)
    row_s := mth.floor((pos.y - range) / hash_hw)
    row_e := mth.floor((pos.y + range) / hash_hw)

    if col_s < 0 {
        col_s = 0
    } else if col_s >= hash_cols {
        col_s = hash_cols - 1
    }

    if col_e < 0 {
        col_e = 0
    } else if col_e >= hash_cols {
        col_e = hash_cols - 1
    }

    if row_s < 0 {
        row_s = 0
    } else if row_s >= hash_rows {
        row_s = hash_rows - 1
    }

    if row_e < 0 {
        row_e = 0
    } else if row_e >= hash_rows {
        row_e = hash_rows - 1 
    }

    for i:int = int(col_s); i <= int(col_e); i += 1 {
        for j:int = int(row_s); j <= int(row_e); j += 1 {
            for k := 0; k < len(hash[i][j].items); k += 1 {
                chk := hash[i][j].items[k]
                if chk.status == .Active {
                    dist := rl.Vector2Distance(pos, chk^.pos)
                    if dist < range {
                        append(&found, &(chk^))
                    }
                }
            }
        }
    }

    return found
}