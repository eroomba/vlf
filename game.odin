package vlf

import "core:fmt"
import utf8 "core:unicode/utf8"
import mem "core:mem"
import vmem "core:mem/virtual"
import "core:strings"
import "core:strconv"
import mth "core:math"
import rl "vendor:raylib"
import "core:math/rand"

Game_State :: enum {
    Active,
    Paused,
    Stopped,
    Ended
}

game_state:Game_State = .Active
active_player:Player

game_init :: proc() {

    haze_init()

    p_dir:f32 = rand.float32() * 360
    p_idx := entities_add(.Player, .Proto, "player", { active_width * 0.5, active_height * 0.5 }, { 0, p_dir }, p_dir, 1, "ABGD")
    active_player = Player{
        status = .Active,
        entity = p_idx,
        params = Player_Params{
            speed = 0,
            moving = false,
            speed_delta = PLAYER_SPEED_DELTA_BASE,
            dir_delta = PLAYER_DIR_DELTA_BASE
        }
    }
    entities[p_idx].life = 125

    _ = entities_add(.Active, .Proto, "free", { active_width * rand.float32(), active_height * rand.float32() }, { 0, rand.float32() * 360 }, rand.float32() * 360, 0, "ABGD")
    
}

game_state_update :: proc(state:Game_State) {
    if state == .Paused {
        if game_state == .Paused {
            game_state = .Active
        } else {
            game_state = .Paused
        }
    }
}

run_step :: proc() {
    if game_state == .Active {
        step += 1

        run_haze()

        for i in 0..<len(entities) {
            if entities[i].status == .Active || entities[i].status == .Player {
                run_entity(&entities[i])
            }
        }

        run_players()
        
    }
}

run_frame :: proc() {


}
