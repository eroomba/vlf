package vlf

import "core:fmt"
import "core:strings"
import "core:strconv"
import mth "core:math"
import rl "vendor:raylib"
import "core:math/rand"

vlf_player_status :: enum {
	ACTIVE,
    INACTIVE
}

vlf_pipet :: struct {
    pos:rl.Vector2,
    rot:f32,
    texture:rl.Texture2D,
    origin:rl.Vector2
}

vlf_player :: struct {
    id:string,
    name:string,
    status:vlf_player_status,
    color:rl.Color,
    pipet:vlf_pipet
}

vlf_init_player :: proc(id:string,name:string,color:rl.Color) -> vlf_player {
    
    n_pipet := vlf_pipet{
        pos = { 0, 0 },
        rot = 0,
        texture = vlf_tex_cache["item.Pipet"],
        origin = { 0, 0 }
    }

    return vlf_player{
        id = id,
        name = name,
        color = color,
        pipet = n_pipet
    }
}

vlf_run_player :: proc(player:^vlf_player) {
    if player.status == .ACTIVE {

    } 
}

vlf_draw_player :: proc(player:^vlf_player) {
    if player.status == .ACTIVE {

    }
}