package vlf

import "core:fmt"
import "core:strings"
import "core:strconv"
import mth "core:math"
import rl "vendor:raylib"
import "core:math/rand"

vlf_items := make(map[string]vlf_item)
vlf_objects := make(map[string]vlf_object)
vlf_step:int = 0
vlf_idseed:int = 0

vlf_tex_cache := make(map[string]rl.Texture2D)

vlf_players := make(map[string]vlf_player)

vlf_init :: proc() {

	vlf_build_tex_cache()

	vlf_init_players()

	bases := []string{"A","B","G","D","U","X"}

	for base in bases {
		for i := 0; i <= 360; i += 20 {
			new_id := strings.concatenate({"item", int_to_str(vlf_idseed)})
			new_ang := f32(i + 5 - int((11 * rand.float32())))
			new_r := rand.float32() * active_r
			new_x := active_x + (new_r * mth.cos(new_ang * 3.14159 / 180))
			new_y := active_y + (new_r * mth.sin(new_ang * 3.14159 / 180))
			vlf_idseed += 1
			new_vars := make(map[string]f32)
			new_code := base
			new_item := init_item(new_id, vlf_src.NAT, vlf_kind.BASE, {f32(new_x), f32(new_y)}, {0.1,360 * rand.float32()}, new_vars, code=new_code)
			vlf_items[new_id] = new_item
		}
	}
}

vlf_init_players :: proc() {
	p_id:string = "player1"
	p1 := vlf_init_player(p_id, "Player 1", rl.GetColor(0x00CC00FF))
	vlf_players[p_id] = p1
}

vlf_run :: proc() {

	for player_id in vlf_players {
		vlf_run_player(&vlf_players[player_id])
	}

	for item_if in vlf_items {
		vlf_run_item(&vlf_items[item_id])
	}

	vlf_step += 1
}

vlf_draw :: proc() {
	rl.DrawTexture(vlf_tex_cache["main.bg"], i32(-1 * active_width / 2), i32(-1 * active_height / 2), rl.WHITE)

	for item_id in vlf_items {
		if (vlf_items[item_id].status == .ACTIVE) {
			vlf_draw_item(&vlf_items[item_id])
		}
	}

	p_key := "item.Pipet"
	pW := f32(vlf_tex_cache[p_key].width)
	pH := f32(vlf_tex_cache[p_key].height)
	pdW:f32 = 25
	pRatio := pdW / pW
	ptW := pW * pRatio
	ptH := pH
	pX := vlf_objects["pipet"].pos.x
	pY := vlf_objects["pipet"].pos.y + (ptH * 0.98)
	pR := vlf_objects["pipet"].vel.y
	
	rl.DrawTexturePro(vlf_tex_cache[p_key], { 0, 0, pW, pH }, { pX, pY, ptW, ptH}, {(ptW / 2), (ptH * 0.98)}, 0, rl.WHITE)

	rl.DrawTexturePro(vlf_tex_cache["overlay.main"], { 0, 0, screen_width * 2, screen_height * 2 }, { 0, 0, screen_width, screen_height}, {0, 0}, 0, rl.WHITE)
}

vlf_run_item :: proc(item:^vlf_item) {

	if item.status == .ACTIVE {

		vlf_run_codes(item)

		vlf_move_item(item)

	}
}

vlf_move_item :: proc(item:^vlf_item) {

	if item.vel.x == 0 {
		item^.vel.x = item.weight * 0.01
		//item^.vel.y = 360 * rand.float32()
	} else {
		item^.vel.y += f32(1 - int(3 * rand.float32()))
	}

	if item.vel.y > 360 {
		item^.vel.y -= 360
	} else if item.vel.y < 0 {
		item^.vel.y += 360
	}

	if item.vel.x != 0 {
		moveLen := item.vel.x
		dX := moveLen * mth.cos(item.vel.y * 3.14159 / 180)
		dY := moveLen * mth.sin(item.vel.y * 3.14159 / 180)
		rc := false

		c_dist:f32 = rl.Vector2Distance({ item.pos.x + dX, item.pos.y + dY }, active_c)
		c_ang:f32 = mth.atan2(item.pos.y - active_y, item.pos.x - active_x) * 180 / 3.14159
		c_ang -= 180
		if c_ang > 360 {
			c_ang -= 360
		} else if c_ang < 0 {
			c_ang += 360
		}

		if c_dist > active_r {
			item.vel.y = c_ang
			dX = moveLen * mth.cos(item.vel.y * 3.14159 / 180)
			dY = moveLen * mth.sin(item.vel.y * 3.14159 / 180)
		}

		item^.pos.x += dX
		item^.pos.y += dY
	}

	item^.vel.x *= 1 / item.weight
	if item.vel.x < 0.01 {
		item^.vel.x = 0
	}
}

vlf_draw_item :: proc(item:^vlf_item) {
	i_tint := rl.GetColor(0xFFFFFFFF)
	rot:f32 = 0
	scl:f32 = 0.5

	switch item.kind {
		case .EMPTY:
		case .BASE:
			rot = item.vel.y 
			if (item.code == "G") {
				rot -= 45
			}
			base_key := strings.concatenate({"base.",item.code})
			txW:f32 = f32(vlf_tex_cache[base_key].width)
			txH:f32 = f32(vlf_tex_cache[base_key].height)
			tW:f32 = 9
			tH:f32 = 9
			tX:f32 = item.pos.x //- (tW / 4)
			tY:f32 = item.pos.y //- (tH / 4)
			rl.DrawTexturePro(vlf_tex_cache[base_key], { 0, 0, txW, txH }, { tX, tY, tW, tH }, {tW/2, tH/2}, rot, {255,255,255,150})
		case .CODE:
		case .STRAND:
		case .PROTO:
			proto_key := strings.concatenate({"proto.",vlf_src_name(item.src)})
			rot = item.vel.y 
			txW:f32 = f32(vlf_tex_cache[proto_key].width)
			txH:f32 = f32(vlf_tex_cache[proto_key].height)
			dW:f32 = 51
			oW:f32 = 300
			reduce:f32 = dW / oW
			tW:f32 = txW * reduce
			tH:f32 = txH * reduce
			tX:f32 = item.pos.x
			tY:f32 = item.pos.y
			rl.DrawTexturePro(vlf_tex_cache[proto_key], { 0, 0, txW, txH }, { tX, tY, tW, tH}, {tW/2, tH/2}, rot, {255,255,255,200})
		case .HUSK:
			husk_key := strings.concatenate({"husk.",vlf_src_name(item.src)})
			rot = item.vel.y 
			txW:f32 = f32(vlf_tex_cache[husk_key].width)
			txH:f32 = f32(vlf_tex_cache[husk_key].height)
			tW:f32 = 17
			tH:f32 = 17
			tX:f32 = item.pos.x
			tY:f32 = item.pos.y
			rl.DrawTexturePro(vlf_tex_cache[husk_key], { 0, 0, txW, txH }, { tX, tY, tW, tH}, {tW/2, tH/2}, rot, {255,255,255,180})
		case .EXTRA:
	}


}

vlf_build_tex_cache :: proc() {

	bg_c1 := rl.GetColor(0xCCFFFFFF)
	bg_c2 := rl.GetColor(0x33FFFFFF)
	bg_tint := rl.GetColor(0xFFFFFFFF)
	bg_img := rl.GenImageGradientRadial(i32(active_width * 2), i32(active_height * 2), 0.2, bg_c1, bg_c2)
	bg := rl.LoadTextureFromImage(bg_img)
	rl.UnloadImage(bg_img)
	vlf_tex_cache["main.bg"] = bg

	cover_img := rl.GenImageColor(i32(screen_width * 2), i32(screen_height * 2), rl.BLACK)
	rl.ImageDrawCircleV(&cover_img, {active_x * 2,active_y * 2}, i32((active_r + 8) * 2), {220, 220, 220, 255})
	rl.ImageDrawCircleV(&cover_img, {active_x * 2,active_y * 2}, i32((active_r + 2) * 2), {240, 240, 240, 255})
	rl.ImageDrawCircleV(&cover_img, {active_x * 2,active_y * 2}, i32((active_r - 1) * 2), rl.BLANK)
	cover := rl.LoadTextureFromImage(cover_img)
	rl.GenTextureMipmaps(&cover);
	rl.SetTextureFilter(cover, rl.TextureFilter.BILINEAR); 
	rl.UnloadImage(cover_img)
	vlf_tex_cache["overlay.main"] = cover

	c_img:rl.Image
	c_txt:rl.Texture2D
	filter := rl.TextureFilter.BILINEAR
	line_width:i32 = 2
	t1:u8 = 200

	c_img = rl.GenImageColor(i32(screen_width), i32(screen_height), rl.BLANK)
	rl.ImageDrawRectangle(&c_img, 0, i32(screen_height - 200), 300, 200, { 100, 100, 100, 200 })
	rl.ImageDrawRectangle(&c_img, i32(screen_width - 300), i32(screen_height - 200), 300, 200, { 100, 100, 100, 200 })
	c_txt = rl.LoadTextureFromImage(c_img)
	rl.GenTextureMipmaps(&c_txt)
	rl.SetTextureFilter(c_txt, filter)
	vlf_tex_cache["overlay.panels"] = c_txt
	rl.UnloadImage(c_img)

	// ITEMS

	c_txt = rl.LoadTexture("./images/items/pipet.png")
	rl.GenTextureMipmaps(&c_txt)
	rl.SetTextureFilter(c_txt, filter)
	vlf_tex_cache["item.Pipet"] = c_txt


	// BASES

	base_c1:rl.Color = { 200, 200, 200, t1 }

	// A base
	c_txt = rl.LoadTexture("./images/base/A.png")
	rl.GenTextureMipmaps(&c_txt)
	rl.SetTextureFilter(c_txt, filter)
	vlf_tex_cache["base.Animal"] = c_txt

	// B base
	c_txt = rl.LoadTexture("./images/base/B.png")
	rl.GenTextureMipmaps(&c_txt)
	rl.SetTextureFilter(c_txt, filter)
	vlf_tex_cache["base.B"] = c_txt

	// G base
	c_txt = rl.LoadTexture("./images/base/G.png")
	rl.GenTextureMipmaps(&c_txt)
	rl.SetTextureFilter(c_txt, filter)
	vlf_tex_cache["base.G"] = c_txt

	// D base
	c_txt = rl.LoadTexture("./images/base/D.png")
	rl.GenTextureMipmaps(&c_txt)
	rl.SetTextureFilter(c_txt, filter)
	vlf_tex_cache["base.D"] = c_txt
	
	// U base
	c_txt = rl.LoadTexture("./images/base/U.png")
	rl.GenTextureMipmaps(&c_txt)
	rl.SetTextureFilter(c_txt, filter)
	vlf_tex_cache["base.U"] = c_txt

	// X base
	c_txt = rl.LoadTexture("./images/base/X.png")
	rl.GenTextureMipmaps(&c_txt)
	rl.SetTextureFilter(c_txt, filter)
	vlf_tex_cache["base.X"] = c_txt


	// HUSKS

	h_ln_w:i32 = 6
	h_ln_op:u8 = 100
	h_cn_op:u8 = 100

	// Animal Husk
	c_txt = rl.LoadTexture("./images/husk/ANM.png")
	rl.GenTextureMipmaps(&c_txt)
	rl.SetTextureFilter(c_txt, filter)
	vlf_tex_cache["husk.Animal"] = c_txt

	// Vegetable Husk
	c_txt = rl.LoadTexture("./images/husk/VGT.png")
	rl.GenTextureMipmaps(&c_txt)
	rl.SetTextureFilter(c_txt, filter)
	vlf_tex_cache["husk.Vegetable"] = c_txt

	// Synthetic Husk
	c_txt = rl.LoadTexture("./images/husk/SYN.png")
	rl.GenTextureMipmaps(&c_txt)
	rl.SetTextureFilter(c_txt, filter)
	vlf_tex_cache["husk.Synthetic"] = c_txt


	// PROTOS

	p_ln_w:i32 = 6
	p_ln_op:u8 = 200
	p_cn_op:u8 = 100

	// Animal Proto base
	c_txt = rl.LoadTexture("./images/proto/ANM.png")
	rl.GenTextureMipmaps(&c_txt)
	rl.SetTextureFilter(c_txt, filter)
	vlf_tex_cache["proto.Animal"] = c_txt

	// Vegetable Proto base
	c_txt = rl.LoadTexture("./images/proto/VGT.png")
	rl.GenTextureMipmaps(&c_txt)
	rl.SetTextureFilter(c_txt, filter)
	vlf_tex_cache["proto.Vegetable"] = c_txt

	// Synthetic Proto base
	c_txt = rl.LoadTexture("./images/proto/SYN.png")
	rl.GenTextureMipmaps(&c_txt)
	rl.SetTextureFilter(c_txt, filter)
	vlf_tex_cache["proto.Synthetic"] = c_txt
}