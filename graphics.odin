package vlf

import "core:fmt"
import "core:strings"
import mth "core:math"
import rl "vendor:raylib"
import "core:strconv"
import "core:math/rand"

Graphics_Params :: struct {
	rect:rl.Rectangle,
	color:rl.Color
}

src_images:[9]rl.Image
textures:[12]rl.Texture2D
font:rl.Font
main_filter:rl.TextureFilter

t_bg_idx := -1
t_env_idx := -1
t_info_idx := -1
t_player_idx := -1
t_ort_idx := -1
t_snip_idx := -1
t_strand_idx := -1
t_proto_idx := -1
t_proto_parts_idx := -1
t_proto_draw_idx := -1
t_struck_idx := -1
t_item_idx := -1
t_tool_idx := -1

i_ort_idx := -1
i_snip_idx := -1
i_strand_idx := -1
i_proto_idx := -1
i_proto_parts_idx := -1
i_struck_idx := -1
i_item_idx := -1

vlf_draw :: proc() {

    rl.DrawTexture(textures[t_bg_idx], i32(-1 * active_width / 2), i32(-1 * active_height / 2), rl.WHITE)

	for &ent in entities {
		if ent.status == .Active {
			draw_entity(&ent)
		}
	}

	if .Shift in set_flags {
		draw_environment()
	}

	if info_item != nil && info_item^.status == .Active && info_item_timer > 0 {
		draw_info()
	}

	for &item in items {
		draw_item(&item)
	}

	draw_player()
}

draw_entity :: proc(ent:^Entity) {
	switch ent^.core.e_type {
		case .None:
		case .Chem:
		case .Ort:
			o_params := item_draw_params(ent)
			if ent^.decay <= 10 {
				o_params.color[3] = u8(f32(o_params.color[3]) * (f32(ent^.decay) / 10))
			}
			ort_thw:f32 = mth.floor(screen_height * 0.013)
			rl.DrawTexturePro(textures[t_ort_idx], o_params.rect, {ent.pos.x, ent.pos.y, ort_thw, ort_thw }, {ort_thw / 2, ort_thw / 2}, ent.vel.y, o_params.color)
		case .Snip:
			sn_params := item_draw_params(ent)
			if ent^.decay <= 10 {
				sn_params.color[3] = u8(f32(sn_params.color[3]) * (f32(ent^.decay) / 10))
			}
			snip_th:f32 = mth.floor(screen_height * 0.015)
			snip_tw:f32 = (sn_params.rect.width / sn_params.rect.height) * snip_th
			rl.DrawTexturePro(textures[t_snip_idx], sn_params.rect, {ent.pos.x, ent.pos.y, snip_tw, snip_th }, {snip_tw / 2, snip_th / 2}, ent.vel.y, sn_params.color)
		case .Strand:
			st_params := item_draw_params(ent)
			if ent^.decay <= 10 {
				st_params.color[3] = u8(f32(st_params.color[3]) * (f32(ent^.decay) / 10))
			}
			strand_th:f32 = mth.floor(screen_height * 0.017)
			strand_tw:f32 = (st_params.rect.width / st_params.rect.height) * strand_th
			rl.DrawTexturePro(textures[t_strand_idx], st_params.rect, {ent.pos.x, ent.pos.y, strand_tw, strand_th }, {strand_tw / 2, strand_th / 2}, ent.vel.y, st_params.color)
		case .Proto:
			pr_params := item_draw_params(ent)
			if ent^.life <= 10 {
				pr_params.color[3] = u8(f32(pr_params.color[3]) * (f32(ent^.life) / 10))
			}
			proto_rot := ent^.dir
			proto_th:f32 = mth.floor(screen_height * 0.032)
			proto_tw:f32 = (pr_params.rect.width / pr_params.rect.height) * proto_th
			proto_origin:rl.Vector2 = {proto_tw / 2, proto_th / 2}

			pr_img:rl.Image = rl.GenImageColor(i32(proto_tw) * 2, i32(proto_th), {255, 255, 255, 0});
			rl.ImageDraw(&pr_img, src_images[i_proto_idx], pr_params.rect, { 0, 0, proto_tw, proto_th}, rl.WHITE)

			pr_types := check_type(ent^.data)

			skin_color:rl.Color = { 255, 255, 255, 255 }
			has_skin:bool = false
			if .Chem in pr_types {
				skin_color = { 100, 255, 100, 255 }
			}
			if .Breathe in pr_types {
				br_rect := pr_params.rect
				br_rect.y = 600
				rl.ImageDraw(&pr_img, src_images[i_proto_idx], br_rect, { 0, 0, proto_tw, proto_th}, skin_color)
				has_skin = true
			}
			
			switch ent^.core.sub_type {
				case "Simple":
					if .Move in pr_types {
						mv_rect := pr_params.rect
						mv_rect.y = 400
						rl.ImageDraw(&pr_img, src_images[i_proto_idx], mv_rect, { 0, 0, proto_tw, proto_th}, skin_color)
						has_skin = true
					}		
				case "Complex":
					proto_rot = ent^.vel.y + 180
					proto_origin.x += proto_tw / 4
					if .Move in pr_types {
						//if step %% 4 == 0 {
							//p_val := ent^.num_vars["t_step"]
							//for ent^.num_vars["t_step"] == p_val {
							//	ent^.num_vars["t_step"] = 100 * mth.floor(rand.float32() * 6)
							//}
						//}
						//tail_off_x:f32 = 0
						//tail_off_y:f32 =  ent^.num_vars["t_step"]
						//rl.ImageDraw(&pr_img, src_images[i_proto_parts_idx], { tail_off_x, tail_off_y, 300, 100}, { proto_tw * 0.89, proto_th * 0.25, proto_tw, proto_th / 2}, skin_color)
						t_color:rl.Color = { 204, 204, 204, 255 }
						t_ow:f32 = f32(proto_tw) * 5
						t_oh:f32 = f32(proto_th / 2) * 4
						t_img := rl.GenImageColor(i32(t_ow), i32(t_oh), { 255, 255, 255, 0 })
						ts_pt:rl.Vector2 = { 0, proto_th * 0.25 } 
						t_pt:rl.Vector2 = { 0, proto_th }
						t_dir:f32 = step %% 2 == 0 ? -1 : 1
						t_max:int = 4
						if .MoveS2 in pr_types {
							t_max = 5
						} else if .MoveS3 in pr_types {
							t_max = 7
						}
						for i in 0..<t_max {
							t_pt2:rl.Vector2 = t_pt
							t_dx:f32 = t_ow * (0.05 + (rand.float32() * 0.05))
							t_pt2.x += t_dx
							if i == 0 {
								t_pt2.y += (t_dir * (rand.float32() * 0.2) * t_oh)
							} else {
								t_pt2.y += (t_dir * (rand.float32() * 0.4) * t_oh)
							}
							t_dir *= -1
							rl.ImageDrawLineEx(&t_img, t_pt, t_pt2, 6, t_color)
							t_pt = t_pt2
						}
						rl.ImageDraw(&pr_img, t_img, { 0, 0, t_ow, t_oh }, { proto_tw * 0.89, proto_th * 0.25, proto_tw, proto_th / 2}, skin_color)
						rl.UnloadImage(t_img)
					}
			}	

			textures[t_proto_draw_idx] = rl.LoadTextureFromImage(pr_img)
			rl.UnloadImage(pr_img)		
			
			rl.GenTextureMipmaps(&textures[t_proto_draw_idx])
			rl.SetTextureFilter(textures[t_proto_draw_idx], main_filter)
			rl.DrawTexturePro(textures[t_proto_draw_idx], { 0, 0, proto_tw * 2, proto_th }, {ent.pos.x, ent.pos.y, proto_tw * 2, proto_th }, proto_origin, proto_rot, pr_params.color)
		case .Struck:
			stk_params := item_draw_params(ent)
			if ent^.decay <= 10 {
				stk_params.color[3] = u8(f32(stk_params.color[3]) * (f32(ent^.decay) / 10))
			}
			stk_rot := ent.dir
			struck_th:f32 = mth.floor(screen_height * 0.028)
			struck_tw:f32 = (stk_params.rect.width / stk_params.rect.height) * struck_th
			rl.DrawTexturePro(textures[t_struck_idx], stk_params.rect, {ent.pos.x, ent.pos.y, struck_tw, struck_th }, {struck_tw / 2, struck_th / 2}, stk_rot, stk_params.color)
	}
}

draw_player :: proc() {
	if active_player >= 0 {

		c_color:rl.Color = { 100, 210, 210, 255 }
		pos_1:rl.Vector2 = players[active_player].pos
		reach := players[active_player].reach
		dir := players[active_player].dir + 270

		t_rad:f32 = player_tool_rad
		t_rad2:f32 = t_rad * 2
		t_pad:f32 = mth.ceil(active_height * 0.01)
		t_pad2:f32 = t_pad * 2
		t_w:f32 = mth.ceil(active_height * 0.01)

		tool_w:f32 = t_rad2 * 2
		tool_h:f32 = (2 * reach) + (t_rad2) + t_pad2
		tool_img := rl.GenImageColor(i32(tool_w), i32(tool_h), { 255, 255, 255, 0 })

		rl.ImageDrawLineEx(&tool_img, {tool_w * 0.5, tool_h}, {tool_w * 0.5, tool_h * 0.5}, i32(t_w * 2), c_color)
		rl.ImageDrawLineEx(&tool_img, {tool_w * 0.5, tool_h * 0.5}, {tool_w * 0.5, t_rad2 * 2 }, i32(t_w), c_color)

		switch players[active_player].tool {
			case .None:

			case .Brane:
				rl.ImageDrawCircleV(&tool_img,{ tool_w * 0.5, t_rad2 }, i32(t_rad2), c_color)
				rl.ImageDrawCircleV(&tool_img,{ tool_w * 0.5, t_rad2 }, i32(t_rad2 - t_w), { 255, 255, 255, 0 })
				rl.ImageDrawRectangleRec(&tool_img, { 0, f32(t_rad2), f32(t_rad2 - (t_w * 0.5)), f32(t_rad2) }, { 255, 255, 255, 0 })
				if players[active_player].brane_count > 0 {
					br_tr:u8 = 100
					br_dec:int = int(players[active_player].num_vars["tool_timer"] * 10)
					if br_dec > 100 {
						br_tr = 0
					} else if br_dec <= 100 {
						br_tr -= u8(br_dec)
					}

					br_rec:rl.Rectangle = { 0, 0, 200, 200 } 
					br_color:rl.Color = { 0, 230, 230, br_tr }

					br_th:f32 = mth.floor(screen_height * 0.028)
					br_tw:f32 = (br_rec.width / br_rec.height) * br_th
					br_tw *= 2
					br_th *= 2
			
					rl.ImageDraw(&tool_img, src_images[i_struck_idx], br_rec, {t_rad2 - (br_tw * 0.5), t_rad2 - (br_th * 0.5), br_tw, br_th}, br_color)
				}
			case .Pulse:
				p_rad:f32 = t_rad2 * 0.25
				rl.ImageDrawLineEx(&tool_img, {tool_w * 0.5, t_rad2 * 2 }, {tool_w * 0.5, t_rad2 }, 6, c_color)
				rl.ImageDrawCircleV(&tool_img,{tool_w * 0.5, t_rad2}, i32(p_rad), c_color)
			case .Grab:
				rl.ImageDrawCircleV(&tool_img,{ tool_w * 0.5, t_rad2 }, i32(t_rad2), c_color)
				rl.ImageDrawRectangleRec(&tool_img, {0, 0, tool_w, t_rad2}, { 255, 255, 255, 0 })
		}

		rl.ImageDrawCircleV(&tool_img,{f32(tool_w * 0.5), f32(tool_h - t_pad2)}, i32(t_rad), c_color)

		textures[t_tool_idx] = rl.LoadTextureFromImage(tool_img)
		rl.UnloadImage(tool_img)
		rl.GenTextureMipmaps(&textures[t_tool_idx])
		rl.SetTextureFilter(textures[t_tool_idx], main_filter)
		rl.DrawTexturePro(textures[t_tool_idx], {0, 0, tool_w, tool_h}, {players[active_player].pos.x, players[active_player].pos.y, tool_w * 0.5, tool_h * 0.5}, {tool_w * 0.25, (tool_h * 0.5) - t_pad}, players[active_player].dir, { 255, 255, 255, 180})

		font_size:i32 = 16
		line_spacing:i32 = 3
		player_text := []string{ "MICRO-TOOL: ", "Status: ", "[E to switch tool, SPACE to activate]" }
		switch players[active_player].tool {
			case .None:
				player_text[0] = strings.concatenate({player_text[0], "n/a"})
				player_text[01] = strings.concatenate({player_text[1], "n/a"})
			case .Brane:
				player_text[0] = strings.concatenate({player_text[0], "Release"})
				if players[active_player].brane_count == 0 {
					player_text[1] = strings.concatenate({player_text[1], "Empty"})
				} else if players[active_player].num_vars["tool_timer"] > 0 {
					player_text[1] = strings.concatenate({player_text[1], "Loading..."})
				} else {
					player_text[1] = strings.concatenate({player_text[1], "Ready"})
				}
			case .Pulse:
				player_text[0] = strings.concatenate({player_text[0], "Pulse"})
				if players[active_player].num_vars["tool_timer"] > 0 {
					player_text[1] = strings.concatenate({player_text[1], "Charging..."})
				} else {
					player_text[1] = strings.concatenate({player_text[1], "Ready"})
				}
			case .Grab:
				player_text[0] = strings.concatenate({player_text[0], "Retrieval"})
				player_text[1] = strings.concatenate({player_text[1], "Not yet implemented"})
				//if players[active_player].num_vars["tool_timer"] > 0 {
				//	player_text[1] = strings.concatenate({player_text[1], "Resetting..."})
				//} else {
				//	player_text[1] = strings.concatenate({player_text[1], "Ready"})
				//}
		}

		text_h:f32 = 0
		text_w:f32 = 0
		for l in 0..<len(player_text) {
			f_size := font_size
			if player_text[l][0] == '[' {
				f_size = i32(f32(font_size) * 0.75)
			}
			text_size := rl.MeasureTextEx(font, strings.clone_to_cstring(player_text[l]), f32(f_size), 0)
			if text_size.x > text_w {
				text_w = f32(text_size.x)
			}
			text_h += f32(f_size)
			text_h += l > 0 ? f32(line_spacing) : 0
		}
		
		padding:f32 = mth.ceil(active_height * 0.01)
		img_w:i32 = i32(20)

		bar_h:i32 = i32(f32(font_size) / 2)
		p_det_w:i32 = i32(padding * 2) + i32(text_w)
		p_det_h:i32 = i32(text_h) + img_w + bar_h + i32(4 * padding)

		p_det := rl.GenImageColor(i32(p_det_w), i32(p_det_h), {255,255,255,0})

		round_r:i32 = 5
		p_det_bg:rl.Color = { 255, 255, 255, 150 }
		rl.ImageDrawCircle(&p_det, round_r, round_r, round_r, p_det_bg)
		rl.ImageDrawCircle(&p_det, p_det_w - round_r, round_r, round_r, p_det_bg)
		rl.ImageDrawCircle(&p_det, p_det_w - round_r, p_det_h - round_r, round_r, p_det_bg)
		rl.ImageDrawCircle(&p_det, round_r, p_det_h - round_r, round_r, p_det_bg)
		rl.ImageDrawRectangle(&p_det, round_r, 0, p_det_w - (2 * round_r), p_det_h,  p_det_bg)
		rl.ImageDrawRectangle(&p_det, 0, round_r, p_det_w, p_det_h - (2 * round_r), p_det_bg)

		curr_y:f32 = padding

		for l in 0..<len(player_text) {
			f_size := font_size
			if player_text[l][0] == '[' {
				f_size = i32(f32(font_size) * 0.75)
			}
			rl.ImageDrawTextEx(&p_det, font, strings.clone_to_cstring(player_text[l]), { padding, curr_y }, f32(f_size), 0, { 30, 30, 30, 255 })
			curr_y += f32(f_size)
			curr_y += l > 0 ? f32(line_spacing) : 0
		}

		curr_y += padding

		img_color:rl.Color = { 0, 230, 230, 255}
		img_ow:f32 = 200
		img_oh:f32 = 200
		img_rec:rl.Rectangle = {0, 0, img_ow, img_oh}
		img_tw:f32 = f32(img_w)
		img_th:f32 = f32(img_w)

		img_x:f32 = f32(padding)
		img_y:f32 = curr_y
		rl.ImageDraw(&p_det, src_images[i_struck_idx], img_rec, { img_x, img_y, img_tw, img_th }, img_color)

		b_txt := strings.concatenate({"S-branes: ", int_to_str(players[active_player].brane_count)})
		b_txt_w := rl.MeasureTextEx(font, strings.clone_to_cstring(b_txt), f32(font_size), 0).x
		b_txt_x:f32 = f32((padding * 2) + f32(img_tw))
		b_txt_y:f32 = f32(curr_y + (img_th * 0.5)) - (f32(font_size) / 2)
		rl.ImageDrawTextEx(&p_det, font, strings.clone_to_cstring(b_txt), { b_txt_x, b_txt_y }, f32(font_size), 0, { 30, 30, 30, 255 })

		curr_y += img_th + padding

		bar_w:i32 = i32(b_txt_w + padding + img_tw)
		bar_x:f32 = f32(padding)
		bar_y:f32 = curr_y
		rl.ImageDrawRectangleLines(&p_det, {bar_x, bar_y, f32(bar_w), f32(bar_h)}, 1, { 120, 120, 120, 200 })
		bar_per:f32 = f32(bar_w) * players[active_player].brane_percent
		rl.ImageDrawRectangleRec(&p_det, {bar_x + 1, bar_y + 1, f32(bar_per - 2), f32(bar_h - 2)}, { 80, 220, 220, 200 })

		textures[t_player_idx] = rl.LoadTextureFromImage(p_det)
		rl.GenTextureMipmaps(&textures[t_player_idx])
		rl.SetTextureFilter(textures[t_player_idx], main_filter)

		p_det_x:f32 = 20
		p_det_y:f32 = active_height - 20 - f32(p_det_h)

		rl.DrawTextureRec(textures[t_player_idx], {0, 0, f32(p_det_w), f32(p_det_h)}, { p_det_x, p_det_y }, { 255, 255, 255, 200})
	}
}

draw_item :: proc(item:^Item) {
	if item^.status == .Active {
		switch item^.i_type {
			case .None:
			case .Pulse:
				step := item^.num_vars["step"]
				p_pos := item^.pos

				p_rad:f32 = player_tool_rad + f32(step * 5)
				//p_alpha := u8(240 * (1 - (step / 5))) 
				p_alpha:u8 = u8(240 - (((8 - u8(step)) / 8) * 200))
				rl.DrawCircleLinesV(p_pos, p_rad, {180, 180, 255, p_alpha})
		}
	}
}

draw_info :: proc() {
	if info_item != nil && info_item^.status == .Active && info_item_timer > 0 {
		info_id := info_item^.id
		info_type := info_item^.core.e_type
		info_sub_type := info_item^.core.sub_type
		info_data := info_item^.data
		info_params := item_draw_params(info_item)

		buf:[64]u8

		font_size:i32 = 16
		text_color:rl.Color = { 30, 30, 30, 200 }

		padding:i32 = 10
		line_spacing:f32 = 5
		line_height:f32 = f32(font_size) + line_spacing

		i_buff:string = ""
		text_height:f32 = f32(padding)
		lines := make([dynamic]string)
		
		disp_id:string = info_id
		append(&lines, strings.concatenate({"Item ID: ", disp_id}))
		text_height += line_height

		append(&lines, strings.concatenate({"Type: ", type_name(info_type)}))
		text_height += line_height

		append(&lines, strings.concatenate({"Class: ", class_name(info_type,info_sub_type)}))
		text_height += line_height

		switch info_type {
			case .None:
			case .Chem:
			case .Ort:
			case .Snip:
				if !(info_sub_type == "ex" || info_sub_type == "block") {
					append(&lines, strings.concatenate({"Code: ", info_data}))
					text_height += line_height
				}
			case .Strand:
				append(&lines, "Code: ")
				text_height += line_height

				code_parts := make([dynamic]string)
				code := info_data
				c_idx:int = 0
				curr_part:string = ""
				for c_idx < len(code) {
					if len(curr_part) == 21 {
						append(&code_parts, curr_part)
						curr_part = ""
					}
					curr_part = strings.concatenate({curr_part, strings.cut(code, c_idx, 1)})
					c_idx += 1
				}
				if len(curr_part) > 0 {
					append(&code_parts, curr_part)
				}

				for c := 0; c < len(code_parts); c += 1 {
					append(&lines, code_parts[c])
					text_height += line_height
				}

				delete(code_parts)
			case .Proto:
			case .Struck:
		}

		img_height:f32 = 80

		info_w:i32 = 200
		info_h:i32 = i32(text_height + img_height) + (2 * padding)
		info_offset:f32 = 20

		info := rl.GenImageColor(info_w, info_h, {255,255,255,0})

		round_r:i32 = 5
		info_bg:rl.Color = { 255, 255, 255, 100 }
		rl.ImageDrawCircle(&info, round_r, round_r, round_r, info_bg)
		rl.ImageDrawCircle(&info, info_w - round_r, round_r, round_r, info_bg)
		rl.ImageDrawCircle(&info, info_w - round_r, info_h - round_r, round_r, info_bg)
		rl.ImageDrawCircle(&info, round_r, info_h - round_r, round_r, info_bg)
		rl.ImageDrawRectangle(&info, round_r, 0, info_w - (2 * round_r), info_h,  info_bg)
		rl.ImageDrawRectangle(&info, 0, round_r, info_w, info_h - (2 * round_r), info_bg)
		switch info_type {
			case .None:
			case .Chem:
			case .Ort:
				info_params.color[3] = 255

				ort_thw:f32 = img_height

				t_x:f32 = (f32(info_w) / 2) - (ort_thw / 2)
				t_y:f32 = f32(padding)
				rl.ImageDraw(&info, src_images[i_ort_idx], info_params.rect, {t_x, t_y, ort_thw, ort_thw}, info_params.color)
			case .Snip:
				info_params.color[3] = 255

				snip_th:f32 = img_height
				snip_tw:f32 = (info_params.rect.width / info_params.rect.height) * snip_th

				t_x:f32 = (f32(info_w) / 2) - (snip_tw / 2)
				t_y:f32 = f32(padding)

				rl.ImageDraw(&info, src_images[i_snip_idx], info_params.rect, {t_x, t_y, snip_tw, snip_th }, info_params.color)
			case .Strand:
				info_params.color[3] = 255

				strand_th:f32 = img_height
				strand_tw:f32 = (info_params.rect.width / info_params.rect.height) * strand_th

				t_x:f32 = (f32(info_w) / 2) - (strand_tw / 2)
				t_y:f32 = f32(padding)

				rl.ImageDraw(&info, src_images[i_strand_idx], info_params.rect, {t_x, t_y, strand_tw, strand_th }, info_params.color)
			case .Proto:
			case .Struck:
				info_params.color[3] = 255

				struck_th:f32 = img_height
				struck_tw:f32 = (info_params.rect.width / info_params.rect.height) * struck_th

				t_x:f32 = (f32(info_w) / 2) - (struck_tw / 2)
				t_y:f32 = f32(padding)

				rl.ImageDraw(&info, src_images[i_struck_idx], info_params.rect, {t_x, t_y, struck_tw, struck_th }, info_params.color)
		}

		y_off:f32 = f32(2 * padding) + img_height

		for i in 0..<len(lines) {
			rl.ImageDrawTextEx(&info, font, strings.clone_to_cstring(lines[i]), { f32(padding), y_off }, f32(font_size), 0, text_color)
			y_off += line_height
		}

		delete(lines)

		textures[t_info_idx] = rl.LoadTextureFromImage(info)
		rl.GenTextureMipmaps(&textures[t_info_idx])
		rl.SetTextureFilter(textures[t_info_idx], main_filter)

		info_a:f32 = 200
		if info_item_timer < 10 && info_item_timer >= 0 {
			info_a = 255 * (f32(info_item_timer) / 10)
		}

		info_x:f32 = active_width - info_offset - f32(info_w)
		info_y:f32 = active_height - info_offset - f32(info_h)

		rl.DrawTextureRec(textures[t_info_idx], {0, 0, f32(info_w), f32(info_h)}, { info_x, info_y }, { 255, 255, 255, u8(info_a)})
	}
}

draw_environment :: proc() {
	buf:[64]u8
	counts := haze_query_2(mouse_pos)

	font_size:i32 = 15

	padding:i32 = 10
	padding_x:i32 = padding
	padding_y:i32 = 3

	off_x:i32 = 50
	off_y:i32 = padding

	hud_w:i32 = 150
	hud_h:i32 = ((font_size + padding_y) * 8) + (2 * padding)
	hud_offset:f32 = 20

	hud := rl.GenImageColor(hud_w, hud_h, {255,255,255,0})

	round_r:i32 = 5
	hud_bg:rl.Color = { 20, 20, 20, 100 }
	rl.ImageDrawCircle(&hud, round_r, round_r, round_r, hud_bg)
	rl.ImageDrawCircle(&hud, hud_w - round_r, round_r, round_r, hud_bg)
	rl.ImageDrawCircle(&hud, hud_w - round_r, hud_h - round_r, round_r, hud_bg)
	rl.ImageDrawCircle(&hud, round_r, hud_h - round_r, round_r, hud_bg)
	rl.ImageDrawRectangle(&hud, round_r, 0, hud_w - (2 * round_r), hud_h,  hud_bg)
	rl.ImageDrawRectangle(&hud, 0, round_r, hud_w, hud_h - (2 * round_r), hud_bg)

	disp:string = ""

	text_color := rl.WHITE

	lines := [][]string{
		{ "a1", "a2" },
		{ "b1", "b2" },
		{ "g1", "g2" },
		{ "d1", "d2" },
		{ "u1", "u2" },
		{ "x", "v" },
		{ "o1", "o2", "o3" }
	}

	disp = "CHEM COUNTS"
	rl.ImageDrawTextEx(&hud, font, strings.clone_to_cstring(disp), { f32(padding), f32(off_y) }, f32(font_size), 0, text_color)
	off_y += font_size + padding_y

	for l1 := 0; l1 < len(lines); l1 += 1 {
		for l2 := 0; l2 < len(lines[l1]); l2 += 1 {
			cl:string = lines[l1][l2]
			disp = strings.concatenate({chem_name(cl), ": ", strconv.itoa(buf[:], counts[cl])})
			rl.ImageDrawTextEx(&hud, font, strings.clone_to_cstring(disp), { f32(padding + (i32(l2) * off_x)), f32(off_y) }, f32(font_size), 0, text_color)
		}
		off_y += font_size + padding_y
	}

	hud_pos:rl.Vector2 = { 0, 0 }

	hud_pos.x = mouse_pos.x - f32(hud_w) - hud_offset
	hud_pos.y = mouse_pos.y - f32(hud_h) - hud_offset

	if hud_pos.x < 0 {
		hud_pos.x = mouse_pos.x + hud_offset
	}

	if hud_pos.y < 0 {
		hud_pos.y = mouse_pos.y + hud_offset
	}

	textures[t_env_idx] = rl.LoadTextureFromImage(hud)
	rl.GenTextureMipmaps(&textures[t_env_idx])
	rl.SetTextureFilter(textures[t_env_idx], main_filter)

	rl.DrawTextureRec(textures[t_env_idx], {0, 0, f32(hud_w), f32(hud_h)}, hud_pos, rl.WHITE)
}

init_graphics :: proc() {

	font = rl.LoadFont("./nina.ttf")
	main_filter = rl.TextureFilter.BILINEAR

	t_idx := 0
	i_idx := 0

    // main background
    bg_c1 := rl.GetColor(0xCCFFFFFF)
	bg_c2 := rl.GetColor(0x33FFFFFF)
	bg_tint := rl.GetColor(0xFFFFFFFF)
	bg_img := rl.GenImageGradientRadial(i32(active_width * 2), i32(active_height * 2), 0.2, bg_c1, bg_c2)
	bg := rl.LoadTextureFromImage(bg_img)
	rl.GenTextureMipmaps(&bg)
	rl.SetTextureFilter(bg, main_filter)
	rl.UnloadImage(bg_img)
	textures[t_idx] = bg
	t_bg_idx = t_idx
	t_idx += 1

	x_img := rl.GenImageColor(200, 200, { 0, 0, 0, 255 })

	env := rl.LoadTextureFromImage(x_img)
	rl.GenTextureMipmaps(&env)
	rl.SetTextureFilter(env, main_filter)
	textures[t_idx] = env
	t_env_idx = t_idx
	t_idx += 1

	info := rl.LoadTextureFromImage(x_img)
	rl.GenTextureMipmaps(&info)
	rl.SetTextureFilter(info, main_filter)
	textures[t_idx] = info
	t_info_idx = t_idx
	t_idx += 1

	player := rl.LoadTextureFromImage(x_img)
	rl.GenTextureMipmaps(&player)
	rl.SetTextureFilter(player, main_filter)
	textures[t_idx] = info
	t_player_idx = t_idx
	t_idx += 1

	proto_draw := rl.LoadTextureFromImage(x_img)
	rl.GenTextureMipmaps(&proto_draw)
	rl.SetTextureFilter(proto_draw, main_filter)
	textures[t_idx] = proto_draw
	t_proto_draw_idx = t_idx
	t_idx += 1

	tool_draw := rl.LoadTextureFromImage(x_img)
	rl.GenTextureMipmaps(&tool_draw)
	rl.SetTextureFilter(tool_draw, main_filter)
	textures[t_idx] = tool_draw
	t_tool_idx = t_idx
	t_idx += 1

	rl.UnloadImage(x_img)

	img_loader:[]u8
	data_size:i32

	img_loader = #load("./images/orts.png")
	data_size = i32(len(img_loader))
	orts_img := rl.LoadImageFromMemory(".png",&img_loader[0],data_size)
	img_loader = []u8{}
	orts := rl.LoadTextureFromImage(orts_img)
	rl.GenTextureMipmaps(&orts)
	rl.SetTextureFilter(orts, main_filter)
	textures[t_idx] = orts
	src_images[i_idx] = orts_img
	t_ort_idx = t_idx
	t_idx += 1
	i_ort_idx = i_idx
	i_idx += 1
	

	img_loader = #load("./images/snips.png")
	data_size = i32(len(img_loader))
	snips_img := rl.LoadImageFromMemory(".png",&img_loader[0],data_size)
	img_loader = []u8{}
	snips := rl.LoadTextureFromImage(snips_img)
	rl.GenTextureMipmaps(&snips)
	rl.SetTextureFilter(snips, main_filter)
	textures[t_idx] = snips
	src_images[i_idx] = snips_img
	t_snip_idx = t_idx
	t_idx += 1
	i_snip_idx = i_idx
	i_idx += 1

	img_loader = #load("./images/strands.png")
	data_size = i32(len(img_loader))
	strands_img := rl.LoadImageFromMemory(".png",&img_loader[0],data_size)
	img_loader = []u8{}
	strands := rl.LoadTextureFromImage(strands_img)
	rl.GenTextureMipmaps(&strands)
	rl.SetTextureFilter(strands, main_filter)
	textures[t_idx] = strands
	src_images[i_idx] = strands_img
	t_strand_idx = t_idx
	t_idx += 1
	i_strand_idx = i_idx
	i_idx += 1

	img_loader = #load("./images/protos.png")
	data_size = i32(len(img_loader))
	protos_img := rl.LoadImageFromMemory(".png",&img_loader[0],data_size)
	img_loader = []u8{}
	protos := rl.LoadTextureFromImage(protos_img)
	rl.GenTextureMipmaps(&protos)
	rl.SetTextureFilter(protos, main_filter)
	textures[t_idx] = protos
	src_images[i_idx] = protos_img
	t_proto_idx = t_idx
	t_idx += 1
	i_proto_idx = i_idx
	i_idx += 1

	img_loader = #load("./images/proto_parts.png")
	data_size = i32(len(img_loader))
	proto_parts_img := rl.LoadImageFromMemory(".png",&img_loader[0],data_size)
	img_loader = []u8{}
	proto_parts := rl.LoadTextureFromImage(proto_parts_img)
	rl.GenTextureMipmaps(&proto_parts)
	rl.SetTextureFilter(proto_parts, main_filter)
	textures[t_idx] = proto_parts
	src_images[i_idx] = proto_parts_img
	t_proto_parts_idx = t_idx
	t_idx += 1
	i_proto_parts_idx = i_idx
	i_idx += 1

	img_loader = #load("./images/strucks.png")
	data_size = i32(len(img_loader))
	strucks_img := rl.LoadImageFromMemory(".png",&img_loader[0],data_size)
	img_loader = []u8{}
	strucks := rl.LoadTextureFromImage(strucks_img)
	rl.GenTextureMipmaps(&strucks)
	rl.SetTextureFilter(strucks, main_filter)
	textures[t_idx] = strucks
	src_images[i_idx] = strucks_img
	t_struck_idx = t_idx
	t_idx += 1
	i_struck_idx = i_idx
	i_idx += 1
}

graphics_end :: proc() {
	for tex in textures {
		rl.UnloadTexture(tex)
	}
	for img in src_images {
		rl.UnloadImage(img)
	}
	//delete(img_cache)
	//delete(tex_cache)
	rl.UnloadFont(font)
}

item_draw_params :: proc(ent:^Entity) -> Graphics_Params {
	ret_rec:rl.Rectangle = { 0, 0, 0, 0 }
	ret_color:rl.Color = { 255, 255, 255, 255 }

	switch ent^.core.e_type {
		case .None:
		case .Chem:
		case .Ort:
			offset_x:f32 = 0
			offset_y:f32 = 0
			o_alpha:u8 = 70
			ret_color = { 102, 102, 102, o_alpha}

			switch ent^.core.sub_type {
				case "A":
					offset_x = 0
					ret_color = { 255, 0, 0, o_alpha}
				case "B":
					offset_x = 100
					ret_color = { 102, 255, 0, o_alpha}
				case "G":
					offset_x = 200
					ret_color = { 255, 255, 0, o_alpha}
				case "D":
					offset_x = 300
					ret_color = { 0, 0, 255, o_alpha}
				case "P":
					offset_x = 400
					ret_color = { 255, 0, 255, o_alpha}
				case "E":
					offset_x = 500
					ret_color = { 0, 255, 255, o_alpha}
				case "U":
					offset_x = 600
					ret_color = { 255, 0, 128, o_alpha}
				case "I":
					offset_x = 700
					ret_color = { 0, 255, 128, o_alpha}
			}

			ort_ohw:f32 = 100

			ret_rec = {offset_x, offset_y, ort_ohw, ort_ohw}
		case .Snip:
			offset_x:f32 = 0
			offset_y:f32 = 0
			sn_alpha:u8 = 90
			ret_color = { 102, 102, 102, sn_alpha}

			switch ent^.core.sub_type {
				case "pre":
					offset_y = 0
					if strings.contains(ent.data,"U") {
						ret_color = { 255, 230, 0, sn_alpha}
					} else {
						ret_color = { 255, 51, 204, sn_alpha}
					}
				case "go":
					offset_y = 100
					if strings.contains(ent.data,"U") {
						ret_color = { 255, 204, 0, sn_alpha}
					} else {
						ret_color = { 102, 0, 204, sn_alpha}
					}
				case "block":
					offset_y = 200
					ret_color = { 0, 153, 255, sn_alpha}
				case "ex":
					offset_y = 300
					ret_color = { 153, 255, 153, sn_alpha}
				case "build":
					offset_y = 400
					if "b_step" in ent^.num_vars {
						offset_y += ent^.num_vars["b_step"] * 100
					}
					ret_color = { 255, 204, 0, sn_alpha}
			}

			snip_ow:f32 = 200
			snip_oh:f32 = 100
			
			ret_rec = {offset_x, offset_y, snip_ow, snip_oh}
		case .Strand:
			offset_x:f32 = 0
			offset_y:f32 = 0
			st_alpha:u8 = 110
			ret_color = { 102, 102, 102, st_alpha}

			switch ent^.core.sub_type {
				case "D":
					offset_y = 0
					ret_color = { 255, 60, 204, st_alpha}
					if len(ent^.data) >= 18 {
						offset_y = 450
					}
				case "R":
					offset_y = 150
					if "b_step" in ent^.num_vars && ent^.num_vars["b_step"] > 0  {
						offset_y = 450 + (ent^.num_vars["b_step"] * 150)
					}
					ret_color = { 255, 204, 0, st_alpha}
			}

			strand_ow:f32 = 300
			strand_oh:f32 = 150
			
			ret_rec = {offset_x, offset_y, strand_ow, strand_oh}
		case .Proto:
			offset_x:f32 = 0
			offset_y:f32 = 0
			pr_alpha:u8 = 160
			ret_color = { 102, 102, 102, pr_alpha}

			switch ent^.core.sub_type {
				case "Simple":
					offset_x = 300
					ret_color = { 80, 255, 80, pr_alpha}
				case "Complex":
					ret_color = { 20, 255, 255, pr_alpha}
			}

			proto_ow:f32 = 300
			proto_oh:f32 = 200
			
			ret_rec = {offset_x, offset_y, proto_ow, proto_oh}
		case .Struck:
			offset_x:f32 = 0
			offset_y:f32 = 0
			stk_alpha:u8 = 100
			ret_color = { 102, 102, 102, stk_alpha}

			switch ent^.core.sub_type {
				case "brane":
					offset_y = 0
					ret_color = { 0, 230, 230, stk_alpha}
				case "knot":
					offset_y = 200
					ret_color = { 100, 240, 100, stk_alpha - 10}
				case "husk":
					offset_y = 400
					ret_color = { 100, 200, 200, stk_alpha}
			}

			struck_ow:f32 = 200
			struck_oh:f32 = 200
			
			ret_rec = {offset_x, offset_y, struck_ow, struck_oh}
	}

	return Graphics_Params{
		rect = ret_rec, 
		color = ret_color
	}
}
