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
			vlf_set_flags += { .EnvironmentDisplay }
		} else {
			vlf_set_flags -= { .EnvironmentDisplay }
		}

        if rl.IsKeyDown(rl.KeyboardKey.LEFT_SHIFT) || rl.IsKeyDown(rl.KeyboardKey.RIGHT_SHIFT) {
			vlf_set_flags += { .ItemDisplay }
		} else {
			vlf_set_flags -= { .ItemDisplay }
		}

		vlf_mouse_pos = rl.GetMousePosition()

		if rl.IsMouseButtonPressed(rl.MouseButton.LEFT) {
			inject_at(&vlf_events, 0, VLF_Event{
				e_type = .Click,
				flags = vlf_set_flags + {},
				pos = vlf_mouse_pos
			})
		
			if mouse_button_timer[0] > 0 {
				inject_at(&vlf_events, 0, VLF_Event{
					e_type = .DoubleClick,
					flags = vlf_set_flags + {},
					pos = vlf_mouse_pos
				})
			}

			mouse_button_timer[0] = 10
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


