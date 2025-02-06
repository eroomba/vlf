package vlf

import "core:fmt"
import "core:strings"
import mth "core:math"
import rl "vendor:raylib"
import "core:strconv"

VLF_Graphics_Params :: struct {
	rect:rl.Rectangle,
	color:rl.Color
}

vlf_img_cache := make(map[string]rl.Image)
vlf_tex_cache := make(map[string]rl.Texture2D)
vlf_font:rl.Font

vlf_draw :: proc() {

    rl.DrawTexture(vlf_tex_cache["bg"], i32(-1 * active_width / 2), i32(-1 * active_height / 2), rl.WHITE)

	for e_id in vlf_elements {
		if vlf_elements[e_id].status == .Active {
			vlf_draw_element(&vlf_elements[e_id])
		}
	}

	if .EnvironmentDisplay in vlf_set_flags {
		vlf_draw_environment()
	}
	
	if len(vlf_info_item) > 0 && vlf_info_item in vlf_elements && vlf_info_item_timer > 0 {
		vlf_draw_info()
	}
}

vlf_draw_info :: proc() {
	if len(vlf_info_item) > 0 && vlf_info_item in vlf_elements && vlf_elements[vlf_info_item].status == .Active && vlf_info_item_timer > 0 {
		buf:[64]u8

		font_size:i32 = 16
		text_color:rl.Color = { 30, 30, 30, 200 }

		padding:i32 = 10

		info_w:i32 = 200
		info_h:i32 = 200 + (2 * padding)
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

		switch vlf_elements[vlf_info_item].core.e_type {
			case .None:
			case .Spek:
			case .Ort:
				o_params := vlf_item_draw_params(&vlf_elements[vlf_info_item])
				o_params.color[3] = 255

				ort_thw:f32 = 100

				t_x:f32 = (f32(info_w) / 2) - (ort_thw / 2)
				t_y:f32 = f32(padding)

				rl.ImageDraw(&info, vlf_img_cache["orts"], o_params.rect, {t_x, t_y, ort_thw, ort_thw}, o_params.color)
			case .Snip:
				sn_params := vlf_item_draw_params(&vlf_elements[vlf_info_item])
				sn_params.color[3] = 255

				snip_th:f32 = 100
				snip_tw:f32 = (sn_params.rect.width / sn_params.rect.height) * snip_th

				t_x:f32 = (f32(info_w) / 2) - (snip_tw / 2)
				t_y:f32 = f32(padding)

				rl.ImageDraw(&info, vlf_img_cache["snips"], sn_params.rect, {t_x, t_y, snip_tw, snip_th }, sn_params.color)
			case .Strand:
				st_params := vlf_item_draw_params(&vlf_elements[vlf_info_item])
				st_params.color[3] = 255

				strand_th:f32 = 100
				strand_tw:f32 = (st_params.rect.width / st_params.rect.height) * strand_th

				t_x:f32 = (f32(info_w) / 2) - (strand_tw / 2)
				t_y:f32 = f32(padding)

				rl.ImageDraw(&info, vlf_img_cache["strands"], st_params.rect, {t_x, t_y, strand_tw, strand_th }, st_params.color)
			case .Proto:
			case .Struck:
			case .Xtra:
		}

		i_buff:string = ""
		y_off:f32 = 110
		
		disp_id:string = vlf_elements[vlf_info_item].id
		i_buff = strings.concatenate({"Item ID: ", disp_id})
		rl.ImageDrawTextEx(&info, vlf_font, strings.clone_to_cstring(i_buff), { f32(padding), y_off }, f32(font_size), 0, text_color)

		y_off += f32(font_size) + 3

		i_buff = strings.concatenate({"Type: ", vlf_type_name(vlf_elements[vlf_info_item].core.e_type)})
		rl.ImageDrawTextEx(&info, vlf_font, strings.clone_to_cstring(i_buff), { f32(padding), y_off }, f32(font_size), 0, text_color)

		y_off += f32(font_size) + 3

		i_buff = strings.concatenate({"Class: ", vlf_class_name(vlf_elements[vlf_info_item].core.e_type,vlf_elements[vlf_info_item].core.sub_type)})
		rl.ImageDrawTextEx(&info, vlf_font, strings.clone_to_cstring(i_buff), { f32(padding), y_off }, f32(font_size), 0, text_color)

		y_off += f32(font_size) + 3

		switch vlf_elements[vlf_info_item].core.e_type {
			case .None:
			case .Spek:
			case .Ort:
			case .Snip:
				if !(vlf_elements[vlf_info_item].core.sub_type == "ex" || vlf_elements[vlf_info_item].core.sub_type == "block") {
					i_buff = strings.concatenate({"Code: ", vlf_elements[vlf_info_item].data})
					rl.ImageDrawTextEx(&info, vlf_font, strings.clone_to_cstring(i_buff), { f32(padding), y_off }, f32(font_size), 0, text_color)
					y_off += f32(font_size) + 3
				}
			case .Strand:
				i_buff = "Code: "
				rl.ImageDrawTextEx(&info, vlf_font, strings.clone_to_cstring(i_buff), { f32(padding), y_off }, f32(font_size), 0, text_color)
				y_off += f32(font_size) + 3

				code_parts := make([dynamic]string)
				code := vlf_elements[vlf_info_item].data
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
					i_buff = code_parts[c]
					rl.ImageDrawTextEx(&info, vlf_font, strings.clone_to_cstring(i_buff), { f32(padding), y_off }, f32(font_size), 0, text_color)
					y_off += f32(font_size)
				}

				delete(code_parts)
			case .Proto:
			case .Struck:
			case .Xtra:
		}


		filter := rl.TextureFilter.BILINEAR

		vlf_tex_cache["info"] = rl.LoadTextureFromImage(info)
		rl.GenTextureMipmaps(&vlf_tex_cache["info"])
		rl.SetTextureFilter(vlf_tex_cache["info"], filter)

		info_a:f32 = 200
		if vlf_info_item_timer < 10 && vlf_info_item_timer >= 0 {
			info_a = 255 * (f32(vlf_info_item_timer) / 10)
		}

		info_x:f32 = active_width - info_offset - f32(info_w)
		info_y:f32 = active_height - info_offset - f32(info_h)

		rl.DrawTextureRec(vlf_tex_cache["info"], {0, 0, f32(info_w), f32(info_h)}, { info_x, info_y }, { 255, 255, 255, u8(info_a)})
	}
}

vlf_draw_environment :: proc() {
	buf:[64]u8
	counts := vlf_haze_query_2(vlf_mouse_pos)

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

	disp = "SPEK COUNTS"
	rl.ImageDrawTextEx(&hud, vlf_font, strings.clone_to_cstring(disp), { f32(padding), f32(off_y) }, f32(font_size), 0, text_color)
	off_y += font_size + padding_y

	for l1 := 0; l1 < len(lines); l1 += 1 {
		for l2 := 0; l2 < len(lines[l1]); l2 += 1 {
			cl:string = lines[l1][l2]
			disp = strings.concatenate({cl, ": ", strconv.itoa(buf[:], counts[cl])})
			rl.ImageDrawTextEx(&hud, vlf_font, strings.clone_to_cstring(disp), { f32(padding + (i32(l2) * off_x)), f32(off_y) }, f32(font_size), 0, text_color)
		}
		off_y += font_size + padding_y
	}

	hud_pos:rl.Vector2 = { 0, 0 }

	hud_pos.x = vlf_mouse_pos.x - f32(hud_w) - hud_offset
	hud_pos.y = vlf_mouse_pos.y - f32(hud_h) - hud_offset

	if hud_pos.x < 0 {
		hud_pos.x = vlf_mouse_pos.x + hud_offset
	}

	if hud_pos.y < 0 {
		hud_pos.y = vlf_mouse_pos.y + hud_offset
	}

	filter := rl.TextureFilter.BILINEAR

	vlf_tex_cache["env"] = rl.LoadTextureFromImage(hud)
	rl.GenTextureMipmaps(&vlf_tex_cache["env"])
	rl.SetTextureFilter(vlf_tex_cache["env"], filter)

	rl.DrawTextureRec(vlf_tex_cache["env"], {0, 0, f32(hud_w), f32(hud_h)}, hud_pos, rl.WHITE)
}

vlf_draw_element :: proc(elem:^VLF_Element) {
	switch elem.core.e_type {
		case .None:
		case .Spek:
		case .Ort:
			o_params := vlf_item_draw_params(elem)
			if elem^.decay <= 10 {
				o_params.color[3] = u8(f32(o_params.color[3]) * (f32(elem^.decay) / 10))
			}
			ort_thw:f32 = f32(i32(screen_height * 0.013))
			rl.DrawTexturePro(vlf_tex_cache["orts"], o_params.rect, {elem.pos.x, elem.pos.y, ort_thw, ort_thw }, {ort_thw / 2, ort_thw / 2}, elem.vel.y, o_params.color)
		case .Snip:
			sn_params := vlf_item_draw_params(elem)
			if elem^.decay <= 10 {
				sn_params.color[3] = u8(f32(sn_params.color[3]) * (f32(elem^.decay) / 10))
			}
			snip_th:f32 = f32(i32(screen_height * 0.015))
			snip_tw:f32 = (sn_params.rect.width / sn_params.rect.height) * snip_th
			rl.DrawTexturePro(vlf_tex_cache["snips"], sn_params.rect, {elem.pos.x, elem.pos.y, snip_tw, snip_th }, {snip_tw / 2, snip_th / 2}, elem.vel.y, sn_params.color)
		case .Strand:
			st_params := vlf_item_draw_params(elem)
			if elem^.decay <= 10 {
				st_params.color[3] = u8(f32(st_params.color[3]) * (f32(elem^.decay) / 10))
			}
			strand_th:f32 = f32(i32(screen_height * 0.017))
			strand_tw:f32 = (st_params.rect.width / st_params.rect.height) * strand_th
			rl.DrawTexturePro(vlf_tex_cache["strands"], st_params.rect, {elem.pos.x, elem.pos.y, strand_tw, strand_th }, {strand_tw / 2, strand_th / 2}, elem.vel.y, st_params.color)
		case .Proto:
		case .Struck:
		case .Xtra:
	}
}

vlf_init_graphics :: proc() {

	vlf_font = rl.LoadFont("./nina.ttf")
	filter := rl.TextureFilter.BILINEAR

    // main background
    bg_c1 := rl.GetColor(0xCCFFFFFF)
	bg_c2 := rl.GetColor(0x33FFFFFF)
	bg_tint := rl.GetColor(0xFFFFFFFF)
	bg_img := rl.GenImageGradientRadial(i32(active_width * 2), i32(active_height * 2), 0.2, bg_c1, bg_c2)
	bg := rl.LoadTextureFromImage(bg_img)
	rl.GenTextureMipmaps(&bg)
	rl.SetTextureFilter(bg, filter)
	rl.UnloadImage(bg_img)
	vlf_tex_cache["bg"] = bg

	x_img := rl.GenImageColor(200, 200, { 0, 0, 0, 255 })

	env := rl.LoadTextureFromImage(x_img)
	rl.GenTextureMipmaps(&env)
	rl.SetTextureFilter(env, filter)
	vlf_tex_cache["env"] = env

	info := rl.LoadTextureFromImage(x_img)
	rl.GenTextureMipmaps(&info)
	rl.SetTextureFilter(info, filter)
	vlf_tex_cache["info"] = info

	rl.UnloadImage(x_img)

	orts_img := rl.LoadImage("./images/orts.png")
	orts := rl.LoadTextureFromImage(orts_img)
	rl.GenTextureMipmaps(&orts)
	rl.SetTextureFilter(orts, filter)
	vlf_img_cache["orts"] = orts_img
	vlf_tex_cache["orts"] = orts

	snips_img := rl.LoadImage("./images/snips.png")
	snips := rl.LoadTextureFromImage(snips_img)
	rl.GenTextureMipmaps(&snips)
	rl.SetTextureFilter(snips, filter)
	vlf_img_cache["snips"] = snips_img
	vlf_tex_cache["snips"] = snips

	strands_img := rl.LoadImage("./images/strands.png")
	strands := rl.LoadTextureFromImage(strands_img)
	rl.GenTextureMipmaps(&strands)
	rl.SetTextureFilter(strands, filter)
	vlf_img_cache["strands"] = strands_img
	vlf_tex_cache["strands"] = strands
}

vlf_graphics_end :: proc() {
	for key in vlf_img_cache {
		rl.UnloadImage(vlf_img_cache[key])
	}
	for key in vlf_tex_cache {
		rl.UnloadTexture(vlf_tex_cache[key])
	}
	delete(vlf_img_cache)
	delete(vlf_tex_cache)
	rl.UnloadFont(vlf_font)
}

vlf_item_draw_params :: proc(elem:^VLF_Element) -> VLF_Graphics_Params {
	ret_rec:rl.Rectangle = { 0, 0, 0, 0 }
	ret_color:rl.Color = { 255, 255, 255, 255 }

	switch elem^.core.e_type {
		case .None:
		case .Spek:
		case .Ort:
			offset_x:f32 = 0
			offset_y:f32 = 0
			o_alpha:u8 = 70
			ret_color = { 102, 102, 102, o_alpha}

			switch elem^.core.sub_type {
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

			switch elem^.core.sub_type {
				case "pre":
					offset_y = 0
					ret_color = { 255, 51, 204, sn_alpha}
				case "go":
					offset_y = 100
					if strings.contains(elem.data,"U") {
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
					if "b_step" in elem^.num_vars {
						offset_y += elem^.num_vars["b_step"] * 100
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

			switch elem^.core.sub_type {
				case "D":
					offset_y = 0
					ret_color = { 255, 51, 204, st_alpha}
				case "R":
					offset_y = 150
					ret_color = { 255, 204, 0, st_alpha}
			}

			strand_ow:f32 = 300
			strand_oh:f32 = 150
			
			ret_rec = {offset_x, offset_y, strand_ow, strand_oh}
		case .Proto:
		case .Struck:
		case .Xtra:
	}

	return VLF_Graphics_Params{
		rect = ret_rec, 
		color = ret_color
	}
}
