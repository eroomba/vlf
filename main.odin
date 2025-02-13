package vlf

import "core:fmt"
import "core:strings"
import "core:strconv"
import mth "core:math"
import rl "vendor:raylib"
import "core:math/rand"

screen_width:f32 = 1280
screen_height: f32 = 720

active_width:f32 = screen_width
active_height:f32 = screen_height

frame_rate:f32 = 400
delta:f32 = 0

mouse_button_state := []int{0,0}
mouse_button_timer := []int{0,0}

main :: proc() {
	rl.SetTraceLogLevel(rl.TraceLogLevel.NONE)
	rl.SetConfigFlags({ .VSYNC_HINT })
	rl.InitWindow(i32(screen_width), i32(screen_height), "VLF")
	rl.SetTargetFPS(500)
	defer rl.CloseWindow()

	vlf_init()
	defer vlf_end()

    for !rl.WindowShouldClose() {
		if mouse_button_timer[0] > 0 {
			mouse_button_timer[0] -= 1
		}
		if mouse_button_timer[1] > 0 {
			mouse_button_timer[1] -= 1
		}

		if rl.IsKeyDown(rl.KeyboardKey.LEFT_CONTROL) || rl.IsKeyDown(rl.KeyboardKey.RIGHT_CONTROL) {
			set_flags += { .Cntl }
		} else {
			set_flags -= { .Cntl }
		}

        if rl.IsKeyDown(rl.KeyboardKey.LEFT_SHIFT) || rl.IsKeyDown(rl.KeyboardKey.RIGHT_SHIFT) {
			set_flags += { .Shift }
		} else {
			set_flags -= { .Shift }
		}

		if rl.IsKeyDown(rl.KeyboardKey.LEFT) || rl.IsKeyDown(rl.KeyboardKey.A) {
			set_flags += { .Left }
		} else {
			set_flags -= { .Left }
		}

		if rl.IsKeyDown(rl.KeyboardKey.RIGHT) || rl.IsKeyDown(rl.KeyboardKey.D) {
			set_flags += { .Right }
		} else {
			set_flags -= { .Right }
		}

		if rl.IsKeyDown(rl.KeyboardKey.UP) || rl.IsKeyDown(rl.KeyboardKey.W) {
			set_flags += { .Up }
		} else {
			set_flags -= { .Up }
		}

		if rl.IsKeyDown(rl.KeyboardKey.DOWN) || rl.IsKeyDown(rl.KeyboardKey.S) {
			set_flags += { .Down }
		} else {
			set_flags -= { .Down }
		}

		key := rl.GetKeyPressed()

		// Check if more characters have been pressed on the same frame
		for key != rl.KeyboardKey.KEY_NULL {
			if key == player_keys[0] {
				inject_at(&events, 0, Event{
					e_type = .PlayerAction1,
					flags = set_flags + {},
					pos = mouse_pos
				})
			}

			if key == player_keys[1] {
				inject_at(&events, 0, Event{
					e_type = .PlayerAction2,
					flags = set_flags + {},
					pos = mouse_pos
				})
			}

			key = rl.GetKeyPressed()  // Check next character in the queue
		}


		mouse_pos = rl.GetMousePosition()

		if rl.IsMouseButtonPressed(rl.MouseButton.LEFT) {
			inject_at(&events, 0, Event{
				e_type = .Click,
				flags = set_flags + {},
				pos = mouse_pos
			})
		
			if mouse_button_timer[0] > 0 {
				inject_at(&events, 0, Event{
					e_type = .DoubleClick,
					flags = set_flags + {},
					pos = mouse_pos
				})
			}

			mouse_button_timer[0] = 16
		}

		if rl.IsMouseButtonPressed(rl.MouseButton.RIGHT) {
			inject_at(&events, 0, Event{
				e_type = .Alt_Click,
				flags = set_flags + {},
				pos = mouse_pos
			})
		}

		delta += rl.GetFrameTime()
		runStep := false

		if delta >= 1 / frame_rate {
			delta = 0
			runStep = true
		}
		
		if (runStep) {
			// run game step
			if runStep {
				vlf_run()
			}
		}

		{
			rl.BeginDrawing()
			rl.ClearBackground(rl.BLACK)

			// draw game step	
			vlf_draw()

			rl.EndDrawing()
		}
	}

}


