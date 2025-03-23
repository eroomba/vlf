package vlf

import "core:fmt"
import mth "core:math"
import rl "vendor:raylib"
import "core:math/rand"

PLAYER_DIR_DELTA_BASE:f32 : 1
PLAYER_DIR_DELTA_MAX:f32 : 10
PLAYER_SPEED_DELTA_BASE:f32 : 0.1
PLAYER_SPEED_DELTA_MAX:f32 : 10

Player_Status :: enum {
    Active,
    Paused,
    Inactive
}

Player_Params :: struct {
    speed:f32,
    moving:bool,
    speed_delta:f32,
    dir_delta:f32
}

Player :: struct {
    status:Player_Status,
    entity:int,
    params:Player_Params
}

run_players :: proc() {
    run_player(&active_player)
}

run_player :: proc(pl:^Player) {
    p_ent:^Entity = &entities[pl.entity]

    if p_ent.status != .Inactive {

        player_acc:f32 = 0
        acc_change:bool = false
        dir_change:bool = false
        ent_params := get_code_params(p_ent.code)

        if .Left in player_commands {
            p_ent.vel.y -= pl.params.dir_delta
            dir_change = true
        }

        if .Right in player_commands {
            p_ent.vel.y += pl.params.dir_delta
            dir_change = true
        }

        if .Up in player_commands {
            player_acc += pl.params.speed_delta
            acc_change = true
        }

        if .Down in player_commands {
            //player_acc -= player.params.speed_delta * 1.5
            //acc_change = true
        }
        
        if acc_change {
            pl^.params.speed_delta = pl.params.speed + pl.params.speed_delta > PLAYER_SPEED_DELTA_MAX ? PLAYER_SPEED_DELTA_MAX : pl.params.speed + pl.params.speed_delta 
        } else {
            pl^.params.speed_delta = PLAYER_SPEED_DELTA_BASE
        }
        
        if dir_change {
            if step % 4 == 0 {
                pl^.params.dir_delta = pl.params.dir_delta + PLAYER_DIR_DELTA_BASE > PLAYER_DIR_DELTA_MAX ? PLAYER_DIR_DELTA_MAX : pl.params.dir_delta + PLAYER_DIR_DELTA_BASE
            }
        } else {
            pl^.params.dir_delta = PLAYER_DIR_DELTA_BASE
        }

        pl^.params.moving = dir_change || acc_change
        
        if player_acc > 0 {
            p_ent^.vel.x += player_acc
        } 
        
        if p_ent.vel.x == 0 {
            p_ent^.vel.y += 0.1 - (mth.floor(rand.float32() * 2) / 10)
            p_ent^.vel.x = 0.05
        } else {
            p_ent^.vel.x *= 0.98
        }

        if p_ent.vel.x < 0.01 {
            p_ent^.vel.x = 0
        } else if p_ent.vel.x > ent_params.speed {
            p_ent^.vel.x = ent_params.speed
        }

        d_pos := polar_delta_wobble(p_ent.vel.x, p_ent.vel.y)

        recalc:bool = false

        if player_acc == 0 || p_ent.pos.x > active_width {
            if p_ent.pos.x + d_pos.x < 0 || p_ent.pos.x + d_pos.x > active_width {
                d_pos.x *= -1
                recalc = true
            }

            if p_ent.pos.y + d_pos.y < 0 || p_ent.pos.y + d_pos.y > active_height {
                d_pos.y *= -1
                recalc = true
            } 
        }

        if recalc {
            p_ent^.vel.y = mth.atan2(d_pos.y, d_pos.x) * 180 / mth.π
        }

        p_ent^.vel.y = f32(i32(p_ent^.vel.y) % 360)
        if p_ent.vel.y < 0 {
            p_ent.vel.y += 360
        }

        p_ent^.pos.x += d_pos.x
        p_ent^.pos.y += d_pos.y

        if p_ent.pos.x < 0 {
            p_ent^.pos.x = 0
        } else if p_ent.pos.x > active_width {
            p_ent^.pos.x = active_width
        }

        if p_ent.pos.y < 0 {
            p_ent^.pos.y = 0
        } else if p_ent.pos.y > active_height {
            p_ent^.pos.y = active_height
        }

        pl^.params.speed = p_ent.vel.x
    }
}