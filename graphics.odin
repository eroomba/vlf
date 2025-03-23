package vlf

import "core:fmt"
import "core:strings"
import mth "core:math"
import rl "vendor:raylib"
import "core:math/rand"

Graphics_Params :: struct {
	rect:rl.Rectangle,
	color:rl.Color
}

Hover_Params :: struct {
	text:string,
	pos:rl.Vector2,
	active:bool
}

textures:[7]rl.Texture2D
tmp_textures:[5]rl.Texture2D

t_bg_idx:int = -1
t_cover_idx:int = -1
t_base_idx:int = -1
t_block_idx:int = -1
t_strand_idx:int = -1
t_proto_idx:int = -1
t_oth_idx:int = -1

font:rl.Font
default_font_size:i32 = 16
main_filter:rl.TextureFilter
tmp_idx:int = 0

draw_step :: proc() {
	tmp_idx = 0

    rl.DrawTexture(textures[t_bg_idx], i32(view_width * -0.5), i32(view_height * -0.5), rl.WHITE)

    draw_player(&active_player)

	for i in 0..<len(entities) {
		draw_entity(&entities[i])
	}

    if game_state == .Paused {
        f_size := active_height * 0.25
        t_size := rl.MeasureTextEx(font, "PAUSED", f_size, 0)
        rl.DrawTextEx(font, "PAUSED", {(view_width * 0.5) - (t_size.x * 0.5), (view_height * 0.5) - (t_size.y * 0.5)}, f_size, 0, rl.WHITE)
    }
}

draw_player :: proc(p:^Player) {
}

draw_entity :: proc(ent:^Entity) {
	draw_entity_detailed(ent, ent.pos)
}

draw_entity_detailed :: proc(ent:^Entity, pos:rl.Vector2, size:rl.Vector2 = { -1, -1 }) {
	if ent.status != .Inactive {
		bar_dw:f32 = 0
		bar_dw_color:rl.Color = { 255, 255, 255, 255 }

		p_alpha_mult:f32 = 1
		e_pos:rl.Vector2 = { pos.x - view_offset.x, pos.y - view_offset.y }
		bar_dw_pos:rl.Vector2 = { pos.x - view_offset.x, pos.y - view_offset.y }

		switch ent.type {
			case .None:
			case .Base:
				gr_params := item_draw_params(ent.type, ent.sub_type)

				blk_th:f32 = mth.floor(active_height * 0.01)
				blk_tw:f32 = blk_th
				
				blk_origin:rl.Vector2 = { blk_tw * 0.5, blk_th * 0.5 }
				blk_rot:f32 = ent.vel.y

				rl.DrawTexturePro(textures[t_base_idx], gr_params.rect, { pos.x, pos.y, blk_tw, blk_th }, blk_origin, blk_rot, gr_params.color)

			case .Block:
				gr_params := item_draw_params(ent.type, ent.sub_type)

				chn_th:f32 = mth.floor(active_height * 0.011)
				chn_tw:f32 = (gr_params.rect.width / gr_params.rect.height) * chn_th
				
				chn_origin:rl.Vector2 = { chn_tw * 0.5, chn_th * 0.5 }
				chn_rot:f32 = ent.vel.y

				rl.DrawTexturePro(textures[t_block_idx], gr_params.rect, { pos.x, pos.y, chn_tw, chn_th }, chn_origin, chn_rot, gr_params.color)

			case .Strand:
				gr_params := item_draw_params(ent.type, ent.sub_type)

				str_th:f32 = mth.floor(active_height * 0.012)
				str_tw:f32 = (gr_params.rect.width / gr_params.rect.height) * str_th
				
				str_origin:rl.Vector2 = { str_tw * 0.5, str_th * 0.5 }
				str_rot:f32 = ent.vel.y

				rl.DrawTexturePro(textures[t_strand_idx], gr_params.rect, { pos.x, pos.y, str_tw, str_th }, str_origin, str_rot, gr_params.color)

			case .Proto:
				p_subtype := "simple"
				p_params := get_code_params(ent.code)
				if p_params.complex {
					p_subtype = "complex"
				}

				gr_params := item_draw_params(ent.type, p_subtype)

				p_mxw:f32 = 1 //1.3
				p_th:f32 = mth.floor(active_height * 0.03)
				p_tw:f32 = ((gr_params.rect.width * p_mxw) / gr_params.rect.height) * p_th

				p_origin:rl.Vector2 = { p_tw * 0.5, p_th * 0.5 }
				p_rot:f32 = ent.vel.y

				bar_dw = p_tw * 1.5
				bar_color_mult:f32 = 201
				bar_dw_color = { u8((f32(gr_params.color[0])/255) * bar_color_mult), u8((f32(gr_params.color[1])/255) * bar_color_mult), u8((f32(gr_params.color[2])/255) * bar_color_mult), 255 }

				low_life:f32 = 12
				if f32(ent.life) < low_life {
					p_alpha_mult = f32(ent.life) / low_life < 0.05 ? 0.05 : f32(ent.life) / low_life
				}

				p_alpha:rl.Color = { gr_params.color[0], gr_params.color[1], gr_params.color[2], u8(f32(gr_params.color[3]) * p_alpha_mult) }

				p_pos:rl.Vector2 = e_pos
				bar_dw_pos = { e_pos.x, e_pos.y - (p_th * 0.5) }

				rl.DrawTexturePro(textures[t_proto_idx], gr_params.rect, { p_pos.x, p_pos.y, p_tw, p_th }, p_origin, p_rot, p_alpha)

				if p_subtype == "complex" && p_params.speed > 0 {
					t_w:f32 = p_th
					t_h:f32 = p_th * 2
					t_rad:f32 = p_th
					t_alpha:u8 = 180
					t_img := rl.GenImageColor(i32(t_w), i32(t_h * 2), { 255, 255, 255, 0 })
					t_pos:rl.Vector2 = { 0, 0 }
					if ent.params.tail_step >= 5 {
						t_pos.y = t_h
					}
					if ent.status != .Player || (ent.status == .Player && active_player.params.moving) {
						rl.ImageDrawCircleV(&t_img, t_pos, i32(t_rad + 1), bar_dw_color)
						rl.ImageDrawCircleV(&t_img, t_pos, i32(t_rad - 1), { 255, 255, 255, 0 })
						rl.ImageDrawRectangleRec(&t_img, { 0, 0, t_w, t_h * 0.1}, { 255, 255, 255, 0 })
						rl.ImageDrawRectangleRec(&t_img, { 0, t_h - (t_h * 0.1), t_w, t_h * 0.1}, { 255, 255, 255, 0 })
						rl.ImageDrawRectangleRec(&t_img, { t_w * 0.9, 0, t_w * 0.1, t_h }, { 255, 255, 255, 0 })
						rl.ImageBlurGaussian(&t_img, 2)
						t_alpha = 150
					} else {
						rl.ImageDrawCircleV(&t_img, t_pos, i32(t_rad + 3), bar_dw_color)
						rl.ImageDrawCircleV(&t_img, t_pos, i32(t_rad - 3), { 255, 255, 255, 0 })
						rl.ImageDrawRectangleRec(&t_img, { 0, 0, t_w, t_h * 0.1}, { 255, 255, 255, 0 })
						rl.ImageDrawRectangleRec(&t_img, { 0, t_h - (t_h * 0.1), t_w, t_h * 0.1}, { 255, 255, 255, 0 })
						rl.ImageDrawRectangleRec(&t_img, { t_w * 0.9, 0, t_w * 0.1, t_h }, { 255, 255, 255, 0 })
					}

					tmp_textures[tmp_idx] = rl.LoadTextureFromImage(t_img)
					rl.UnloadImage(t_img)
					rl.GenTextureMipmaps(&tmp_textures[tmp_idx])
					rl.SetTextureFilter(tmp_textures[tmp_idx], main_filter)

					td_rot:f32 = ent.params.dir_history[0] - 180
					td_pos:rl.Vector2 = polar_add(p_tw * 0.39, ent.vel.y - 180, p_pos)

					rl.DrawTexturePro(tmp_textures[tmp_idx], { 0, 0, t_w, t_h }, { td_pos.x, td_pos.y, t_w * 0.5, t_h * 0.2 }, { 0, t_h * 0.1 }, td_rot, { 255, 255, 255, u8(f32(t_alpha) * p_alpha_mult)})
					tmp_idx = tmp_idx + 1 > len(tmp_textures) ? 0 : tmp_idx + 1
				}
			case .Other:

		}

		if ent.status == .Player {
			bar_w:f32 = bar_dw
			bar_h:f32 =  0.2 * bar_w
			bar_tw:f32 = bar_w * 0.5
			bar_th:f32 = bar_h * 0.5
			bar_img := rl.GenImageColor(i32(bar_w), i32(bar_h), { 255, 255, 255, 0 })
			bar_color:rl.Color = bar_dw_color
			bar_life := ent.life
			if bar_life > 100 {
				bar_life = 100
				bar_color[0] = 0
				bar_color[1] = 255
				bar_color[2] = 0
			}
			bar_lw:f32 = bar_w * (f32(bar_life) / 100)
			rl.ImageDrawRectangleRec(&bar_img, { 0, 0, bar_lw, bar_h }, bar_color)
			rl.ImageDrawRectangleLines(&bar_img, { 0, 0, bar_w, bar_h }, 2, bar_color)
			//rl.UnloadTexture(textures[t_tmp_idx])
			tmp_textures[tmp_idx] = rl.LoadTextureFromImage(bar_img)
			rl.UnloadImage(bar_img)
			rl.GenTextureMipmaps(&tmp_textures[tmp_idx])
			rl.SetTextureFilter(tmp_textures[tmp_idx], main_filter)
			bar_pos:rl.Vector2 = { e_pos.x, bar_dw_pos.y - (bar_th * 2) }
			bar_alpha:rl.Color = { 255, 255, 255, u8(100 * p_alpha_mult) }
			rl.DrawTexturePro(tmp_textures[tmp_idx], { 0, 0, bar_w, bar_h }, { bar_pos.x, bar_pos.y, bar_tw, bar_th }, { bar_tw * 0.5, bar_th * 0.5 }, 0, bar_alpha)
			tmp_idx = tmp_idx + 1 > len(tmp_textures) ? 0 : tmp_idx + 1 
		}
	}
}

init_graphics :: proc() {

    font = rl.LoadFont("./nina.ttf")
    main_filter = rl.TextureFilter.BILINEAR
    img_loader:[]u8
	data_size:i32

    t_idx:int = 0
    i_idx:int = 0

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

	tmp_img := rl.GenImageColor(10,10,rl.WHITE)

	for i in 0..<5 {
		tmp_textures[i] = rl.LoadTextureFromImage(tmp_img)
	}

	rl.UnloadImage(tmp_img)

	img_loader = #load("./images/bases.png")
	data_size = i32(len(img_loader))
	bases_img := rl.LoadImageFromMemory(".png",&img_loader[0],data_size)
	img_loader = []u8{}
	bases := rl.LoadTextureFromImage(bases_img)
	rl.GenTextureMipmaps(&bases)
	rl.SetTextureFilter(bases, main_filter)
    rl.UnloadImage(bases_img)
	textures[t_idx] = bases
	t_base_idx = t_idx
	t_idx += 1

	img_loader = #load("./images/blocks.png")
	data_size = i32(len(img_loader))
	blocks_img := rl.LoadImageFromMemory(".png",&img_loader[0],data_size)
	img_loader = []u8{}
	blocks := rl.LoadTextureFromImage(blocks_img)
	rl.GenTextureMipmaps(&blocks)
	rl.SetTextureFilter(blocks, main_filter)
    rl.UnloadImage(blocks_img)
	textures[t_idx] = blocks
	t_block_idx = t_idx
	t_idx += 1

	img_loader = #load("./images/strands.png")
	data_size = i32(len(img_loader))
	strands_img := rl.LoadImageFromMemory(".png",&img_loader[0],data_size)
	img_loader = []u8{}
	strands := rl.LoadTextureFromImage(strands_img)
	rl.GenTextureMipmaps(&strands)
	rl.SetTextureFilter(strands, main_filter)
    rl.UnloadImage(strands_img)
	textures[t_idx] = strands
	t_strand_idx = t_idx
	t_idx += 1

    img_loader = #load("./images/protos.png")
	data_size = i32(len(img_loader))
	protos_img := rl.LoadImageFromMemory(".png",&img_loader[0],data_size)
	img_loader = []u8{}
	protos := rl.LoadTextureFromImage(protos_img)
	rl.GenTextureMipmaps(&protos)
	rl.SetTextureFilter(protos, main_filter)
    rl.UnloadImage(protos_img)
	textures[t_idx] = protos
	t_proto_idx = t_idx
	t_idx += 1
	
}

end_graphics :: proc() {
    for i in 0..<len(textures) {
        rl.UnloadTexture(textures[i])
    }

	for i in 0..<len(tmp_textures) {
        rl.UnloadTexture(tmp_textures[i])
    }
}

item_draw_params :: proc(type:Entity_Type, sub_type:string) -> Graphics_Params {
	ret_rec:rl.Rectangle = { 0, 0, 0, 0 }
	ret_color:rl.Color = { 255, 255, 255, 255 }

	switch type {
		case .None:
		case .Base:
			offset_x:f32 = 0
			offset_y:f32 = 0
			blk_alpha:u8 = 70
			ret_color = { 100, 100, 100, blk_alpha }

			switch sub_type {
				case "A":
					ret_color = { 255, 0, 0, blk_alpha }
					offset_x = 0
				case "B":
					ret_color = { 0, 0, 153, blk_alpha }
					offset_x = 100
				case "G":
					ret_color = { 0, 153, 51, blk_alpha }
					offset_x = 200
				case "D":
					ret_color = { 255, 255, 0, blk_alpha }
					offset_x = 300
				case "U":
					ret_color = { 204, 163, 0, blk_alpha }
					offset_x = 400
				case "I":
					ret_color = { 0, 102, 153, blk_alpha }
					offset_x = 500
				case "X":
					ret_color = { 255, 102, 0, blk_alpha }
					offset_x = 600
				case "O":
					ret_color = { 153, 51, 255, blk_alpha }
					offset_x = 700
			}

			block_ow:f32 = 100
			block_oh:f32 = 100
			
			ret_rec = {offset_x, offset_y, block_ow, block_oh}
		case .Block:
			offset_x:f32 = 0
			offset_y:f32 = 0
			chn_alpha:u8 = 85
			ret_color = { 100, 100, 100, chn_alpha }

			switch sub_type {
				case "2":
					ret_color = { 51, 0, 255, chn_alpha }
					offset_y = 0
				case "3":
					ret_color = { 102, 0, 255, chn_alpha }
					offset_y = 100
			}

			chain_ow:f32 = 200
			chain_oh:f32 = 100
			
			ret_rec = {offset_x, offset_y, chain_ow, chain_oh}
		case .Strand:
			offset_x:f32 = 0
			offset_y:f32 = 0
			str_alpha:u8 = 100
			ret_color = { 100, 100, 100, str_alpha }

			switch sub_type {
				case "pre":
					ret_color = { 153, 0, 255, str_alpha }
					offset_y = 0
				case "part":
					ret_color = { 204, 0, 255, str_alpha }
					offset_y = 150
				case "full":
					ret_color = { 255, 0, 255, str_alpha }
					offset_y = 300
			}

			str_ow:f32 = 300
			str_oh:f32 = 150
			
			ret_rec = {offset_x, offset_y, str_ow, str_oh}
		case .Proto:
			offset_x:f32 = 0
			offset_y:f32 = 0
			pr_alpha:u8 = 140
			ret_color = { 0, 191, 255, pr_alpha } //{ 0, 191, 255, pr_alpha }

			switch sub_type {
				case "simple":
					offset_x = 300
				case "complex":
			}

			proto_ow:f32 = 300
			proto_oh:f32 = 200
			
			ret_rec = {offset_x, offset_y, proto_ow, proto_oh}
		case .Other:
	}

	return Graphics_Params{
		rect = ret_rec, 
		color = ret_color
	}
}