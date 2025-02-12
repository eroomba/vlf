package vlf

import "core:fmt"
import "core:unicode/utf8"
import mem "core:mem"
import "core:strings"
import mth "core:math"
import rl "vendor:raylib"
import "core:math/rand"

entity_cores := make(map[string]Entity_Core)

chem_types := []string{"na","a1","a2","b1","b2","g1","g2","d1","d2","u1","u2","x","o1","o2","o3","v"}

// quick function to get index of an array
// based on chem type string
chmi :: proc(t:string) -> int {
    for i := 0; i < len(chem_types); i += 1 {
        if chem_types[i] == t {
            return i;
        }
    }
    return 0;
}

chem_name :: proc(t:string) -> string {
    switch t {
        case "a1":
            return "A-1"
        case "a2":
            return "A-2"
        case "b1":
            return "Bt"
        case "b2":
            return "Bu"
        case "g1":
            return "g90"
        case "g2":
            return "g100"
        case "d1":
            return "D.3"
        case "d2":
            return "D.7"
        case "u1":
            return "U/u"
        case "u2":
            return "U/v"
        case "x":
            return "X"
        case "v":
            return "-V"
        case "o1":
            return "o1"
        case "o2":
            return "o2"
        case "o3":
            return "o3"
    }
    return "N/A";
}

ort_types := []string{"A","B","G","D","P","E","U","I"}

snip_types := []string{"pre","go","block","ex","build"}

strand_types := []string{"D","R","V"}

proto_types := []string{"Simple","Complex"}

struck_types := []string{"brane","knot","husk"}

Entity_Status :: enum {
    None,
    Active,
    Inactive
}

Entity_Type :: enum {
    None,
    Chem,
    Ort,
    Snip,
    Strand,
    Proto,
    Struck
}

Entity_Core :: struct {
    e_type:Entity_Type,
    sub_type:string,
    weight:f32,
    data:string,
    range:f32,
    decay:int,
    maxlife:int
}

Entity :: struct {
    id:string,
    core:^Entity_Core,
    pos:rl.Vector2,
    vel:rl.Vector2,
    gen:int,
    age:int,
    status:Entity_Status,
    life:int,
    maxlife:int,
    decay:int,
    complexity:int,
    num_vars:map[string]f32,
    str_vars:map[string]string,
    data:string,
    parent:string,
    owner:int
}

active_d :: "ABGD"
active_r :: "ABGU"
knot_count:int = 3
brane_count:int = 3

init_cores :: proc() {

    for ort_type in ort_types {
        ort_weight:f32 = 0.1
        ort_key := strings.concatenate({"ort.", ort_type})

        entity_cores[ort_key] = Entity_Core{
            e_type = Entity_Type.Ort,
            sub_type = ort_type,
            weight = ort_weight,
            data = ort_type,
            range = 10,
            decay = 5000,
            maxlife = 100
        }
    }

    for snip_type in snip_types {
        snip_weight:f32 = 0.18
        snip_key := strings.concatenate({"snip.", snip_type})
        snip_decay:int = 10000
        if snip_type == "pre" {
            snip_decay = 1500
        }

        entity_cores[snip_key] = Entity_Core{
            e_type = Entity_Type.Snip,
            sub_type = snip_type,
            weight = snip_weight,
            data = snip_type,
            range = 14,
            decay = snip_decay,
            maxlife = 100
        }
    }

    for strand_type in strand_types {
        strand_weight:f32 = 0.2
        strand_key := strings.concatenate({"strand.", strand_type})

        entity_cores[strand_key] = Entity_Core{
            e_type = Entity_Type.Strand,
            sub_type = strand_type,
            weight = strand_weight,
            data = "",
            range = 16,
            decay = 50000,
            maxlife = 100
        }
    }

    for struck_type in struck_types {
        struck_key := strings.concatenate({"struck.", struck_type})
        struck_weight:f32 = 0.3
        struck_range:f32 = 20
        struck_decay:int = 30000

        switch struck_type {
            case "brane":
                struck_weight = 0.25
                struck_decay = 20000
            case "knot":
                struck_weight = 0.18
            case "husk":
                struck_weight = 0.2
                struck_decay = 90000
        }

        entity_cores[struck_key] = Entity_Core{
            e_type = Entity_Type.Struck,
            sub_type = struck_type,
            weight = struck_weight,
            data = "",
            range = struck_range,
            decay = struck_decay,
            maxlife = 100
        }
    }
}

run_entity :: proc(ent:^Entity) {
    if ent.status == .Active {
        switch ent.core.e_type {
            case .None:
            case .Chem:
            case .Ort:
                run_ort(ent)
            case .Snip:
                run_snip(ent)
            case .Strand:
                run_strand(ent)
            case .Proto:
                run_proto(ent)
            case .Struck:
                run_struck(ent)
        }
    }

    if ent.status == .Active {
        if ent.vel.x == 0 {
            ent^.vel.x = 0.05
        } else if ent.vel.x < 1.5 {
            ent^.vel.y += 2 - (rand.float32() * 5)
        }

        if ent.vel.x != 0 {
            moveLen := ent.vel.x
            dX := moveLen * mth.cos(ent.vel.y * mth.π / 180)
            dY := moveLen * mth.sin(ent.vel.y * mth.π / 180)
            rc := false

            if ent.pos.x + dX < 0 || ent.pos.x + dX > active_width {
                dX *= -1
                rc = true
            }
            if ent.pos.y + dY < 0 || ent.pos.y + dY > active_height {
                dY *= -1
                rc = true
            }

            if rc {
                ent^.vel.y = mth.atan2(dY, dX) * 180 / mth.π
            }

            ent^.pos.x += dX
            ent^.pos.y += dY
            
            dV := ent.core.weight * visc
            if ent.vel.x - dV < 0.001 {
                ent^.vel.x = 0
            } else {
                ent^.vel.x -= dV
            }
        }
    }
}

run_ort :: proc(ort:^Entity) {
    if ort^.status == .Active {
        ort^.decay -= 1
        if (ort^.decay <= 0) {
            ort^.status = .Inactive
            decay_entity(ort)
        } else {
            if ort^.core.sub_type == "E" {
                g_count := haze_query(ort, {"g1","g2"})
                if len(g_count) > 0 && rand.float32() > 0.999 {
                    ort^.status = .Inactive
                    g_count[0]^.nodes[chmi("g1")] -= 1
                    g_count[0]^.nodes[chmi("g2")] -= 1

                    sn_key := "snip.ex"
                    sn_pos := ort.pos
                    sn_vel := ort.vel

                    sn_id:string = build_id(.Snip)
                    append(&entities, Entity{
                        id = sn_id,
                        core = &entity_cores[sn_key],
                        pos = sn_pos,
                        vel = sn_vel,
                        gen = step,
                        age = 1,
                        status = .Active,
                        life = entity_cores[sn_key].maxlife,
                        maxlife = entity_cores[sn_key].maxlife,
                        decay = entity_cores[sn_key].decay,
                        complexity = 0,
                        num_vars = make(map[string]f32),
                        str_vars = make(map[string]string),
                        data = "E--",
                        parent = "",
                        owner = 0
                    })
                }
            }
            else {
                close := hash_find(ort, { .Ort })
                if len(close) >= 2 {
                    if ((strings.contains(active_d,ort^.data) && strings.contains(active_d,close[0]^.data) && strings.contains(active_d,close[1]^.data)) || 
                            (strings.contains(active_r, ort^.data) && strings.contains(active_r,close[0]^.data) && strings.contains(active_r, close[1]^.data))) {
                        sn_pos := ort^.pos
                        sn_vel := ort^.vel
                        sn_data := ort^.data
                        sn_weight := ort^.core.weight
                        for i := 0; i < 2; i += 1 {
                            close[i]^.status = .Inactive
                            sn_pos += close[i]^.pos
                            sn_vel = momentum_add(sn_vel, sn_weight, close[i]^.vel, close[i]^.core.weight)
                            sn_data = strings.concatenate({sn_data, close[i]^.data })
                        }
                        ort^.status = .Inactive

                        sn_key := "snip.go"
                        sn_pos /= 3
                        sn_num_vars := make(map[string]f32)

                        types := check_type(sn_data)

                        if .Build in types {
                            sn_key = "snip.build"
                            sn_num_vars["b_step"] = 0
                        } 

                        sn_id:string = build_id(.Snip)
                        append(&entities, Entity{
                            id = sn_id,
                            core = &entity_cores[sn_key],
                            pos = sn_pos,
                            vel = sn_vel,
                            gen = step,
                            age = 1,
                            status = .Active,
                            life = entity_cores[sn_key].maxlife,
                            maxlife = entity_cores[sn_key].maxlife,
                            decay = entity_cores[sn_key].decay,
                            complexity = 0,
                            num_vars = sn_num_vars,
                            str_vars = make(map[string]string),
                            data = sn_data,
                            parent = "",
                            owner = 0
                        })
                    }
                }
                else if len(close) == 1 && ((strings.contains(active_d, ort^.data) && strings.contains(active_d,close[0]^.data)) || 
                            (strings.contains(active_r,ort^.data) && strings.contains(active_r,close[0]^.data))) { 
                    close[0]^.status = .Inactive
                    ort^.status = .Inactive

                    sn_pos := ort^.pos + close[0]^.pos
                    sn_vel := momentum_add(ort^.vel, ort^.core.weight, close[0]^.vel, close[0]^.core.weight)
                    sn_data := strings.concatenate({ort^.data, close[0]^.data })

                    ort^.status = .Inactive

                    sn_key := "snip.pre"
                    sn_pos /= 2

                    sn_id:string = build_id(.Snip)
                    append(&entities, Entity{
                        id = sn_id,
                        core = &entity_cores[sn_key],
                        pos = sn_pos,
                        vel = sn_vel,
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
                delete(close)
            }
        }
    }
}

run_snip :: proc(snip:^Entity) {
    if snip^.status == .Active {
        snip^.decay -= 1
        if (snip^.decay <= 0) {
            snip^.status = .Inactive
            decay_entity(snip)
        } else { 
            switch snip.core^.sub_type {
                case "pre":
                    close := hash_find(snip, {.Ort })
                    if len(close) > 0 && ((!strings.contains(snip^.data, "U") && strings.contains(active_d,close[0]^.data)) || 
                            (strings.contains(snip^.data, "U") && strings.contains(active_r,close[0]^.data))) {
                        close[0]^.status = .Inactive
                        snip^.status = .Inactive

                        sn_pos := snip^.pos + close[0]^.pos
                        sn_vel := momentum_add(snip^.vel, snip^.core.weight, close[0]^.vel, close[0]^.core.weight)
                        sn_data := strings.concatenate({snip^.data, close[0]^.data })

                        sn_key := "snip.go"
                        sn_pos /= 2
                        sn_num_vars := make(map[string]f32)

                        types := check_type(sn_data)

                        if .Build in types {
                            sn_key = "snip.build"
                            sn_num_vars["b_step"] = 0
                        } 

                        sn_id:string = build_id(.Snip)
                        append(&entities, Entity{
                            id = sn_id,
                            core = &entity_cores[sn_key],
                            pos = sn_pos,
                            vel = sn_vel,
                            gen = step,
                            age = 1,
                            status = .Active,
                            life = entity_cores[sn_key].maxlife,
                            maxlife = entity_cores[sn_key].maxlife,
                            decay = entity_cores[sn_key].decay,
                            complexity = 0,
                            num_vars = sn_num_vars,
                            str_vars = make(map[string]string),
                            data = sn_data,
                            parent = "",
                            owner = 0
                        })
                    }
                    delete(close)
                case "go":

                    close := hash_find(snip, { .Snip })
                    if len(close) > 0 {
                        st_code:string = snip^.data
                        combined:bool = false

                        st_vel := snip^.vel
                        st_weight := snip^.core.weight

                        for sn in close {
                            if sn^.core.sub_type == "go" && ((!strings.contains(st_code,"U") && !strings.contains(sn^.data,"U")) ||
                                (strings.contains(st_code,"U") && strings.contains(sn^.data,"U"))) {
                                    sn^.status = .Inactive
                                    st_code = strings.concatenate({st_code, sn^.data})
                                    st_vel = momentum_add(st_vel, st_weight, sn^.vel, sn^.core.weight)
                                    combined = true
                                }
                        }

                        if combined {
                            snip^.status = .Inactive

                            types := check_type(st_code)
                            st_num_vars := make(map[string]f32)

                            st_key:string = "strand.D"
                            if strings.contains(st_code,"U") {
                                st_key = "strand.R"
                                if .Build in types {
                                    st_num_vars["b_step"] = 0
                                }
                            }
                            st_pos:rl.Vector2 = snip^.pos

                            st_id:string = build_id(.Strand)
                            append(&entities, Entity{
                                id = st_id,
                                core = &entity_cores[st_key],
                                pos = st_pos,
                                vel = st_vel,
                                gen = step,
                                age = 1,
                                status = .Active,
                                life = entity_cores[st_key].maxlife,
                                maxlife = entity_cores[st_key].maxlife,
                                decay = entity_cores[st_key].decay,
                                complexity = 0,
                                num_vars = st_num_vars,
                                str_vars = make(map[string]string),
                                data = st_code,
                                parent = "",
                                owner = 0
                            })
                        }
                    }
                    delete(close)
                case "ex":

                    close := hash_find(snip, { .Snip })
                    ex_b := make([dynamic]^Entity)
                    for sn in close {
                        if sn^.core.sub_type == "ex" && len(ex_b) < knot_count - 1 {
                            append(&ex_b, sn)
                        }
                    }

                    if len(ex_b) == knot_count - 1 {
                        k_pos := snip^.pos
                        k_vel := snip^.vel
                        k_w := snip^.core.weight
                        for sn in ex_b {
                            sn^.status = .Inactive
                            k_pos += sn^.pos
                            k_vel = momentum_add(k_vel, k_w, sn^.vel, sn^.core.weight)
                        }

                        snip^.status = .Inactive
                        k_id := build_id(.Struck)
                        k_pos /= 3
                        k_key:string = "struck.knot"

                        stk_id := build_id(.Struck)
                        append(&entities, Entity{
                            id = k_id,
                            core = &entity_cores[k_key],
                            pos = k_pos,
                            vel = k_vel,
                            gen = step,
                            age = 1,
                            status = .Active,
                            life = entity_cores[k_key].maxlife,
                            maxlife = entity_cores[k_key].maxlife,
                            decay = entity_cores[k_key].decay,
                            complexity = 0,
                            num_vars = make(map[string]f32),
                            str_vars = make(map[string]string),
                            data = "KNOT",
                            parent = "",
                            owner = 0
                        })
                    }

                    delete(ex_b)
                    delete(close)
                case "block":

                    close := hash_find_2(snip^.pos, snip^.core.range * 3, { .Snip })
                    blk_b := make([dynamic]^Entity)
                    blk_b_2 := make([dynamic]^Entity)
                    for sn in close {
                        if snip^.id != sn^.id && sn^.core.sub_type == "block" {
                            append(&blk_b_2, sn)
                            dist := rl.Vector2Distance(snip^.pos, sn^.pos)
                            if dist <= snip^.core.range && len(blk_b) < brane_count - 1 {
                                append(&blk_b, sn)
                            }
                        }
                    }

                    if len(blk_b) == brane_count - 1 {
                        b_pos := snip^.pos
                        b_vel := snip^.vel
                        b_w := snip^.core.weight
                        for sn in blk_b {
                            sn^.status = .Inactive
                            b_pos += sn^.pos
                            b_vel = momentum_add(b_vel, b_w, sn^.vel, sn^.core.weight)
                        }

                        snip^.status = .Inactive
                        b_id := build_id(.Struck)
                        b_pos /= 3
                        b_key:string = "struck.brane"

                        brn_id := build_id(.Struck)
                        append(&entities, Entity{
                            id = brn_id,
                            core = &entity_cores[b_key],
                            pos = b_pos,
                            vel = b_vel,
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
                        })
                    }
                    else if len(blk_b_2) > 0 {
                        t_pos := blk_b_2[0]^.pos
                        t_ang := mth.atan2(t_pos.y - snip^.pos.y, t_pos.x - snip^.pos.x) * 180 / mth.π
                        snip^.vel.y = t_ang
                        dist := rl.Vector2Distance(snip^.pos, t_pos)
                        min_dist := snip^.core.range * 1.5
                        if dist > min_dist && snip^.vel.x < 0.1 {
                            snip^.vel.x = 0.05
                        } else if dist <= snip^.core.range {
                            snip^.vel.y = snip^.vel.y - 180 < 0 ? 180 + snip^.vel.y : snip^.vel.y - 180
                            if snip^.vel.x == 0 {
                                snip^.vel.x = 0.05
                            }
                        } else if dist <= min_dist {
                            if snip^.vel.x > 0 {
                                snip^.vel.x = snip^.vel.x - 0.1 > 0 ? snip^.vel.x - 0.1 : 0 
                            }
                        }
                    }

                    delete(blk_b)
                    delete(blk_b_2)
                    delete(close)
            }
        }
    }

    if snip^.status == .Active && len(snip^.data) >= 3 {
        run_code(snip)
    }
}

run_strand :: proc(strand:^Entity) {
    
    if strand^.status == .Active {
        strand^.decay -= 1
        if strand^.decay <= 0 {
            strand^.status = .Inactive
            decay_entity(strand)
        } else {
            close := hash_find(strand, { .Snip, .Strand })
            combined:bool = false

            st_vel := strand^.vel
            st_weight := strand^.core.weight

            for ent in close {
                if (!strings.contains(strand^.data,"U") && !strings.contains(ent^.data,"U")) ||
                    (strings.contains(strand^.data,"U") && strings.contains(ent^.data,"U")) {
                        if (ent^.core.e_type == .Snip && ent^.core.sub_type == "go") || ent^.core.e_type == .Strand {
                            ent^.status = .Inactive
                            strand^.data = strings.concatenate({strand^.data, ent^.data})
                            st_vel = momentum_add(st_vel, st_weight, ent^.vel, ent^.core.weight)
                            combined = true
                        }
                    }
            }
            delete(close)

            if combined {
                strand^.decay = strand^.core.decay
                types := check_type(strand^.data)
                strand^.vel = st_vel
                if .Build in types && !("b_step" in strand^.num_vars) {
                    strand^.num_vars["b_step"] = 0
                }
            }
        }
    }

    if strand^.status == .Active {
        run_code(strand)
    }
}

run_proto :: proc(proto:^Entity) {
    
}

run_struck :: proc(struck:^Entity) {
    if struck.status == .Active {
        switch struck^.core.sub_type {
            case "brane":
            case "knot":
            case "husk":
        }
    }
}

decay_entity :: proc(ent:^Entity) {
    if ent.status == .Inactive {
        switch ent.core.e_type {
            case .None:
            case .Chem:
            case .Ort:
                decay_ort(ent^.pos, ent^.core.sub_type)
            case .Snip:
                decay_snip(ent^.pos, ent^.core.sub_type, ent^.data)
            case .Strand:
                decay_strand(ent^.pos, ent^.core.sub_type, ent^.data)
            case .Proto:
                //decay_proto(ent)
            case .Struck:
                decay_struck(ent^.pos, ent^.core.sub_type)
        }
    }
}

decay_ort :: proc(pos:rl.Vector2, sub_type:string) {
    switch sub_type {
        case "A":
            // b1, g2
            haze_transact(pos, "b1", 1)
            haze_transact(pos, "g2", 1)
        case "B":
            // g1, d2
            haze_transact(pos, "g1", 1)
            haze_transact(pos, "d2", 1)
        case "G":
            // d1, a2
            haze_transact(pos, "d1", 1)
            haze_transact(pos, "a2", 1)
        case "D":
            // a1, b2
            haze_transact(pos, "a1", 1)
            haze_transact(pos, "b2", 1)
        case "P":
            // u1, o1
            haze_transact(pos, "u1", 1)
            haze_transact(pos, "o2", 1)
        case "E":
            // u2, o2
            haze_transact(pos, "u2", 1)
            haze_transact(pos, "o2", 1)
        case "U":
            // x, o3
            haze_transact(pos, "x", 1)
            haze_transact(pos, "o3", 1)
        case "I":
            // x, o3
            haze_transact(pos, "x", 1)
            haze_transact(pos, "o3", 1)
    }
}

decay_snip :: proc(pos:rl.Vector2, sub_type:string, code:string) {
    if sub_type == "ex" || code == "E--" {
        n_dir:f32 = mth.floor(rand.float32() * 360)
        n_vel:f32 = mth.floor(rand.float32() * 2) + 1
        x_dir:f32 = 12 * mth.cos(n_dir * mth.π / 180)
        y_dir:f32 = 12 * mth.sin(n_dir * mth.π / 180)

        o_id:string = build_id(.Ort)
        o_key:string = strings.concatenate({"ort.P"})
        append(&entities, Entity{
            id = o_id,
            core = &entity_cores[o_key],
            pos = {pos.x + x_dir, pos.y + y_dir},
            vel = {n_vel, n_dir},
            gen = step,
            age = 1,
            status = .Active,
            life = entity_cores[o_key].maxlife,
            maxlife = entity_cores[o_key].maxlife,
            decay = entity_cores[o_key].decay,
            complexity = 0,
            num_vars = make(map[string]f32),
            str_vars = make(map[string]string),
            data = "P",
            parent = "",
            owner = 0
        })
        haze_transact(pos, "x", 2)
    } else {
        code_d:string = code
        dec_ort:string = ""
        if code_d == ":PPP" {
            code_d = "PPP"
        }
        if len(code_d) == 3 {
            dec_ort = code[2:2]
            code_d = code[0:2]
        }

        n_dir:f32 = mth.floor(rand.float32() * 360)
        n_vel:f32 = mth.floor(rand.float32() * 2) + 1
        for c in code_d {
            c_str:string = utf8.runes_to_string([]rune{c})
            x_dir:f32 = 12 * mth.cos(n_dir * mth.π / 180)
            y_dir:f32 = 12 * mth.sin(n_dir * mth.π / 180)

            o_id:string = build_id(.Ort)
            o_key:string = strings.concatenate({"ort.", c_str})
            append(&entities, Entity{
                id = o_id,
                core = &entity_cores[o_key],
                pos = {pos.x + x_dir, pos.y + y_dir},
                vel = {n_vel, n_dir},
                gen = step,
                age = 1,
                status = .Active,
                life = entity_cores[o_key].maxlife,
                maxlife = entity_cores[o_key].maxlife,
                decay = entity_cores[o_key].decay,
                complexity = 0,
                num_vars = make(map[string]f32),
                str_vars = make(map[string]string),
                data = c_str,
                parent = "",
                owner = 0
            })

            n_dir += (360 / f32(len(code)))
            n_dir = f32(int(n_dir) %% 360)
        }

        if len(dec_ort) == 1 {
            decay_ort(pos, dec_ort)
        }
    }
}

decay_strand :: proc(pos:rl.Vector2, sub_type:string, code:string) {
    
}

decay_proto :: proc(strand:^Entity) {
    
}

decay_struck :: proc(pos:rl.Vector2, sub_type:string) {
    
}


build_id :: proc(e_type:Entity_Type) -> string {
    ret_str:string = ""
    
    e_num:string = int_to_str(id_seed)
    id_seed += 1
    for len(e_num) < 10 {
        e_num = strings.concatenate({"0",e_num})
    }

    switch e_type {
        case .None:
            ret_str = "na"
        case .Chem:
            ret_str = "ch"
        case .Ort:
            ret_str = "o"
        case .Snip:
            ret_str = "sn"
        case .Strand:
            ret_str = "st"
        case .Proto:
            ret_str = "p"
        case .Struck:
            ret_str = "sk"
    }

    ret_str = strings.concatenate({ret_str, "-", e_num})

    return ret_str
}

type_name :: proc(e_type:Entity_Type) -> string {
    switch e_type {
        case .None:
            return "None"
        case .Chem:
            return "Chem"
        case .Ort:
            return "Ort"
        case .Snip:
            return "Snip"
        case .Strand:
            return "Strand"
        case .Proto:
            return "Proto"
        case .Struck:
            return "Struct"
    }
    return "Uknown"
}

class_name :: proc(e_type:Entity_Type, sub_type:string) -> string {
    switch e_type {
        case .None:
            return "None"
        case .Chem:
            return chem_name(sub_type)
        case .Ort:
            switch sub_type {
                case "A":
                    return "Alpha"
                case "B":
                    return "Beta"
                case "G":
                    return "Gamma"
                case "D":
                    return "Delta"
                case "P":
                    return "Pylon"
                case "E":
                    return "Endo"
                case "U":
                    return "Upsilon"
                case "I":
                    return "Inert"
            }
            return "Unknown"
        case .Snip:
            switch sub_type {
                case "pre":
                    return "Pre-snip"
                case "go":
                    return "Active"
                case "block":
                    return "Block"
                case "ex":
                    return "Ext"
                case "build":
                    return "Builder"
            }
            return "Unknown"
        case .Strand:
            switch sub_type {
                case "D":
                    return "DNA"
                case "R":
                    return "RNA"
                case "V":
                    return "Viral"
            }
            return "Unknown"
        case .Proto:
            switch sub_type {
                case "C":
                    return "Complex"
                case "S":
                    return "Simple"
            }
            return "Unknown"
        case .Struck:
            switch sub_type {
                case "brane":
                    return "S-brane"
                case "knot":
                    return "Knot"
                case "husk":
                    return "Husk"
            }
            return "Uknown"
    }
    return "Uknown"
}