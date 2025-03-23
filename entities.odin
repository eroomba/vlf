package vlf

import "core:fmt"
import mth "core:math"
import rl "vendor:raylib"
import "core:math/rand"

ENTITY_MAX_SPEED:f32 : 16
ENTITY_DIR_HISTORY:int : 5

Entity_Type :: enum {
    None,
    Base,
    Block,
    Strand,
    Proto,
    Other
}

Entity_Status :: enum {
    Player,
    Active,
    Inactive,
    Paused
}

Entity_Params :: struct {
    step:int,
    tail_step:int,
    dir_history:[ENTITY_DIR_HISTORY]f32
}

Entity :: struct {
    id:int,
    idx:int,
    status:Entity_Status,
    type:Entity_Type,
    sub_type:string,
    age:int,
    pos:rl.Vector2,
    vel:rl.Vector2,
    dir:f32,
    life:int,
    owner:int,
    code:string,
    params:Entity_Params
}

entities := make([dynamic]Entity)

entities_init :: proc() {

}

new_entity_params :: proc() -> Entity_Params {
    return Entity_Params{
        step = 0,
        tail_step = 0,
        dir_history = [ENTITY_DIR_HISTORY]f32{}
    }
}

entities_add :: proc(status:Entity_Status, type:Entity_Type, sub_type:string, pos:rl.Vector2, vel:rl.Vector2, dir:f32, owner:int, code:string = "") -> int {
    add_idx := entity_find_idx()
    if add_idx >= len(entities) {
        add_idx = len(entities)
        append(&entities, Entity{
            id = 1,
            idx = add_idx,
            status = status,
            type = type,
            sub_type = sub_type,
            age = 0,
            pos = pos,
            vel = vel,
            dir = dir,
            life = 100,
            owner = owner,
            code = code,
            params = new_entity_params()
        })
        for i in 0..<ENTITY_DIR_HISTORY {
            entities[add_idx].params.dir_history[i] = vel.y 
        }
        return add_idx
    } else {
        entities[add_idx] = Entity{
            id = 1,
            idx = add_idx,
            status = status,
            type = type,
            sub_type = sub_type,
            age = 0,
            pos = pos,
            vel = vel,
            dir = dir,
            life = 100,
            owner = owner,
            code = code,
            params = new_entity_params()
        }
        for i in 0..<ENTITY_DIR_HISTORY {
            entities[add_idx].params.dir_history[i] = vel.y 
        }
        return add_idx
    }
}

entity_find_idx :: proc() -> int {
    i:int = 0
    for i < len(entities) {
        if entities[i].status == .Inactive {
            return i
        }
        i += 1
    }
    return len(entities)
}

run_entity :: proc(ent:^Entity) {
    if ent.status == .Active || ent.status == .Player {
        ent^.age += 1

        if step % 24 == 0 {
            ent^.life -= 1
        }
    
        if ent.life <= 0 {
            ent^.status = .Inactive
        } else {

            ent_max_speed := ENTITY_MAX_SPEED

            switch ent.type {
                case .None:
                case .Base:
                case .Block:
                case .Strand:
                case .Proto:
                    if ent.status == .Active {
                        pr_params := get_code_params(ent.code)
                        ent_max_speed = pr_params.speed
                        ent.vel.x = pr_params.speed
                    }
                    run_proto(ent)
                case .Other:
            }

            if ent.status != .Player || (ent.status == .Player && active_player.params.moving) {
                for i := 0; i < ENTITY_DIR_HISTORY - 1; i += 1 {
                    ent^.params.dir_history[i] = ent.params.dir_history[i + 1]
                }
                ent^.params.dir_history[ENTITY_DIR_HISTORY-1] = ent.vel.y
            }

            if ent.status == .Active || ent.status == .Player {
                if ent.vel.x < 0.01 {
                    ent^.vel.x = 0
                } else if ent.vel.x > ent_max_speed {
                    ent^.vel.x = ent_max_speed
                } 
            }
           
            if ent.status == .Active {
                d_pos := polar_delta_wobble(ent.vel.x, ent.vel.y)
        
                recalc:bool = false

                if ent.vel.x == 0 {
                    ent^.vel.y += 0.1 - (mth.floor(rand.float32() * 2) / 10)
                    ent^.vel.x = 0.05
                } else {
                    ent^.vel.x *= 0.98
                }
        
                if ent.pos.x + d_pos.x < 0 || ent.pos.x + d_pos.x > active_width {
                    d_pos.x *= -1
                    recalc = true
                }

                if ent.pos.y + d_pos.y < 0 || ent.pos.y + d_pos.y > active_height {
                    d_pos.y *= -1
                    recalc = true
                } 

                if recalc {
                    ent^.vel.y = mth.atan2(d_pos.y, d_pos.x) * 180 / mth.π
                }
        
                ent^.vel.y = f32(i32(ent^.vel.y) % 360)
                if ent.vel.y < 0 {
                    ent.vel.y += 360
                }
        
                ent^.pos.x += d_pos.x
                ent^.pos.y += d_pos.y
        
                if ent.pos.x < 0 {
                    ent^.pos.x = 0
                } else if ent.pos.x > active_width {
                    ent^.pos.x = active_width
                }
        
                if ent.pos.y < 0 {
                    ent^.pos.y = 0
                } else if ent.pos.y > active_height {
                    ent^.pos.y = active_height
                }
        
            }
        }
    }
}

run_base :: proc(base:^Entity) {
    if base.status == .Active {

    }
}

run_block :: proc(block:^Entity) {
    if block.status == .Active {

    }
}

run_chain :: proc(chain:^Entity) {
    if chain.status == .Active {
        
    }
}

run_strand :: proc(strand:^Entity) {
    if strand.status == .Active {
        
    }
}

run_proto :: proc(proto:^Entity) {
    if proto.status != .Player || (proto.status == .Player && active_player.params.moving) {
        proto^.params.tail_step += 1
        if proto.params.tail_step >= 10 {
            proto^.params.tail_step = 0
        }
    }
}