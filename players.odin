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
    Pulse,
    Drop,
    Grab
}

Player_Tool :: enum {
    None,
    Brane,
    Pulse
}

Player :: struct {
    status:Player_Status,
    num:int,
    name:string,
    color:rl.Color,
    brane_count:int,
    brane_percent:f32,
    counts:map[string]int,
    tool:Player_Ammo,
    pos:rl.Vector2,
    reach:f32,
    dir:f32
}

players := make([dynamic]Player)

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
        reach = active_height / 2 - 10,
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
        player^.brane_percent += 0.1
    }

    if player^.brane_percent >= 1 {
        player^.brane_percent = 0
        player^.brane_count += 1
    }
}

run_player_event :: proc(player:^Player, event:Player_Event) {
    switch event {
        case .Shoot:

            if (player^.ammo == .Brane) {

            } else {
                n_vars := make(map[string]f32)
                dist:f32 = active_height / 2
                dist *= player^.beam_strength
                n_vars["dist"] = dist
                n_vars["step"] = 0
                n_vars["power"] = 5

                p_vel:rl.Vector2 = { 1, player^.dir + 270 }

                append(&items, Item{
                    id = strings.concatenate({"p-", int_to_str(player^.num),"-shoot-", int_to_str(step)}),
                    i_type = .Beam,
                    status = .Active,
                    pos = player^.pos,
                    vel = p_vel,
                    num_vars = n_vars,
                    str_vars = make(map[string]string),
                    owner = player^.num
                })
            }

        case .Suck:
    }
}