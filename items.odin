package vlf

import "core:fmt"
import "core:unicode/utf8"
import mem "core:mem"
import "core:strings"
import mth "core:math"
import rl "vendor:raylib"
import "core:math/rand"

Item_Type :: enum {
    None,
    Beam
}

Item_Status :: enum {
    Active,
    Inactive
}

Item :: struct {
    id:string,
    status:Item_Status,
    i_type:Item_Type,
    pos:rl.Vector2,
    vel:rl.Vector2,
    num_vars:map[string]f32,
    str_vars:map[string]string,
    owner:int
}

items := make([dynamic]Item)

run_items :: proc() {
    for &item in items {
        run_item(&item)
    }

    for i := 0; i < len(items); i += 1 {
		if items[i].status == .Inactive {
			ordered_remove(&items, i) 
		}
	}

    shrink(&items)
}

run_item :: proc(item:^Item) {
    if item^.status == .Active {
        switch item^.i_type {
            case .None:
            case .Beam:
                power := item^.num_vars["power"]
                step := item^.num_vars["step"]
                dist := item^.num_vars["dist"]

                if step == 5 {
                    h_pos := item^.pos
                    h_pos.x += dist * mth.cos(item^.vel.y * mth.π / 180)
                    h_pos.y += dist * mth.sin(item^.vel.y * mth.π / 180)

                    h_range:f32 = active_width * 0.1
                    hits := hash_find_2(h_pos, h_range)
                    for hit in hits {
                        ang:f32 = mth.atan2(hit^.pos.y - h_pos.y, hit^.pos.x - h_pos.x) * 180 / mth.π
                        dist:f32 = rl.Vector2Distance(h_pos, hit^.pos)
                        power2:f32 = power * (1 - (dist / h_range))
                        power2 += hit^.vel.x
                        hit^.vel = { power2, ang}
                    }
                    delete(hits)
                } 
                
                if step >= 11 {
                    item^.status = .Inactive
                } else {
                    item^.num_vars["step"] += 1
                }
        }
    }
}