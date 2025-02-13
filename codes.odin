package vlf

import "core:fmt"
import mem "core:mem"
import "core:strings"
import mth "core:math"
import rl "vendor:raylib"
import "core:math/rand"

Code_Action :: enum {
    Move,
    Breathe,
    Seek,
    Percieve,
    Chem,
    Build,
    MoveS1,
    MoveS2,
    MoveS3
}

Code_Params :: struct {
    act_move:bool,
    act_percieve:bool,
    act_seek:bool,
    act_breathe:bool,
    act_chem:bool,
    act_build:bool,
    move_speed:f32,
    range:f32,
    breath_in:i32,
    breath_out:i32
}

run_code :: proc(ent:^Entity) {
    code:string = ent^.data

    c_params := Code_Params{
        act_move = false,
        act_percieve = false,
        act_seek = false,
        act_breathe = false,
        act_chem = false,
        act_build = false,
        move_speed = 0,
        range = ent^.core.range,
        breath_in = 0,
        breath_out = 1
    }

    c_breath :: []string{ "g1", "g2" }

    if len(code) >= 3 {
        for c:int = 2; c < len(code); c += 1 {
            curr_code:string = code[c-2:c+1]
            switch curr_code {
                case "AAA":
                    c_params.move_speed += 0.2
                case "AAB":
                    c_params.move_speed += 0.4
                case "AAC":
                    c_params.move_speed += 0.6
                case "AAD":
                    c_params.move_speed += 0.8
                case "ABA":
                    c_params.range *= 3
                case "ABB":
                    if ent^.complexity > 0 {
                        c_params.act_seek = true
                    }
                case "ABD":
                    if ent^.complexity > 0 {
                        c_params.act_move = true
                        c_params.move_speed += 0.1
                    }
                case "ACA":
                    c_params.breath_in = 1
                    c_params.breath_out = 0
                case "ACB":
                    if ent^.complexity > 0 {
                        c_params.act_breathe = true
                    }


                case "BBB":

                case "GGG":

                case "DDD":

                case "PPP":

                case "E--":

                case "UUU":
                case "UBA":
                    c_params.act_build = true
                case "UBB":
                    c_params.act_build = true
                case "UBG":
                    c_params.act_build = true
                case "UBU":
                    c_params.act_build = true
                case "UAB":
                    c_params.act_build = true
                case "UGB":
                    c_params.act_build = true
                case "UUB":
                    c_params.act_build = true

                case "III":
            }
        }

        if c_params.act_move {
            if (ent^.vel.x < c_params.move_speed) {
                ent^.vel.x = c_params.move_speed
            }
        }

        if c_params.act_seek {
            
        }

        if c_params.act_percieve {
            
        }

        if c_params.act_breathe {
            
        }

        if c_params.act_chem {
            
        }

        if c_params.act_build {
            if ent^.num_vars["b_step"] < 3 {
                close := hash_find(ent, {.Ort})
                for ort in close {
                    if ort^.core.sub_type == "P" {
                        ort^.status = .Inactive
                        ent^.num_vars["b_step"] += 1
                    }
                }
                delete(close)
            }

            if ent^.num_vars["b_step"] == 3 {
                ent^.num_vars["b_step"] = 0
                sn_key := "snip.block"
                sn_pos:rl.Vector2 = { ent^.pos.x, ent^.pos.y }
                sn_vel_x:f32 = mth.floor(rand.float32() * 2)
                sn_vel_y:f32 = ent^.vel.y - 180
                if sn_vel_y < 0 {
                    sn_vel_y +=360
                }
                sn_data:string = ":PPP"

                sn_id:string = build_id(.Snip)
                append(&entities, Entity{
                    id = sn_id,
                    core = &entity_cores[sn_key],
                    pos = sn_pos,
                    vel = { sn_vel_x, sn_vel_y },
                    dir = 0,
                    gen = step,
                    age = 1,
                    status = .Active,
                    life = entity_cores[sn_key].maxlife,
                    maxlife = entity_cores[sn_key].maxlife,
                    decay = entity_cores[sn_key].decay,
                    complexity = 0,
                    num_vars = make(map[string]f32),
                    str_vars = make(map[string]string),
                    data = sn_data,
                    parent = "",
                    owner = 0
                })
            }
        }

    }
}

check_type :: proc(code:string) -> bit_set[Code_Action] {
    ret_val := bit_set[Code_Action]{}

    if  strings.contains(code,"UBA") ||
        strings.contains(code,"UBB") ||
        strings.contains(code,"UBG") ||
        strings.contains(code,"UBU") ||
        strings.contains(code,"UAB") ||
        strings.contains(code,"UGB") ||
        strings.contains(code,"UUB")
        {
            ret_val += {.Build}
        }

    if strings.contains(code,"ABD") {
        ret_val += {.Move}

        m_speed:f32 = 0.1
        if strings.contains(code,"AAA") {
            m_speed += 0.2
        }
        if strings.contains(code,"AAB") {
            m_speed += 0.4
        }
        if strings.contains(code,"AAC") {
            m_speed += 0.6
        }
        if strings.contains(code,"AAD") {
            m_speed += 0.8
        }

        if m_speed > 1.2 {
            ret_val += {.MoveS3}
        } else if m_speed > 0.6 {
            ret_val += {.MoveS2}
        } else {
            ret_val += {.MoveS1}
        }
    }

    if strings.contains(code,"ACB") {
        ret_val += {.Breathe}
    }

    if strings.contains(code,"ABB") {
        ret_val += {.Seek}
    }

    return ret_val
}