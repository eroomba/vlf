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
    Pulse,
    Capsule
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
    level:int,
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
    if item.status == .Active {
        switch item.i_type {
            case .None:
            case .Pulse:
                run_pulse(item)
            case .Capsule:
                run_capsule(item)
        }
    }
}

run_pulse :: proc(pulse:^Item) {
    if pulse.status == .Active {
        power := pulse.num_vars["power"]
        step := pulse.num_vars["step"]
        h_pos := pulse.pos

        if step == 0 {

            h_range:f32 = active_width * 0.15
            hits := hash_find_2(h_pos, h_range)
            for hit_id in hits {
                hit := &entities[hit_id]
                ang:f32 = mth.atan2(hit.pos.y - h_pos.y, hit.pos.x - h_pos.x) * 180 / mth.π
                dist:f32 = rl.Vector2Distance(h_pos, hit.pos)
                power2:f32 = power * (1 - (dist / h_range))
                hit^.vel.x += power2
                hit^.vel.y = ang
            }
            delete(hits)
        } 
        
        if step >= 8 {
            pulse^.status = .Inactive
        } else {
            pulse^.num_vars["step"] += 1
        }
    }
}

run_capsule :: proc(capsule:^Item) {
    if capsule.status == .Active {
        curr_chem := haze_query_2(capsule.pos)

        o1_i := chmi("o1")
        o2_i := chmi("o2")
        o3_i := chmi("o3")

        add_count:int = 1 + int(mth.floor(rand.float32() * 2))
        if rand.float32() > 0.99 {
            haze_transact(capsule.pos, "o1", add_count)
        }

        add_count = 1 + int(mth.floor(rand.float32() * 2))
        if rand.float32() > 0.99 {
            haze_transact(capsule.pos, "o2", add_count)
        }

        add_count = 3 + int(mth.floor(rand.float32() * 7))
        if rand.float32() > 0.98 {
            haze_transact(capsule.pos, "o3", add_count)
        }

    }
}
