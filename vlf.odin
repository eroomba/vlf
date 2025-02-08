package vlf

import "core:fmt"
import mem "core:mem"
import "core:strings"
import "core:strconv"
import mth "core:math"
import rl "vendor:raylib"
import "core:math/rand"

step:int = 0
id_seed:int = 0
visc:f32 : 0.3
entities := make([dynamic]Entity)

Flags :: enum {
    EnvironmentDisplay,
    ItemDisplay
}

Event_Type :: enum {
    Click,
    DoubleClick,
    KeyPress
}

Event :: struct {
    e_type:Event_Type,
    flags:bit_set[Flags],
    pos:rl.Vector2
}

set_flags:bit_set[Flags]
events := make([dynamic]Event)
mouse_pos:rl.Vector2 = { 0, 0 }

info_item:^Entity = nil
info_item_timer:int = 0

vlf_init :: proc() {

    init_graphics()

    init_cores()

    init_haze()

    init_hash()

}

vlf_run :: proc() {
    
    step += 1
    if info_item_timer > 0 {
        info_item_timer -= 1
    } else if info_item_timer == 0 {
        info_item = nil
    }

    build_hash()

    run_haze()

    run_events()

    for &ent in entities {
		if ent.status == .Active {
			run_entity(&ent)
		}
	}

    buff_id := ""
    if info_item != nil {
        buff_id = info_item^.id
    }

    for i := 0; i < len(entities); i += 1 {
		if entities[i].status != .Active {
            if buff_id == entities[i].id {
                info_item = nil
            } 
			ordered_remove(&entities, i) 
		} else if entities[i].id == buff_id {
            info_item = &entities[i]
        }
	}

    shrink(&entities)
}

vlf_end :: proc() {
    delete(events)

    for ent in entities {
        clear1 := ent.num_vars
        clear(&clear1)
        clear2 := ent.str_vars
        clear(&clear2)
    }

    delete(&entities)
    graphics_end()
    hash_end()
    haze_end()
    //mem.scratch_destroy(&alloc)
}

info_click :: proc(pos:rl.Vector2) {

    items := hash_find_2(pos,20)
    min_dist:f32 = -1
    found_item:bool = false
    found_ptr:^Entity = nil

    for item in items {
        dist := rl.Vector2Distance(item^.pos, pos)
        if min_dist < 0 || dist < min_dist {
            min_dist = dist
            found_ptr = &(item^)
            found_item = true
        }
    }

    if found_item {
        info_item = found_ptr
        info_item_timer = 400
    } else {
        info_item_timer = 0
    }

    delete(items)

}

run_events :: proc() {
    for len(events) > 0 {
        event := pop(&events)
        run_event(&event)
    }
}

run_event :: proc(event:^Event) {
    switch event^.e_type {
        case .Click:
            if .ItemDisplay in event^.flags {
                info_click(event^.pos)
            }
        case .DoubleClick:
            p_power:f32 = 5
            p_range:f32 = active_width * 0.1
            hits := hash_find_2(event^.pos, p_range)
            for hit in hits {
                ang:f32 = mth.atan2(hit^.pos.y - event^.pos.y, hit^.pos.x - event^.pos.x) * 180 / mth.π
                dist:f32 = rl.Vector2Distance(event^.pos, hit^.pos)
                p_power2:f32 = p_power * (1 - (dist / p_range))
                p_power2 += hit^.vel.x
                hit^.vel = { p_power2, ang}
            }
            delete(hits)
        case .KeyPress:
    }
}

int_to_str :: proc(val: $T) -> string {
	return fmt.aprintf("%d", val)
}

momentum_add :: proc(v1:rl.Vector2, w1:f32, v2:rl.Vector2, w2:f32) -> rl.Vector2 {
    ret_vec:rl.Vector2
    v1_x:f32 = v1.x * mth.cos(v1.y * mth.π / 180)
    v1_y:f32 = v1.x * mth.sin(v1.y * mth.π / 180)

    v2_x:f32 = v2.x * mth.cos(v2.y * mth.π / 180)
    v2_y:f32 = v2.x * mth.sin(v2.y * mth.π / 180)

    v1_w := w1
    v2_w := w2

    if v1_w > v2_w {
        ratio:f32 = v2_w / v1_w
        v1_w = 1
        v2_w = ratio
    } else if v2_w > v1_w {
        ratio:f32 = v1_w / v2_w
        v2_w = 1
        v1_w = ratio
    } else {
        v2_w = 1
        v2_w = 1
    }

    r_x:f32 = (v1_x * v1_w) + (v2_x * v2_w)
    r_y:f32 = (v1_y * v1_w) + (v2_y * v2_w)

    ret_vec.x = mth.hypot_f32(r_x, r_y)
    ret_vec.y = mth.atan2(r_y, r_x) * 180 / mth.π

    if ret_vec.y > 360 {
        ret_vec.y -= 360
    } else if ret_vec.y < 0 {
        ret_vec.y += 360
    }

    return ret_vec
}
