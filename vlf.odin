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
vlf_elems := make([dynamic]VLF_Element)

VLF_Flags :: enum {
    EnvironmentDisplay,
    ItemDisplay
}

VLF_Event_Type :: enum {
    Click,
    DoubleClick,
    KeyPress
}

VLF_Event :: struct {
    e_type:VLF_Event_Type,
    flags:bit_set[VLF_Flags],
    pos:rl.Vector2
}

vlf_set_flags:bit_set[VLF_Flags]
vlf_events := make([dynamic]VLF_Event)
vlf_mouse_pos:rl.Vector2 = { 0, 0 }

vlf_info_item:^VLF_Element = nil
vlf_info_item_timer:int = 0

vlf_init :: proc() {

    vlf_init_graphics()

    vlf_init_cores()

    vlf_init_haze()

    vlf_init_hash()

}

vlf_run :: proc() {
    
    step += 1
    if vlf_info_item_timer > 0 {
        vlf_info_item_timer -= 1
    } else if vlf_info_item_timer == 0 {
        vlf_info_item = nil
    }

    vlf_build_hash()

    vlf_run_haze()

    vlf_run_events()

    for &elem in vlf_elems {
		if elem.status == .Active {
			vlf_element_run(&elem)
		}
	}

    buff_id := ""
    if vlf_info_item != nil {
        buff_id = vlf_info_item^.id
    }

    for i := 0; i < len(vlf_elems); i += 1 {
		if vlf_elems[i].status != .Active {
            if buff_id == vlf_elems[i].id {
                vlf_info_item = nil
            } 
			ordered_remove(&vlf_elems, i) 
		} else if vlf_elems[i].id == buff_id {
            vlf_info_item = &vlf_elems[i]
        }
	}

    shrink(&vlf_elems)
}

vlf_end :: proc() {
    delete(vlf_events)

    for elem in vlf_elems {
        clear1 := elem.num_vars
        clear(&clear1)
        clear2 := elem.str_vars
        clear(&clear2)
    }

    //clear(&vlf_elements)
    vlf_graphics_end()
    vlf_hash_end()
    vlf_haze_end()
    //mem.scratch_destroy(&vlf_alloc)
}

vlf_info_click :: proc(pos:rl.Vector2) {

    items := vlf_hash_find_2(pos,20)
    min_dist:f32 = -1
    found_item:bool = false
    found_ptr:^VLF_Element = nil

    for item in items {
        dist := rl.Vector2Distance(item^.pos, pos)
        if min_dist < 0 || dist < min_dist {
            min_dist = dist
            found_ptr = &(item^)
            found_item = true
        }
    }

    if found_item {
        vlf_info_item = found_ptr
        vlf_info_item_timer = 400
    } else {
        vlf_info_item_timer = 0
    }

    delete(items)

}

vlf_run_events :: proc() {
    for len(vlf_events) > 0 {
        event := pop(&vlf_events)
        vlf_run_event(&event)
    }
}

vlf_run_event :: proc(event:^VLF_Event) {
    switch event^.e_type {
        case .Click:
            if .ItemDisplay in event^.flags {
                vlf_info_click(event^.pos)
            }
        case .DoubleClick:
            p_power:f32 = 5
            p_range:f32 = active_width * 0.1
            hits := vlf_hash_find_2(event^.pos, p_range)
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
