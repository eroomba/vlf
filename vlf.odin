package vlf

import "core:fmt"
import "core:strings"
import "core:strconv"
import mth "core:math"
import rl "vendor:raylib"
import "core:math/rand"

step:int = 0
id_seed:int = 0
visc:f32 = 0.3
vlf_elements := make(map[string]VLF_Element)

VLF_Flags :: enum {
    EnvironmentDisplay,
    ItemDisplay
}

VLF_Event_Type :: enum {
    Puff,
    Add,
    Get
}

VLF_Event :: struct {
    e_type:VLF_Event_Type,
    pos:rl.Vector2
}

vlf_set_flags:bit_set[VLF_Flags]
vlf_events := make([dynamic]VLF_Event)
vlf_mouse_pos:rl.Vector2 = { 0, 0 }

vlf_info_item:string = ""
vlf_info_item_timer:int = 0

vlf_init :: proc() {
    vlf_init_graphics()

    vlf_init_cores()

    vlf_init_haze()

    vlf_init_hash()

    if 1 == 0 {
        for i := 0; i < 30; i += 1 {
            sn_num_vars := make(map[string]f32)
            sn_num_vars["b_step"] = 0
            sn_pos:rl.Vector2 = { mth.floor(rand.float32() * active_width), mth.floor(rand.float32() * active_height)}
            sn_vel:rl.Vector2 = { 1, rand.float32() * 360}

            sn_id:string = strings.concatenate({"sn-", int_to_str(id_seed)})
            id_seed += 1
            vlf_elements[sn_id] = VLF_Element{
                id = strings.concatenate({"snip-", int_to_str(id_seed)}),
                core = &vlf_cores["snip.build"],
                pos = sn_pos,
                vel = sn_vel,
                gen = step,
                age = 1,
                status = .Active,
                life = vlf_cores["snip.build"].maxlife,
                maxlife = vlf_cores["snip.build"].maxlife,
                decay = vlf_cores["snip.build"].decay,
                complexity = 0,
                num_vars = sn_num_vars,
                str_vars = make(map[string]string),
                data = "UBU",
                parent = ""
            }
        }
    }
}

vlf_run :: proc() {

    step += 1
    if vlf_info_item_timer > 0 {
        vlf_info_item_timer -= 1
    } else if vlf_info_item_timer == 0 {
        vlf_info_item = ""
    }

    vlf_build_hash()

    vlf_run_haze()

    vlf_run_events()

    for e_id in vlf_elements {
		if vlf_elements[e_id].status == .Active {
			vlf_element_run(&vlf_elements[e_id])
		} else {
            delete_key(&vlf_elements, e_id)
        }
	}

    shrink(&vlf_elements)
}

vlf_end :: proc() {
    delete(vlf_events)
    for i in vlf_elements {
        clear1 := vlf_elements[i].num_vars
        clear(&clear1)
        clear2 := vlf_elements[i].str_vars
        clear(&clear2)
    }
    clear(&vlf_elements)
    vlf_graphics_end()
    vlf_hash_end()
    vlf_haze_end()
}

vlf_click :: proc(pos:rl.Vector2, flags:bit_set[VLF_Flags]) {
    if .ItemDisplay in flags {
        items := vlf_hash_find_2(pos,20)
        min_dist:f32 = -1
        found_item:bool = false
        found_id:string = ""

        for item in items {
            dist := rl.Vector2Distance(vlf_elements[item].pos, pos)
            if min_dist < 0 || dist < min_dist {
                min_dist = dist
                found_id = vlf_elements[item].id
                found_item = true
            }
        }

        if found_item {
            vlf_info_item = found_id
            vlf_info_item_timer = 400
        } else {
            vlf_info_item_timer = 0
        }

        delete(items)
    }
}

vlf_run_events :: proc() {
    for len(vlf_events) > 0 {
        event := pop(&vlf_events)
        vlf_run_event(&event)
    }
}

vlf_run_event :: proc(event:^VLF_Event) {
    switch event^.e_type {
        case .Puff:
            p_power:f32 = 5
            p_range:f32 = active_width * 0.1
            hits := vlf_hash_find_2(event^.pos, p_range)
            for hit in hits {
                ang:f32 = mth.atan2(vlf_elements[hit].pos.y - event^.pos.y, vlf_elements[hit].pos.x - event^.pos.x) * 180 / mth.π
                dist:f32 = rl.Vector2Distance(event^.pos, vlf_elements[hit].pos)
                p_power2:f32 = p_power * (1 - (dist / p_range))
                p_power2 += vlf_elements[hit].vel.x
                (&vlf_elements[hit])^.vel = { p_power2, ang}
            }
            delete(hits)
        case .Add:
        case .Get:
    }
}

int_to_str :: proc(val: $T) -> string {
	return fmt.aprintf("%d", val)
}
