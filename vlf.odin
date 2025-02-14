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
entities := make(map[string]Entity)

Flags :: enum {
    Shift,
    Cntl,
    ItemDisplay,
    Left,
    Right,
    Up,
    Down
}

Event_Type :: enum {
    Click,
    Alt_Click,
    DoubleClick,
    PlayerAction1,
    PlayerAction2,
    PlayerAction3
}

Event :: struct {
    e_type:Event_Type,
    flags:bit_set[Flags],
    pos:rl.Vector2
}

run_test:bool = true
show_debug:bool = false
set_flags:bit_set[Flags]
events := make([dynamic]Event)
mouse_pos:rl.Vector2 = { 0, 0 }

info_item:string = ""
info_item_timer:int = 0


vlf_init :: proc() {

    init_graphics()

    init_cores()

    init_haze()

    if run_test {
        vlf_test_init("strand1")
    }

    init_hash()

    sys_player := add_player("System", 0, {0,0,0,0}, {0, 0})
    players[sys_player].status = .Inactive
    active_player = add_player("Player 1", 1, {100,245,100,255}, {active_width / 2, active_height})

    if len(players) - 1 == 1{
        max_reach = active_width * 0.49
    }

    if show_debug {
        fmt.println("\n\n\n\n\n\n")
    }

}

vlf_run :: proc() {

    step += 1
    if info_item_timer > 0 {
        info_item_timer -= 1
    } else if info_item_timer == 0 {
        info_item = ""
    }

    if .Left in set_flags && active_player >= 0 {
        player_update_dir(&players[active_player], -1)
    }

    if .Right in set_flags && active_player >= 0 {
        player_update_dir(&players[active_player], 1)
    }

    if .Up in set_flags && active_player >= 0 {
        player_update_reach(&players[active_player], 1)
    }

    if .Down in set_flags && active_player >= 0 {
        player_update_reach(&players[active_player], -1)
    }

    build_hash()

    run_haze()

    run_events()

    for ent in entities {
		if entities[ent].status == .Active {
			run_entity(&entities[ent])
		}
	}

    run_items()

    run_players()

    buff_id := ""
    if len(info_item) > 0 {
        buff_id = info_item
    }

    for ent in entities {
		if entities[ent].status != .Active {
            if buff_id == entities[ent].id {
                info_item = ""
            } 
			delete_key(&entities, ent)
		} else if entities[ent].id == buff_id {
            info_item = ent
        }
	}

    shrink(&entities)

    if show_debug {
        if step %% 48 == 0 {
            if step > 0 {
                fmt.println("\x1b[7;A")
            }
            fmt.println("                                \rentities: ",(len(entities) * size_of(Entity)))
            fmt.println("                                \rhash: ",hash_size_of())
            fmt.println("                                \rhaze: ",haze_size_of())
            fmt.println("                                \rtext_cache: ",size_of(textures))
            fmt.println("                                \rimg_cache: ",size_of(src_images))
            fmt.println("                                \r-----------------------------")
        }
    }
}

vlf_end :: proc() {
    delete(events)

    for ent in entities {
        clear1 := entities[ent].num_vars
        clear(&clear1)
        clear2 := entities[ent].str_vars
        clear(&clear2)
    }

    delete(entities)
    graphics_end()
    hash_end()
    haze_end()
    //mem.scratch_destroy(&alloc)
}

vlf_test_init :: proc(ver:string) {
    switch ver {
        case "brane1":
            for t := 0; t < 10; t += 1 {
                brn_id := build_id(.Struck)
                brn_x:f32 = (active_width * 0.5) + (50 - mth.floor(rand.float32() * 101))
                brn_y:f32 = (active_height * 0.5) + mth.floor(rand.float32() * active_height * 0.5)
                brn_v:f32 = 0.5
                brn_a:f32 = rand.float32() * 360
                b_key := "struck.brane"

                entities[brn_id] = Entity{
                    id = brn_id,
                    core = &entity_cores[b_key],
                    pos = { brn_x, brn_y },
                    vel = { brn_v, brn_a },
                    dir = 0,
                    gen = step,
                    age = 1,
                    status = .Active,
                    life = entity_cores[b_key].maxlife,
                    maxlife = entity_cores[b_key].maxlife,
                    decay = entity_cores[b_key].decay,
                    complexity = 0,
                    num_vars = make(map[string]f32),
                    str_vars = make(map[string]string),
                    data = "BRANE",
                    parent = "",
                    owner = 0
                }
            }
        case "proto1":
            pr_id := build_id(.Proto)
            pr_x:f32 = mth.floor(rand.float32() * active_width)
            pr_y:f32 = mth.floor(rand.float32() * active_height)
            pr_v:f32 = 0
            pr_a:f32 = rand.float32() * 360
            pr_key := "proto.Simple"
            pro_nvars := make(map[string]f32)

            entities[pr_id] = Entity{
                id = pr_id,
                core = &entity_cores[pr_key],
                pos = { pr_x, pr_y },
                vel = { pr_v, pr_a },
                dir = rand.float32() * 360,
                gen = step,
                age = 1,
                status = .Active,
                life = entity_cores[pr_key].maxlife,
                maxlife = entity_cores[pr_key].maxlife,
                decay = entity_cores[pr_key].decay,
                complexity = 1,
                num_vars = pro_nvars,
                str_vars = make(map[string]string),
                data = "ABDACB",
                parent = "",
                owner = 0
            }

            pr_id = build_id(.Proto)
            pr_x = mth.floor(rand.float32() * active_width)
            pr_y = mth.floor(rand.float32() * active_height)
            pr_v = 0
            pr_a = rand.float32() * 360
            pr_key = "proto.Complex"

            entities[pr_id] = Entity{
                id = pr_id,
                core = &entity_cores[pr_key],
                pos = { pr_x, pr_y },
                vel = { pr_v, pr_a },
                dir = 0,
                gen = step,
                age = 1,
                status = .Active,
                life = entity_cores[pr_key].maxlife,
                maxlife = entity_cores[pr_key].maxlife,
                decay = entity_cores[pr_key].decay,
                complexity = 2,
                num_vars = make(map[string]f32),
                str_vars = make(map[string]string),
                data = "",
                parent = "",
                owner = 0
            }
        case "strand1":
            str_id := build_id(.Strand)
            str_x:f32 = mth.floor(rand.float32() * active_width)
            str_y:f32 = mth.floor(rand.float32() * active_height)
            str_v:f32 = 0
            str_a:f32 = rand.float32() * 360
            str_key := "strand.D"

            entities[str_id] = Entity{
                id = str_id,
                core = &entity_cores[str_key],
                pos = { str_x, str_y },
                vel = { str_v, str_a },
                dir = rand.float32() * 360,
                gen = step,
                age = 1,
                status = .Active,
                life = entity_cores[str_key].maxlife,
                maxlife = entity_cores[str_key].maxlife,
                decay = entity_cores[str_key].decay,
                complexity = 0,
                num_vars = make(map[string]f32),
                str_vars = make(map[string]string),
                data = "DAAAAABAACAADABDABGAAAGGGA",
                parent = "",
                owner = 0
            }
    }
}

info_click :: proc(pos:rl.Vector2) {

    items := hash_find_2(pos,20)
    min_dist:f32 = -1
    found_item:bool = false
    found_id:string = ""

    for item_id in items {
        item := &entities[item_id]
        dist := rl.Vector2Distance(item.pos, pos)
        if min_dist < 0 || dist < min_dist {
            min_dist = dist
            found_id = item.id
            found_item = true
        }
    }

    if found_item {
        info_item = found_id
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
    switch event.e_type {
        case .Click:
            close_info()
        case .DoubleClick:
        case .Alt_Click:
            info_click(event.pos)
        case .PlayerAction1:
            if active_player >= 0 {
                run_player_event(&players[active_player], .Activate)
            }
        case .PlayerAction2:
            if active_player >= 0 {
                run_player_event(&players[active_player], .Toggle)
            }
        case .PlayerAction3:
    }
}

close_info :: proc() {
    if len(info_item) > 0 {
        info_item = ""
        info_item_timer = 0
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
