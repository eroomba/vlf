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
    dir:f32
}

player_keys := [3]rune {
	rune(32), // SPACE
	'Q', 
	'E'
}

players := make([dynamic]Player)
player_tool_rad:f32 = 8
max_brane_count:int = 5
active_player:int = -1
player_dir_delta:f32 = 2
player_reach_delta:f32 = 5

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
        reach = active_height / 4,
        dir = 0
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
                case .Pulse:
                    n_vars := make(map[string]f32)
                    n_vars["step"] = 0
                    n_vars["power"] = 5

                    p_dist := player^.reach - player_tool_rad

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
    }
}

player_update_reach :: proc(player:^Player, dir:f32) {
    players[active_player].reach += dir * player_reach_delta
    if players[active_player].reach < 30 {
        players[active_player].reach = 30
    } else if players[active_player].reach > active_height / 2 {
        players[active_player].reach = active_height / 2
    }
}

player_update_dir :: proc(player:^Player, dir:f32) {
    players[active_player].dir += dir * player_dir_delta
    if players[active_player].dir < -85 {
        players[active_player].dir = -85
    } else if players[active_player].dir > 85 {
        players[active_player].dir = 85
    }
}