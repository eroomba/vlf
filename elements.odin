package vlf

import "core:fmt"
import mem "core:mem"
import "core:strings"
import mth "core:math"
import rl "vendor:raylib"
import "core:math/rand"

vlf_cores := make(map[string]VLF_Element_Core)

// SPEKS
// (OLD: A1, A2, B1, B2, C1, C2, D1, D2, U1, U2, X, G1, G2, G3, V)

vlf_spek_types := []string{"na","a1","a2","b1","b2","g1","g2","d1","d2","u1","u2","x","o1","o2","o3","v"}

// quick function to get index of an array
// based on spek type string
spki :: proc(t:string) -> int {
    for i := 0; i < len(vlf_spek_types); i += 1 {
        if vlf_spek_types[i] == t {
            return i;
        }
    }
    return 0;
}

// ORTS
// (OLD: A, B, C, D, P, E, U, I)
// alpha : a (A)
// beta : b (B)
// gamma : g (C)
// delta : d (D)
// pi : p (P)
// epsilon: e (E)
// upsilon: u (U)
// psi: i (I)

vlf_ort_types := []string{"A","B","G","D","P","E","U","I"}

// SNIP
// (OLD: Pre, Go, Blk, Ex)

vlf_snip_types := []string{"pre","go","block","ex","build"}

// STRAND
// (OLD: D, R, V)

vlf_strand_types := []string{"D","R","V"}

// PROTO
// (OLD: C, S)

vlf_proto_types := []string{"Simple","Complex"}

// STRUCK
// (OLD: Brane, Blip, Seed, Husk)

vlf_struck_types := []string{"brane","seed","husk"}

VLF_ElementStatus :: enum {
    None,
    Active,
    Inactive
}

VLF_Element_Type :: enum {
    None,
    Spek,
    Ort,
    Snip,
    Strand,
    Proto,
    Struck,
    Xtra
}

VLF_Element_Core :: struct {
    e_type:VLF_Element_Type,
    sub_type:string,
    weight:f32,
    data:string,
    range:f32,
    decay:int,
    maxlife:int
}

VLF_Element :: struct {
    id:string,
    core:^VLF_Element_Core,
    pos:rl.Vector2,
    vel:rl.Vector2,
    gen:int,
    age:int,
    status:VLF_ElementStatus,
    life:int,
    maxlife:int,
    decay:int,
    complexity:int,
    num_vars:map[string]f32,
    str_vars:map[string]string,
    data:string,
    parent:string,
    next:^VLF_Element,
    prev:^VLF_Element
}

vlf_active_d :: "ABGD"
vlf_active_r :: "ABGU"

vlf_init_cores :: proc() {

    for ort_type in vlf_ort_types {
        ort_weight:f32 = 0.1
        ort_key := strings.concatenate({"ort.", ort_type})

        vlf_cores[ort_key] = VLF_Element_Core{
            e_type = VLF_Element_Type.Ort,
            sub_type = ort_type,
            weight = ort_weight,
            data = ort_type,
            range = 10,
            decay = 5000,
            maxlife = 100
        }
    }

    for snip_type in vlf_snip_types {
        snip_weight:f32 = 0.2
        snip_key := strings.concatenate({"snip.", snip_type})

        vlf_cores[snip_key] = VLF_Element_Core{
            e_type = VLF_Element_Type.Snip,
            sub_type = snip_type,
            weight = snip_weight,
            data = snip_type,
            range = 14,
            decay = 10000,
            maxlife = 100
        }
    }

    for strand_type in vlf_strand_types {
        strand_weight:f32 = 0.25
        strand_key := strings.concatenate({"strand.", strand_type})

        vlf_cores[strand_key] = VLF_Element_Core{
            e_type = VLF_Element_Type.Strand,
            sub_type = strand_type,
            weight = strand_weight,
            data = "",
            range = 16,
            decay = 50000,
            maxlife = 100
        }
    }
}

vlf_element_run :: proc(elem:^VLF_Element) {
    if elem.status == .Active {
        switch elem.core.e_type {
            case .None:
            case .Spek:
            case .Ort:
                vlf_run_ort(elem)
            case .Snip:
                vlf_run_snip(elem)
            case .Strand:
                vlf_run_strand(elem)
            case .Proto:
                vlf_run_proto(elem)
            case .Struck:
                vlf_run_struck(elem)
            case .Xtra:
                vlf_run_xtra(elem)
        }
    }

    if elem.status == .Active {
        if elem.vel.x == 0 {
            elem^.vel.x = 0.05
        } else if elem.vel.x < 1.5 {
            elem^.vel.y += 2 - (rand.float32() * 5)
        }

        if elem.vel.x != 0 {
            moveLen := elem.vel.x
            dX := moveLen * mth.cos(elem.vel.y * mth.π / 180)
            dY := moveLen * mth.sin(elem.vel.y * mth.π / 180)
            rc := false

            if elem.pos.x + dX < 0 || elem.pos.x + dX > active_width {
                dX *= -1
                rc = true
            }
            if elem.pos.y + dY < 0 || elem.pos.y + dY > active_height {
                dY *= -1
                rc = true
            }

            if rc {
                elem^.vel.y = mth.atan2(dY, dX) * 180 / mth.π
            }

            elem^.pos.x += dX
            elem^.pos.y += dY
            
            dV := elem.core.weight * visc
            if elem.vel.x - dV < 0.001 {
                elem^.vel.x = 0
            } else {
                elem^.vel.x -= dV
            }
        }
    }
}

vlf_element_decay :: proc(elem:^VLF_Element) {
    if elem.status == .Inactive {
        switch elem.core.e_type {
            case .None:
            case .Spek:
            case .Ort:
                vlf_decay_ort(elem)
            case .Snip:
                vlf_decay_snip(elem)
            case .Strand:
                vlf_decay_strand(elem)
            case .Proto:
                vlf_decay_proto(elem)
            case .Struck:
                vlf_decay_struck(elem)
            case .Xtra:
                vlf_decay_xtra(elem)
        }
    }
}

vlf_run_ort :: proc(ort:^VLF_Element) {
    if ort^.status == .Active {
        ort^.decay -= 1
        if (ort^.decay <= 0) {
            ort^.status = .Inactive
            vlf_decay_ort(ort)
        } else {
            if ort^.core.sub_type == "E" {
                g_count := vlf_haze_query(ort, {"g1","g2"})
                if len(g_count) > 0 && rand.float32() > 0.999 {
                    ort^.status = .Inactive
                    g_count[0]^.nodes[spki("g1")] -= 1
                    g_count[0]^.nodes[spki("g2")] -= 1

                    sn_key := "snip.ex"
                    sn_pos := ort.pos
                    sn_vel := ort.vel

                    sn_id:string = vlf_build_id(.Snip)
                    id_seed += 1
                    append(&vlf_elems, VLF_Element{
                        id = sn_id,
                        core = &vlf_cores[sn_key],
                        pos = sn_pos,
                        vel = sn_vel,
                        gen = step,
                        age = 1,
                        status = .Active,
                        life = vlf_cores[sn_key].maxlife,
                        maxlife = vlf_cores[sn_key].maxlife,
                        decay = vlf_cores[sn_key].decay,
                        complexity = 0,
                        num_vars = make(map[string]f32),
                        str_vars = make(map[string]string),
                        data = "E--",
                        parent = "",
                        next = nil,
                        prev = nil
                    })
                }
            }
            else {
                close := vlf_hash_find(ort, { .Ort })
                if len(close) >= 2 {
                    if ((strings.contains(vlf_active_d,ort^.data) && strings.contains(vlf_active_d,close[0]^.data) && strings.contains(vlf_active_d,close[1]^.data)) || 
                            (strings.contains(vlf_active_r, ort^.data) && strings.contains(vlf_active_r,close[0]^.data) && strings.contains(vlf_active_r, close[1]^.data))) {
                        sn_pos := ort^.pos
                        sn_vel := ort^.vel
                        sn_data := ort^.data
                        for i := 0; i < 2; i += 1 {
                            close[i]^.status = .Inactive
                            sn_pos += close[i]^.pos
                            sn_vel += close[i]^.vel
                            sn_data = strings.concatenate({sn_data, close[i]^.data })
                        }
                        ort^.status = .Inactive

                        sn_key := "snip.go"
                        sn_pos /= 3
                        sn_num_vars := make(map[string]f32)

                        types := vlf_check_type(sn_data)

                        if .Build in types {
                            sn_key = "snip.build"
                            sn_num_vars["b_step"] = 0
                        } 

                        sn_id:string = vlf_build_id(.Snip)
                        id_seed += 1
                        append(&vlf_elems, VLF_Element{
                            id = sn_id,
                            core = &vlf_cores[sn_key],
                            pos = sn_pos,
                            vel = sn_vel,
                            gen = step,
                            age = 1,
                            status = .Active,
                            life = vlf_cores[sn_key].maxlife,
                            maxlife = vlf_cores[sn_key].maxlife,
                            decay = vlf_cores[sn_key].decay,
                            complexity = 0,
                            num_vars = sn_num_vars,
                            str_vars = make(map[string]string),
                            data = sn_data,
                            parent = "",
                            next = nil,
                            prev = nil
                        })
                    }
                }
                else if len(close) == 1 && ((strings.contains(vlf_active_d, ort^.data) && strings.contains(vlf_active_d,close[0]^.data)) || 
                            (strings.contains(vlf_active_r,ort^.data) && strings.contains(vlf_active_r,close[0]^.data))) { 
                    close[0]^.status = .Inactive
                    ort^.status = .Inactive

                    sn_pos := ort^.pos + close[0]^.pos
                    sn_vel := ort^.vel + close[0]^.vel
                    sn_data := strings.concatenate({ort^.data, close[0]^.data })

                    ort^.status = .Inactive

                    sn_key := "snip.pre"
                    sn_pos /= 2

                    sn_id:string = vlf_build_id(.Snip)
                    id_seed += 1
                    append(&vlf_elems, VLF_Element{
                        id = sn_id,
                        core = &vlf_cores[sn_key],
                        pos = sn_pos,
                        vel = sn_vel,
                        gen = step,
                        age = 1,
                        status = .Active,
                        life = vlf_cores[sn_key].maxlife,
                        maxlife = vlf_cores[sn_key].maxlife,
                        decay = vlf_cores[sn_key].decay,
                        complexity = 0,
                        num_vars = make(map[string]f32),
                        str_vars = make(map[string]string),
                        data = sn_data,
                        parent = "",
                        next = nil,
                        prev = nil
                    })
                }
                delete(close)
            }
        }
    }
}

vlf_run_snip :: proc(snip:^VLF_Element) {
    if snip^.status == .Active {
        snip^.decay -= 1
        if (snip^.decay <= 0) {
            snip^.status = .Inactive
            vlf_decay_snip(snip)
        } else { 
            switch snip.core^.sub_type {
                case "pre":
                    close := vlf_hash_find(snip, {.Ort })
                    if len(close) > 0 && ((!strings.contains(snip^.data, "U") && strings.contains(vlf_active_d,close[0]^.data)) || 
                            (strings.contains(snip^.data, "U") && strings.contains(vlf_active_r,close[0]^.data))) {
                        close[0]^.status = .Inactive
                        snip^.status = .Inactive

                        sn_pos := snip^.pos + close[0]^.pos
                        sn_vel := snip^.vel + close[0]^.vel
                        sn_data := strings.concatenate({snip^.data, close[0]^.data })

                        sn_key := "snip.go"
                        sn_pos /= 2
                        sn_num_vars := make(map[string]f32)

                        types := vlf_check_type(sn_data)

                        if .Build in types {
                            sn_key = "snip.build"
                            sn_num_vars["b_step"] = 0
                        } 

                        sn_id:string = vlf_build_id(.Snip)
                        append(&vlf_elems, VLF_Element{
                            id = sn_id,
                            core = &vlf_cores[sn_key],
                            pos = sn_pos,
                            vel = sn_vel,
                            gen = step,
                            age = 1,
                            status = .Active,
                            life = vlf_cores[sn_key].maxlife,
                            maxlife = vlf_cores[sn_key].maxlife,
                            decay = vlf_cores[sn_key].decay,
                            complexity = 0,
                            num_vars = sn_num_vars,
                            str_vars = make(map[string]string),
                            data = sn_data,
                            parent = "",
                            next = nil,
                            prev = nil
                        })
                    }
                    delete(close)
                case "go":

                    close := vlf_hash_find(snip, { .Snip })
                    if len(close) > 0 {
                        st_code:string = snip^.data
                        combined:bool = false

                        for sn in close {
                            if sn^.core.sub_type == "go" && ((!strings.contains(st_code,"U") && !strings.contains(sn^.data,"U")) ||
                                (strings.contains(st_code,"U") && strings.contains(sn^.data,"U"))) {
                                    sn^.status = .Inactive
                                    st_code = strings.concatenate({st_code, sn^.data})
                                    combined = true
                                }
                        }

                        if combined {
                            snip^.status = .Inactive

                            st_key:string = "strand.D"
                            if strings.contains(st_code,"U") {
                                st_key = "strand.R"
                            }
                            st_pos:rl.Vector2 = snip^.pos
                            st_vel:rl.Vector2 = snip^.vel

                            st_id:string = vlf_build_id(.Strand)
                            id_seed += 1
                            append(&vlf_elems, VLF_Element{
                                id = st_id,
                                core = &vlf_cores[st_key],
                                pos = st_pos,
                                vel = st_vel,
                                gen = step,
                                age = 1,
                                status = .Active,
                                life = vlf_cores[st_key].maxlife,
                                maxlife = vlf_cores[st_key].maxlife,
                                decay = vlf_cores[st_key].decay,
                                complexity = 0,
                                num_vars = make(map[string]f32),
                                str_vars = make(map[string]string),
                                data = st_code,
                                parent = "",
                                next = nil,
                                prev = nil
                            })
                        }
                    }
                    delete(close)
            }
        }
    }

    if snip^.status == .Active && len(snip^.data) >= 3 {
        vlf_run_code(snip)
    }
}

vlf_run_strand :: proc(strand:^VLF_Element) {
    
    if strand^.status == .Active {
        strand^.decay -= 1
        if strand^.decay <= 0 {
            strand^.status = .Inactive
            vlf_decay_strand(strand)
        } else {
            close := vlf_hash_find(strand, { .Snip, .Strand })
            combined:bool = false

            for elem in close {
                if (!strings.contains(strand^.data,"U") && !strings.contains(elem^.data,"U")) ||
                    (strings.contains(strand^.data,"U") && strings.contains(elem^.data,"U")) {
                        if (elem^.core.e_type == .Snip && elem^.core.sub_type == "go") || elem^.core.e_type == .Strand {
                            elem^.status = .Inactive
                            strand^.data = strings.concatenate({strand^.data, elem^.data})
                            combined = true
                        }
                    }
            }
            delete(close)

            if combined {
                strand^.decay = strand^.core.decay
            }
        }
    }

    if strand^.status == .Active {
        vlf_run_code(strand)
    }
}

vlf_run_proto :: proc(proto:^VLF_Element) {
    
}

vlf_run_struck :: proc(struck:^VLF_Element) {
    
}

vlf_run_xtra :: proc(xtra:^VLF_Element) {
    
}

vlf_decay_ort :: proc(ort:^VLF_Element) {
    if ort^.status == .Inactive {
        switch ort^.core.sub_type {
            case "A":
                // b1, g2
                vlf_haze_transact(ort^.pos, "b1",1)
                vlf_haze_transact(ort^.pos, "g2",1)
            case "B":
                // g1, d2
                vlf_haze_transact(ort^.pos, "g1",1)
                vlf_haze_transact(ort^.pos, "d2",1)
            case "G":
                // d1, a2
                vlf_haze_transact(ort^.pos, "d1",1)
                vlf_haze_transact(ort^.pos, "a2",1)
            case "D":
                // a1, b2
                vlf_haze_transact(ort^.pos, "a1",1)
                vlf_haze_transact(ort^.pos, "b2",1)
            case "P":
                // u1, o1
                vlf_haze_transact(ort^.pos, "u1",1)
                vlf_haze_transact(ort^.pos, "o2",1)
            case "E":
                // u2, o2
                vlf_haze_transact(ort^.pos, "u2",1)
                vlf_haze_transact(ort^.pos, "o2",1)
            case "U":
                // x, o3
                vlf_haze_transact(ort^.pos, "x",1)
                vlf_haze_transact(ort^.pos, "o3",1)
            case "I":
                // x, o3
                vlf_haze_transact(ort^.pos, "x",1)
                vlf_haze_transact(ort^.pos, "o3",1)
        }
    }
}

vlf_decay_snip :: proc(snip:^VLF_Element) {
    
}

vlf_decay_strand :: proc(strand:^VLF_Element) {
    
}

vlf_decay_proto :: proc(strand:^VLF_Element) {
    
}

vlf_decay_struck :: proc(struck:^VLF_Element) {
    
}

vlf_decay_xtra :: proc(xtra:^VLF_Element) {
    
}


vlf_build_id :: proc(e_type:VLF_Element_Type) -> string {
    ret_str:string = ""
    
    e_num:string = int_to_str(id_seed)
    id_seed += 1
    for len(e_num) < 10 {
        e_num = strings.concatenate({"0",e_num})
    }

    switch e_type {
        case .None:
            ret_str = "na"
        case .Spek:
            ret_str = "sp"
        case .Ort:
            ret_str = "o"
        case .Snip:
            ret_str = "sn"
        case .Strand:
            ret_str = "st"
        case .Proto:
            ret_str = "p"
        case .Struck:
            ret_str = "k"
        case .Xtra:
            ret_str = "x"
    }

    ret_str = strings.concatenate({ret_str, "-", e_num})

    return ret_str
}

vlf_type_name :: proc(e_type:VLF_Element_Type) -> string {
    switch e_type {
        case .None:
            return "None"
        case .Spek:
            return "Spek"
        case .Ort:
            return "Ort"
        case .Snip:
            return "Snip"
        case .Strand:
            return "Strand"
        case .Proto:
            return "Proto"
        case .Struck:
            return "Struck"
        case .Xtra:
            return "Extra"
    }
    return "Uknown"
}

vlf_class_name :: proc(e_type:VLF_Element_Type, sub_type:string) -> string {
    switch e_type {
        case .None:
            return "None"
        case .Spek:
            return sub_type
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
                    return "Ent"
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
                    return "Ex"
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
            return "Struck"
        case .Xtra:
            return "Extra"
    }
    return "Uknown"
}