package vlf

import "core:fmt"
import mem "core:mem"
import "core:strings"
import mth "core:math"
import rl "vendor:raylib"
import "core:math/rand"

Player_Status :: enum {
    Active,
    Inactive,
    Spectating
}

Player_Event :: enum {
    Activate,
    Toggle
}

Player_Tool :: enum {
    None,
    Brane,
    Pulse,
    Grab
}

Player :: struct {
    status:Player_Status,
    num:int,
    name:string,
    color:rl.Color,
    brane_count:int,
    brane_percent:f32,
    counts:map[string]int,
    tool:Player_Tool,
    pos:rl.Vector2,
    reach:f32,
    dir:f32,
    num_vars:map[string]f32
}

player_keys := []rl.KeyboardKey {
	rl.KeyboardKey.SPACE, // SPACE
	rl.KeyboardKey.E, // E/e 
	rl.KeyboardKey.Q  // Q
}

players := make([dynamic]Player)
player_tool_rad:f32 = mth.ceil(0.02 * active_height)
max_brane_count:int = 5
active_player:int = -1
min_reach:f32 = mth.ceil(0.05 * active_height)
max_reach:f32 = mth.floor(active_height * 0.5)
player_dir_delta:f32 = mth.ceil(0.002 * active_height)
player_reach_delta:f32 = mth.ceil(0.005 * active_height)

start :: proc() {
    add_player("System",0,{245,245,245,255}, { -100, -100 })
}

add_player :: proc(name:string, num:int, color:rl.Color, pos:rl.Vector2, status:Player_Status = .Active) -> int {
    p_counts := make(map[string]int)
    p_counts["snip"] = 0
    p_counts["strands"] = 0
    p_counts["proto"] = 0
    p_counts["struck"] = 0
    p_counts["xtra"] = 0
    n_vars := make(map[string]f32)
    n_vars["brane_timer"] = 0

    append(&players, Player{
        status = status,
        num = num,
        name = name,
        color = color,
        brane_count = 0,
        brane_percent = 0,
        counts = p_counts,
        tool = .Pulse,
        pos = pos,
        reach = active_height * 0.25,
        dir = 0,
        num_vars = n_vars
    })
    return len(players) - 1
}

run_players :: proc() {
    for p := 1; p < len(players); p += 1 {
        run_player(&players[p])
    }
}

run_player :: proc(player:^Player) {
    if step %% 3 == 0 {
        if player^.brane_count < max_brane_count {
            player^.brane_percent += 0.005
        }

        if player^.num_vars["brane_timer"] > 0 {
            player^.num_vars["brane_timer"] -= 1
        }
    }

    if player^.brane_percent >= 1 {
        if player^.brane_count < max_brane_count {
            player^.brane_count += 1
        }
        player^.brane_percent = 0
    }
}

run_player_event :: proc(player:^Player, event:Player_Event) {
    switch event {
        case .Activate:
            switch player^.tool {
                case .None:
                case .Brane:

                    if player^.brane_count > 0 && player^.num_vars["brane_timer"] == 0 {
                        br_id := build_id(.Struck)
                        br_key:string = "struck.brane"

                        p_dist := player^.reach
                        p_dir := player^.dir + 270
                        br_pos := player^.pos
                        br_pos.x += p_dist * mth.cos(p_dir * mth.π / 180)
                        br_pos.y += p_dist * mth.sin(p_dir * mth.π / 180)

                        br_vel:rl.Vector2 = { 0, p_dir }

                        append(&entities, Entity{
                            id = br_id,
                            core = &entity_cores[br_key],
                            pos = br_pos,
                            vel = br_vel,
                            dir = rand.float32() * 360,
                            gen = step,
                            age = 1,
                            status = .Active,
                            life = entity_cores[br_key].maxlife,
                            maxlife = entity_cores[br_key].maxlife,
                            decay = entity_cores[br_key].decay,
                            complexity = 0,
                            num_vars = make(map[string]f32),
                            str_vars = make(map[string]string),
                            data = "BRANE",
                            parent = "",
                            owner = player^.num
                        })

                        player^.num_vars["brane_timer"] = 36
                        player^.brane_count -= 1

                    }
    
                case .Pulse:
                    n_vars := make(map[string]f32)
                    n_vars["step"] = 0
                    n_vars["power"] = mth.ceil(active_height * 0.008)

                    p_dist := player^.reach

                    p_dir := player^.dir + 270
                    p_pos := player^.pos
                    p_pos.x += p_dist * mth.cos(p_dir * mth.π / 180)
                    p_pos.y += p_dist * mth.sin(p_dir * mth.π / 180)

                    append(&items, Item{
                        id = strings.concatenate({"p-", int_to_str(player^.num),"-shoot-", int_to_str(step)}),
                        i_type = .Pulse,
                        status = .Active,
                        pos = p_pos,
                        vel = { 0, 0 },
                        num_vars = n_vars,
                        str_vars = make(map[string]string),
                        owner = player^.num
                    })
                case .Grab:
            }
        case .Toggle:
            switch player^.tool {
                case .None:
                    player^.tool = .Brane
                case .Brane:
                    player^.tool = .Pulse
                case .Pulse:
                    player^.tool = .Grab
                case .Grab:
                    player^.tool = .Brane
            }
    }
}

player_update_reach :: proc(player:^Player, dir:f32) {
    players[active_player].reach += dir * player_reach_delta
    if players[active_player].reach < min_reach {
        players[active_player].reach = min_reach
    } else if players[active_player].reach > max_reach {
        players[active_player].reach = max_reach
    }
}

player_update_dir :: proc(player:^Player, dir:f32) {
    min_dir:f32 = -85
    max_dir:f32 = 85
    players[active_player].dir += dir * player_dir_delta
    if players[active_player].dir < min_dir {
        players[active_player].dir = min_dir
    } else if players[active_player].dir > max_dir {
        players[active_player].dir = max_dir
    }
}