extends Node2D

# Containment Protocol - Godot 4.3
# Portrait 720x1280, drawn natively for low-overhead Android rendering.

const VIEW_SIZE := Vector2(720.0, 1280.0)
const WORLD_SIZE := Vector2(10400.0, 15200.0)
const BAR_TOP := 1080.0
const EVAC_RADIUS := 76.0
const MIN_ZOOM := 0.45
const MAX_ZOOM := 1.4
const CAMERA_DRAG_THRESHOLD := 14.0
const MINIMAP_SIZE := Vector2(154.0, 190.0)
const MIN_TOUCH_TARGET := 48.0
const HUD_EDGE_PADDING := 18.0
const OUTPOST_COST := 220
const TURRET_COST := 140
const WALL_COST := 75
const OUTPOST_INCOME_INTERVAL := 30.0
const TURRET_RANGE := 220.0
const OUTPOST_COMMAND_RADIUS := 320.0
const OUTPOST_MAX_COUNT := 6
const OUTPOST_COST_STEP := 60
const STRUCTURE_REPAIR_COST := 40
const STRUCTURE_UPGRADE_COST := 150
const DIAGNOSTIC_BUTTON := Rect2(210.0, 214.0, 94.0, 52.0)
const STRUCTURE_ACTION_TOP := 350.0
const GRID_CELL_SIZE := 64.0
const UNIT_SELECT_RADIUS := 30.0
const BUILDING_RADIUS := 11.0
const FLARE_COST := 40
const FLARE_LIFETIME := 6.0
const FLARE_LURE_RADIUS := 220.0
const AUDIO_SAMPLE_RATE := 22050.0
const MAX_ACTIVE_ZOMBIES := 650
const PENDING_WAVE_SPAWN_INTERVAL := 0.20
const SAVE_VERSION := 11
const PREPARATION_SECONDS := 60.0
const GAME_MINUTES_PER_SECOND := 2.4
const MAX_TACTICAL_DECALS := 80
const OUTPOST_MIN_SIZE := 220.0
const OUTPOST_MAX_SIZE := 760.0
const OUTPOST_SNAP := 20.0
const OUTPOST_WALL_THICKNESS := 18.0
const GATE_COST := 90
const CALL_TO_ARMS_COST := 60
const MILITIA_RANGE := 175.0
const HOSPITAL_REGEN_RADIUS := 160.0
const ARMORY_RADIUS := 180.0
const WAREHOUSE_HOLD_TIME := 4.0

const UNIT_DEPLOYMENTS := [
	{"name": "AIRSTRIKE", "detail": "MATS", "cost": 300, "kind": "airstrike"},
	{"name": "FLARE", "detail": "BEACON  MATS", "cost": FLARE_COST, "kind": "flare"}
]
const RECRUIT_DEPLOYMENTS := [
	{"name": "INFANTRY", "detail": "MATS", "cost": 60, "kind": "infantry"},
	{"name": "SNIPER", "detail": "MATS", "cost": 110, "kind": "sniper"},
	{"name": "ENGINEER", "detail": "MATS", "cost": 85, "kind": "engineer"},
	{"name": "MEDIC", "detail": "MATS", "cost": 95, "kind": "medic"},
	{"name": "HEAVY", "detail": "MATS", "cost": 130, "kind": "heavy"}
]
const BASE_DEPLOYMENTS := [
	{"name": "OUTPOST", "detail": "MATS", "cost": OUTPOST_COST, "kind": "outpost"},
	{"name": "TURRET", "detail": "MATS", "cost": TURRET_COST, "kind": "turret"},
	{"name": "WALL", "detail": "MATS", "cost": WALL_COST, "kind": "wall"}, {"name": "GATE", "detail": "MATS", "cost": GATE_COST, "kind": "gate"},
	{"name": "FARM", "detail": "MATS / M45", "cost": 80, "kind": "farm"},
	{"name": "BAKERY", "detail": "MATS / M70", "cost": 120, "kind": "bakery"},
	{"name": "LIVESTOCK", "detail": "MATS / M60", "cost": 100, "kind": "livestock"},
	{"name": "WATCHTOWER", "detail": "MATS / M50", "cost": 90, "kind": "watchtower"},
	{"name": "FIELD CLINIC", "detail": "MATS / M65", "cost": 110, "kind": "clinic"}
]

var civilians: Array[Vector2] = []
var zombies: Array[Dictionary] = []
var pending_wave_spawns := 0
var pending_wave_spawn_timer := 0.0
var units: Array[Dictionary] = []
var vehicles: Array[Dictionary] = []
var auto_ops_enabled := true
var highway_segments: Array[Dictionary] = []
var secondary_road_segments: Array[Dictionary] = []
var task_reservations: Dictionary = {}
var world_callouts: Array[Dictionary] = []
var selected_vehicle_index := -1
var barricades: Array[Dictionary] = []
var flares: Array[Dictionary] = []
var tactical_decals: Array[Dictionary] = []
var sector_index := 0
var sector_name := "Downtown Grid"
var sector_wave_limit := 30
var primary_hq_position := Vector2(-1.0, -1.0)
var shelter_flush_timer := 15.0
var supply_drop_timer := 150.0
var supply_crates: Array[Dictionary] = []
var civilian_steering: Array[Dictionary] = []
var campaign_started := false
var campaign_start_grace_timer := 0.0
var initial_civilian_count := 0
var scrap := 120
var wood := 80
var food := 120
var fuel := 300.0
var last_upkeep_day := 1
var trees: Array[Dictionary] = []
var wildlife: Array[Dictionary] = []
var raider_camps: Array[Dictionary] = []
var constructed_buildings: Array[Dictionary] = []
var cached_light_sources: Array[Dictionary] = []
var radio_log: Array[String] = []
var radio_log_open := false
var endless_containment := false
var day_phase := "DAY"
var world_clock_minutes := 450.0
var survival_day := 1
var best_days_survived := 0
var best_civilians_saved := 0
var radio_banner_text := ""
var radio_banner_timer := 0.0
var radio_day_announced := 0
var recent_outpost_loss_timer := 0.0
var save_path := "user://containment_save.json"
var manual_paused := false
var lifecycle_paused := false
var preview_position := Vector2.ZERO
var preview_active := false
var sfx_enabled := true
var audio_player: AudioStreamPlayer
var audio_queue: Array[String] = []
var audio_effect := ""
var audio_phase := 0.0
var audio_samples_left := 0
var audio_rng := RandomNumberGenerator.new()
var weapons: Dictionary = {"rifles": 6, "snipers": 2, "heavy_mgs": 1, "medkits": 3}
var survivors: Array[Dictionary] = []
var selected_survivor_index := -1
var crafting_orders: Array[Dictionary] = []
var saved_count := 0
var lost_count := 0
var selected_deployment := 0
var game_state := "playing"
var wave := 0
var wave_timer := 2.0
var elapsed := 0.0
var message := "EVACUATE CIVILIANS. HOLD THE LINE."
var message_timer := 4.0
var airstrike_marker := Vector2.ZERO
var airstrike_timer := 0.0
var screen_font: Font
var buildings: Array[Rect2] = []
var building_archetypes: Array[Dictionary] = []
var district_regions: Array[Rect2] = []
var district_seed_points: Array[Vector2] = []
var campaign_map_seed: int = 0
var starting_district_index: int = 0
var gates: Array[Dictionary] = []
var warehouse_hold_timers: Dictionary = {}
var outpost_placement_active := false
var outpost_placement_dragging := false
var outpost_placement_start := Vector2.ZERO
var outpost_placement_rect := Rect2(Vector2.ZERO, Vector2(OUTPOST_MIN_SIZE, OUTPOST_MIN_SIZE))
var outpost_placement_kind := "outpost"
var outpost_placement_valid := false
var outpost_placement_gesture_mode := ""
var outpost_placement_anchor := Vector2.ZERO
var scenario_camera_target := WORLD_SIZE * 0.5
var evacuation_zones: Array[Vector2] = []
var spawn_districts: Array[Rect2] = []
var outposts: Array[Dictionary] = []
var turrets: Array[Dictionary] = []
var civilian_grid: Dictionary = {}
var zombie_grid: Dictionary = {}
var static_building_grid: Dictionary = {}
var smoothed_frame_time_ms: float = 16.67
var zombie_positions: Array[Vector2] = []
var selected_unit_index := -1
var time_scale_index := 0
const TIME_SCALES := [1.0, 0.25]
const TIME_LABELS := ["1x", "0.25x"]
var bullet_tracers: Array[Dictionary] = []
var muzzle_flashes: Array[Dictionary] = []
var shockwaves: Array[Dictionary] = []
var shake_timer := 0.0
var shake_strength := 0.0
var camera_position := WORLD_SIZE * 0.5
var camera_zoom := 0.62
var camera_dragging := false
var camera_drag_origin := Vector2.ZERO
var camera_last_position := Vector2.ZERO
var camera_drag_distance := 0.0
var touch_points: Dictionary = {}
var pinch_start_distance := 0.0
var pinch_start_zoom := 1.0
var multi_touch_gesture := false
var previous_pinch_center := Vector2.ZERO
var command_tab := 0
var viewport_size := VIEW_SIZE
var safe_insets := Vector4.ZERO
var safe_area_rect := Rect2(Vector2.ZERO, VIEW_SIZE)
var touch_target_size := MIN_TOUCH_TARGET
var selected_structure_type := ""
var selected_structure_index := -1
var diagnostics_enabled := false
var fps_sample_timer := 0.0
var fps_sample_value := 0
var fps_frame_count := 0
var citizens: Array[Dictionary] = []
var role_allocations: Dictionary = {"GATHERERS": 0, "ENGINEERS": 0, "FACILITY": 0, "SQUAD": 0}
var raid_squads: Array[Dictionary] = []
var work_zones: Array[Dictionary] = []
var work_zone_dragging := false
var work_zone_start := Vector2.ZERO
var work_zone_current := Vector2.ZERO
var work_outside_enabled := true
var citizen_name_seed: int = 0
var used_citizen_names: Dictionary = {}
var citizen_name_permutation_offset: int = 0
var citizen_name_permutation_stride: int = 1
var citizen_name_permutation_cursor: int = 0
var faction_doctrine: String = "PRAGMATIC FREEHOLD"
var doctrine_change_day: int = 1
var doctrine_morale_shock_days: int = 0
var faction_settlements: Array[Dictionary] = []
var faction_foundation_timer: float = 720.0
var specialists_panel_open: bool = false
var outpost_morale: float = 70.0
var doctrine_morale_recovery_day: int = 0
var selected_raid_squad: int = 0
var ops_monitor_open: bool = false
var outpost_expanding_index: int = -1
var selected_hq_building_idx: int = -1
var outpost_placement_status: String = "VALID"
var recent_gunfire: Array[Dictionary] = []
var population_heat_targets: Array[Dictionary] = []
var population_heat_refresh_timer: float = 0.0
var title_animation_time: float = 0.0
var title_manual_open: bool = false
var menu_fade_alpha: float = 0.0
var menu_transition_timer: float = 0.0
var menu_transition_action: String = ""
var menu_transition_sector: int = 0
var update_request: HTTPRequest
var update_status: String = "CHECKING FOR UPDATES"
var update_available: bool = false
var latest_apk_url: String = ""
var update_check_started: bool = false

func _setup_update_checker() -> void:
	update_request = HTTPRequest.new()
	update_request.timeout = 15.0
	add_child(update_request)
	update_request.request_completed.connect(_on_update_check_completed)
	_check_for_game_updates()

func _check_for_game_updates() -> void:
	if update_request == null or update_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		return
	update_status = "CHECKING FOR UPDATES"
	update_check_started = true
	var headers: PackedStringArray = ["User-Agent: ContainmentProtocol-Android", "Accept: application/vnd.github+json"]
	var request_error: int = update_request.request("https://api.github.com/repos/shitaaa22-sketch/Containment-Protocol/releases/tags/latest-android-apk", headers)
	if request_error != OK:
		update_status = "UPDATE CHECK FAILED"
		update_check_started = false
		queue_redraw()

func _on_update_check_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	update_check_started = false
	update_available = false
	latest_apk_url = ""
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		update_status = "UPDATE CHECK UNAVAILABLE"
		queue_redraw()
		return
	var parsed: Variant = JSON.parse_string(body.get_string_from_utf8())
	if not parsed is Dictionary:
		update_status = "UPDATE CHECK UNAVAILABLE"
		queue_redraw()
		return
	var release: Dictionary = parsed as Dictionary
	var release_body: String = str(release.get("body", ""))
	var installed_commit: String = str(ProjectSettings.get_setting("application/config/version", "dev"))
	var latest_commit: String = ""
	for line in release_body.split("\n"):
		if line.begins_with("Commit "):
			latest_commit = line.trim_prefix("Commit ").strip_edges()
			break
	for asset_value in release.get("assets", []):
		if asset_value is Dictionary and str((asset_value as Dictionary).get("name", "")) == "ContainmentProtocol.apk":
			latest_apk_url = str((asset_value as Dictionary).get("browser_download_url", ""))
			break
	update_available = not latest_apk_url.is_empty() and not latest_commit.is_empty() and latest_commit != installed_commit
	update_status = "UPDATE AVAILABLE — TAP TO DOWNLOAD" if update_available else "GAME IS UP TO DATE"
	queue_redraw()

func _open_latest_game_update() -> void:
	if update_available and not latest_apk_url.is_empty():
		OS.shell_open(latest_apk_url)
	else:
		_check_for_game_updates()

func _ready() -> void:
	randomize()
	screen_font = ThemeDB.fallback_font
	viewport_size = get_viewport_rect().size
	_refresh_safe_area()
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	_configure_sector(0)
	_load_persistent_records()
	_setup_audio()
	_setup_update_checker()
	game_state = "title"
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		_save_operation()
		lifecycle_paused = true
		manual_paused = true
		audio_queue.clear()
		audio_effect = ""
		audio_samples_left = 0
		if audio_player != null:
			audio_player.stop()
		queue_redraw()
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		if audio_player != null and sfx_enabled:
			audio_player.play()
		queue_redraw()
	elif what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if game_state == "title":
			game_state = "sector_select"
		elif game_state == "sector_select":
			game_state = "title"
		elif game_state == "playing":
			manual_paused = not manual_paused
			lifecycle_paused = false
		else:
			game_state = "sector_select"
		queue_redraw()

func _start_round() -> void:
	_start_sector(sector_index)

func _start_sector(index: int) -> void:
	world_callouts.clear()
	sector_index = clampi(index, 0, 2)
	_configure_sector(sector_index)
	civilians.clear()
	zombies.clear()
	units.clear()
	selected_vehicle_index = -1
	auto_ops_enabled = true
	barricades.clear()
	flares.clear()
	tactical_decals.clear()
	trees.clear()
	wildlife.clear()
	raider_camps.clear()
	constructed_buildings.clear()
	cached_light_sources.clear()
	radio_log.clear()
	radio_log_open = false
	outposts.clear()
	turrets.clear()
	gates.clear()
	building_archetypes.clear()
	warehouse_hold_timers.clear()
	outpost_placement_active = false
	outpost_placement_dragging = false
	supply_crates.clear()
	civilian_steering.clear()
	evacuation_zones.clear()
	primary_hq_position = Vector2(-1.0, -1.0)
	campaign_started = false
	campaign_start_grace_timer = 0.0
	initial_civilian_count = 0
	scrap = 140
	wood = 180
	food = 120
	last_upkeep_day = 1
	fuel = 80.0
	endless_containment = true
	world_clock_minutes = 450.0
	survival_day = 1
	radio_banner_text = ""
	radio_banner_timer = 0.0
	radio_day_announced = 0
	recent_outpost_loss_timer = 0.0
	shelter_flush_timer = 15.0
	supply_drop_timer = 150.0
	day_phase = "DAY"
	camera_position = scenario_camera_target
	camera_zoom = 0.62
	command_tab = 0
	ops_monitor_open = false
	manual_paused = false
	lifecycle_paused = false
	scrap = 140
	wood = 180
	food = 120
	fuel = 80.0
	weapons = {"rifles": 4, "snipers": 1, "heavy_mgs": 0, "medkits": 2}
	recent_gunfire.clear()
	population_heat_targets.clear()
	population_heat_refresh_timer = 0.0
	outpost_expanding_index = -1
	survivors = _milestone13_survivors()
	citizens.clear()
	raid_squads.clear()
	work_zones.clear()
	role_allocations = {"GATHERERS": 0, "ENGINEERS": 0, "FACILITY": 0, "SQUAD": 0}
	citizen_name_seed = campaign_map_seed
	used_citizen_names.clear()
	citizen_name_permutation_offset = randi_range(0, 14399)
	citizen_name_permutation_stride = randi_range(1, 14399)
	while _milestone14_gcd(citizen_name_permutation_stride, 14400) != 1:
		citizen_name_permutation_stride = posmod(citizen_name_permutation_stride + 1, 14400)
		if citizen_name_permutation_stride == 0:
			citizen_name_permutation_stride = 1
	citizen_name_permutation_cursor = 0
	faction_doctrine = "PRAGMATIC FREEHOLD"
	doctrine_change_day = 1
	doctrine_morale_shock_days = 0
	faction_settlements.clear()
	faction_foundation_timer = 720.0
	outpost_morale = 70.0
	_milestone14_initialize_citizens()
	_milestone14_seed_factions()
	crafting_orders.clear()
	saved_count = 0
	lost_count = 0
	wave = 0
	wave_timer = 180.0
	elapsed = 0.0
	game_state = "prologue"
	selected_deployment = 0
	selected_unit_index = -1
	selected_structure_type = ""
	selected_structure_index = -1
	diagnostics_enabled = false
	fps_sample_timer = 0.0
	fps_sample_value = 0
	fps_frame_count = 0
	time_scale_index = 0
	bullet_tracers.clear()
	muzzle_flashes.clear()
	shockwaves.clear()
	shake_timer = 0.0
	preview_active = false
	audio_queue.clear()
	audio_effect = ""
	message = "EVACUATE CIVILIANS. HOLD THE LINE."
	message_timer = 4.0
	# Re-assert convoy stock after all campaign state and roster resets.
	scrap = 140
	wood = 180
	food = 120
	fuel = 80.0
	weapons = {"rifles": 4, "snipers": 1, "heavy_mgs": 0, "medkits": 2}
	for district_index in range(spawn_districts.size()):
		var district: Rect2 = spawn_districts[district_index]
		var civilian_spawn_count: int = _scenario_civilian_count(district_index, 30 + _residential_density_bonus(district))
		for i in range(civilian_spawn_count):
			var spawn_point := Vector2(randf_range(district.position.x, district.end.x), randf_range(district.position.y, district.end.y))
			if _is_open_world_position(spawn_point, 18.0):
				civilians.append(spawn_point)
				civilian_steering.append({})
				_milestone14_add_refugee("", false)
	initial_civilian_count = civilians.size()
	_populate_ecology()
	for district_index in range(spawn_districts.size()):
		var district: Rect2 = spawn_districts[district_index]
		for outbreak_index in range(_scenario_initial_zombie_count(district_index)):
			var outbreak_position := Vector2(randf_range(district.position.x, district.end.x), randf_range(district.position.y, district.end.y))
			if _is_open_world_position(outbreak_position, 18.0):
				zombies.append({"pos": outbreak_position, "kind": "shambler", "hp": 30.0, "max_hp": 30.0, "wall_cooldown": 0.0})
	message = "SCOUT THE CITY — SELECT PRIMARY HQ LOCATION"
	message_timer = 6.0
	camera_position = scenario_camera_target
	_clamp_camera()

func _process(delta: float) -> void:
	_update_audio()
	if delta > 0.0:
		smoothed_frame_time_ms = lerpf(smoothed_frame_time_ms, delta * 1000.0, 0.08)
	if delta > 0.0:
		fps_frame_count += 1
		fps_sample_timer += delta
		if fps_sample_timer >= 0.5:
			fps_sample_value = roundi(float(fps_frame_count) / fps_sample_timer)
			fps_frame_count = 0
			fps_sample_timer = 0.0
	_update_combat_effects(delta)
	for callout_index in range(world_callouts.size() - 1, -1, -1):
		world_callouts[callout_index]["life"] = float(world_callouts[callout_index].get("life", 0.0)) - delta
		if float(world_callouts[callout_index]["life"]) <= 0.0:
			world_callouts.remove_at(callout_index)
	if game_state == "title" or game_state == "sector_select" or game_state == "prologue" or game_state == "hq_placement":
		title_animation_time += minf(delta, 0.05)
		if menu_transition_timer > 0.0:
			menu_transition_timer = maxf(0.0, menu_transition_timer - delta)
			menu_fade_alpha = clampf(1.0 - menu_transition_timer / 0.24, 0.0, 1.0)
			if menu_transition_timer <= 0.0:
				var action: String = menu_transition_action
				menu_transition_action = ""
				if action == "deploy":
					_start_sector(menu_transition_sector)
					menu_fade_alpha = 1.0
					menu_transition_timer = 0.24
				elif action == "sector_select":
					game_state = "sector_select"
					menu_fade_alpha = 1.0
					menu_transition_timer = 0.24
				elif action == "hq_placement":
					game_state = "hq_placement"
					menu_fade_alpha = 1.0
					menu_transition_timer = 0.24
				else:
					menu_fade_alpha = 0.0
		queue_redraw()
		return
	if game_state != "playing":
		queue_redraw()
		return
	if manual_paused or lifecycle_paused:
		queue_redraw()
		return
	_update_flares(delta)

	var sim_delta: float = delta * TIME_SCALES[time_scale_index]
	if sim_delta <= 0.0:
		queue_redraw()
		return

	elapsed += sim_delta
	world_clock_minutes += sim_delta * GAME_MINUTES_PER_SECOND
	survival_day = maxi(1, int(floor(world_clock_minutes / 1440.0)) + 1)
	if survival_day > last_upkeep_day:
		for upkeep_day in range(last_upkeep_day + 1, survival_day + 1):
			last_upkeep_day = upkeep_day
			_apply_daily_rations()
		best_days_survived = maxi(best_days_survived, survival_day)
		best_civilians_saved = maxi(best_civilians_saved, saved_count)
		_update_persistent_records()
		_save_operation()
	if doctrine_morale_shock_days > 0 and doctrine_morale_recovery_day > 0 and survival_day >= doctrine_morale_recovery_day:
		outpost_morale = minf(100.0, outpost_morale + 15.0)
		doctrine_morale_shock_days = 0
		doctrine_morale_recovery_day = 0
	_update_day_phase()
	_update_radio_transmission()
	radio_banner_timer = maxf(0.0, radio_banner_timer - sim_delta)
	recent_outpost_loss_timer = maxf(0.0, recent_outpost_loss_timer - sim_delta)
	campaign_start_grace_timer = maxf(0.0, campaign_start_grace_timer - sim_delta)
	_update_vehicles(sim_delta)
	_update_auto_ops(sim_delta)
	_milestone14_tick_workforce(sim_delta)
	_milestone15_tick_infections(sim_delta)
	_milestone14_update_factions(sim_delta)
	_milestone151_update_population_heat(sim_delta)
	_refresh_light_source_cache()
	message_timer = maxf(0.0, message_timer - sim_delta)
	airstrike_timer = maxf(0.0, airstrike_timer - sim_delta)
	wave_timer -= sim_delta

	if campaign_start_grace_timer <= 0.0 and wave_timer <= 0.0:
		_spawn_wave()
		wave_timer = 180.0
		_save_operation()
	_shelter_flush_timer_step(sim_delta)
	_update_supply_drops(sim_delta)
	_update_building_effects(sim_delta)
	_milestone13_tick_construction(sim_delta)
	_milestone13_tick_crafting(sim_delta)
	_update_gate_states()
	# Day phase transitions are driven by the continuous 24-hour clock.

	# Civilians evacuate through the street network; the grid is rebuilt once
	# after movement so every zombie queries current civilian positions.
	for i in range(civilians.size() - 1, -1, -1):
		var civilian: Vector2 = civilians[i]
		var civilian_safe_target: Vector2 = _nearest_evac_zone(civilian)
		var nearest_outpost_distance := INF
		for outpost in outposts:
			if int(outpost.get("sheltered", 0)) >= int(outpost.get("capacity", 12)):
				continue
			var outpost_rect: Rect2 = outpost.get("rect", Rect2(outpost["pos"] - Vector2(110.0, 110.0), Vector2(220.0, 220.0)))
			var outpost_distance: float = civilian.distance_squared_to(outpost["pos"])
			var beacon_active: bool = float(outpost.get("rescue_beacon_timer", 0.0)) > 0.0 and outpost_distance <= 800.0 * 800.0
			if (outpost_rect.grow(80.0).has_point(civilian) or beacon_active) and outpost_distance < nearest_outpost_distance:
				nearest_outpost_distance = outpost_distance
				civilian_safe_target = outpost["pos"]
		var civilian_move_target: Vector2 = _outpost_gate_waypoint(civilian, civilian_safe_target)
		var direction: Vector2 = (civilian_move_target - civilian).normalized()
		var displacement: Vector2 = direction * 43.0 * sim_delta
		var civilian_steer: Dictionary = civilian_steering[i] if i < civilian_steering.size() else {}
		civilian = _move_circle_with_buildings(civilian, displacement, 5.5, sim_delta, civilian_move_target, civilian_steer)
		if i < civilian_steering.size():
			civilian_steering[i] = civilian_steer
		civilians[i] = civilian
		var reached_safe_zone := civilian.distance_to(_nearest_evac_zone(civilian)) <= EVAC_RADIUS
		var reached_outpost_index := -1
		for outpost_index in range(outposts.size()):
			var safe_outpost: Dictionary = outposts[outpost_index]
			var safe_rect: Rect2 = safe_outpost.get("rect", Rect2(safe_outpost["pos"] - Vector2(28.0, 28.0), Vector2(56.0, 56.0)))
			if safe_rect.grow(-24.0).has_point(civilian) and int(safe_outpost.get("sheltered", 0)) < int(safe_outpost.get("capacity", 12)):
				reached_outpost_index = outpost_index
				reached_safe_zone = true
				break
		if reached_safe_zone:
			civilians.remove_at(i)
			if i < civilian_steering.size():
				civilian_steering.remove_at(i)
			if reached_outpost_index >= 0:
				outposts[reached_outpost_index]["sheltered"] = int(outposts[reached_outpost_index].get("sheltered", 0)) + 1
			else:
				saved_count += 1
				scrap += 35
				_milestone14_award_rescue_standing(civilian)
			message = "CIVILIAN SHELTERED / EVACUATED  +MATS"
			message_timer = 1.1

	_rebuild_spatial_grid(civilian_grid, civilians)
	var viewport_world_rect: Rect2 = _camera_view_rect()
	var stagger_offscreen_zombies: bool = zombies.size() > 450 or smoothed_frame_time_ms > 18.5
	for i in range(zombies.size() - 1, -1, -1):
		var zombie: Dictionary = zombies[i]
		zombie["turret_attack_cooldown"] = maxf(0.0, float(zombie.get("turret_attack_cooldown", 0.0)) - sim_delta)
		zombie["gate_attack_cooldown"] = maxf(0.0, float(zombie.get("gate_attack_cooldown", 0.0)) - sim_delta)
		zombie["building_attack_cooldown"] = maxf(0.0, float(zombie.get("building_attack_cooldown", 0.0)) - sim_delta)
		zombie["unit_attack_cooldown"] = maxf(0.0, float(zombie.get("unit_attack_cooldown", 0.0)) - sim_delta)
		var zpos: Vector2 = zombie["pos"]
		var offscreen_stagger_frame: bool = stagger_offscreen_zombies and not viewport_world_rect.has_point(zpos) and posmod(Engine.get_physics_frames() + i, 2) == 1
		var target_index: int = _find_nearest_entity(civilian_grid, civilians, zpos, 640.0 * (1.25 if day_phase == "NIGHT" else 1.0))
		var target: Vector2 = _nearest_evac_zone(zpos)
		if target_index >= 0:
			target = civilians[target_index]
		var heat_target: Vector2 = _milestone151_hottest_target(zpos)
		if heat_target != Vector2.ZERO:
			target = target.lerp(heat_target, 0.32 if target_index >= 0 else 1.0)
		if bool(zombie.get("turned_inside_outpost", false)):
			var nearest_indoor_unit: int = -1
			var nearest_indoor_distance: float = 320.0 * 320.0
			for indoor_unit_index in range(units.size()):
				var indoor_unit: Dictionary = units[indoor_unit_index]
				var indoor_distance: float = zpos.distance_squared_to(indoor_unit.get("pos", Vector2.ZERO))
				if indoor_distance <= nearest_indoor_distance:
					nearest_indoor_distance = indoor_distance
					nearest_indoor_unit = indoor_unit_index
			if nearest_indoor_unit >= 0:
				target = units[nearest_indoor_unit].get("pos", target)
		var siege_building_index: int = int(zombie.get("siege_building", -1))
		if siege_building_index >= 0 and siege_building_index < buildings.size() and not bool(building_archetypes[siege_building_index].get("destroyed", false)) and zpos.distance_to(buildings[siege_building_index].get_center()) <= 300.0:
			target = buildings[siege_building_index].get_center()
		var lure_index: int = _find_nearest_flare(zpos)
		if lure_index >= 0:
			target = flares[lure_index]["pos"]
		var zombie_kind: String = str(zombie.get("kind", "shambler"))
		var zombie_speed: float = 112.0 if zombie_kind == "runner" else 61.0
		if zombie_kind == "brute":
			zombie_speed = 34.0
		if float(zombie.get("stagger_timer", 0.0)) > 0.0:
			zombie["stagger_timer"] = maxf(0.0, float(zombie["stagger_timer"]) - sim_delta)
			zombie_speed *= 0.55
		if day_phase == "NIGHT" and not offscreen_stagger_frame and not _is_position_illuminated(zpos):
			zombie_speed *= 1.20
		if not offscreen_stagger_frame:
			var displacement: Vector2 = (target - zpos).normalized() * zombie_speed * sim_delta
			zpos = _move_circle_with_buildings(zpos, displacement, 10.0 if zombie_kind == "brute" else 7.0, sim_delta, target, zombie, true)
		var contacted_building_index: int = _building_contact_index(zpos, 22.0)
		if contacted_building_index < 0 and siege_building_index >= 0 and siege_building_index < buildings.size() and zpos.distance_to(buildings[siege_building_index].get_center()) <= 28.0:
			contacted_building_index = siege_building_index
		if contacted_building_index >= 0 and float(zombie.get("building_attack_cooldown", 0.0)) <= 0.0:
			var has_garrison := false
			for garrison_unit in units:
				if bool(garrison_unit.get("garrisoned", false)) and int(garrison_unit.get("garrison_building", -1)) == contacted_building_index:
					has_garrison = true
					break
			if has_garrison:
				var building_state: Dictionary = building_archetypes[contacted_building_index]
				var damage: float = 72.0 if zombie_kind == "brute" else (24.0 if zombie_kind == "runner" else 36.0)
				building_state["hp"] = maxf(0.0, float(building_state.get("hp", 900.0)) - damage)
				zombie["building_attack_cooldown"] = 1.0
				if float(building_state["hp"]) <= 0.0:
					building_state["destroyed"] = true
					building_state["secured"] = false
					building_archetypes[contacted_building_index] = building_state
					_rebuild_static_building_grid()
					_eject_building_garrison(contacted_building_index)
					message = "BUILDING BREACHED — GARRISON EJECTED / TRIAGE"
					message_timer = 2.0
				else:
					building_archetypes[contacted_building_index] = building_state

		for wall_index in range(barricades.size() - 1, -1, -1):
			var wall: Dictionary = barricades[wall_index]
			var wall_pos: Vector2 = wall["pos"]
			var wall_rect: Rect2 = wall.get("rect", Rect2(wall_pos - Vector2(15.0, 15.0), Vector2(30.0, 30.0)))
			var wall_nearest := Vector2(clampf(zpos.x, wall_rect.position.x, wall_rect.end.x), clampf(zpos.y, wall_rect.position.y, wall_rect.end.y))
			if zpos.distance_to(wall_nearest) < 30.0:
				if zombie_kind == "brute":
					var attack_cooldown: float = float(zombie.get("wall_cooldown", 0.0))
					if attack_cooldown <= 0.0:
						wall["hp"] = maxf(0.0, float(wall["hp"]) - 50.0)
						zombie["wall_cooldown"] = 1.0
						if float(wall["hp"]) <= 0.0:
							barricades.remove_at(wall_index)
							message = "CONCRETE BARRICADE DESTROYED"
							message_timer = 1.2
						else:
							barricades[wall_index] = wall
					else:
						zombie["wall_cooldown"] = maxf(0.0, attack_cooldown - sim_delta)
				else:
					zpos -= (target - wall_pos).normalized() * 38.0 * sim_delta
				break

		for gate_index in range(gates.size() - 1, -1, -1):
			var gate: Dictionary = gates[gate_index]
			var gate_rect: Rect2 = gate["rect"]
			var gate_nearest := Vector2(clampf(zpos.x, gate_rect.position.x, gate_rect.end.x), clampf(zpos.y, gate_rect.position.y, gate_rect.end.y))
			if zpos.distance_to(gate_nearest) <= 30.0 and float(zombie.get("gate_attack_cooldown", 0.0)) <= 0.0:
				var gate_damage: float = 50.0 if zombie_kind == "brute" else 18.0
				gate["hp"] = maxf(0.0, float(gate.get("hp", 500.0)) - gate_damage)
				zombie["gate_attack_cooldown"] = 1.0
				if float(gate["hp"]) <= 0.0:
					gates.remove_at(gate_index)
					message = "PERIMETER GATE BREACHED"
				else:
					gates[gate_index] = gate
				break

		for turret_index in range(turrets.size() - 1, -1, -1):
			var nearby_turret: Dictionary = turrets[turret_index]
			var turret_position: Vector2 = nearby_turret["pos"]
			if zpos.distance_to(turret_position) <= 26.0:
				if float(zombie["turret_attack_cooldown"]) <= 0.0:
					var turret_damage := 28.0 if zombie_kind == "brute" else 14.0
					nearby_turret["hp"] = maxf(0.0, float(nearby_turret["hp"]) - turret_damage)
					zombie["turret_attack_cooldown"] = 1.0
					if float(nearby_turret["hp"]) <= 0.0:
						turrets.remove_at(turret_index)
						message = "SENTRY TURRET DESTROYED"
						message_timer = 1.2
					else:
						turrets[turret_index] = nearby_turret
				break
		if float(zombie.get("unit_attack_cooldown", 0.0)) <= 0.0:
			for unit_index in range(units.size()):
				var exposed_unit: Dictionary = units[unit_index]
				var turned_inside: bool = bool(zombie.get("turned_inside_outpost", false))
				if bool(exposed_unit.get("garrisoned", false)) and not turned_inside:
					continue
				var contact_range: float = 76.0 if turned_inside else 22.0
				if zpos.distance_to(exposed_unit["pos"]) <= contact_range:
					var melee_damage: float = 42.0 if zombie_kind == "brute" else (28.0 if turned_inside else 20.0)
					exposed_unit["hp"] = maxf(0.0, float(exposed_unit.get("hp", 100.0)) - melee_damage)
					zombie["unit_attack_cooldown"] = 1.0
					if float(exposed_unit["hp"]) <= 0.0:
						_milestone14_remove_casualty(exposed_unit)
						units.remove_at(unit_index)
						if selected_unit_index == unit_index:
							selected_unit_index = -1
						elif selected_unit_index > unit_index:
							selected_unit_index -= 1
						message = "FRIENDLY UNIT LOST"
						message_timer = 1.5
					else:
						units[unit_index] = exposed_unit
						_milestone15_apply_pathogen_exposure(unit_index, zombie_kind)
					break
		zombie["pos"] = zpos
		zombies[i] = zombie

		var civilian_cell := _cell_for(zpos)
		var infected_index := -1
		for cell_y in range(civilian_cell.y - 1, civilian_cell.y + 2):
			for cell_x in range(civilian_cell.x - 1, civilian_cell.x + 2):
				var cell_key := Vector2i(cell_x, cell_y)
				if not civilian_grid.has(cell_key):
					continue
				var nearby_civilians: Array = civilian_grid[cell_key]
				for raw_civilian_index in nearby_civilians:
					var civilian_index: int = int(raw_civilian_index)
					if civilian_index < civilians.size() and zpos.distance_to(civilians[civilian_index]) < 15.0:
						infected_index = civilian_index
						break
				if infected_index >= 0:
					break
			if infected_index >= 0:
				break
		if infected_index >= 0:
			var infected_pos: Vector2 = civilians[infected_index]
			civilians.remove_at(infected_index)
			if infected_index < civilian_steering.size():
				civilian_steering.remove_at(infected_index)
			_rebuild_spatial_grid(civilian_grid, civilians)
			lost_count += 1
			if zombies.size() < MAX_ACTIVE_ZOMBIES:
				zombies.append({"pos": infected_pos, "kind": "shambler", "hp": 30.0, "max_hp": 30.0})
			message = "CIVILIAN LOST"
			message_timer = 1.4

	_update_outpost_damage(sim_delta)
	_rebuild_zombie_spatial_grid()
	for outpost_index in range(outposts.size()):
		var outpost: Dictionary = outposts[outpost_index]
		outpost["rescue_beacon_timer"] = maxf(0.0, float(outpost.get("rescue_beacon_timer", 0.0)) - sim_delta)
		outpost["income_timer"] = float(outpost["income_timer"]) - sim_delta
		if float(outpost["income_timer"]) <= 0.0:
			var income_amount := 15 if int(outpost.get("level", 1)) >= 2 else 10
			scrap += income_amount
			outpost["income_timer"] = OUTPOST_INCOME_INTERVAL
			message = "OUTPOST SUPPLY +MATS %d" % income_amount
			message_timer = 0.8
		outposts[outpost_index] = outpost

	_spawn_pending_wave_spawns(sim_delta)

	for turret_index in range(turrets.size() - 1, -1, -1):
		var turret: Dictionary = turrets[turret_index]
		turret["cooldown"] = maxf(0.0, float(turret["cooldown"]) - sim_delta)
		if float(turret["cooldown"]) <= 0.0:
			var turret_range := float(turret.get("range", TURRET_RANGE))
			var target_zombie: int = _milestone17_find_turret_target(turret, turret_range)
			if target_zombie >= 0:
				var turret_target: Vector2 = zombies[target_zombie]["pos"]
				var turret_damage := float(turret.get("damage", 22.0))
				var base_interval := float(turret.get("fire_interval", 0.18))
				var command_buff := false
				for command_outpost in outposts:
					if turret["pos"].distance_to(command_outpost["pos"]) <= OUTPOST_COMMAND_RADIUS:
						command_buff = true
						break
				var fire_interval := base_interval * (0.8 if command_buff else 1.0)
				if _is_near_building_type(turret["pos"], "ARMORY", ARMORY_RADIUS):
					fire_interval /= 1.15
				if int(turret.get("level", 1)) >= 2:
					var tracer_direction: Vector2 = (turret_target - turret["pos"]).normalized().orthogonal() * 5.0
					_add_bullet_tracer(turret["pos"] + tracer_direction, turret_target + tracer_direction)
					_add_bullet_tracer(turret["pos"] - tracer_direction, turret_target - tracer_direction)
				else:
					_add_bullet_tracer(turret["pos"], turret_target)
				_damage_zombie(target_zombie, turret_damage, -1, turret["pos"])
				turret["cooldown"] = fire_interval
				_rebuild_zombie_spatial_grid()
		turrets[turret_index] = turret

	for unit_index in range(units.size()):
		var unit: Dictionary = units[unit_index]
		var unit_move_target: Variant = unit.get("move_target", null)
		if not bool(unit.get("garrisoned", false)) and unit_move_target is Vector2:
			var unit_position: Vector2 = unit["pos"]
			var unit_waypoint: Vector2 = _outpost_gate_waypoint(unit_position, unit_move_target)
			if unit_position.distance_to(unit_waypoint) > 12.0:
				var raw_unit_steering: Variant = unit.get("steering", {})
				var unit_steering: Dictionary = raw_unit_steering if raw_unit_steering is Dictionary else {}
				var unit_kind_for_speed: String = str(unit.get("kind", ""))
				var unit_speed: float = 60.0 if unit_kind_for_speed == "infantry" else (58.0 if unit_kind_for_speed == "militia" else (48.0 if unit_kind_for_speed == "engineer" else (50.0 if unit_kind_for_speed == "heavy" else 52.0)))
				if float(unit.get("triage_timer", 0.0)) > 0.0:
					unit_speed *= 0.5
				var desired_velocity: Vector2 = (unit_waypoint - unit_position).normalized() * unit_speed
				var current_velocity: Vector2 = unit.get("move_velocity", Vector2.ZERO)
				var smoothed_velocity: Vector2 = current_velocity.move_toward(desired_velocity, 180.0 * sim_delta)
				var unit_displacement: Vector2 = smoothed_velocity * sim_delta
				unit["pos"] = _move_circle_with_buildings(unit_position, unit_displacement, 8.0, sim_delta, unit_waypoint, unit_steering)
				unit["move_velocity"] = smoothed_velocity
				unit["facing"] = smoothed_velocity.normalized()
				unit["steering"] = unit_steering
			else:
				unit["move_target"] = null
				unit["manual_order"] = false
				if str(unit.get("ops_location", "")) == "INDOORS" and _milestone15_inside_outpost(unit["pos"]):
					unit["garrisoned"] = true
					unit["garrison_building"] = -1
		units[unit_index] = unit
		unit["cooldown"] = maxf(0.0, float(unit["cooldown"]) - sim_delta)
		if float(unit["cooldown"]) > 0.0 or zombies.is_empty():
			continue
		var unit_pos: Vector2 = unit["pos"]
		var unit_kind: String = str(unit["kind"])
		var is_sniper: bool = unit_kind == "sniper"
		var is_militia: bool = unit_kind == "militia"
		var is_heavy: bool = unit_kind == "heavy"
		var attack_range: float = 390.0 if is_sniper else (MILITIA_RANGE if is_militia else (235.0 if is_heavy else 205.0))
		if bool(unit.get("garrisoned", false)):
			attack_range *= 1.35
		var target_index: int = _find_unit_combat_target(unit_pos, attack_range, is_sniper)
		if target_index >= 0:
			var target_pos: Vector2 = zombies[target_index]["pos"]
			var firing_origin: Vector2 = unit_pos
			if bool(unit.get("garrisoned", false)):
				var garrison_building_index: int = int(unit.get("garrison_building", -1))
				if garrison_building_index >= 0 and garrison_building_index < buildings.size():
					var roof: Rect2 = buildings[garrison_building_index]
					var fire_direction: Vector2 = (target_pos - roof.get_center()).normalized()
					var half_extent: Vector2 = roof.size * 0.5
					var horizontal_scale: float = absf(fire_direction.x) / maxf(half_extent.x, 1.0)
					var vertical_scale: float = absf(fire_direction.y) / maxf(half_extent.y, 1.0)
					var edge_scale: float = maxf(horizontal_scale, vertical_scale)
					firing_origin = roof.get_center() + fire_direction / maxf(edge_scale, 0.001) * 0.88
			_add_bullet_tracer(firing_origin, target_pos)
			if bool(unit.get("garrisoned", false)):
				var firing_building_index: int = int(unit.get("garrison_building", -1))
				if firing_building_index >= 0 and firing_building_index < buildings.size():
					var marked_zombie: Dictionary = zombies[target_index]
					marked_zombie["siege_building"] = firing_building_index
					zombies[target_index] = marked_zombie
			var unit_rank: int = clampi(int(unit.get("rank", 0)), 0, 3)
			var combat_proficiency: float = _milestone14_citizen_multiplier(int(unit.get("survivor_id", -1)), "combat")
			if faction_doctrine == "MARTIAL LAW":
				combat_proficiency *= 1.2
			var unit_damage: float = (80.0 if is_sniper else (16.0 if is_militia else (25.0 if is_heavy else 35.0))) * combat_proficiency
			var fire_interval: float = (1.05 if is_sniper else (0.24 if is_heavy else (0.85 if is_militia else 0.62))) / ((1.0 + float(unit_rank) * 0.10) * combat_proficiency)
			if is_heavy and str(zombies[target_index].get("kind", "")) == "brute":
				var staggered_brute: Dictionary = zombies[target_index]
				staggered_brute["stagger_timer"] = maxf(float(staggered_brute.get("stagger_timer", 0.0)), 0.65)
				zombies[target_index] = staggered_brute
			if _is_near_building_type(unit_pos, "ARMORY", ARMORY_RADIUS):
				fire_interval /= 1.15
			_damage_zombie(target_index, unit_damage, unit_index, firing_origin)
			unit = units[unit_index]
			unit["cooldown"] = fire_interval
			muzzle_flashes.append({"pos": firing_origin, "life": 0.10, "max_life": 0.10})
			_queue_sfx("gunfire")
			_rebuild_zombie_spatial_grid()
		units[unit_index] = unit

	_update_wildlife(sim_delta)
	_update_work_orders(sim_delta)

	if wave >= 30 and zombies.is_empty() and pending_wave_spawns <= 0 and civilians.is_empty() and _total_sheltered_civilians() == 0 and not endless_containment:
		game_state = "victory"
		_save_operation()
		message = "SECTOR SECURED"
	elif campaign_started and game_state == "playing" and campaign_start_grace_timer <= 0.0:
		var surviving_civilians: int = civilians.size() + _total_sheltered_civilians() + saved_count
		var minimum_survivors: int = maxi(1, ceili(float(maxi(initial_civilian_count, 1)) * 0.05))
		if outposts.is_empty() or (lost_count > 0 and surviving_civilians < minimum_survivors):
			game_state = "defeat"
			message = "EVACUATION FAILED"
			_update_persistent_records()

	queue_redraw()


func _setup_city() -> void:
	_configure_sector(sector_index)

func _configure_sector(index: int) -> void:
	sector_index = clampi(index, 0, 2)
	sector_wave_limit = 30
	match sector_index:
		0:
			sector_name = "Suburban Outskirts"
		1:
			sector_name = "Medical & Urban Core"
		2:
			sector_name = "Industrial Highway"
	_generate_state_map()
	_rebuild_static_building_grid()
	starting_district_index = randi_range(0, maxi(0, district_regions.size() - 1))
	if starting_district_index < district_regions.size():
		scenario_camera_target = district_regions[starting_district_index].get_center()

func _scenario_civilian_count(district_index: int, base_count: int) -> int:
	var multiplier: float = 1.0
	match sector_index:
		0:
			multiplier = 1.45 if district_index == 1 else 0.55
		1:
			multiplier = 1.10 if district_index == 0 or district_index == 3 else 0.65
		2:
			multiplier = 1.15 if district_index == 2 or district_index == 4 else 0.55
	return maxi(8, roundi(float(base_count) * multiplier))

func _scenario_initial_zombie_count(district_index: int) -> int:
	# Seed a broad, low-intensity state-wide presence rather than a starting swarm.
	var urban_bonus: int = 2 if district_index in [0, 1, 3, 6] else 0
	var sector_bias: int = 1 if (sector_index == 1 and district_index in [0, 3]) or (sector_index == 2 and district_index in [2, 4]) else 0
	return clampi(8 + urban_bonus + sector_bias, 8, 14)

func _generate_state_map() -> void:
	buildings.clear()
	building_archetypes.clear()
	highway_segments.clear()
	secondary_road_segments.clear()
	district_regions.clear()
	spawn_districts.clear()
	district_seed_points.clear()
	campaign_map_seed = randi()
	vehicles.clear()
	highway_segments.clear()
	secondary_road_segments.clear()
	var map_rng := RandomNumberGenerator.new()
	map_rng.seed = campaign_map_seed
	for district_index in range(8):
		var district_column: int = district_index % 2
		var district_row: int = floori(float(district_index) / 2.0)
		var seed_point := Vector2((float(district_column) + 0.5) * WORLD_SIZE.x / 2.0 + map_rng.randf_range(-380.0, 380.0), (float(district_row) + 0.5) * WORLD_SIZE.y / 4.0 + map_rng.randf_range(-420.0, 420.0))
		var found_seed := false
		for attempt in range(120):
			var candidate := seed_point + Vector2(map_rng.randf_range(-280.0, 280.0), map_rng.randf_range(-300.0, 300.0))
			var candidate_size := Vector2(3600.0, 2850.0)
			var candidate_region_position := candidate - candidate_size * 0.5
			candidate_region_position.x = clampf(candidate_region_position.x, 0.0, WORLD_SIZE.x - candidate_size.x)
			candidate_region_position.y = clampf(candidate_region_position.y, 0.0, WORLD_SIZE.y - candidate_size.y)
			var candidate_region := Rect2(candidate_region_position, candidate_size)
			var spaced := true
			for existing_region in district_regions:
				if candidate_region.intersects(existing_region):
					spaced = false
					break
			if spaced:
				seed_point = candidate
				found_seed = true
				break
		if not found_seed:
			seed_point = Vector2(map_rng.randf_range(700.0, WORLD_SIZE.x - 700.0), map_rng.randf_range(700.0, WORLD_SIZE.y - 700.0))
		district_seed_points.append(seed_point)
		var region_size := Vector2(3600.0, 2850.0)
		var region_position := seed_point - region_size * 0.5
		region_position.x = clampf(region_position.x, 0.0, WORLD_SIZE.x - region_size.x)
		region_position.y = clampf(region_position.y, 0.0, WORLD_SIZE.y - region_size.y)
		var region := Rect2(region_position, region_size)
		district_regions.append(region)
		spawn_districts.append(region.grow(-150.0))
		var cell_width: float = region.size.x / 4.0
		var cell_height: float = region.size.y / 3.0
		for row in range(3):
			for column in range(4):
				if map_rng.randf() < 0.19:
					continue
				var archetype: String = _building_type_for_district(district_index, row, column)
				var width: float = map_rng.randf_range(230.0, 345.0)
				var height: float = map_rng.randf_range(230.0, 355.0)
				if archetype == "HIGHRISE":
					width = map_rng.randf_range(340.0, 405.0)
					height = map_rng.randf_range(350.0, 420.0)
				var x: float = region.position.x + float(column) * cell_width + (cell_width - width) * 0.5 + map_rng.randf_range(-42.0, 42.0)
				var y: float = region.position.y + float(row) * cell_height + (cell_height - height) * 0.5 + map_rng.randf_range(-48.0, 48.0)
				var rect := Rect2(Vector2(x, y), Vector2(width, height))
				rect.position.x = clampf(rect.position.x, region.position.x + 18.0, region.end.x - rect.size.x - 18.0)
				rect.position.y = clampf(rect.position.y, region.position.y + 18.0, region.end.y - rect.size.y - 18.0)
				var base_hp: float = 1800.0 if archetype == "HIGHRISE" else 900.0
				buildings.append(rect)
				building_archetypes.append({"type": archetype, "district": district_index, "cache_available": archetype in ["WAREHOUSE", "SUPERMARKET", "GUN_SHOP", "ARMORY", "RESIDENTIAL"], "cache_hold": 0.0, "hp": base_hp, "max_hp": base_hp, "destroyed": false, "fortified": false, "secured": false, "fortified_outpost_index": -1})
	# A valid campaign always has visible structures, even if future road-clearance
	# or district-generation rules reject every procedural candidate.
	while buildings.size() < 8:
		var fallback_index: int = buildings.size()
		var fallback_center: Vector2 = Vector2(WORLD_SIZE.x * (0.18 + float(fallback_index % 4) * 0.21), WORLD_SIZE.y * (0.12 + float(floori(float(fallback_index) / 4.0)) * 0.76))
		var fallback_rect := Rect2(fallback_center - Vector2(110.0, 100.0), Vector2(220.0, 200.0))
		buildings.append(fallback_rect)
		building_archetypes.append({"type": "RESIDENTIAL", "district": -1, "cache_available": false, "cache_hold": 0.0, "hp": 900.0, "max_hp": 900.0, "destroyed": false, "fortified": false, "secured": false, "fortified_outpost_index": -1})
	for road_index in range(3):
		var road_y: float = WORLD_SIZE.y * float(road_index + 1) / 4.0
		highway_segments.append({"from": Vector2(0.0, road_y), "to": Vector2(WORLD_SIZE.x, road_y), "width": 76.0})
	for road_index in range(2):
		var road_x: float = WORLD_SIZE.x * float(road_index + 1) / 3.0
		highway_segments.append({"from": Vector2(road_x, 0.0), "to": Vector2(road_x, WORLD_SIZE.y), "width": 68.0})
	for district_index in range(district_seed_points.size()):
		var center: Vector2 = district_seed_points[district_index]
		var nearest_road_y: float = roundf(center.y / (WORLD_SIZE.y / 4.0)) * (WORLD_SIZE.y / 4.0)
		secondary_road_segments.append({"from": Vector2(center.x, center.y), "to": Vector2(center.x, nearest_road_y), "width": 24.0})
	for vehicle_index in range(6):
		var industrial_region: Rect2 = district_regions[2]
		var humvee_pos: Vector2 = _find_vehicle_spawn_position(map_rng, industrial_region, 34.0, vehicle_index, "humvee")
		vehicles.append({"kind": "humvee", "pos": humvee_pos, "hp": 350.0, "max_hp": 350.0, "active": false, "salvage_timer": 4.0, "salvage_cost": 120, "fuel_cost": 20.0, "move_target": null, "onboard": 0, "cooldown": 0.0, "salvage_started": false})
	for helicopter_index in range(3):
		var medical_region: Rect2 = district_regions[3]
		var helicopter_pos: Vector2 = _find_vehicle_spawn_position(map_rng, medical_region, 42.0, helicopter_index, "helicopter")
		vehicles.append({"kind": "helicopter", "pos": helicopter_pos, "hp": 260.0, "max_hp": 260.0, "active": false, "salvage_timer": 4.0, "salvage_cost": 220, "fuel_cost": 55.0, "move_target": null, "onboard": 0, "cooldown": 0.0, "salvage_started": false})

func _populate_ecology() -> void:
	var ecology_rng := RandomNumberGenerator.new()
	ecology_rng.seed = abs(campaign_map_seed) + 12017
	var tree_districts: Array[int] = [1, 4, 5, 7]
	for tree_index in range(260):
		var tree_district_index: int = tree_districts[tree_index % tree_districts.size()]
		if tree_district_index >= spawn_districts.size():
			continue
		var tree_region: Rect2 = spawn_districts[tree_district_index]
		var candidate := Vector2(ecology_rng.randf_range(tree_region.position.x, tree_region.end.x), ecology_rng.randf_range(tree_region.position.y, tree_region.end.y))
		if _is_open_world_position(candidate, 20.0):
			trees.append({"pos": candidate, "alive": true, "work_timer": 3.0})
	for herd_index in range(14):
		var herd_district_index: int = 4 if herd_index % 2 == 0 else 7
		var herd_region: Rect2 = spawn_districts[herd_district_index]
		var center := Vector2(ecology_rng.randf_range(herd_region.position.x, herd_region.end.x), ecology_rng.randf_range(herd_region.position.y, herd_region.end.y))
		for animal_index in range(ecology_rng.randi_range(2, 4)):
			var animal_pos := center + Vector2(ecology_rng.randf_range(-70.0, 70.0), ecology_rng.randf_range(-70.0, 70.0))
			wildlife.append({"pos": animal_pos, "kind": "boar" if ecology_rng.randf() < 0.28 else "deer", "alive": true})
	for camp_index in range(3):
		var camp_district_index: int = 5 if camp_index % 2 == 0 else 7
		var camp_region: Rect2 = spawn_districts[camp_district_index]
		var camp_pos := Vector2(ecology_rng.randf_range(camp_region.position.x, camp_region.end.x), ecology_rng.randf_range(camp_region.position.y, camp_region.end.y))
		raider_camps.append({"pos": camp_pos, "raided": false, "food_stock": ecology_rng.randi_range(90, 160), "materials_stock": ecology_rng.randi_range(70, 130), "fuel_stock": ecology_rng.randi_range(35, 70)})

func _find_vehicle_spawn_position(map_rng: RandomNumberGenerator, region: Rect2, margin: float, spawn_index: int, kind: String) -> Vector2:
	for attempt in range(80):
		var candidate := Vector2(map_rng.randf_range(region.position.x + margin, region.end.x - margin), map_rng.randf_range(region.position.y + margin, region.end.y - margin))
		if _is_open_world_position(candidate, margin):
			return candidate
	var road_x: float = WORLD_SIZE.x * float((spawn_index % 2) + 1) / 3.0
	var road_y: float = WORLD_SIZE.y * float((spawn_index % 3) + 1) / 4.0
	var fallback := Vector2(road_x + float(spawn_index % 2) * 110.0, road_y + float(spawn_index % 3) * 90.0)
	return Vector2(clampf(fallback.x, margin, WORLD_SIZE.x - margin), clampf(fallback.y, margin, WORLD_SIZE.y - margin))

func _building_type_for_district(district_index: int, row: int, column: int) -> String:
	match district_index:
		0:
			return "GUN_SHOP" if row == 2 and column == 3 else ("SUPERMARKET" if row == 1 and column == 2 else ("HIGHRISE" if (row + column) % 4 == 0 else "RESIDENTIAL"))
		1:
			return "GUN_SHOP" if row == 2 and column == 2 else ("SUPERMARKET" if row == 0 and column == 1 else ("RESIDENTIAL" if (row + column) % 3 != 0 else "HIGHRISE"))
		2:
			return "GUN_SHOP" if column == 0 and row == 1 else ("ARMORY" if column % 4 == 0 else "WAREHOUSE")
		3:
			return "HOSPITAL" if column % 3 == 0 else "RESIDENTIAL"
		6:
			return "HOSPITAL" if column == 0 else ("HIGHRISE" if row == 1 else "RESIDENTIAL")
		7:
			return "WAREHOUSE" if column % 2 == 0 else "RESIDENTIAL"
		_:
			return "WAREHOUSE" if column % 4 == 0 else "RESIDENTIAL"

func _residential_density_bonus(region: Rect2) -> int:
	var residential_count: int = 0
	for index in range(buildings.size()):
		if _building_type_at(index) == "RESIDENTIAL" and region.intersects(buildings[index]):
			residential_count += 1
	return mini(residential_count * 2, 36)

func _building_type_at(index: int) -> String:
	if index < 0 or index >= building_archetypes.size():
		return "RESIDENTIAL"
	return str(building_archetypes[index].get("converted_to", building_archetypes[index].get("type", "RESIDENTIAL")))

func _is_near_building_type(position: Vector2, archetype: String, radius: float) -> bool:
	var radius_squared: float = radius * radius
	for index in range(buildings.size()):
		if _building_type_at(index) != archetype:
			continue
		var nearest := Vector2(clampf(position.x, buildings[index].position.x, buildings[index].end.x), clampf(position.y, buildings[index].position.y, buildings[index].end.y))
		if position.distance_squared_to(nearest) <= radius_squared:
			return true
	return false

func _update_engineer_repairs(delta: float) -> void:
	for unit_index in range(units.size()):
		var unit: Dictionary = units[unit_index]
		if str(unit.get("kind", "")) != "engineer" or bool(unit.get("garrisoned", false)):
			continue
		var repair_target: Vector2 = unit["pos"]
		var best_distance: float = 90.0 * 90.0
		var target_kind: String = ""
		var target_index: int = -1
		for index in range(outposts.size()):
			var distance: float = unit["pos"].distance_squared_to(outposts[index]["pos"])
			if distance <= best_distance and float(outposts[index].get("hp", 0.0)) < float(outposts[index].get("max_hp", 1.0)):
				best_distance = distance
				target_kind = "outpost"
				target_index = index
		for index in range(barricades.size()):
			var distance: float = unit["pos"].distance_squared_to(barricades[index]["pos"])
			if distance <= best_distance and float(barricades[index].get("hp", 0.0)) < float(barricades[index].get("max_hp", 1.0)):
				best_distance = distance
				target_kind = "wall"
				target_index = index
		for index in range(gates.size()):
			var distance: float = unit["pos"].distance_squared_to(gates[index]["pos"])
			if distance <= best_distance and float(gates[index].get("hp", 0.0)) < float(gates[index].get("max_hp", 1.0)):
				best_distance = distance
				target_kind = "gate"
				target_index = index
		for index in range(turrets.size()):
			var distance: float = unit["pos"].distance_squared_to(turrets[index]["pos"])
			if distance <= best_distance and float(turrets[index].get("hp", 0.0)) < float(turrets[index].get("max_hp", 1.0)):
				best_distance = distance
				target_kind = "turret"
				target_index = index
		if target_index < 0:
			continue
		match target_kind:
			"outpost":
				outposts[target_index]["hp"] = minf(float(outposts[target_index]["max_hp"]), float(outposts[target_index]["hp"]) + 8.0 * delta)
			"wall":
				barricades[target_index]["hp"] = minf(float(barricades[target_index]["max_hp"]), float(barricades[target_index]["hp"]) + 8.0 * delta)
			"gate":
				gates[target_index]["hp"] = minf(float(gates[target_index]["max_hp"]), float(gates[target_index]["hp"]) + 8.0 * delta)
			"turret":
				turrets[target_index]["hp"] = minf(float(turrets[target_index]["max_hp"]), float(turrets[target_index]["hp"]) + 8.0 * delta)

func _update_building_effects(delta: float) -> void:
	_update_triage(delta)
	_update_engineer_repairs(delta)
	for unit_index in range(units.size()):
		var unit: Dictionary = units[unit_index]
		var max_hp: float = float(unit.get("max_hp", 100.0))
		if food > 0 and _is_near_building_type(unit["pos"], "HOSPITAL", HOSPITAL_REGEN_RADIUS):
			unit["hp"] = minf(max_hp, float(unit.get("hp", max_hp)) + 2.0 * delta)
		if food > 0:
			var clinic_healing_rate: float = 6.0 * _milestone14_facility_medical_multiplier()
			for clinic in constructed_buildings:
				if str(clinic.get("kind", "")) == "clinic" and unit["pos"].distance_squared_to(clinic["pos"]) <= 150.0 * 150.0:
					unit["hp"] = minf(max_hp, float(unit.get("hp", max_hp)) + clinic_healing_rate * delta)
		if str(unit.get("kind", "")) == "medic" and not bool(unit.get("garrisoned", false)):
			for ally_index in range(units.size()):
				if ally_index == unit_index:
					continue
				var ally: Dictionary = units[ally_index]
				if unit["pos"].distance_squared_to(ally["pos"]) <= 110.0 * 110.0:
					ally["hp"] = minf(float(ally.get("max_hp", 100.0)), float(ally.get("hp", 100.0)) + 6.0 * delta * _milestone14_proficiency_bonus(unit, "medical"))
					for survivor_index in range(survivors.size()):
						if int(survivors[survivor_index].get("id", -2)) == int(unit.get("survivor_id", -1)):
							survivors[survivor_index]["medical_xp"] = int(survivors[survivor_index].get("medical_xp", 0)) + 1
							break
					units[ally_index] = ally
		units[unit_index] = unit
	for building_index in range(buildings.size()):
		if _building_type_at(building_index) not in ["WAREHOUSE", "SUPERMARKET", "GUN_SHOP", "ARMORY", "RESIDENTIAL"]:
			continue
		var archetype: Dictionary = building_archetypes[building_index]
		if not bool(archetype.get("cache_available", true)):
			continue
		var center: Vector2 = buildings[building_index].get_center()
		var held := false
		for unit in units:
			if center.distance_to(unit["pos"]) <= 72.0:
				held = true
				break
		var hold_time: float = float(archetype.get("cache_hold", 0.0))
		hold_time = hold_time + delta if held else 0.0
		archetype["cache_hold"] = hold_time
		if hold_time >= WAREHOUSE_HOLD_TIME:
			archetype["cache_available"] = false
			var loot_type: String = _building_type_at(building_index)
			if loot_type == "SUPERMARKET":
				food += 55
				message = "SUPERMARKET SCAVENGED +55 FOOD"
			elif loot_type == "GUN_SHOP" or loot_type == "ARMORY":
				_milestone13_loot_weapons(building_index)
				scrap += 35
				message = "WEAPON CACHE SECURED — GEAR +35 MATS"
			else:
				scrap += 100
				if randf() < 0.25:
					weapons["rifles"] = int(weapons.get("rifles", 0)) + 1
				message = "BUILDING CACHE SECURED +100 MATS"
			message_timer = 2.0
		building_archetypes[building_index] = archetype

func _outpost_gate_waypoint(position: Vector2, destination: Vector2) -> Vector2:
	for outpost_index in range(outposts.size()):
		var outpost_rect: Rect2 = outposts[outpost_index].get("rect", Rect2(outposts[outpost_index]["pos"] - Vector2(110.0, 110.0), Vector2(220.0, 220.0)))
		var starts_inside: bool = outpost_rect.has_point(position)
		var ends_inside: bool = outpost_rect.has_point(destination)
		if starts_inside == ends_inside:
			continue
		var nearest_gate_position := Vector2.ZERO
		var nearest_gate_distance := INF
		for gate in gates:
			if int(gate.get("outpost_index", -1)) != outpost_index or float(gate.get("hp", 0.0)) <= 0.0:
				continue
			var gate_position: Vector2 = gate.get("pos", Vector2.ZERO)
			var distance: float = position.distance_squared_to(gate_position)
			if distance < nearest_gate_distance:
				nearest_gate_distance = distance
				nearest_gate_position = gate_position
		if nearest_gate_distance < INF and position.distance_to(nearest_gate_position) > 24.0:
			return nearest_gate_position
	return destination

func _update_gate_states() -> void:
	for gate_index in range(gates.size()):
		var gate: Dictionary = gates[gate_index]
		var gate_position: Vector2 = gate["pos"]
		var should_open := false
		for unit in units:
			if gate_position.distance_to(unit["pos"]) <= 55.0:
				should_open = true
				break
		if not should_open:
			for civilian in civilians:
				if gate_position.distance_to(civilian) <= 55.0:
					should_open = true
					break
		gate["open"] = should_open
		gates[gate_index] = gate

func _outpost_build_cost(size: Vector2) -> int:
	var wall_segments: int = ceili((2.0 * (size.x + size.y)) / 40.0)
	return OUTPOST_COST + wall_segments * 5

func _outpost_placement_cost() -> int:
	if outpost_placement_kind == "hq":
		return 0
	if outpost_placement_kind == "expand" and outpost_expanding_index >= 0 and outpost_expanding_index < outposts.size():
		var old_rect: Rect2 = outposts[outpost_expanding_index].get("rect", outpost_placement_rect)
		var old_segments: int = ceili((2.0 * (old_rect.size.x + old_rect.size.y)) / 40.0)
		var new_segments: int = ceili((2.0 * (outpost_placement_rect.size.x + outpost_placement_rect.size.y)) / 40.0)
		return maxi(0, new_segments - old_segments) * 5
	return _outpost_build_cost(outpost_placement_rect.size)

func _outpost_placement_wood_cost() -> int:
	if outpost_placement_kind != "expand" or outpost_expanding_index < 0 or outpost_expanding_index >= outposts.size():
		return 0
	var old_rect: Rect2 = outposts[outpost_expanding_index].get("rect", outpost_placement_rect)
	var old_segments: int = ceili((2.0 * (old_rect.size.x + old_rect.size.y)) / 40.0)
	var new_segments: int = ceili((2.0 * (outpost_placement_rect.size.x + outpost_placement_rect.size.y)) / 40.0)
	return maxi(0, new_segments - old_segments) * 2

func _outpost_placement_status() -> String:
	return _outpost_placement_status_for_rect(outpost_placement_rect)

func _outpost_placement_status_for_rect(rect: Rect2) -> String:
	if not _outpost_rect_geometry_valid(rect):
		return "OVERLAPS ROAD/OUTPOST"
	if outpost_placement_kind == "hq":
		var anchored_building: bool = false
		for building_index in range(buildings.size()):
			if building_index >= building_archetypes.size():
				continue
			var building_state: Dictionary = building_archetypes[building_index]
			if bool(building_state.get("destroyed", false)):
				continue
			var building_rect: Rect2 = buildings[building_index]
			var building_area: float = building_rect.get_area()
			if building_area <= 0.0:
				continue
			var overlap_area: float = rect.intersection(building_rect).get_area()
			if overlap_area >= building_area * 0.5:
				anchored_building = true
				break
		if not anchored_building:
			return "NO BUILDING ENCLOSED"
	var initial_convoy_hq: bool = outpost_placement_kind == "hq" and outposts.is_empty()
	var required_wood: int = 0 if initial_convoy_hq else _outpost_placement_wood_cost()
	var required_scrap: int = 0 if initial_convoy_hq else _outpost_placement_cost() + (0 if outpost_placement_kind in ["hq", "expand"] else 40)
	if wood < required_wood or scrap < required_scrap:
		return "NOT ENOUGH WOOD/SCRAP"
	return "VALID"

func _outpost_rect_valid(rect: Rect2) -> bool:
	return _outpost_placement_status_for_rect(rect) == "VALID"

func _outpost_rect_geometry_valid(rect: Rect2) -> bool:
	if rect.position.x < 20.0 or rect.position.y < 20.0 or rect.end.x > WORLD_SIZE.x - 20.0 or rect.end.y > WORLD_SIZE.y - 20.0:
		return false
	if outpost_placement_kind == "hq" and outposts.is_empty():
		for segment in highway_segments:
			var highway_from: Vector2 = segment.get("from", Vector2.ZERO)
			var highway_to: Vector2 = segment.get("to", Vector2.ZERO)
			var highway_width: float = float(segment.get("width", 48.0))
			var highway_rect: Rect2 = Rect2(highway_from, highway_to - highway_from).abs().grow(highway_width * 0.5)
			if rect.intersects(highway_rect):
				return false
		return true
	var edge: float = OUTPOST_WALL_THICKNESS + 8.0
	var edge_bands: Array[Rect2] = [Rect2(rect.position, Vector2(rect.size.x, edge)), Rect2(rect.position, Vector2(edge, rect.size.y)), Rect2(Vector2(rect.end.x - edge, rect.position.y), Vector2(edge, rect.size.y)), Rect2(Vector2(rect.position.x, rect.end.y - edge), Vector2(rect.size.x, edge))]
	for index in range(buildings.size()):
		var building: Rect2 = buildings[index]
		if not rect.intersects(building) or rect.encloses(building):
			continue
		if _building_type_at(index) == "HIGHRISE":
			for edge_band in edge_bands:
				if edge_band.intersects(building):
					return false
	for outpost_index in range(outposts.size()):
		if outpost_placement_kind == "expand" and outpost_index == outpost_expanding_index:
			continue
		var other_rect: Rect2 = outposts[outpost_index].get("rect", Rect2(outposts[outpost_index]["pos"] - Vector2(110.0, 110.0), Vector2(220.0, 220.0)))
		if rect.intersects(other_rect.grow(40.0)):
			return false
	var perimeter_edge: float = OUTPOST_WALL_THICKNESS + 8.0
	var perimeter_bands: Array[Rect2] = [Rect2(rect.position, Vector2(rect.size.x, perimeter_edge)), Rect2(rect.position, Vector2(perimeter_edge, rect.size.y)), Rect2(Vector2(rect.end.x - perimeter_edge, rect.position.y), Vector2(perimeter_edge, rect.size.y)), Rect2(Vector2(rect.position.x, rect.end.y - perimeter_edge), Vector2(rect.size.x, perimeter_edge))]
	for segment in highway_segments + secondary_road_segments:
		var road_from: Vector2 = segment.get("from", Vector2.ZERO)
		var road_to: Vector2 = segment.get("to", Vector2.ZERO)
		var road_width: float = float(segment.get("width", 48.0))
		var road_rect: Rect2 = Rect2(road_from, road_to - road_from).abs().grow(road_width * 0.5 + 8.0)
		for perimeter_band in perimeter_bands:
			if road_rect.intersects(perimeter_band):
				return false
	return true
func _snap_outpost_size(size: Vector2) -> Vector2:
	return Vector2(clampf(roundf(size.x / OUTPOST_SNAP) * OUTPOST_SNAP, OUTPOST_MIN_SIZE, OUTPOST_MAX_SIZE), clampf(roundf(size.y / OUTPOST_SNAP) * OUTPOST_SNAP, OUTPOST_MIN_SIZE, OUTPOST_MAX_SIZE))


func _hq_building_capacity(building_index: int) -> int:
	if building_index < 0 or building_index >= building_archetypes.size():
		return 0
	var archetype: String = _building_type_at(building_index)
	return 8 if archetype == "HIGHRISE" else 4

func _hq_establish_button_rect() -> Rect2:
	var top: float = _safe_bottom_y(touch_target_size + 6.0)
	return Rect2(safe_insets.x + HUD_EDGE_PADDING, top, viewport_size.x - safe_insets.x - safe_insets.z - HUD_EDGE_PADDING * 2.0, touch_target_size)

func _establish_hq_from_selected_building() -> void:
	if not outposts.is_empty() or selected_hq_building_idx < 0 or selected_hq_building_idx >= buildings.size() or selected_hq_building_idx >= building_archetypes.size():
		return
	var building_state: Dictionary = building_archetypes[selected_hq_building_idx]
	if bool(building_state.get("destroyed", false)):
		selected_hq_building_idx = -1
		return
	var hq_center: Vector2 = buildings[selected_hq_building_idx].get_center()
	building_state["converted_to"] = "HEADQUARTERS"
	building_archetypes[selected_hq_building_idx] = building_state
	primary_hq_position = hq_center
	_milestone13_spawn_survivors(hq_center, selected_hq_building_idx)
	evacuation_zones.clear()
	evacuation_zones.append(hq_center)
	wood = 180
	scrap = 140
	food = 120
	fuel = 80.0
	weapons = {"rifles": 4, "snipers": 1, "heavy_mgs": 0, "medkits": 2}
	var territory_rect := Rect2(hq_center - Vector2(210.0, 210.0), Vector2(420.0, 420.0))
	territory_rect.position.x = clampf(territory_rect.position.x, 20.0, WORLD_SIZE.x - territory_rect.size.x - 20.0)
	territory_rect.position.y = clampf(territory_rect.position.y, 20.0, WORLD_SIZE.y - territory_rect.size.y - 20.0)
	outposts.append({"pos": hq_center, "rect": territory_rect, "territory_rect": territory_rect, "income_timer": OUTPOST_INCOME_INTERVAL, "safe_radius": 210.0, "vision_radius": 300.0, "command_radius": OUTPOST_COMMAND_RADIUS, "hp": 1200.0, "max_hp": 1200.0, "level": 1, "capacity": _hq_building_capacity(selected_hq_building_idx), "sheltered": 0, "evac_timer": 11.25, "rescue_beacon_timer": 0.0, "fortified_buildings": [], "is_hq": true})
	game_state = "playing"
	campaign_started = true
	campaign_start_grace_timer = 60.0
	wave_timer = 60.0
	endless_containment = true
	radio_banner_text = "COMMANDER VANCE: CONTAINMENT PROTOCOL IS LIVE. DR. ROSTOVA, CONFIRM THE HOSPITAL CHANNEL."
	radio_log.append("DAY 1 — " + radio_banner_text)
	radio_banner_timer = 7.0
	radio_day_announced = 1
	selected_hq_building_idx = -1
	message = "HEADQUARTERS ESTABLISHED — 60s PREPARATION / TERRITORY UNFORTIFIED"
	message_timer = 3.0
	_save_operation()
	queue_redraw()

func _begin_outpost_placement(world_position: Vector2, placement_kind: String) -> void:
	outpost_placement_active = true
	outpost_placement_dragging = true
	outpost_placement_gesture_mode = "resize"
	outpost_placement_kind = placement_kind
	outpost_expanding_index = -1
	outpost_placement_start = world_position
	outpost_placement_anchor = world_position
	outpost_placement_rect = Rect2(world_position, Vector2(OUTPOST_MIN_SIZE, OUTPOST_MIN_SIZE))
	_update_outpost_placement_from_anchor(world_position + Vector2(OUTPOST_MIN_SIZE, OUTPOST_MIN_SIZE))

func _begin_outpost_expansion(index: int) -> void:
	if index < 0 or index >= outposts.size():
		return
	outpost_expanding_index = index
	outpost_placement_kind = "expand"
	outpost_placement_active = true
	outpost_placement_dragging = false
	outpost_placement_rect = outposts[index].get("rect", Rect2(outposts[index].get("pos", Vector2.ZERO) - Vector2(110.0, 110.0), Vector2(220.0, 220.0)))
	outpost_placement_anchor = outpost_placement_rect.end
	outpost_placement_status = "VALID"
	outpost_placement_valid = true
	message = "DRAG A CORNER OUTWARD TO EXPAND THE PERIMETER"
	message_timer = 2.2
	queue_redraw()

func _begin_outpost_resize(world_position: Vector2) -> void:
	var corners: Array[Vector2] = [outpost_placement_rect.position, Vector2(outpost_placement_rect.end.x, outpost_placement_rect.position.y), outpost_placement_rect.end, Vector2(outpost_placement_rect.position.x, outpost_placement_rect.end.y)]
	var nearest_corner_index := 0
	var nearest_distance := INF
	for corner_index in range(corners.size()):
		var distance: float = world_position.distance_squared_to(corners[corner_index])
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_corner_index = corner_index
	var opposite_corners: Array[Vector2] = [outpost_placement_rect.end, Vector2(outpost_placement_rect.position.x, outpost_placement_rect.end.y), outpost_placement_rect.position, Vector2(outpost_placement_rect.end.x, outpost_placement_rect.position.y)]
	outpost_placement_anchor = opposite_corners[nearest_corner_index]
	outpost_placement_dragging = true
	outpost_placement_gesture_mode = "resize"
	_update_outpost_placement_from_anchor(corners[nearest_corner_index])

func _update_outpost_placement(world_position: Vector2) -> void:
	_update_outpost_placement_from_anchor(world_position)

func _update_outpost_placement_from_anchor(world_position: Vector2) -> void:
	var delta: Vector2 = world_position - outpost_placement_anchor
	var size: Vector2 = _snap_outpost_size(Vector2(absf(delta.x), absf(delta.y)))
	if outpost_placement_kind == "hq":
		size.x = minf(size.x, 560.0)
		size.y = minf(size.y, 560.0)
	var top_left := Vector2(minf(world_position.x, outpost_placement_anchor.x), minf(world_position.y, outpost_placement_anchor.y))
	outpost_placement_rect = Rect2(top_left, size)
	if outpost_placement_kind == "expand" and outpost_expanding_index >= 0 and outpost_expanding_index < outposts.size():
		var current_rect: Rect2 = outposts[outpost_expanding_index].get("rect", outpost_placement_rect)
		var merged_rect: Rect2 = outpost_placement_rect.merge(current_rect)
		var expanded_size := Vector2(minf(OUTPOST_MAX_SIZE, ceilf(merged_rect.size.x / OUTPOST_SNAP) * OUTPOST_SNAP), minf(OUTPOST_MAX_SIZE, ceilf(merged_rect.size.y / OUTPOST_SNAP) * OUTPOST_SNAP))
		outpost_placement_rect = Rect2(merged_rect.position, expanded_size)
	outpost_placement_status = _outpost_placement_status()
	var initial_convoy_hq: bool = outpost_placement_kind == "hq" and outposts.is_empty()
	outpost_placement_valid = _outpost_rect_valid(outpost_placement_rect) and (initial_convoy_hq or outpost_placement_kind == "expand" or outposts.size() < OUTPOST_MAX_COUNT + 1)
	queue_redraw()

func _confirm_outpost_placement() -> void:
	var size: Vector2 = outpost_placement_rect.size
	var initial_convoy_hq: bool = outpost_placement_kind == "hq" and outposts.is_empty()
	var cost: int = 0 if initial_convoy_hq else _outpost_placement_cost()
	var wood_cost: int = 0 if initial_convoy_hq else _outpost_placement_wood_cost()
	outpost_placement_status = _outpost_placement_status_for_rect(outpost_placement_rect)
	outpost_placement_valid = _outpost_rect_valid(outpost_placement_rect) and (initial_convoy_hq or outpost_placement_kind == "expand" or outposts.size() < OUTPOST_MAX_COUNT + 1)
	if not outpost_placement_valid:
		message = outpost_placement_status
		message_timer = 1.8
		return
	var center: Vector2 = outpost_placement_rect.get_center()
	if outpost_placement_kind == "expand":
		if outpost_expanding_index < 0 or outpost_expanding_index >= outposts.size():
			message = "OUTPOST NO LONGER AVAILABLE"
			message_timer = 1.8
			return
		var expanded_outpost: Dictionary = outposts[outpost_expanding_index]
		expanded_outpost["rect"] = outpost_placement_rect
		expanded_outpost["territory_rect"] = outpost_placement_rect
		expanded_outpost["safe_radius"] = maxf(size.x, size.y) * 0.5
		outposts[outpost_expanding_index] = expanded_outpost
		outpost_expanding_index = -1
		outpost_placement_active = false
		outpost_placement_dragging = false
		message = "TERRITORY EXPANDED FREE — OPEN BORDERS / NO WALLS BUILT"
		message_timer = 2.5
		_save_operation()
		queue_redraw()
		return
	if outpost_placement_kind == "hq":
		var anchor_index: int = -1
		var anchor_distance: float = INF
		var best_anchor_overlap: float = 0.0
		for building_index in range(buildings.size()):
			if building_index >= building_archetypes.size():
				continue
			if bool(building_archetypes[building_index].get("destroyed", false)):
				continue
			var building_rect: Rect2 = buildings[building_index]
			var building_area: float = building_rect.get_area()
			if building_area <= 0.0:
				continue
			var overlap_area: float = outpost_placement_rect.intersection(building_rect).get_area()
			if overlap_area < building_area * 0.5:
				continue
			var building_distance: float = center.distance_squared_to(building_rect.get_center())
			if overlap_area > best_anchor_overlap or (is_equal_approx(overlap_area, best_anchor_overlap) and building_distance < anchor_distance):
				best_anchor_overlap = overlap_area
				anchor_distance = building_distance
				anchor_index = building_index
		if anchor_index < 0:
			message = "NO BUILDING ENCLOSED"
			message_timer = 2.0
			return
		center = buildings[anchor_index].get_center()
		building_archetypes[anchor_index]["converted_to"] = "HEADQUARTERS"
		primary_hq_position = center
		_milestone13_spawn_survivors(center)
		evacuation_zones.clear()
		evacuation_zones.append(center)
		var hq_capacity: int = maxi(12, roundi(size.x * size.y / 18000.0))
		var hq_fortified_count: int = _fortify_enclosed_buildings(outpost_placement_rect, 0)
		outposts.append({"pos": center, "rect": outpost_placement_rect, "income_timer": OUTPOST_INCOME_INTERVAL, "safe_radius": minf(size.x, size.y) * 0.42, "vision_radius": 300.0, "command_radius": OUTPOST_COMMAND_RADIUS, "hp": 1200.0, "max_hp": 1200.0, "level": 1, "capacity": hq_capacity + hq_fortified_count * 8, "sheltered": 0, "evac_timer": 11.25, "rescue_beacon_timer": 0.0, "fortified_buildings": _fortified_building_indices(0)})
		_create_outpost_perimeter(outpost_placement_rect, 0)
		game_state = "playing"
		wave_timer = PREPARATION_SECONDS
		endless_containment = true
	else:
		var capacity: int = maxi(12, roundi(size.x * size.y / 18000.0))
		var new_outpost_index: int = outposts.size()
		var fortified_count: int = _fortify_enclosed_buildings(outpost_placement_rect, new_outpost_index)
		outposts.append({"pos": center, "rect": outpost_placement_rect, "income_timer": OUTPOST_INCOME_INTERVAL, "safe_radius": minf(size.x, size.y) * 0.42, "vision_radius": 260.0, "command_radius": OUTPOST_COMMAND_RADIUS, "hp": 900.0, "max_hp": 900.0, "level": 1, "capacity": capacity + fortified_count * 8, "sheltered": 0, "evac_timer": 11.25, "rescue_beacon_timer": 0.0, "fortified_buildings": _fortified_building_indices(new_outpost_index)})
		_create_outpost_perimeter(outpost_placement_rect, outposts.size() - 1)
	if outpost_placement_kind != "hq":
		scrap -= cost
		scrap -= 40
	if outpost_placement_kind == "hq":
		# The HQ, perimeter and evacuation zone are now registered before the campaign can tick.
		campaign_started = not outposts.is_empty() and float(outposts[0].get("hp", 0.0)) > 0.0
		campaign_start_grace_timer = PREPARATION_SECONDS
		radio_banner_text = "COMMANDER VANCE: CONTAINMENT PROTOCOL IS LIVE. DR. ROSTOVA, CONFIRM THE HOSPITAL CHANNEL."
		radio_log.append("DAY 1 — " + radio_banner_text)
		radio_banner_timer = 7.0
		radio_day_announced = 1
	outpost_placement_active = false
	outpost_placement_dragging = false
	message = "FREE CONVOY HQ ESTABLISHED" if outpost_placement_kind == "hq" else "CUSTOM OUTPOST ESTABLISHED — MATS %d" % cost
	message_timer = 2.5
	_save_operation()
	queue_redraw()

func _fortified_building_indices(outpost_index: int) -> Array[int]:
	var indices: Array[int] = []
	for building_index in range(building_archetypes.size()):
		if bool(building_archetypes[building_index].get("fortified", false)) and int(building_archetypes[building_index].get("fortified_outpost_index", -1)) == outpost_index:
			indices.append(building_index)
	return indices

func _fortify_enclosed_buildings(rect: Rect2, outpost_index: int) -> int:
	var count: int = 0
	var indices: Array[int] = []
	for building_index in range(buildings.size()):
		if not rect.encloses(buildings[building_index]):
			continue
		var state: Dictionary = building_archetypes[building_index]
		if bool(state.get("fortified", false)):
			continue
		state["fortified"] = true
		state["secured"] = true
		state["fortified_outpost_index"] = outpost_index
		state["hp"] = float(state.get("max_hp", 900.0))
		building_archetypes[building_index] = state
		indices.append(building_index)
		count += 1
	if outpost_index >= 0 and outpost_index < outposts.size():
		outposts[outpost_index]["fortified_buildings"] = indices
	return count

func _create_outpost_perimeter(rect: Rect2, outpost_index: int) -> void:
	var thickness: float = OUTPOST_WALL_THICKNESS
	var gate_width: float = 60.0
	var gate_rect := Rect2(Vector2(rect.position.x + rect.size.x * 0.5 - gate_width * 0.5, rect.end.y - thickness * 0.5), Vector2(gate_width, thickness))
	var wall_rects: Array[Rect2] = [Rect2(rect.position, Vector2(rect.size.x, thickness)), Rect2(rect.position, Vector2(thickness, rect.size.y)), Rect2(Vector2(rect.end.x - thickness, rect.position.y), Vector2(thickness, rect.size.y)), Rect2(Vector2(rect.position.x, rect.end.y - thickness), Vector2((rect.size.x - gate_width) * 0.5, thickness)), Rect2(Vector2(rect.position.x + (rect.size.x + gate_width) * 0.5, rect.end.y - thickness), Vector2((rect.size.x - gate_width) * 0.5, thickness))]
	for wall_rect in wall_rects:
		barricades.append({"pos": wall_rect.get_center(), "rect": wall_rect, "hp": 650.0, "max_hp": 650.0, "kind": "perimeter", "outpost_index": outpost_index})
	gates.append({"pos": gate_rect.get_center(), "rect": gate_rect, "hp": 500.0, "max_hp": 500.0, "open": false, "outpost_index": outpost_index})

func _snap_turret_to_outpost(position: Vector2) -> Vector2:
	var best_position: Vector2 = position
	var best_distance: float = 72.0 * 72.0
	for outpost in outposts:
		var rect: Rect2 = outpost.get("rect", Rect2(outpost["pos"] - Vector2(110.0, 110.0), Vector2(220.0, 220.0)))
		var candidates: Array[Vector2] = [Vector2(clampf(position.x, rect.position.x, rect.end.x), rect.position.y), Vector2(clampf(position.x, rect.position.x, rect.end.x), rect.end.y), Vector2(rect.position.x, clampf(position.y, rect.position.y, rect.end.y)), Vector2(rect.end.x, clampf(position.y, rect.position.y, rect.end.y)), rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]
		for candidate in candidates:
			var distance: float = position.distance_squared_to(candidate)
			if distance < best_distance:
				best_distance = distance
				best_position = candidate
	return best_position

func _try_place_gate(position: Vector2) -> bool:
	if scrap < GATE_COST or scrap < 15:
		return false
	for outpost_index in range(outposts.size()):
		var rect: Rect2 = outposts[outpost_index]["rect"]
		var nearest := Vector2(clampf(position.x, rect.position.x, rect.end.x), clampf(position.y, rect.position.y, rect.end.y))
		if nearest.distance_to(position) > 32.0:
			continue
		for wall_index in range(barricades.size() - 1, -1, -1):
			var wall: Dictionary = barricades[wall_index]
			if int(wall.get("outpost_index", -1)) != outpost_index:
				continue
			var wall_rect: Rect2 = wall.get("rect", Rect2(wall["pos"] - Vector2(15.0, 15.0), Vector2(30.0, 30.0)))
			var wall_point := Vector2(clampf(nearest.x, wall_rect.position.x, wall_rect.end.x), clampf(nearest.y, wall_rect.position.y, wall_rect.end.y))
			if wall_point.distance_to(nearest) > 24.0:
				continue
			barricades.remove_at(wall_index)
			var gate_rect: Rect2
			if wall_rect.size.x >= wall_rect.size.y:
				gate_rect = Rect2(Vector2(nearest.x - 30.0, wall_rect.position.y), Vector2(60.0, wall_rect.size.y))
				var left_width: float = gate_rect.position.x - wall_rect.position.x
				var right_start: float = gate_rect.end.x
				var right_width: float = wall_rect.end.x - right_start
				if left_width > 8.0:
					var left_rect := Rect2(wall_rect.position, Vector2(left_width, wall_rect.size.y))
					barricades.append({"pos": left_rect.get_center(), "rect": left_rect, "hp": float(wall["hp"]), "max_hp": float(wall["max_hp"]), "kind": "perimeter", "outpost_index": outpost_index})
				if right_width > 8.0:
					var right_rect := Rect2(Vector2(right_start, wall_rect.position.y), Vector2(right_width, wall_rect.size.y))
					barricades.append({"pos": right_rect.get_center(), "rect": right_rect, "hp": float(wall["hp"]), "max_hp": float(wall["max_hp"]), "kind": "perimeter", "outpost_index": outpost_index})
			else:
				gate_rect = Rect2(Vector2(wall_rect.position.x, nearest.y - 30.0), Vector2(wall_rect.size.x, 60.0))
				var top_height: float = gate_rect.position.y - wall_rect.position.y
				var bottom_start: float = gate_rect.end.y
				var bottom_height: float = wall_rect.end.y - bottom_start
				if top_height > 8.0:
					var top_rect := Rect2(wall_rect.position, Vector2(wall_rect.size.x, top_height))
					barricades.append({"pos": top_rect.get_center(), "rect": top_rect, "hp": float(wall["hp"]), "max_hp": float(wall["max_hp"]), "kind": "perimeter", "outpost_index": outpost_index})
				if bottom_height > 8.0:
					var bottom_rect := Rect2(Vector2(wall_rect.position.x, bottom_start), Vector2(wall_rect.size.x, bottom_height))
					barricades.append({"pos": bottom_rect.get_center(), "rect": bottom_rect, "hp": float(wall["hp"]), "max_hp": float(wall["max_hp"]), "kind": "perimeter", "outpost_index": outpost_index})
			gates.append({"pos": gate_rect.get_center(), "rect": gate_rect, "hp": 500.0, "max_hp": 500.0, "open": false, "outpost_index": outpost_index})
			scrap -= GATE_COST
			scrap -= 15
			_save_operation()
			return true
	return false


func _cell_for(position: Vector2) -> Vector2i:
	return Vector2i(floori(position.x / GRID_CELL_SIZE), floori(position.y / GRID_CELL_SIZE))

func _rebuild_spatial_grid(grid: Dictionary, positions: Array[Vector2]) -> void:
	# Reuse occupied buckets between frames to avoid allocating a new Dictionary
	# and new bucket Arrays for every entity-index rebuild.
	for cell_key in grid:
		var existing_bucket: Array = grid[cell_key]
		existing_bucket.clear()
	for index in range(positions.size()):
		var cell: Vector2i = _cell_for(positions[index])
		if not grid.has(cell):
			var new_bucket: Array[int] = []
			grid[cell] = new_bucket
		var entries: Array = grid[cell]
		entries.append(index)

func _rebuild_zombie_spatial_grid() -> void:
	zombie_positions.resize(zombies.size())
	for index in range(zombies.size()):
		zombie_positions[index] = zombies[index]["pos"]
	_rebuild_spatial_grid(zombie_grid, zombie_positions)

func _find_nearest_entity(grid: Dictionary, positions: Array[Vector2], origin: Vector2, radius: float) -> int:
	# Bound the cell neighborhood: lookup work stays independent of total entity count.
	var cell_radius: int = mini(ceili(radius / GRID_CELL_SIZE), 6)
	var center_cell: Vector2i = _cell_for(origin)
	var best_index := -1
	var best_distance := radius * radius
	for y in range(center_cell.y - cell_radius, center_cell.y + cell_radius + 1):
		for x in range(center_cell.x - cell_radius, center_cell.x + cell_radius + 1):
			var cell := Vector2i(x, y)
			if not grid.has(cell):
				continue
			var entries: Array = grid[cell]
			for raw_index in entries:
				var index: int = int(raw_index)
				if index >= positions.size():
					continue
				var distance: float = origin.distance_squared_to(positions[index])
				if distance < best_distance:
					best_distance = distance
					best_index = index
	return best_index

func _find_nearest_zombie(origin: Vector2, radius: float) -> int:
	return _find_nearest_entity(zombie_grid, zombie_positions, origin, radius)

func _rebuild_static_building_grid() -> void:
	static_building_grid.clear()
	for building_index in range(buildings.size()):
		if building_index < building_archetypes.size() and bool(building_archetypes[building_index].get("destroyed", false)):
			continue
		var building_rect: Rect2 = buildings[building_index]
		var minimum_cell: Vector2i = Vector2i(floori(building_rect.position.x / GRID_CELL_SIZE), floori(building_rect.position.y / GRID_CELL_SIZE))
		var maximum_cell: Vector2i = Vector2i(floori(building_rect.end.x / GRID_CELL_SIZE), floori(building_rect.end.y / GRID_CELL_SIZE))
		for cell_y in range(minimum_cell.y, maximum_cell.y + 1):
			for cell_x in range(minimum_cell.x, maximum_cell.x + 1):
				var cell_key: Vector2i = Vector2i(cell_x, cell_y)
				var cell_buildings: Array = static_building_grid.get(cell_key, [])
				cell_buildings.append(building_index)
				static_building_grid[cell_key] = cell_buildings

func _building_indices_for_rect(query_rect: Rect2) -> Array[int]:
	var result: Array[int] = []
	var seen: Dictionary = {}
	if static_building_grid.is_empty():
		for building_index in range(buildings.size()):
			if building_index < building_archetypes.size() and not bool(building_archetypes[building_index].get("destroyed", false)):
				result.append(building_index)
		return result
	var minimum_cell: Vector2i = Vector2i(floori(query_rect.position.x / GRID_CELL_SIZE), floori(query_rect.position.y / GRID_CELL_SIZE))
	var maximum_cell: Vector2i = Vector2i(floori(query_rect.end.x / GRID_CELL_SIZE), floori(query_rect.end.y / GRID_CELL_SIZE))
	for cell_y in range(minimum_cell.y, maximum_cell.y + 1):
		for cell_x in range(minimum_cell.x, maximum_cell.x + 1):
			var cell_key: Vector2i = Vector2i(cell_x, cell_y)
			var cell_buildings: Array = static_building_grid.get(cell_key, [])
			for raw_index in cell_buildings:
				var building_index: int = int(raw_index)
				if seen.has(building_index) or building_index >= building_archetypes.size() or bool(building_archetypes[building_index].get("destroyed", false)):
					continue
				seen[building_index] = true
				result.append(building_index)
	return result

func _building_index_at(position: Vector2) -> int:
	for index in range(buildings.size()):
		if bool(building_archetypes[index].get("destroyed", false)):
			continue
		if buildings[index].has_point(position):
			return index
	return -1

func _garrison_unit(unit_index: int, building_index: int, manual_order: bool = true) -> void:
	if unit_index < 0 or unit_index >= units.size() or building_index < 0 or building_index >= buildings.size():
		return
	var state: Dictionary = building_archetypes[building_index]
	if bool(state.get("destroyed", false)):
		message = "BUILDING DESTROYED — GARRISON UNAVAILABLE"
		message_timer = 1.4
		return
	var garrison_count: int = 0
	for existing_unit in units:
		if bool(existing_unit.get("garrisoned", false)) and int(existing_unit.get("garrison_building", -1)) == building_index:
			garrison_count += 1
	var capacity: int = 8 if _building_type_at(building_index) == "HIGHRISE" else 4
	if not bool(units[unit_index].get("garrisoned", false)) and garrison_count >= capacity:
		message = "BUILDING GARRISON FULL — %d/%d" % [garrison_count, capacity]
		message_timer = 1.5
		return
	var unit: Dictionary = units[unit_index]
	unit["garrisoned"] = true
	unit["garrison_building"] = building_index
	unit["manual_order"] = manual_order
	unit["ai_task"] = "GARRISON"
	unit["pos"] = buildings[building_index].get_center()
	unit.erase("move_target")
	units[unit_index] = unit
	selected_unit_index = unit_index
	message = "UNIT GARRISONED — +35% RANGE / 360° FIRE"
	message_timer = 1.8
	queue_redraw()

func _exit_unit_garrison(unit_index: int, destination: Vector2) -> void:
	if unit_index < 0 or unit_index >= units.size():
		return
	var unit: Dictionary = units[unit_index]
	var exit_position: Vector2 = destination
	if bool(unit.get("garrisoned", false)) and not _is_valid_street_position(exit_position):
		var building_index: int = int(unit.get("garrison_building", -1))
		if building_index >= 0 and building_index < buildings.size():
			var center: Vector2 = buildings[building_index].get_center()
			var found := false
			for radius in [48.0, 72.0, 100.0, 132.0]:
				for angle_index in range(8):
					var angle: float = TAU * float(angle_index) / 8.0
					var candidate: Vector2 = center + Vector2(cos(angle), sin(angle)) * radius
					if _is_valid_street_position(candidate):
						exit_position = candidate
						found = true
						break
				if found:
					break
	unit["garrisoned"] = false
	unit["garrison_building"] = -1
	unit["pos"] = exit_position
	unit.erase("move_target")
	units[unit_index] = unit

func _building_contact_index(position: Vector2, distance_limit: float) -> int:
	for index in range(buildings.size()):
		if bool(building_archetypes[index].get("destroyed", false)):
			continue
		var building: Rect2 = buildings[index]
		var nearest := Vector2(clampf(position.x, building.position.x, building.end.x), clampf(position.y, building.position.y, building.end.y))
		if position.distance_to(nearest) <= distance_limit:
			return index
	return -1

func _move_circle_with_buildings(origin: Vector2, displacement: Vector2, radius: float, delta: float, target: Vector2 = Vector2.ZERO, steering: Dictionary = {}, block_gates_for_hostiles: bool = false) -> Vector2:
	var position: Vector2 = origin
	var remaining: Vector2 = displacement
	var lock_time: float = maxf(0.0, float(steering.get("lock_time", 0.0)) - delta)
	steering["lock_time"] = lock_time
	var locked_tangent: Vector2 = steering.get("tangent", Vector2.ZERO)
	if lock_time > 0.0 and locked_tangent.length_squared() > 0.001:
		remaining = locked_tangent.normalized() * displacement.length()
	for iteration in range(2):
		var candidate: Vector2 = position + remaining
		for building_index in _building_indices_for_rect(Rect2(candidate - Vector2(radius, radius), Vector2(radius * 2.0, radius * 2.0))):
			if building_index >= building_archetypes.size() or bool(building_archetypes[building_index].get("destroyed", false)):
				continue
			var building: Rect2 = buildings[building_index]
			var closest: Vector2 = Vector2(
				clampf(candidate.x, building.position.x, building.end.x),
				clampf(candidate.y, building.position.y, building.end.y)
			)
			var offset: Vector2 = candidate - closest
			var distance: float = offset.length()
			if distance < radius:
				var normal := Vector2.ZERO
				if distance > 0.001:
					normal = offset / distance
				else:
					var left_gap: float = candidate.x - building.position.x
					var right_gap: float = building.end.x - candidate.x
					var top_gap: float = candidate.y - building.position.y
					var bottom_gap: float = building.end.y - candidate.y
					var smallest: float = minf(minf(left_gap, right_gap), minf(top_gap, bottom_gap))
					if smallest == left_gap:
						normal = Vector2.LEFT
					elif smallest == right_gap:
						normal = Vector2.RIGHT
					elif smallest == top_gap:
						normal = Vector2.UP
					else:
						normal = Vector2.DOWN
				candidate = closest + normal * radius
				var into_wall: float = remaining.dot(normal)
				if into_wall < 0.0:
					var original_progress := remaining.dot((target - position).normalized()) if target != Vector2.ZERO else 0.0
					remaining -= normal * into_wall
					var tangent_progress := remaining.dot((target - candidate).normalized()) if target != Vector2.ZERO else remaining.length()
					if target != Vector2.ZERO and original_progress > 0.0 and tangent_progress < original_progress * 0.35:
						var corners: Array[Vector2] = [
							building.position - Vector2(radius, radius),
							Vector2(building.end.x + radius, building.position.y - radius),
							building.end + Vector2(radius, radius),
							Vector2(building.position.x - radius, building.end.y + radius)
						]
						var nearest_corner := corners[0]
						var nearest_corner_distance := target.distance_squared_to(nearest_corner)
						for corner in corners:
							var corner_distance := target.distance_squared_to(corner)
							if corner_distance < nearest_corner_distance:
								nearest_corner = corner
								nearest_corner_distance = corner_distance
						var tangent := (nearest_corner - candidate).normalized()
						tangent = tangent - normal * tangent.dot(normal)
						if tangent.length_squared() > 0.001:
							if tangent.dot(target - candidate) < 0.0:
								tangent = -tangent
							remaining = tangent.normalized() * maxf(remaining.length(), displacement.length() * 0.65)
							steering["tangent"] = tangent.normalized()
							steering["lock_time"] = 0.35
		for wall in barricades:
			if float(wall.get("hp", 1.0)) <= 0.0:
				continue
			var wall_rect: Rect2 = wall.get("rect", Rect2(wall["pos"] - Vector2(15.0, 15.0), Vector2(30.0, 30.0)))
			var closest_wall := Vector2(clampf(candidate.x, wall_rect.position.x, wall_rect.end.x), clampf(candidate.y, wall_rect.position.y, wall_rect.end.y))
			var wall_offset: Vector2 = candidate - closest_wall
			if wall_offset.length() < radius:
				var wall_normal: Vector2 = wall_offset.normalized() if wall_offset.length_squared() > 0.001 else Vector2.UP
				candidate = closest_wall + wall_normal * radius
		for gate in gates:
			if float(gate.get("hp", 0.0)) <= 0.0:
				continue
			if bool(gate.get("open", false)) and not block_gates_for_hostiles:
				continue
			var gate_rect: Rect2 = gate["rect"]
			var closest_gate := Vector2(clampf(candidate.x, gate_rect.position.x, gate_rect.end.x), clampf(candidate.y, gate_rect.position.y, gate_rect.end.y))
			var gate_offset: Vector2 = candidate - closest_gate
			if gate_offset.length() < radius:
				var gate_normal: Vector2 = gate_offset.normalized() if gate_offset.length_squared() > 0.001 else Vector2.UP
				candidate = closest_gate + gate_normal * radius
		position = candidate
	return position


func _generate_city_blocks(style: int) -> Array[Rect2]:
	var result: Array[Rect2] = []
	var cell_w: float = 300.0 if style == 1 else 250.0
	var cell_h: float = 340.0 if style == 2 else 300.0
	for row in range(1, 14):
		for col in range(1, 11):
			if (row + col + style) % 5 == 0:
				continue
			var width: float = cell_w * randf_range(0.58, 0.82)
			var height: float = cell_h * randf_range(0.55, 0.80)
			var x: float = float(col) * (cell_w + 25.0) + randf_range(4.0, 18.0)
			var y: float = float(row) * (cell_h + 18.0) + randf_range(3.0, 16.0)
			if x + width < WORLD_SIZE.x - 20.0 and y + height < WORLD_SIZE.y - 20.0:
				result.append(Rect2(x, y, width, height))
	return result

func _is_open_world_position(position: Vector2, margin: float = 28.0) -> bool:
	if position.x < margin or position.x > WORLD_SIZE.x - margin or position.y < margin or position.y > WORLD_SIZE.y - margin:
		return false
	for building_index in range(buildings.size()):
		if building_index < building_archetypes.size() and bool(building_archetypes[building_index].get("destroyed", false)):
			continue
		if buildings[building_index].grow(margin).has_point(position):
			return false
	return true

func _is_vehicle_ground_position(position: Vector2) -> bool:
	if not _is_valid_street_position(position):
		return false
	for wall in barricades:
		var wall_rect: Rect2 = wall.get("rect", Rect2(wall["pos"] - Vector2(15.0, 15.0), Vector2(30.0, 30.0)))
		if wall_rect.grow(8.0).has_point(position):
			return false
	for gate in gates:
		if bool(gate.get("open", false)):
			continue
		if gate["rect"].grow(8.0).has_point(position):
			return false
	return true

func _is_valid_street_position(position: Vector2) -> bool:
	if position.x < 28.0 or position.x > WORLD_SIZE.x - 28.0 or position.y < 270.0 or position.y > WORLD_SIZE.y - 220.0:
		return false
	for building_index in range(buildings.size()):
		if building_index < building_archetypes.size() and bool(building_archetypes[building_index].get("destroyed", false)):
			continue
		var expanded: Rect2 = buildings[building_index].grow(UNIT_SELECT_RADIUS)
		if expanded.has_point(position):
			return false
	return true

func _update_combat_effects(delta: float) -> void:
	shake_timer = maxf(0.0, shake_timer - delta)
	for i in range(bullet_tracers.size() - 1, -1, -1):
		bullet_tracers[i]["life"] = float(bullet_tracers[i]["life"]) - delta
		if float(bullet_tracers[i]["life"]) <= 0.0:
			bullet_tracers.remove_at(i)
	for i in range(muzzle_flashes.size() - 1, -1, -1):
		muzzle_flashes[i]["life"] = float(muzzle_flashes[i]["life"]) - delta
		if float(muzzle_flashes[i]["life"]) <= 0.0:
			muzzle_flashes.remove_at(i)
	for i in range(shockwaves.size() - 1, -1, -1):
		var effect: Dictionary = shockwaves[i]
		effect["life"] = float(effect["life"]) - delta
		if not bool(effect.get("toxic", false)):
			effect["radius"] = minf(190.0, float(effect["radius"]) + 280.0 * delta)
		if float(effect["life"]) <= 0.0:
			shockwaves.remove_at(i)
		else:
			shockwaves[i] = effect

func _add_bullet_tracer(origin: Vector2, target: Vector2) -> void:
	bullet_tracers.append({"from": origin, "to": target, "life": 0.12, "max_life": 0.12})
	recent_gunfire.append({"pos": origin, "strength": 1.0, "life": 12.0})
	if recent_gunfire.size() > 80:
		recent_gunfire.pop_front()

func _draw_buildings() -> void:
	var visible_rect: Rect2 = _camera_view_rect().grow(120.0)
	for index in range(buildings.size()):
		var building: Rect2 = buildings[index]
		if not visible_rect.intersects(building):
			continue
		var archetype: String = _building_type_at(index)
		var state: Dictionary = building_archetypes[index] if index < building_archetypes.size() else {}
		var fill: Color = Color("#263746")
		var edge: Color = Color("#829db5")
		var tag: String = "RES"
		match archetype:
			"SUPERMARKET":
				fill = Color("#3d3a27")
				edge = Color("#e1c36b")
				tag = "MARKET"
			"HOSPITAL":
				fill = Color("#40232b")
				edge = Color("#e45b70")
				tag = "HOSP"
			"ARMORY":
				fill = Color("#40321d")
				edge = Color("#e6b44e")
				tag = "ARMORY"
			"WAREHOUSE":
				fill = Color("#3b3025")
				edge = Color("#c58b4d")
				tag = "SUPPLY"
			"HIGHRISE":
				fill = Color("#1d2e3c")
				edge = Color("#55c8d8")
				tag = "TOWER"
		if bool(state.get("destroyed", false)):
			fill = Color("#171c20")
			edge = Color("#596268")
		draw_rect(Rect2(building.position + Vector2(10.0, 12.0), building.size), Color(0.0, 0.0, 0.0, 0.34))
		draw_rect(building, fill)
		draw_rect(building, edge, false, 5.0 if archetype == "HIGHRISE" else 3.0)
		if archetype == "HIGHRISE":
			draw_rect(building.grow(-10.0), Color("#8be4ed", 0.72), false, 2.0)
			for window_index in range(1, 4):
				var window_x: float = building.position.x + building.size.x * float(window_index) / 4.0
				draw_line(Vector2(window_x, building.position.y + 15.0), Vector2(window_x, building.end.y - 15.0), Color("#7189a5"), 2.0)
		elif archetype == "HOSPITAL":
			var pad_center: Vector2 = building.get_center() + Vector2(building.size.x * 0.25, building.size.y * 0.24)
			draw_circle(pad_center, 30.0, Color("#283a3a"))
			draw_circle(pad_center, 30.0, Color("#b6d7d2"), false, 2.0)
			_draw_text("H", pad_center + Vector2(-9.0, 9.0), 24, Color("#e8f7f2"))
			var center: Vector2 = building.get_center() + Vector2(0.0, -42.0)
			draw_rect(Rect2(center - Vector2(20.0, 6.0), Vector2(40.0, 12.0)), Color("#fff4f5"))
			draw_rect(Rect2(center - Vector2(6.0, 20.0), Vector2(12.0, 40.0)), Color("#fff4f5"))
		elif archetype == "ARMORY":
			draw_line(building.position + Vector2(20.0, 20.0), building.end - Vector2(20.0, 20.0), edge, 5.0)
		elif archetype == "GUN_SHOP":
			draw_rect(building.grow(-12.0), Color("#a66bd0", 0.20), false, 5.0)
			_draw_text("GUNS // ARMAMENTS", building.position + Vector2(18.0, 46.0), 13, Color("#f0d9ff"))
			if bool(state.get("cache_available", false)):
				_draw_text("GEAR CACHE", building.get_center() + Vector2(-40.0, 12.0), 11, Color("#f0d9ff"))
		elif archetype == "SUPERMARKET":
			var market_sign: Rect2 = Rect2(building.position + Vector2(20.0, 20.0), Vector2(building.size.x - 40.0, 28.0))
			draw_rect(market_sign, Color("#e1c36b"))
			_draw_text("FOOD MARKET", market_sign.position + Vector2(12.0, 20.0), 13, Color("#29271d"))
			if bool(state.get("cache_available", false)):
				_draw_text("+55 FOOD", building.get_center() + Vector2(-34.0, 12.0), 12, Color("#fff0b0"))
		elif archetype == "WAREHOUSE":
			for stripe in range(1, 4):
				var stripe_x: float = building.position.x + building.size.x * float(stripe) / 4.0
				draw_line(Vector2(stripe_x, building.position.y + 18.0), Vector2(stripe_x, building.end.y - 18.0), edge, 3.0)
			if bool(state.get("cache_available", false)):
				var cache_center: Vector2 = building.get_center()
				draw_rect(Rect2(cache_center - Vector2(14.0, 14.0), Vector2(28.0, 28.0)), Color("#d8b65b"))
				_draw_text("MATS", cache_center + Vector2(-15.0, 5.0), 13, Color("#fff0b0"))
		if archetype != "HOSPITAL":
			for vent_index in range(3):
				var vent_pos: Vector2 = building.position + Vector2(26.0 + float(vent_index) * 34.0, 30.0)
				draw_rect(Rect2(vent_pos, Vector2(16.0, 12.0)), Color("#17221f"))
				draw_rect(Rect2(vent_pos, Vector2(16.0, 12.0)), edge, false, 1.5)
		var tag_size: int = 18 if building.size.x > 300.0 else 15
		var tag_width: float = screen_font.get_string_size(tag, HORIZONTAL_ALIGNMENT_LEFT, -1.0, tag_size).x if screen_font != null else 70.0
		if screen_font != null:
			draw_string(screen_font, Vector2(building.get_center().x - tag_width * 0.5, building.get_center().y + 6.0), tag, HORIZONTAL_ALIGNMENT_LEFT, -1.0, tag_size, Color("#f5f8f2"))
		if bool(state.get("fortified", false)):
			draw_rect(building.grow(-7.0), Color("#53e89b"), false, 4.0)

func _next_unit_id() -> int:
	var highest_id: int = 0
	for existing_unit in units:
		highest_id = maxi(highest_id, int(existing_unit.get("id", 0)))
	return highest_id + 1

func _best_recruitment_outpost() -> int:
	var best_index: int = -1
	var best_discount: bool = false
	for index in range(outposts.size()):
		if int(outposts[index].get("sheltered", 0)) <= 0:
			continue
		var discounted: bool = _is_near_building_type(outposts[index]["pos"], "ARMORY", ARMORY_RADIUS)
		if best_index < 0 or (discounted and not best_discount):
			best_index = index
			best_discount = discounted
	return best_index

func _outpost_recruit_spawn(outpost_index: int, fallback: Vector2) -> Vector2:
	if outpost_index < 0 or outpost_index >= outposts.size():
		return fallback + Vector2(28.0, 0.0)
	for gate in gates:
		if int(gate.get("outpost_index", -1)) == outpost_index:
			return gate["rect"].get_center() + Vector2(0.0, 20.0)
	return outposts[outpost_index]["pos"] + Vector2(0.0, 118.0)

func _recruit_unit(kind: String) -> void:
	if selected_survivor_index < 0 or selected_survivor_index >= survivors.size():
		message = "SELECT ONE OF THE 18 SURVIVORS FIRST"
		message_timer = 2.0
		return
	var role: String = kind.to_upper()
	var weapon_key: String = "rifles" if kind == "infantry" else ("snipers" if kind == "sniper" else ("heavy_mgs" if kind == "heavy" else ("medkits" if kind == "medic" else "")))
	var survivor: Dictionary = survivors[selected_survivor_index]
	var previous_weapon: String = str(survivor.get("equipped_weapon", ""))
	if not weapon_key.is_empty() and int(weapons.get(weapon_key, 0)) <= 0:
		message = "NO " + weapon_key.to_upper() + " IN STOCKPILE"
		message_timer = 2.0
		return
	if not previous_weapon.is_empty():
		weapons[previous_weapon] = int(weapons.get(previous_weapon, 0)) + 1
	if not weapon_key.is_empty():
		weapons[weapon_key] = int(weapons.get(weapon_key, 0)) - 1
	survivor["role"] = role
	survivor["equipped_weapon"] = weapon_key
	survivors[selected_survivor_index] = survivor
	for unit_index in range(units.size()):
		if int(units[unit_index].get("survivor_id", -1)) == int(survivor.get("id", -1)):
			units[unit_index]["kind"] = kind
			selected_unit_index = unit_index
			break
	message = str(survivor.get("name", "SURVIVOR")) + " ASSIGNED " + role + " — XP / RANK PRESERVED"
	message_timer = 2.0
	_save_operation()

func _ai_button_rect() -> Rect2:
	return Rect2(Vector2(safe_insets.x + 390.0, safe_insets.y + 196.0), Vector2(140.0, touch_target_size))

func _recruit_button_rect(index: int) -> Rect2:
	return Rect2(Vector2(safe_insets.x + 390.0, safe_insets.y + 196.0 + float(index + 1) * (touch_target_size + 6.0)), Vector2(140.0, touch_target_size))

func _engineer_button_rect() -> Rect2:
	return Rect2(Vector2(safe_insets.x + 390.0, safe_insets.y + 196.0 + 3.0 * (touch_target_size + 6.0)), Vector2(140.0, touch_target_size))

func _salvage_button_rect() -> Rect2:
	return Rect2(Vector2(safe_insets.x + 390.0, safe_insets.y + 196.0 + 4.0 * (touch_target_size + 6.0)), Vector2(140.0, touch_target_size))

func _segment_intersects_rect(segment_start: Vector2, segment_end: Vector2, rect: Rect2) -> bool:
	# Liang-Barsky clipping: test the finite segment against the rectangle bounds.
	var direction: Vector2 = segment_end - segment_start
	var t_min: float = 0.0
	var t_max: float = 1.0
	for axis in range(2):
		var start_coord: float = segment_start.x if axis == 0 else segment_start.y
		var delta_coord: float = direction.x if axis == 0 else direction.y
		var min_coord: float = rect.position.x if axis == 0 else rect.position.y
		var max_coord: float = rect.end.x if axis == 0 else rect.end.y
		if absf(delta_coord) < 0.000001:
			if start_coord < min_coord or start_coord > max_coord:
				return false
			continue
		var t1: float = (min_coord - start_coord) / delta_coord
		var t2: float = (max_coord - start_coord) / delta_coord
		if t1 > t2:
			var swap_value: float = t1
			t1 = t2
			t2 = swap_value
		t_min = maxf(t_min, t1)
		t_max = minf(t_max, t2)
		if t_min > t_max:
			return false
	return true

func _has_clear_building_line_of_sight(origin: Vector2, target: Vector2) -> bool:
	var segment_rect: Rect2 = Rect2(origin, target - origin).abs().grow(1.0)
	for building_index in _building_indices_for_rect(segment_rect):
		if building_index >= building_archetypes.size() or bool(building_archetypes[building_index].get("destroyed", false)):
			continue
		var building_rect: Rect2 = buildings[building_index]
		if building_rect.has_point(origin):
			continue
		if _segment_intersects_rect(origin, target, building_rect):
			return false
	return true

func _milestone17_find_turret_target(turret: Dictionary, attack_range: float) -> int:
	var turret_position: Vector2 = turret.get("pos", Vector2.ZERO)
	var turret_kind: String = str(turret.get("kind", "machine_gun")).to_lower()
	var best_target_index: int = -1
	var best_score: float = -INF
	var maximum_distance_squared: float = attack_range * attack_range
	for target_index in range(zombies.size()):
		var zombie: Dictionary = zombies[target_index]
		var target_position: Vector2 = zombie.get("pos", Vector2.ZERO)
		var distance_squared: float = turret_position.distance_squared_to(target_position)
		if distance_squared > maximum_distance_squared:
			continue
		if not _has_clear_building_line_of_sight(turret_position, target_position):
			continue
		var zombie_kind: String = str(zombie.get("kind", "shambler")).to_lower()
		var threat_weight: float = 1.0
		if zombie_kind in ["brute", "spitter"]:
			threat_weight = 4.0
		elif zombie_kind in ["raider", "hostile_raider", "hostile raider"]:
			threat_weight = 3.5
		elif zombie_kind in ["runner", "fast"]:
			threat_weight = 2.5
		var role_weight: float = 1.0
		if turret_kind == "sniper_tower":
			role_weight = 1.35 if zombie_kind in ["brute", "spitter", "raider", "hostile_raider"] else 0.85
		elif turret_kind == "machine_gun":
			role_weight = 1.2 if zombie_kind in ["runner", "fast"] else 1.0
		var score: float = threat_weight * role_weight * 100000.0 - distance_squared - float(target_index) * 0.001
		if score > best_score:
			best_score = score
			best_target_index = target_index
	return best_target_index

func _find_unit_combat_target(position: Vector2, attack_range: float, sniper: bool) -> int:
	var best_target_index: int = -1
	var best_score: float = -INF
	var maximum_distance_squared: float = attack_range * attack_range
	for target_idx in range(zombies.size()):
		var zombie: Dictionary = zombies[target_idx]
		var target_position: Vector2 = zombie.get("pos", Vector2.ZERO)
		var dist_sq: float = position.distance_squared_to(target_position)
		if dist_sq > maximum_distance_squared or not _has_clear_building_line_of_sight(position, target_position):
			continue
		var zombie_kind: String = str(zombie.get("kind", "")).to_lower()
		var threat_weight: float = 1.0
		if zombie_kind in ["brute", "spitter"]:
			threat_weight = 3.0
		elif zombie_kind in ["raider", "hostile_raider", "hostile raider"]:
			threat_weight = 2.0
		var score: float = (threat_weight * 100000.0) - dist_sq - (float(target_idx) * 0.001)
		if score > best_score:
			best_score = score
			best_target_index = target_idx
	return best_target_index

func _update_auto_ops(delta: float) -> void:
	if delta <= 0.0 or not auto_ops_enabled:
		return
	var reserved_civilians: Array[Vector2] = []
	var reserved_caches: Array[int] = []
	var reserved_crates: Array[int] = []
	for unit_index in range(units.size()):
		var unit: Dictionary = units[unit_index]
		if bool(unit.get("garrisoned", false)) or bool(unit.get("manual_order", false)):
			continue
		var position: Vector2 = unit["pos"]
		var task: String = str(unit.get("ai_task", ""))
		var move_target: Variant = unit.get("move_target", null)
		if bool(unit.get("carrying_civilian", false)):
			var destination_outpost: int = _nearest_outpost_index(position)
			if destination_outpost >= 0:
				var gate_position: Vector2 = _nearest_outpost_gate_position(destination_outpost, position)
				if position.distance_to(gate_position) <= 32.0:
					var shelter_capacity: int = int(outposts[destination_outpost].get("capacity", 20))
					outposts[destination_outpost]["sheltered"] = mini(shelter_capacity, int(outposts[destination_outpost].get("sheltered", 0)) + 1)
					unit["carrying_civilian"] = false
					unit["move_target"] = null
					unit["ai_task"] = ""
					world_callouts.append({"pos": gate_position, "text": "CIVILIAN SECURED", "life": 1.8})
				else:
					unit["move_target"] = gate_position
					unit["ai_task"] = "ESCORT"
			units[unit_index] = unit
			continue
		if move_target is Vector2 and position.distance_to(move_target) > 22.0:
			if task == "ESCORT":
				var reserved_position: Vector2 = unit.get("ai_target_pos", move_target)
				reserved_civilians.append(reserved_position)
			elif task == "SCAVENGE":
				reserved_caches.append(int(unit.get("ai_target_index", -1)))
			elif task == "SUPPLY":
				reserved_crates.append(int(unit.get("ai_target_index", -1)))
			continue
		if task == "ESCORT":
			var civilian_pickup := _nearest_civilian_to(position, 34.0)
			if civilian_pickup >= 0:
				civilians.remove_at(civilian_pickup)
				if civilian_pickup < civilian_steering.size():
					civilian_steering.remove_at(civilian_pickup)
				_rebuild_spatial_grid(civilian_grid, civilians)
				unit["carrying_civilian"] = true
				unit["move_target"] = null
				unit["ai_task"] = "ESCORT"
				units[unit_index] = unit
				continue
		if task == "SCAVENGE":
			var cache_index: int = int(unit.get("ai_target_index", -1))
			if cache_index >= 0 and cache_index < buildings.size():
				var cache_state: Dictionary = building_archetypes[cache_index]
				if bool(cache_state.get("cache_available", false)) and position.distance_to(buildings[cache_index].get_center()) <= 72.0:
					cache_state["cache_available"] = false
					building_archetypes[cache_index] = cache_state
					if _building_type_at(cache_index) == "SUPERMARKET":
						food += 55
						world_callouts.append({"pos": buildings[cache_index].get_center(), "text": "+55 FOOD", "life": 2.0})
					elif _building_type_at(cache_index) in ["GUN_SHOP", "ARMORY"]:
						_milestone13_loot_weapons(cache_index)
						scrap += 35
						world_callouts.append({"pos": buildings[cache_index].get_center(), "text": "WEAPON +35 MATS", "life": 2.0})
					else:
						scrap += 100
						if randf() < 0.22:
							weapons["rifles"] = int(weapons.get("rifles", 0)) + 1
						world_callouts.append({"pos": buildings[cache_index].get_center(), "text": "+100 MATS / RIFLE", "life": 2.0})
					unit["ai_task"] = ""
					unit["move_target"] = null
					units[unit_index] = unit
					continue
		if task == "CHOP" or task == "HUNT":
			if str(unit.get("work_kind", "")) != ("chop" if task == "CHOP" else "hunt"):
				unit["work_kind"] = "chop" if task == "CHOP" else "hunt"
				unit["work_target_index"] = int(unit.get("ai_target_index", -1))
				unit["work_timer"] = 3.0
			units[unit_index] = unit
			continue
		if task == "SUPPLY":
			var crate_index: int = int(unit.get("ai_target_index", -1))
			if crate_index >= 0 and crate_index < supply_crates.size() and position.distance_to(supply_crates[crate_index]["pos"]) <= 30.0:
				scrap += 80
				scrap += 15
				fuel = minf(300.0, fuel + 15.0)
				world_callouts.append({"pos": supply_crates[crate_index]["pos"], "text": "+MATS / ⚙15", "life": 2.0})
				supply_crates.remove_at(crate_index)
				unit["ai_task"] = ""
				unit["move_target"] = null
				units[unit_index] = unit
				continue
		unit["ai_task"] = ""
		unit["move_target"] = null
		var next_task := ""
		var next_target := position
		if str(unit.get("kind", "")) == "infantry" and float(unit.get("hp", 100.0)) / maxf(float(unit.get("max_hp", 100.0)), 1.0) < 0.25:
			var retreat_index: int = _nearest_outpost_index(position)
			if retreat_index >= 0:
				next_target = _nearest_outpost_gate_position(retreat_index, position)
				next_task = "RETREAT"
		if next_task.is_empty() and str(unit.get("kind", "")) == "engineer":
			var repair_position: Vector2 = _nearest_damaged_structure(position, 650.0)
			if repair_position.x >= 0.0:
				next_target = repair_position
				next_task = "REPAIR"
		if next_task.is_empty():
			var rescue_index: int = _nearest_unreserved_civilian(position, 500.0, reserved_civilians)
			if rescue_index >= 0:
				next_target = civilians[rescue_index]
				next_task = "ESCORT"
				unit["ai_target_pos"] = next_target
				reserved_civilians.append(next_target)
		if next_task.is_empty():
			var warehouse_index: int = _nearest_unreserved_warehouse(position, 500.0, reserved_caches)
			if warehouse_index >= 0:
				next_target = buildings[warehouse_index].get_center()
				next_task = "SCAVENGE"
				unit["ai_target_index"] = warehouse_index
				reserved_caches.append(warehouse_index)
		if next_task.is_empty():
			var crate_index: int = _nearest_unreserved_crate(position, 420.0, reserved_crates)
			if crate_index >= 0:
				next_target = supply_crates[crate_index]["pos"]
				next_task = "SUPPLY"
				unit["ai_target_index"] = crate_index
				reserved_crates.append(crate_index)
		if next_task.is_empty() and (str(unit.get("kind", "")) == "infantry" or str(unit.get("kind", "")) == "sniper"):
			var animal_index: int = _nearest_wildlife(position, 500.0)
			if animal_index >= 0:
				next_target = wildlife[animal_index]["pos"]
				next_task = "HUNT"
				unit["ai_target_index"] = animal_index
		if next_task.is_empty():
			var tree_index: int = _nearest_tree(position, 500.0)
			if tree_index >= 0:
				next_target = trees[tree_index]["pos"]
				next_task = "CHOP"
				unit["ai_target_index"] = tree_index
		if next_task.is_empty() and _zombies_nearby(position, 260.0):
			var shelter_index: int = _nearest_intact_building(position, 180.0)
			if shelter_index >= 0 and _building_garrison_count(shelter_index) < (8 if _building_type_at(shelter_index) == "HIGHRISE" else 4):
				_garrison_unit(unit_index, shelter_index, false)
				continue
		if not next_task.is_empty():
			unit["ai_task"] = next_task
			if position.distance_to(next_target) > 24.0:
				unit["move_target"] = next_target
			elif next_task == "CHOP" or next_task == "HUNT":
				unit["work_kind"] = "chop" if next_task == "CHOP" else "hunt"
				unit["work_target_index"] = int(unit.get("ai_target_index", -1))
				unit["work_timer"] = 3.0
		units[unit_index] = unit

func _nearest_outpost_gate_position(outpost_index: int, from_position: Vector2) -> Vector2:
	var best_position: Vector2 = outposts[outpost_index]["pos"]
	var best_distance: float = INF
	for gate in gates:
		if int(gate.get("outpost_index", -1)) != outpost_index or float(gate.get("hp", 0.0)) <= 0.0:
			continue
		var gate_position: Vector2 = gate["pos"]
		var distance: float = from_position.distance_squared_to(gate_position)
		if distance < best_distance:
			best_distance = distance
			best_position = gate_position
	return best_position

func _nearest_civilian_to(position: Vector2, radius: float) -> int:
	var best_index := -1
	var best_distance: float = radius * radius
	for index in range(civilians.size()):
		var distance: float = position.distance_squared_to(civilians[index])
		if distance < best_distance:
			best_distance = distance
			best_index = index
	return best_index

func _nearest_unreserved_civilian(position: Vector2, radius: float, reserved: Array[Vector2]) -> int:
	var best_index := -1
	var best_distance: float = radius * radius
	for index in range(civilians.size()):
		var candidate: Vector2 = civilians[index]
		var taken := false
		for reserved_position in reserved:
			if candidate.distance_squared_to(reserved_position) <= 42.0 * 42.0:
				taken = true
				break
		if taken:
			continue
		var distance: float = position.distance_squared_to(candidate)
		if distance < best_distance:
			best_distance = distance
			best_index = index
	return best_index

func _nearest_unreserved_warehouse(position: Vector2, radius: float, reserved: Array[int]) -> int:
	var best_index := -1
	var best_distance: float = radius * radius
	for index in range(buildings.size()):
		if _building_type_at(index) not in ["WAREHOUSE", "SUPERMARKET", "GUN_SHOP", "ARMORY", "RESIDENTIAL"] or index in reserved or not bool(building_archetypes[index].get("cache_available", false)):
			continue
		var distance: float = position.distance_squared_to(buildings[index].get_center())
		if distance < best_distance:
			best_distance = distance
			best_index = index
	return best_index

func _nearest_unreserved_crate(position: Vector2, radius: float, reserved: Array[int]) -> int:
	var best_index := -1
	var best_distance: float = radius * radius
	for index in range(supply_crates.size()):
		if index in reserved:
			continue
		var distance: float = position.distance_squared_to(supply_crates[index]["pos"])
		if distance < best_distance:
			best_distance = distance
			best_index = index
	return best_index

func _nearest_damaged_structure(position: Vector2, radius: float) -> Vector2:
	var best_position := Vector2(-1.0, -1.0)
	var best_distance: float = radius * radius
	for structure in outposts:
		if float(structure.get("hp", 0.0)) >= float(structure.get("max_hp", 1.0)):
			continue
		var distance: float = position.distance_squared_to(structure["pos"])
		if distance < best_distance:
			best_distance = distance
			best_position = structure["pos"]
	for structure in barricades:
		if float(structure.get("hp", 0.0)) >= float(structure.get("max_hp", 1.0)):
			continue
		var distance: float = position.distance_squared_to(structure["pos"])
		if distance < best_distance:
			best_distance = distance
			best_position = structure["pos"]
	for structure in gates:
		if float(structure.get("hp", 0.0)) >= float(structure.get("max_hp", 1.0)):
			continue
		var distance: float = position.distance_squared_to(structure["pos"])
		if distance < best_distance:
			best_distance = distance
			best_position = structure["pos"]
	for structure in turrets:
		if float(structure.get("hp", 0.0)) >= float(structure.get("max_hp", 1.0)):
			continue
		var distance: float = position.distance_squared_to(structure["pos"])
		if distance < best_distance:
			best_distance = distance
			best_position = structure["pos"]
	return best_position



func _nearest_outpost_index(position: Vector2) -> int:
	var best: int = -1
	var best_distance: float = INF
	for index in range(outposts.size()):
		var distance: float = position.distance_squared_to(outposts[index]["pos"])
		if distance < best_distance:
			best_distance = distance
			best = index
	return best

func _nearest_unescorted_civilian(position: Vector2, radius: float) -> int:
	var best: int = -1
	var best_distance: float = radius * radius
	for index in range(civilians.size()):
		var distance: float = position.distance_squared_to(civilians[index])
		if distance <= best_distance:
			best_distance = distance
			best = index
	return best

func _nearest_supply_crate(position: Vector2, radius: float) -> int:
	var best: int = -1
	var best_distance: float = radius * radius
	for index in range(supply_crates.size()):
		var distance: float = position.distance_squared_to(supply_crates[index]["pos"])
		if distance <= best_distance:
			best_distance = distance
			best = index
	return best

func _zombies_nearby(position: Vector2, radius: float) -> bool:
	for zombie in zombies:
		if position.distance_squared_to(zombie["pos"]) <= radius * radius:
			return true
	return false

func _nearest_intact_building(position: Vector2, radius: float) -> int:
	var best: int = -1
	var best_distance: float = radius * radius
	for index in range(buildings.size()):
		if bool(building_archetypes[index].get("destroyed", false)):
			continue
		var distance: float = position.distance_squared_to(buildings[index].get_center())
		if distance <= best_distance:
			best_distance = distance
			best = index
	return best

func _building_garrison_count(building_index: int) -> int:
	var count: int = 0
	for unit in units:
		if bool(unit.get("garrisoned", false)) and int(unit.get("garrison_building", -1)) == building_index:
			count += 1
	return count

func _unit_near_vehicle_kind(position: Vector2, kind: String, radius: float) -> bool:
	for unit in units:
		if str(unit.get("kind", "")) == kind and not bool(unit.get("garrisoned", false)) and unit["pos"].distance_to(position) <= radius:
			return true
	return false

func _salvage_nearest_vehicle() -> void:
	var best_index: int = -1
	var best_distance: float = 75.0 * 75.0
	for index in range(vehicles.size()):
		if bool(vehicles[index].get("active", false)):
			continue
		for unit in units:
			if not bool(unit.get("garrisoned", false)):
				var distance: float = unit["pos"].distance_squared_to(vehicles[index]["pos"])
				if distance <= best_distance:
					best_distance = distance
					best_index = index
	if best_index < 0:
		message = "SQUAD MUST HOLD WITHIN 75M OF VEHICLE"
		message_timer = 1.8
		return
	var vehicle: Dictionary = vehicles[best_index]
	if scrap < int(vehicle.get("salvage_cost", 0)) or fuel < float(vehicle.get("fuel_cost", 0.0)):
		message = "SALVAGE REQUIRES %d MATS + %.0f FUEL" % [int(vehicle.get("salvage_cost", 0)), float(vehicle.get("fuel_cost", 0.0))]
		message_timer = 1.5
		return
	var engineer_salvage: bool = _unit_near_vehicle_kind(vehicle["pos"], "engineer", 75.0)
	var salvage_duration: float = 4.0
	vehicle["salvage_started"] = true
	vehicle["salvage_duration"] = salvage_duration
	vehicle["salvage_timer"] = salvage_duration
	vehicles[best_index] = vehicle
	message = "ENGINEER SALVAGE — HOLD 2.0S" if engineer_salvage else "SALVAGE CREW DEPLOYED — HOLD 4.0S"
	message_timer = 1.8

func _update_vehicles(delta: float) -> void:
	for index in range(vehicles.size()):
		var vehicle: Dictionary = vehicles[index]
		var position: Vector2 = vehicle["pos"]
		var helicopter: bool = str(vehicle.get("kind", "")) == "helicopter"
		if bool(vehicle.get("active", false)):
			var at_refuel_outpost := false
			for refuel_outpost in outposts:
				if position.distance_to(refuel_outpost["pos"]) <= 115.0:
					at_refuel_outpost = true
					break
			if at_refuel_outpost and vehicle.get("move_target", null) == null:
				fuel = minf(300.0, fuel + delta * 5.0)
			else:
				fuel = maxf(0.0, fuel - (1.5 if helicopter else 0.8) * delta)
			vehicle["grounded"] = fuel <= 0.0
		if not bool(vehicle.get("active", false)):
			if bool(vehicle.get("salvage_started", false)):
				var holding_unit := false
				var engineer_present := false
				for unit in units:
					if bool(unit.get("garrisoned", false)) or unit["pos"].distance_to(position) > 75.0:
						continue
					holding_unit = true
					if str(unit.get("kind", "")) == "engineer":
						engineer_present = true
				if holding_unit:
					vehicle["salvage_timer"] = maxf(0.0, float(vehicle.get("salvage_timer", 4.0)) - delta * (2.0 if engineer_present else 1.0))
					if float(vehicle["salvage_timer"]) <= 0.0 and scrap >= int(vehicle.get("salvage_cost", 0)) and fuel >= float(vehicle.get("fuel_cost", 0.0)):
						scrap -= int(vehicle.get("salvage_cost", 0))
						fuel -= float(vehicle.get("fuel_cost", 0.0))
						scrap += 15
						vehicle["active"] = true
						vehicle["salvage_started"] = false
						message = "VEHICLE RESTORED"
						message_timer = 2.0
						world_callouts.append({"pos": position, "text": "RESTORED", "life": 2.2})
				else:
					vehicle["salvage_timer"] = 4.0
		else:
			var speed: float = 280.0 if helicopter else 145.0
			if fuel > 0.0 and fuel <= 30.0:
				speed *= 0.5
			if bool(vehicle.get("grounded", false)):
				speed = 0.0
			var moved := false
			var target_value: Variant = vehicle.get("move_target", null)
			if int(vehicle.get("onboard", 0)) > 0 and not (target_value is Vector2):
				var destination_outpost: int = _nearest_outpost_index(position)
				if destination_outpost >= 0:
					vehicle["move_target"] = _nearest_outpost_gate_position(destination_outpost, position)
					target_value = vehicle["move_target"]
			if target_value is Vector2:
				var target: Vector2 = target_value
				var next_position: Vector2 = position.move_toward(target, speed * delta)
				if helicopter or _is_vehicle_ground_position(next_position):
					moved = next_position.distance_squared_to(position) > 0.01
					if moved:
						vehicle["facing"] = (target - position).normalized()
					position = next_position
					vehicle["pos"] = position
				if position.distance_to(target) <= 24.0:
					vehicle["move_target"] = null
					if int(vehicle.get("onboard", 0)) > 0:
						var arrival_outpost: int = _nearest_outpost_index(position)
						if arrival_outpost >= 0 and position.distance_to(_nearest_outpost_gate_position(arrival_outpost, position)) <= 55.0:
							var rescued: int = int(vehicle["onboard"])
							vehicle["onboard"] = 0
							saved_count += rescued
							_milestone14_award_rescue_standing(position)
							scrap += rescued * 35
							world_callouts.append({"pos": position, "text": "+MATS %d" % (rescued * 35), "life": 2.0})
							message = "VEHICLE EVACUATION — %d CIVILIANS" % rescued
							message_timer = 2.0
			if not helicopter and moved:
				var track_timer: float = maxf(0.0, float(vehicle.get("track_timer", 0.0)) - delta)
				if track_timer <= 0.0:
					var track_direction: Vector2 = vehicle.get("facing", Vector2.UP)
					var track_side: Vector2 = track_direction.orthogonal() * 10.0
					_add_tactical_decal(position - track_side, track_direction)
					_add_tactical_decal(position + track_side, track_direction)
					track_timer = 0.35
				vehicle["track_timer"] = track_timer
			var pickup_count: int = int(vehicle.get("onboard", 0))
			if pickup_count < 6:
				for civilian_index in range(civilians.size() - 1, -1, -1):
					if position.distance_to(civilians[civilian_index]) <= (62.0 if helicopter else 42.0):
						civilians.remove_at(civilian_index)
						if civilian_index < civilian_steering.size():
							civilian_steering.remove_at(civilian_index)
						pickup_count += 1
						if pickup_count >= 6:
							break
			vehicle["onboard"] = pickup_count
			if not helicopter and moved and speed >= 90.0:
				for zombie_index in range(zombies.size() - 1, -1, -1):
					if position.distance_to(zombies[zombie_index]["pos"]) <= 34.0:
						var hit_zombie: Dictionary = zombies[zombie_index]
						var knockback: Vector2 = (hit_zombie["pos"] - position).normalized()
						hit_zombie["pos"] = position + knockback * 46.0
						hit_zombie["hp"] = float(hit_zombie.get("hp", 30.0)) - 45.0
						if float(hit_zombie["hp"]) <= 0.0:
							zombies.remove_at(zombie_index)
						else:
							zombies[zombie_index] = hit_zombie
			vehicle["cooldown"] = maxf(0.0, float(vehicle.get("cooldown", 0.0)) - delta)
			if float(vehicle["cooldown"]) <= 0.0 and not bool(vehicle.get("grounded", false)):
				var target_zombie: int = _find_nearest_zombie(position, 260.0)
				if target_zombie >= 0:
					var zombie_target: Vector2 = zombies[target_zombie]["pos"]
					var side_offset: Vector2 = (zombie_target - position).normalized().orthogonal() * (12.0 if helicopter else 0.0)
					_add_bullet_tracer(position + side_offset, zombie_target)
					if helicopter:
						_add_bullet_tracer(position - side_offset, zombie_target)
					_damage_zombie(target_zombie, 28.0 if helicopter else 32.0, -1, position)
					vehicle["cooldown"] = 0.28 if helicopter else 0.35
		vehicles[index] = vehicle
	_rebuild_zombie_spatial_grid()


func _milestone151_settlement_population() -> int:
	var total_population: int = 0
	for outpost in outposts:
		var outpost_rect: Rect2 = outpost.get("rect", Rect2(outpost.get("pos", Vector2.ZERO) - Vector2(110.0, 110.0), Vector2(220.0, 220.0)))
		for unit in units:
			if outpost_rect.grow(120.0).has_point(unit.get("pos", Vector2.ZERO)):
				total_population += 1
	for faction in faction_settlements:
		if bool(faction.get("warband_defeated", false)):
			continue
		var faction_kind: String = str(faction.get("faction", "NEUTRAL"))
		var troop_multiplier: int = 9 if faction_kind == "MILITARISTIC" else 5
		total_population += maxi(0, int(faction.get("strength", 1))) * troop_multiplier
	return total_population

func _spawn_wave() -> void:
	wave += 1
	if wave == 1:
		campaign_start_grace_timer = 0.0
	var escalation_phase: int = int(float(wave - 1) / 6.0) + 1
	var phase_multiplier: float = minf(1.0 + float(escalation_phase - 1) * 0.25, 3.0)
	var day_multiplier: float = minf(1.0 + float(survival_day - 1) * 0.12, 3.0)
	var early_curve: float = 0.45 if survival_day <= 2 else minf(1.0, 0.45 + float(survival_day - 2) * 0.18)
	var population_curve: float = 1.0 + minf(0.35, float(civilians.size() + _total_sheltered_civilians() + _milestone151_settlement_population()) / 500.0)
	var night_multiplier: float = (1.4 + minf(float(survival_day - 1) * 0.02, 0.6)) if day_phase == "NIGHT" else 1.0
	var relief_multiplier: float = 0.88 if recent_outpost_loss_timer > 0.0 else 1.0
	var count: int = mini(roundi(float(18 + wave * 8) * phase_multiplier * day_multiplier * early_curve * population_curve * night_multiplier * relief_multiplier), 900)
	pending_wave_spawns += count
	_spawn_pending_wave_spawns(0.0, true)
	if wave % 5 == 0:
		_spawn_refugee_wave()
	message = "PHASE %d — HORDE WAVE %d INBOUND" % [ceili(float(wave) / 6.0), wave]
	message_timer = 3.0


func _spawn_pending_wave_spawns(delta: float, fill_available: bool = false) -> void:
	if pending_wave_spawns <= 0:
		pending_wave_spawn_timer = 0.0
		return
	if spawn_districts.is_empty():
		return
	if fill_available:
		while pending_wave_spawns > 0 and zombies.size() < MAX_ACTIVE_ZOMBIES:
			if not _spawn_one_wave_zombie():
				break
			pending_wave_spawns -= 1
		pending_wave_spawn_timer = PENDING_WAVE_SPAWN_INTERVAL if pending_wave_spawns > 0 else 0.0
		return
	pending_wave_spawn_timer = maxf(0.0, pending_wave_spawn_timer - delta)
	if pending_wave_spawn_timer > 0.0 or zombies.size() >= MAX_ACTIVE_ZOMBIES:
		return
	if not _spawn_one_wave_zombie():
		pending_wave_spawn_timer = PENDING_WAVE_SPAWN_INTERVAL
		return
	pending_wave_spawns -= 1
	pending_wave_spawn_timer = PENDING_WAVE_SPAWN_INTERVAL if pending_wave_spawns > 0 else 0.0

func _spawn_one_wave_zombie() -> bool:
	if zombies.size() >= MAX_ACTIVE_ZOMBIES or spawn_districts.is_empty():
		return false
	var district_weights: Array[float] = []
	var total_district_weight: float = 0.0
	for district_index in range(spawn_districts.size()):
		var candidate_district: Rect2 = spawn_districts[district_index]
		var district_weight: float = 1.0
		for building in buildings:
			if candidate_district.encloses(building):
				district_weight += 0.12
		for heat_target in population_heat_targets:
			if candidate_district.has_point(heat_target.get("pos", Vector2.ZERO)):
				district_weight += minf(8.0, float(heat_target.get("heat", 0.0)) * 0.08)
		district_weights.append(district_weight)
		total_district_weight += district_weight
	var district_roll: float = randf() * total_district_weight
	var chosen_district_index: int = 0
	for district_index in range(district_weights.size()):
		district_roll -= district_weights[district_index]
		if district_roll <= 0.0:
			chosen_district_index = district_index
			break
	var district: Rect2 = spawn_districts[chosen_district_index]
	var spawn_point := Vector2.ZERO
	var found_open_spawn := false
	# Spawn near a weighted local heat source when one exists in this district.
	var local_heat_total: float = 0.0
	for heat_target in population_heat_targets:
		var heat_position: Vector2 = heat_target.get("pos", Vector2.ZERO)
		if district.has_point(heat_position):
			local_heat_total += maxf(0.0, float(heat_target.get("heat", 0.0)))
	var preferred_spawn_center: Vector2 = district.get_center()
	if local_heat_total > 0.0 and randf() < 0.72:
		var heat_roll: float = randf() * local_heat_total
		for heat_target in population_heat_targets:
			var heat_position: Vector2 = heat_target.get("pos", Vector2.ZERO)
			if not district.has_point(heat_position):
				continue
			heat_roll -= maxf(0.0, float(heat_target.get("heat", 0.0)))
			if heat_roll <= 0.0:
				preferred_spawn_center = heat_position
				break
	for attempt in range(16):
		if attempt < 10 and local_heat_total > 0.0:
			var spawn_offset := Vector2.from_angle(randf_range(0.0, TAU)) * randf_range(120.0, 620.0)
			spawn_point = preferred_spawn_center + spawn_offset
			spawn_point.x = clampf(spawn_point.x, district.position.x + 20.0, district.end.x - 20.0)
			spawn_point.y = clampf(spawn_point.y, district.position.y + 20.0, district.end.y - 20.0)
		else:
			spawn_point = Vector2(randf_range(district.position.x, district.end.x), randf_range(district.position.y, district.end.y))
		if _is_open_world_position(spawn_point, 18.0):
			found_open_spawn = true
			break
	if not found_open_spawn:
		return false
	var roll: float = randf()
	var kind: String = "shambler"
	var brute_chance: float = clampf(0.08 + float(wave) * 0.008 + float(survival_day - 1) * 0.012, 0.08, 0.42)
	var spitter_chance: float = clampf(0.10 + float(wave) * 0.006 + float(survival_day - 1) * 0.010, 0.10, 0.38)
	var runner_chance: float = clampf(0.16 + float(wave) * 0.006, 0.16, 0.34)
	if wave >= 2 and roll < brute_chance:
		kind = "brute"
	elif wave >= 2 and roll < brute_chance + spitter_chance:
		kind = "spitter"
	elif roll < brute_chance + spitter_chance + runner_chance:
		kind = "runner"
	var hp: float = 30.0
	if kind == "runner":
		hp = 25.0
	elif kind == "brute":
		hp = 180.0 + float(wave) * 15.0
	elif kind == "spitter":
		hp = 42.0 + float(wave) * 4.0
	if (sector_index == 0 or sector_index == 2) and randf() < 0.09:
		kind = "police_zed"
		hp = 115.0 + float(wave) * 6.0
	zombies.append({"pos": spawn_point, "kind": kind, "hp": hp, "max_hp": hp, "wall_cooldown": 0.0})
	return true

func _to_canvas_pos(raw_pos: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform().affine_inverse() * raw_pos

func _to_canvas_delta(raw_delta: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform().affine_inverse().basis_xform(raw_delta)

func _input(event: InputEvent) -> void:
	if event is InputEventScreenDrag and work_zone_dragging:
		var zone_drag := event as InputEventScreenDrag
		var zone_drag_pos: Vector2 = _to_canvas_pos(zone_drag.position)
		work_zone_current = _screen_to_world(zone_drag_pos)
		queue_redraw()
		return
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		var touch_pos: Vector2 = _to_canvas_pos(touch.position)
		if touch.pressed and _handle_title_touch(touch_pos):
			get_viewport().set_input_as_handled()
			return
		if touch.pressed:
			touch_points[touch.index] = touch_pos
			if touch_points.size() == 1:
				var touch_world: Vector2 = _screen_to_world(touch_pos)
				if game_state == "playing" and command_tab == 1 and touch_pos.y < _safe_bottom_y(_deployment_panel_height()) - 90.0 and touch_pos.y > safe_insets.y + 360.0:
					work_zone_dragging = true
					work_zone_start = touch_world
					work_zone_current = touch_world
					return
				var can_start_placement: bool = not outpost_placement_active and game_state == "playing" and touch_pos.y > safe_insets.y + 520.0 and touch_pos.y < _safe_bottom_y(260.0) and command_tab == 0 and selected_deployment < BASE_DEPLOYMENTS.size() and str(BASE_DEPLOYMENTS[selected_deployment]["kind"]) == "outpost"
				if can_start_placement:
					_begin_outpost_placement(touch_world, "hq" if game_state == "hq_placement" else "outpost")
				elif outpost_placement_active:
					if outpost_placement_rect.grow(maxf(24.0, touch_target_size * 0.5 / maxf(camera_zoom, 0.01))).has_point(touch_world):
						_begin_outpost_resize(touch_world)
					elif (game_state == "hq_placement" and touch_pos.y >= _safe_bottom_y(touch_target_size + 126.0)) or (game_state == "playing" and touch_pos.y >= _safe_bottom_y(260.0) and touch_pos.y <= _safe_bottom_y(260.0 - touch_target_size)):
						outpost_placement_gesture_mode = ""
						outpost_placement_dragging = false
					else:
						outpost_placement_gesture_mode = "pan"
						outpost_placement_dragging = true
				else:
					outpost_placement_gesture_mode = ""
				camera_drag_origin = touch_pos
				camera_last_position = touch_pos
				camera_drag_distance = 0.0
				camera_dragging = false
			elif touch_points.size() == 2:
				multi_touch_gesture = true
				var points: Array = touch_points.values()
				var first_point: Vector2 = points[0]
				var second_point: Vector2 = points[1]
				pinch_start_distance = first_point.distance_to(second_point)
				previous_pinch_center = (first_point + second_point) * 0.5
		else:
			if touch_points.has(touch.index):
				if work_zone_dragging:
					work_zone_dragging = false
					var zone_rect := Rect2(work_zone_start, work_zone_current - work_zone_start).abs()
					if zone_rect.size.x >= 30.0 and zone_rect.size.y >= 30.0:
						_milestone14_commit_work_zone(zone_rect)
				elif outpost_placement_active and outpost_placement_dragging:
					outpost_placement_dragging = false
					outpost_placement_gesture_mode = ""
				elif touch_points.size() == 1 and not multi_touch_gesture and not camera_dragging and camera_drag_distance < CAMERA_DRAG_THRESHOLD:
					_handle_tap(touch_pos)
				touch_points.erase(touch.index)
			if touch_points.is_empty():
				multi_touch_gesture = false
			if touch_points.size() < 2:
				pinch_start_distance = 0.0
			if touch_points.size() == 1:
				camera_last_position = touch_points.values()[0]
				camera_drag_distance = 0.0
				camera_dragging = false
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		var drag_pos: Vector2 = _to_canvas_pos(drag.position)
		var drag_delta: Vector2 = _to_canvas_delta(drag.relative)
		if touch_points.has(drag.index):
			touch_points[drag.index] = drag_pos
		if touch_points.size() >= 2:
			var points: Array = touch_points.values()
			var first_point: Vector2 = points[0]
			var second_point: Vector2 = points[1]
			var center := (first_point + second_point) * 0.5
			var distance := first_point.distance_to(second_point)
			camera_position -= (center - previous_pinch_center) / camera_zoom
			_clamp_camera()
			if pinch_start_distance > 0.0 and distance > 1.0:
				_zoom_camera(distance / pinch_start_distance, center)
			pinch_start_distance = distance
			previous_pinch_center = center
		else:
			if outpost_placement_active and outpost_placement_dragging and outpost_placement_gesture_mode == "resize":
				_update_outpost_placement_from_anchor(_screen_to_world(drag_pos))
				return
			camera_drag_distance += drag_delta.length()
			if camera_drag_distance > CAMERA_DRAG_THRESHOLD:
				camera_dragging = true
			if camera_dragging:
				camera_position -= drag_delta / camera_zoom
				_clamp_camera()
				queue_redraw()
	elif event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		var mouse_pos: Vector2 = _to_canvas_pos(mouse.position)
		if mouse.button_index == MOUSE_BUTTON_LEFT and mouse.pressed and _handle_title_touch(mouse_pos):
			get_viewport().set_input_as_handled()
			return
		if mouse.button_index == MOUSE_BUTTON_LEFT:
			if mouse.pressed:
				var mouse_world: Vector2 = _screen_to_world(mouse_pos)
				var can_start_placement: bool = not outpost_placement_active and game_state == "playing" and mouse_pos.y > safe_insets.y + 520.0 and mouse_pos.y < _safe_bottom_y(260.0) and command_tab == 0 and selected_deployment < BASE_DEPLOYMENTS.size() and str(BASE_DEPLOYMENTS[selected_deployment]["kind"]) == "outpost"
				if can_start_placement:
					_begin_outpost_placement(mouse_world, "hq" if game_state == "hq_placement" else "outpost")
				elif outpost_placement_active:
					if outpost_placement_rect.grow(maxf(24.0, touch_target_size * 0.5 / maxf(camera_zoom, 0.01))).has_point(mouse_world):
						_begin_outpost_resize(mouse_world)
					elif (game_state == "hq_placement" and mouse_pos.y >= _safe_bottom_y(touch_target_size + 126.0)) or (game_state == "playing" and mouse_pos.y >= _safe_bottom_y(260.0) and mouse_pos.y <= _safe_bottom_y(260.0 - touch_target_size)):
						outpost_placement_gesture_mode = ""
						outpost_placement_dragging = false
					else:
						outpost_placement_gesture_mode = "pan"
						outpost_placement_dragging = true
				camera_drag_origin = mouse_pos
				camera_drag_distance = 0.0
				camera_dragging = false
			elif outpost_placement_active and outpost_placement_dragging:
				outpost_placement_dragging = false
				outpost_placement_gesture_mode = ""
			elif not camera_dragging and camera_drag_distance < CAMERA_DRAG_THRESHOLD:
				_handle_tap(mouse_pos)
		elif mouse.pressed and mouse.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom_camera(1.12, mouse_pos)
		elif mouse.pressed and mouse.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom_camera(0.89, mouse_pos)
	elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var motion := event as InputEventMouseMotion
		var motion_pos: Vector2 = _to_canvas_pos(motion.position)
		var motion_delta: Vector2 = _to_canvas_delta(motion.relative)
		camera_drag_distance += motion_delta.length()
		if camera_drag_distance > CAMERA_DRAG_THRESHOLD:
			camera_dragging = true
		if outpost_placement_active and outpost_placement_dragging and outpost_placement_gesture_mode == "resize":
			_update_outpost_placement_from_anchor(_screen_to_world(motion_pos))
		elif camera_dragging:
			camera_position -= motion_delta / camera_zoom
			_clamp_camera()
			queue_redraw()

func _handle_title_touch(canvas_position: Vector2) -> bool:
	if game_state != "title" and game_state != "sector_select":
		return false
	var title_position: Vector2 = canvas_position - safe_area_rect.position
	if title_manual_open:
		# The modal owns every title-screen tap until it is dismissed.
		title_manual_open = false
		_queue_sfx("menu_click")
		queue_redraw()
		return true
	if _get_title_update_rect().has_point(title_position):
		_open_latest_game_update()
		_queue_sfx("menu_click")
		queue_redraw()
		return true
	if _get_title_manual_rect().has_point(title_position):
		title_manual_open = true
		_queue_sfx("menu_click")
		queue_redraw()
		return true
	if _get_title_sfx_rect().has_point(title_position):
		sfx_enabled = not sfx_enabled
		_queue_sfx("menu_click")
		queue_redraw()
		return true
	return false

func _handle_tap(pos: Vector2) -> void:
	if game_state == "title" or game_state == "sector_select":
		var title_pos: Vector2 = pos - safe_area_rect.position
		var title_size: Vector2 = _safe_viewport_size()
		if game_state == "title":
			var preview: Dictionary = _get_title_save_preview()
			var command_rect: Rect2 = Rect2(title_size.x * 0.055, title_size.y * 0.405, title_size.x * 0.89, title_size.y * 0.30)
			var ui_scale: float = _title_ui_scale(title_size)
			var launch_rect: Rect2 = Rect2(command_rect.position.x + 18.0, command_rect.end.y - maxf(78.0, 78.0 * ui_scale), command_rect.size.x - 36.0, maxf(62.0, 62.0 * ui_scale))
			if launch_rect.has_point(title_pos):
				if not preview.is_empty():
					_queue_sfx("menu_click")
					_resume_operation()
				else:
					menu_transition_action = "sector_select"
					menu_transition_timer = 0.24
					menu_fade_alpha = 0.0
					_queue_sfx("radar")
		else:
			for sector in range(3):
				var card_rect: Rect2 = _title_sector_card_rect(title_size, sector)
				if card_rect.has_point(title_pos):
					menu_transition_action = "deploy"
					menu_transition_sector = sector
					menu_transition_timer = 0.24
					menu_fade_alpha = 0.0
					_queue_sfx("radar")
					break
		queue_redraw()
		return
	if game_state == "prologue":
		if pos.y >= viewport_size.y - 160.0:
			menu_transition_action = "hq_placement"
			menu_transition_timer = 0.24
			menu_fade_alpha = 0.0
			_queue_sfx("menu_click")
			message = "SELECT AN INTACT BUILDING TO ANCHOR YOUR HQ"
			message_timer = 3.0
		queue_redraw()
		return
	if game_state == "hq_placement":
		if _hq_establish_button_rect().has_point(pos):
			_establish_hq_from_selected_building()
			queue_redraw()
			return
		if pos.y >= _safe_bottom_y(touch_target_size + 126.0):
			return
		var world_tap: Vector2 = _screen_to_world(pos)
		var building_index: int = _building_index_at(world_tap)
		if building_index >= 0 and building_index < building_archetypes.size() and not bool(building_archetypes[building_index].get("destroyed", false)):
			selected_hq_building_idx = building_index
			message = "%s SELECTED — SHELTER CAPACITY %d" % [_building_type_at(building_index), _hq_building_capacity(building_index)]
			message_timer = 2.0
		else:
			selected_hq_building_idx = -1
		queue_redraw()
		return
	if game_state == "sector_select":
		var title_pos: Vector2 = pos - safe_area_rect.position
		var title_size: Vector2 = _safe_viewport_size()
		if title_pos.y >= title_size.y * 0.44 and title_pos.y < title_size.y * 0.80:
			var selected_sector := clampi(int((title_pos.y - title_size.y * 0.44) / (title_size.y * 0.12)), 0, 2)
			_start_sector(selected_sector)
		queue_redraw()
		return
	if game_state == "victory" or game_state == "defeat":
		if game_state == "victory" and wave >= 30 and pos.y >= viewport_size.y * 0.66 and pos.y <= viewport_size.y * 0.82:
			endless_containment = true
			game_state = "playing"
			wave_timer = 1.0
			message = "ENDLESS CONTAINMENT ACTIVATED"
			message_timer = 3.0
		else:
			game_state = "sector_select"
		queue_redraw()
		return
	if game_state != "playing":
		return
	if _milestone15_handle_ops_tap(pos):
		queue_redraw()
		return
	if _milestone14_handle_settlement_tap(pos):
		queue_redraw()
		return
	if _milestone14_handle_panel_tap(pos):
		queue_redraw()
		return
	if _pause_button_rect().has_point(pos):
		manual_paused = not manual_paused
		lifecycle_paused = false
		queue_redraw()
		return
	if _radio_log_button_rect().has_point(pos):
		radio_log_open = not radio_log_open
		queue_redraw()
		return
	if radio_log_open:
		radio_log_open = false
		queue_redraw()
		return
	if outpost_placement_active and pos.y >= _safe_bottom_y(260.0) and pos.y <= _safe_bottom_y(260.0 - touch_target_size):
		if pos.x < safe_insets.x + (viewport_size.x - safe_insets.x - safe_insets.z) * 0.5:
			_confirm_outpost_placement()
		else:
			outpost_placement_active = false
			outpost_placement_dragging = false
		queue_redraw()
		return
	if radio_banner_timer > 0.0:
		var banner_width: float = minf(viewport_size.x - safe_insets.x - safe_insets.z - 28.0, 600.0)
		if Rect2((viewport_size.x - banner_width) * 0.5, safe_insets.y + 12.0, banner_width, 58.0).has_point(pos):
			radio_banner_timer = 0.0
			queue_redraw()
			return
	if campaign_start_grace_timer > 0.0 and Rect2(safe_insets.x + 24.0, _safe_bottom_y(64.0), 230.0, 56.0).has_point(pos):
		campaign_start_grace_timer = 0.0
		wave_timer = 0.0
		message = "COMMAND AUTHORIZED — HORDE DEPLOYMENT"
		message_timer = 2.0
		queue_redraw()
		return
	if _ai_button_rect().has_point(pos):
		work_outside_enabled = not work_outside_enabled
		message = "WORK OUTSIDE ENABLED" if work_outside_enabled else "RECALL TO OUTPOST ORDERED"
		message_timer = 1.8
		queue_redraw()
		return
	if _recruit_button_rect(0).has_point(pos):
		_recruit_unit("infantry")
		queue_redraw()
		return
	if _recruit_button_rect(1).has_point(pos):
		_recruit_unit("sniper")
		queue_redraw()
		return
	if _engineer_button_rect().has_point(pos):
		_recruit_unit("engineer")
		queue_redraw()
		return
	if _rescue_broadcast_rect().has_point(pos):
		_activate_rescue_broadcast()
		queue_redraw()
		return
	if _salvage_button_rect().has_point(pos):
		_salvage_nearest_vehicle()
		queue_redraw()
		return
	if manual_paused or lifecycle_paused:
		if pos.x >= viewport_size.x * 0.2 and pos.x <= viewport_size.x * 0.8 and pos.y >= viewport_size.y * 0.52 and pos.y <= viewport_size.y * 0.68:
			manual_paused = false
			lifecycle_paused = false
		queue_redraw()
		return
	var minimap_rect := Rect2(Vector2(viewport_size.x - safe_insets.z - MINIMAP_SIZE.x - HUD_EDGE_PADDING, safe_insets.y + HUD_EDGE_PADDING), MINIMAP_SIZE)
	if minimap_rect.has_point(pos):
		var local := (pos - minimap_rect.position) / minimap_rect.size
		camera_position = Vector2(local.x * WORLD_SIZE.x, local.y * WORLD_SIZE.y)
		_clamp_camera()
		queue_redraw()
		return
	var zoom_x: float = viewport_size.x - safe_insets.z - 112.0
	var zoom_top: float = safe_insets.y + 220.0
	var zoom_bottom_top: float = zoom_top + touch_target_size + 6.0
	if pos.x >= zoom_x and pos.x <= zoom_x + 94.0 and pos.y >= zoom_top and pos.y <= zoom_top + touch_target_size:
		_zoom_camera(1.18, viewport_size * 0.5)
		return
	if pos.x >= zoom_x and pos.x <= zoom_x + 94.0 and pos.y >= zoom_bottom_top and pos.y <= zoom_bottom_top + touch_target_size:
		_zoom_camera(0.85, viewport_size * 0.5)
		return
	var hud_left: float = safe_insets.x + HUD_EDGE_PADDING
	var hud_top: float = safe_insets.y + HUD_EDGE_PADDING
	if pos.x >= hud_left and pos.x <= hud_left + 172.0 and pos.y >= hud_top + 196.0 and pos.y <= hud_top + 196.0 + touch_target_size:
		time_scale_index = (time_scale_index + 1) % TIME_SCALES.size()
		queue_redraw()
		return
	var sfx_top: float = hud_top + 196.0 + touch_target_size + 6.0
	if pos.x >= hud_left and pos.x <= hud_left + 172.0 and pos.y >= sfx_top and pos.y <= sfx_top + touch_target_size:
		sfx_enabled = not sfx_enabled
		if not sfx_enabled:
			audio_queue.clear()
			audio_effect = ""
		queue_redraw()
		return
	if Rect2(Vector2(safe_insets.x + DIAGNOSTIC_BUTTON.position.x, safe_insets.y + DIAGNOSTIC_BUTTON.position.y), Vector2(DIAGNOSTIC_BUTTON.size.x, touch_target_size)).has_point(pos):
		diagnostics_enabled = not diagnostics_enabled
		queue_redraw()
		return
	if selected_structure_type == "outpost" and pos.y >= _structure_action_top() + 48.0 + touch_target_size and pos.y <= _structure_action_top() + 48.0 + touch_target_size * 2.0 and pos.x >= safe_insets.x + 24.0 and pos.x <= safe_insets.x + 370.0:
		_begin_outpost_expansion(selected_structure_index)
		return
	if not selected_structure_type.is_empty() and pos.y >= _structure_action_top() + 42.0 and pos.y <= _structure_action_top() + 42.0 + touch_target_size:
		if pos.x >= safe_insets.x + 24.0 and pos.x <= safe_insets.x + 190.0:
			_repair_selected_structure()
			return
		if pos.x >= safe_insets.x + 204.0 and pos.x <= safe_insets.x + 370.0:
			_upgrade_selected_structure()
			return
	var safe_left: float = safe_insets.x
	var safe_width: float = viewport_size.x - safe_insets.x - safe_insets.z
	if command_tab == 1:
		var roster_top: float = _milestone13_roster_top() + 25.0
		var row_height: float = _milestone13_roster_row_height()
		var roster_index: int = floori((pos.y - roster_top) / row_height)
		if roster_index >= 0 and roster_index < survivors.size() and pos.y < roster_top + row_height * float(survivors.size()):
			selected_survivor_index = roster_index
			var role_order: Array[String] = ["WORKER", "ENGINEER", "INFANTRY", "SNIPER", "HEAVY", "MEDIC"]
			var current_role: String = str(survivors[roster_index].get("role", "WORKER"))
			var current_index: int = role_order.find(current_role)
			for step in range(1, role_order.size() + 1):
				var next_role: String = role_order[(current_index + step) % role_order.size()]
				var required_key: String = "rifles" if next_role == "INFANTRY" else ("snipers" if next_role == "SNIPER" else ("heavy_mgs" if next_role == "HEAVY" else ("medkits" if next_role == "MEDIC" else "")))
				var current_weapon: String = str(survivors[roster_index].get("equipped_weapon", ""))
				if required_key.is_empty() or required_key == current_weapon or int(weapons.get(required_key, 0)) > 0:
					_milestone13_assign_role(roster_index, next_role)
					break
			queue_redraw()
			return
		var craft_y: float = roster_top + row_height * float(survivors.size()) + 8.0
		if pos.y >= craft_y and pos.y <= craft_y + 34.0:
			var craft_slot: int = clampi(floori((pos.x - safe_left) / (safe_width / 4.0)), 0, 3)
			var craft_keys: Array[String] = ["rifles", "snipers", "heavy_mgs", "medkits"]
			_milestone13_queue_craft(craft_keys[craft_slot])
			queue_redraw()
			return
	var bar_top: float = _safe_bottom_y(_deployment_panel_height())
	if pos.y >= bar_top and pos.x >= safe_left and pos.x <= safe_left + safe_width:
		if pos.y <= bar_top + touch_target_size:
			var safe_tab_width: float = safe_width / 3.0
			command_tab = clampi(int((pos.x - safe_left) / safe_tab_width), 0, 2)
			selected_deployment = 0
			selected_unit_index = -1
			selected_vehicle_index = -1
			queue_redraw()
			return
		var choices: Array = BASE_DEPLOYMENTS if command_tab == 0 else (RECRUIT_DEPLOYMENTS if command_tab == 1 else UNIT_DEPLOYMENTS)
		var button_width: float = safe_width / float(choices.size())
		selected_deployment = clampi(int((pos.x - safe_left) / button_width), 0, choices.size() - 1)
		selected_unit_index = -1
		selected_vehicle_index = -1
		message = str(choices[selected_deployment]["name"]) + " SELECTED"
		message_timer = 1.2
		queue_redraw()
		return
	if pos.y < safe_insets.y + 270.0:
		return
	var world_pos := _screen_to_world(pos)
	if selected_vehicle_index >= 0 and selected_vehicle_index < vehicles.size() and bool(vehicles[selected_vehicle_index].get("active", false)):
		vehicles[selected_vehicle_index]["move_target"] = world_pos
		selected_vehicle_index = -1
		message = "VEHICLE DESTINATION SET"
		message_timer = 1.3
		return
	for vehicle_index in range(vehicles.size()):
		if world_pos.distance_to(vehicles[vehicle_index]["pos"]) <= 48.0 and bool(vehicles[vehicle_index].get("active", false)):
			selected_vehicle_index = vehicle_index
			selected_unit_index = -1
			message = "VEHICLE SELECTED — TAP DESTINATION"
			message_timer = 1.6
			return
	for camp in raider_camps:
		if world_pos.distance_squared_to(camp["pos"]) <= 70.0 * 70.0:
			_interact_raider_camp(world_pos)
			queue_redraw()
			return
	for tree_index in range(trees.size()):
		if bool(trees[tree_index].get("alive", false)) and world_pos.distance_squared_to(trees[tree_index]["pos"]) <= 30.0 * 30.0:
			var worker_index: int = selected_unit_index
			if worker_index < 0 or worker_index >= units.size():
				worker_index = 0 if not units.is_empty() else -1
			if worker_index >= 0:
				units[worker_index]["work_kind"] = "chop"
				units[worker_index]["work_target_index"] = tree_index
				units[worker_index]["work_timer"] = 3.0
				units[worker_index]["move_target"] = trees[tree_index]["pos"]
				units[worker_index]["manual_order"] = true
				message = "TREE HARVEST ORDERED"
			else:
				message = "RECRUIT A SQUAD TO HARVEST TIMBER"
			message_timer = 1.6
			queue_redraw()
			return
	for animal_index in range(wildlife.size()):
		if bool(wildlife[animal_index].get("alive", false)) and world_pos.distance_squared_to(wildlife[animal_index]["pos"]) <= 28.0 * 28.0:
			var hunter_index: int = selected_unit_index
			if hunter_index >= 0 and hunter_index < units.size() and (str(units[hunter_index].get("kind", "")) == "infantry" or str(units[hunter_index].get("kind", "")) == "sniper"):
				units[hunter_index]["work_kind"] = "hunt"
				units[hunter_index]["work_target_index"] = animal_index
				units[hunter_index]["work_timer"] = 3.0
				units[hunter_index]["move_target"] = wildlife[animal_index]["pos"]
				units[hunter_index]["manual_order"] = true
				message = "HUNT ORDERED"
			else:
				message = "SELECT INFANTRY OR SNIPER TO HUNT"
			message_timer = 1.6
			queue_redraw()
			return
	var tapped_building: int = _building_index_at(world_pos)
	if selected_unit_index >= 0 and selected_unit_index < units.size():
		if tapped_building >= 0 and (str(units[selected_unit_index].get("kind", "")) == "engineer" or command_tab == 2):
			units[selected_unit_index]["work_kind"] = "demolish"
			units[selected_unit_index]["work_target_index"] = tapped_building
			units[selected_unit_index]["work_timer"] = 5.0
			units[selected_unit_index]["move_target"] = buildings[tapped_building].get_center()
			units[selected_unit_index]["manual_order"] = true
			message = "SQUAD DEMOLITION ORDERED — ENGINEERS WORK 2X FASTER"
			message_timer = 2.0
			queue_redraw()
			return
		if tapped_building >= 0:
			_garrison_unit(selected_unit_index, tapped_building)
			return
		var selected_is_garrisoned: bool = bool(units[selected_unit_index].get("garrisoned", false))
		if selected_is_garrisoned:
			_exit_unit_garrison(selected_unit_index, world_pos)
			if _is_valid_street_position(world_pos):
				units[selected_unit_index]["move_target"] = world_pos
			units[selected_unit_index]["manual_order"] = true
			message = "UNIT EXITED GARRISON"
			message_timer = 1.5
			selected_unit_index = -1
			queue_redraw()
			return
		if _is_valid_street_position(world_pos):
			_exit_unit_garrison(selected_unit_index, world_pos)
			units[selected_unit_index]["move_target"] = world_pos
			units[selected_unit_index]["manual_order"] = true
			message = "SQUAD REPOSITIONED"
			message_timer = 1.2
			selected_unit_index = -1
			queue_redraw()
			return
	if tapped_building >= 0:
		for garrison_index in range(units.size()):
			if bool(units[garrison_index].get("garrisoned", false)) and int(units[garrison_index].get("garrison_building", -1)) == tapped_building:
				selected_unit_index = garrison_index
				message = "GARRISON UNIT SELECTED — TAP STREET TO EXIT"
				message_timer = 1.8
				queue_redraw()
				return
	if _select_structure_at(world_pos):
		message = "%s SELECTED" % selected_structure_type.to_upper()
		message_timer = 1.2
		queue_redraw()
		return
	selected_structure_type = ""
	selected_structure_index = -1
	for squad_index in range(units.size() - 1, -1, -1):
		if world_pos.distance_to(units[squad_index]["pos"]) <= UNIT_SELECT_RADIUS:
			selected_unit_index = squad_index
			selected_survivor_index = -1
			var survivor_id: int = int(units[squad_index].get("survivor_id", -1))
			for survivor_index in range(survivors.size()):
				if int(survivors[survivor_index].get("id", -2)) == survivor_id:
					selected_survivor_index = survivor_index
					break
			message = "SURVIVOR SELECTED — ASSIGN ROLE FROM RECRUIT TAB"
			message_timer = 2.0
			queue_redraw()
			return
	if selected_unit_index >= 0 and selected_unit_index < units.size():
		if _is_valid_street_position(world_pos):
			units[selected_unit_index]["pos"] = world_pos
			message = "SQUAD REPOSITIONED"
			message_timer = 1.2
			selected_unit_index = -1
			queue_redraw()
			return
		selected_unit_index = -1
	var choices: Array = BASE_DEPLOYMENTS if command_tab == 0 else (RECRUIT_DEPLOYMENTS if command_tab == 1 else UNIT_DEPLOYMENTS)
	if selected_deployment >= choices.size():
		selected_deployment = 0
	var deployment: Dictionary = choices[selected_deployment]
	var cost: int = int(deployment["cost"])
	var kind: String = str(deployment["kind"])
	if kind == "outpost":
		if outposts.size() >= OUTPOST_MAX_COUNT + 1:
			message = "FORWARD OUTPOST LIMIT REACHED (6)"
			message_timer = 1.5
			return
		_begin_outpost_placement(world_pos, "outpost")
		outpost_placement_dragging = false
		queue_redraw()
		return
	if kind == "farm" or kind == "bakery" or kind == "livestock" or kind == "watchtower" or kind == "clinic" or kind == "workshop":
		_construct_survival_building(kind, world_pos)
		queue_redraw()
		return
	if kind == "gate":
		if _try_place_gate(world_pos):
			message = "PERIMETER GATE INSTALLED"
			message_timer = 1.5
		else:
			message = "GATE MUST SNAP TO AN OUTPOST WALL — MATS"
			message_timer = 1.5
		queue_redraw()
		return
	var required_scrap: int = 25 if kind == "turret" else (0 if kind == "wall" else (15 if kind == "gate" else 0))
	var resource_shortage: bool = (wood < cost if kind == "wall" else scrap < cost)
	if resource_shortage or scrap < required_scrap:
		message = "INSUFFICIENT MATERIALS / MATS"
		message_timer = 1.5
		queue_redraw()
		return
	if not _is_valid_street_position(world_pos):
		message = "POSITION BLOCKED — SELECT OPEN STREET"
		message_timer = 1.4
		queue_redraw()
		return
	match kind:
		"airstrike":
			_execute_airstrike(world_pos)
		"flare":
			flares.append({"pos": world_pos, "life": FLARE_LIFETIME, "phase": 0.0})
			_queue_sfx("flare")
		"infantry", "sniper", "engineer":
			_recruit_unit(kind)
			return
		"turret":
			world_pos = _snap_turret_to_outpost(world_pos)
			turrets.append({"pos": world_pos, "hp": 250.0, "max_hp": 250.0, "cooldown": 0.1, "level": 1, "range": TURRET_RANGE, "vision_radius": TURRET_RANGE, "damage": 22.0, "fire_interval": 0.18})
		"wall":
			barricades.append({"pos": world_pos, "hp": 400.0, "max_hp": 400.0})
		"gate":
			pass
	if kind == "wall":
		wood -= cost
	else:
		scrap -= cost
	scrap -= required_scrap
	message = str(deployment["name"]) + " DEPLOYED"
	message_timer = 1.6
	queue_redraw()

func _execute_airstrike(center: Vector2) -> void:
	airstrike_marker = center
	airstrike_timer = 0.8
	_queue_sfx("airstrike")
	shockwaves.append({"pos": center, "radius": 8.0, "life": 0.65, "max_life": 0.65})
	shake_timer = 0.28
	shake_strength = 5.0
	var radius := 112.0
	for i in range(zombies.size() - 1, -1, -1):
		if center.distance_to(zombies[i]["pos"]) <= radius:
			_damage_zombie(i, 10000.0)
	var casualties := 0
	for i in range(civilians.size() - 1, -1, -1):
		if center.distance_to(civilians[i]) <= radius:
			civilians.remove_at(i)
			if i < civilian_steering.size():
				civilian_steering.remove_at(i)
			casualties += 1
	if casualties > 0:
		lost_count += casualties
		var penalty := casualties * 75
		scrap = maxi(0, scrap - penalty)
		message = "FRIENDLY FIRE: %d CIVILIANS LOST (-MATS %d)" % [casualties, penalty]
	else:
		message = "AIRSTRIKE COMPLETE"
	message_timer = 2.5

func _draw() -> void:
	viewport_size = get_viewport_rect().size
	if game_state == "title" or game_state == "sector_select":
		_draw_satellite_backdrop()
		draw_set_transform(safe_area_rect.position, 0.0, Vector2.ONE)
		_draw_title_screen()
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		if menu_fade_alpha > 0.0:
			draw_rect(Rect2(Vector2.ZERO, viewport_size), Color(0.0, 0.015, 0.012, menu_fade_alpha))
		return
	if game_state == "prologue":
		draw_rect(Rect2(Vector2.ZERO, viewport_size), Color("#07110f"))
		draw_rect(Rect2(24.0, 36.0, viewport_size.x - 48.0, viewport_size.y - 72.0), Color("#10241d"))
		draw_rect(Rect2(24.0, 36.0, viewport_size.x - 48.0, viewport_size.y - 72.0), Color("#75c99a"), false, 2.0)
		_draw_text("STATE EXCLUSION ZONE // DAY 01", Vector2(48.0, 86.0), 15, Color("#91e4b0"))
		_draw_text("THE LAZARUS COLLAPSE", Vector2(48.0, 138.0), 27, Color("#f1fff4"))
		_draw_text("The Lazarus Neuro-Pathogen began as neural repair therapy.", Vector2(48.0, 194.0), 13, Color("#d6e9dc"))
		_draw_text("It rewired the dead and turned the living into vectors.", Vector2(48.0, 220.0), 13, Color("#d6e9dc"))
		_draw_text("Nations fell. The State Exclusion Zone is the last corridor.", Vector2(48.0, 246.0), 13, Color("#d6e9dc"))
		_draw_text("18 CONVOY SURVIVORS", Vector2(48.0, 302.0), 17, Color("#f4d77b"))
		_draw_text("Medics, engineers, officers and civilians arrive with", Vector2(48.0, 332.0), 13, Color("#d6e9dc"))
		_draw_text("limited rations and salvaged gear. Secure a building.", Vector2(48.0, 358.0), 13, Color("#d6e9dc"))
		for i in range(mini(8, survivors.size())):
			_draw_text(str(survivors[i].get("name", "SURVIVOR")) + " / " + str(survivors[i].get("role", "WORKER")), Vector2(48.0, 414.0 + float(i) * 25.0), 12, Color("#b8d5c3"))
		_draw_text("+ " + str(maxi(0, survivors.size() - 8)) + " additional convoy members", Vector2(48.0, 630.0), 12, Color("#b8d5c3"))
		draw_rect(Rect2(40.0, viewport_size.y - 140.0, viewport_size.x - 80.0, 48.0), Color("#245a3c"))
		draw_rect(Rect2(40.0, viewport_size.y - 140.0, viewport_size.x - 80.0, 48.0), Color("#75e6a0"), false, 2.0)
		_draw_text("[ESTABLISH HEADQUARTERS]", Vector2(58.0, viewport_size.y - 109.0), 15, Color("#f0fff5"))
		_draw_text("[SKIP]", Vector2(viewport_size.x - 105.0, viewport_size.y - 74.0), 12, Color("#a9c8b7"))
		if menu_fade_alpha > 0.0:
			draw_rect(Rect2(Vector2.ZERO, viewport_size), Color(0.0, 0.015, 0.012, menu_fade_alpha))
		return
	if game_state == "hq_placement":
		_draw_world_scene()
		var world_origin: Vector2 = viewport_size * 0.5 - camera_position * camera_zoom
		if selected_hq_building_idx >= 0 and selected_hq_building_idx < buildings.size():
			draw_set_transform(world_origin, 0.0, Vector2(camera_zoom, camera_zoom))
			var selected_building_rect: Rect2 = buildings[selected_hq_building_idx]
			var pulse_alpha: float = 0.72 + 0.28 * sin(title_animation_time * 5.0)
			draw_rect(selected_building_rect.grow(8.0), Color(0.12, 1.0, 0.48, 0.16 * pulse_alpha), false, 10.0)
			draw_rect(selected_building_rect.grow(4.0), Color(0.12, 1.0, 0.48, 0.98), false, 4.0)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		var hq_panel_top: float = _safe_bottom_y(touch_target_size + 126.0)
		draw_rect(Rect2(safe_insets.x, hq_panel_top, viewport_size.x - safe_insets.x - safe_insets.z, viewport_size.y - hq_panel_top), Color("#071713", 0.97))
		_draw_text("SELECT HQ LOCATION — TAP AN INTACT BUILDING", Vector2(safe_insets.x + 18.0, hq_panel_top + 22.0), 14, Color("#e8fff0"))
		var archetype_label: String = "NO BUILDING SELECTED"
		var shelter_capacity: int = 0
		if selected_hq_building_idx >= 0 and selected_hq_building_idx < buildings.size():
			archetype_label = _building_type_at(selected_hq_building_idx)
			shelter_capacity = _hq_building_capacity(selected_hq_building_idx)
		_draw_text("%s  |  SHELTER CAPACITY %d  |  0 WOOD / 0 SCRAP" % [archetype_label, shelter_capacity], Vector2(safe_insets.x + 18.0, hq_panel_top + 46.0), 11, Color("#a9c8b7"))
		var establish_rect: Rect2 = _hq_establish_button_rect()
		draw_rect(establish_rect, Color("#245a3c") if selected_hq_building_idx >= 0 else Color("#28332e"))
		draw_rect(establish_rect, Color("#72e6a0") if selected_hq_building_idx >= 0 else Color("#59675f"), false, 2.0)
		_draw_text("[ESTABLISH HQ HERE — FREE]", establish_rect.position + Vector2(12.0, touch_target_size * 0.62), 14, Color("#f0fff5"))
		_draw_text("Territory starts open and unfortified. Build walls separately.", Vector2(safe_insets.x + 18.0, establish_rect.end.y + 17.0), 10, Color("#a9c8b7"))
		if menu_fade_alpha > 0.0:
			draw_rect(Rect2(Vector2.ZERO, viewport_size), Color(0.0, 0.015, 0.012, menu_fade_alpha))
		return
	var shake_offset := Vector2.ZERO
	if shake_timer > 0.0:
		shake_offset = Vector2(randf_range(-shake_strength, shake_strength), randf_range(-shake_strength, shake_strength))
	var world_transform_origin := viewport_size * 0.5 - camera_position * camera_zoom + shake_offset
	draw_set_transform(world_transform_origin, 0.0, Vector2(camera_zoom, camera_zoom))
	draw_rect(Rect2(Vector2.ZERO, WORLD_SIZE), Color("#07110f"))
	_draw_grid()
	_draw_roads()
	_draw_evac_zone()
	_draw_buildings()
	_draw_milestone13_rooftop_bars()
	for district_index in range(district_regions.size()):
		var district_rect: Rect2 = district_regions[district_index]
		if _camera_view_rect().intersects(district_rect):
			var district_labels: Array[String] = ["URBAN CORE", "SUBURBS", "INDUSTRIAL ZONE", "MEDICAL DISTRICT", "RURAL HIGHWAYS", "LOGISTICS HUB", "CIVIC CENTER", "OUTER CORRIDOR"]
			var district_label: String = district_labels[district_index] if district_index < district_labels.size() else "REGIONAL DISTRICT"
			_draw_text(district_label, Vector2(70.0, district_rect.position.y + 62.0), 24, Color(0.45, 0.75, 0.62, 0.6))
	_draw_fog()
	_draw_entities()
	_milestone14_draw_faction_banners()
	_draw_placement_preview()
	var visible_effect_rect := _camera_view_rect().grow(220.0)
	for flare in flares:
		var flare_pos: Vector2 = flare["pos"]
		if not visible_effect_rect.has_point(flare_pos):
			continue
		var pulse: float = 1.0 + 0.18 * sin(float(flare["phase"]) * 8.0)
		draw_circle(flare_pos, 11.0 * pulse, Color(1.0, 0.78, 0.12, 0.18))
		draw_circle(flare_pos, 5.0 * pulse, Color("#ffe45c"))
		draw_arc(flare_pos, 18.0 * pulse, 0.0, TAU, 32, Color(1.0, 0.82, 0.22, 0.8), 2.0)
	for wave_effect in shockwaves:
		if not visible_effect_rect.has_point(wave_effect["pos"]):
			continue
		var alpha: float = clampf(float(wave_effect["life"]) / float(wave_effect["max_life"]), 0.0, 1.0)
		var ring_color := Color(0.35, 1.0, 0.28, alpha) if bool(wave_effect.get("toxic", false)) else Color(1.0, 0.48, 0.16, alpha)
		draw_arc(wave_effect["pos"], float(wave_effect["radius"]), 0.0, TAU, 48, ring_color, 3.0)
	if airstrike_timer > 0.0 and visible_effect_rect.has_point(airstrike_marker):
		draw_arc(airstrike_marker, 112.0, 0.0, TAU, 48, Color(1.0, 0.42, 0.12, airstrike_timer), 4.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if day_phase == "DUSK":
		draw_rect(Rect2(Vector2.ZERO, viewport_size), Color(0.30, 0.14, 0.05, 0.08))
	elif day_phase == "NIGHT":
		draw_rect(Rect2(Vector2.ZERO, viewport_size), Color(0.03, 0.06, 0.20, 0.18))
	_draw_hud()
	if command_tab == 1:
		_milestone14_draw_hud_panel()
		_milestone15_draw_ops_monitor()
	if campaign_start_grace_timer > 0.0:
		var fast_start_rect := Rect2(safe_insets.x + 24.0, _safe_bottom_y(64.0), 230.0, 56.0)
		draw_rect(fast_start_rect, Color("#3b3320"))
		draw_rect(fast_start_rect, Color("#e4c66d"), false, 2.0)
		_draw_text("[DEPLOY HORDE NOW]", fast_start_rect.position + Vector2(12.0, 35.0), 14, Color("#fff1b9"))
	_draw_structure_actions()
	_draw_selection_inspector()
	_draw_radio_banner()
	_draw_radio_log()
	_draw_minimap()
	_draw_deployment_bar()
	if outpost_placement_active:
		_draw_outpost_placement_hud(_safe_bottom_y(260.0))
	if manual_paused or lifecycle_paused:
		_draw_pause_overlay()
	if game_state != "playing":
		_draw_end_screen()

func _draw_grid() -> void:
	var visible_rect := _camera_view_rect().grow(100.0)
	var start_x := maxi(0, floori(visible_rect.position.x / 80.0) * 80)
	var end_x := mini(int(WORLD_SIZE.x), ceili(visible_rect.end.x / 80.0) * 80)
	var start_y := maxi(0, floori(visible_rect.position.y / 80.0) * 80)
	var end_y := mini(int(WORLD_SIZE.y), ceili(visible_rect.end.y / 80.0) * 80)
	for x in range(start_x, end_x + 1, 80):
		draw_line(Vector2(x, start_y), Vector2(x, end_y), Color(0.12, 0.23, 0.19, 0.32), 1.0)
	for y in range(start_y, end_y + 1, 80):
		draw_line(Vector2(start_x, y), Vector2(end_x, y), Color(0.12, 0.23, 0.19, 0.32), 1.0)

func _draw_roads() -> void:
	var visible_rect: Rect2 = _camera_view_rect().grow(100.0)
	for segment in highway_segments:
		var road_from: Vector2 = segment["from"]
		var road_to: Vector2 = segment["to"]
		var width: float = float(segment.get("width", 64.0))
		var bounds := Rect2(Vector2(minf(road_from.x, road_to.x), minf(road_from.y, road_to.y)), Vector2(absf(road_to.x - road_from.x), absf(road_to.y - road_from.y))).grow(width * 0.5)
		if not visible_rect.intersects(bounds):
			continue
		draw_line(road_from, road_to, Color("#182522"), width + 10.0)
		draw_line(road_from, road_to, Color("#303a37"), width)
		if absf(road_to.x - road_from.x) > absf(road_to.y - road_from.y):
			var line_y1: float = road_from.y - 7.0
			var line_y2: float = road_from.y + 7.0
			draw_line(Vector2(road_from.x, line_y1), Vector2(road_to.x, line_y1), Color("#d8bd63"), 2.0)
			draw_line(Vector2(road_from.x, line_y2), Vector2(road_to.x, line_y2), Color("#d8bd63"), 2.0)
			var lane_start: float = maxf(minf(road_from.x, road_to.x), visible_rect.position.x)
			var lane_end: float = minf(maxf(road_from.x, road_to.x), visible_rect.end.x)
			for lane_offset in [-25.0, 25.0]:
				var lane_x: float = lane_start
				while lane_x < lane_end:
					draw_line(Vector2(lane_x, road_from.y + lane_offset), Vector2(minf(lane_x + 42.0, lane_end), road_from.y + lane_offset), Color("#b9c8bf", 0.55), 2.0)
					lane_x += 82.0
		else:
			var line_x1: float = road_from.x - 7.0
			var line_x2: float = road_from.x + 7.0
			draw_line(Vector2(line_x1, road_from.y), Vector2(line_x1, road_to.y), Color("#d8bd63"), 2.0)
			draw_line(Vector2(line_x2, road_from.y), Vector2(line_x2, road_to.y), Color("#d8bd63"), 2.0)
			var lane_start: float = maxf(minf(road_from.y, road_to.y), visible_rect.position.y)
			var lane_end: float = minf(maxf(road_from.y, road_to.y), visible_rect.end.y)
			for lane_offset in [-25.0, 25.0]:
				var lane_y: float = lane_start
				while lane_y < lane_end:
					draw_line(Vector2(road_from.x + lane_offset, lane_y), Vector2(road_from.x + lane_offset, minf(lane_y + 42.0, lane_end)), Color("#b9c8bf", 0.55), 2.0)
					lane_y += 82.0
	for segment in secondary_road_segments:
		var road_from: Vector2 = segment["from"]
		var road_to: Vector2 = segment["to"]
		var width: float = float(segment.get("width", 24.0))
		var bounds := Rect2(Vector2(minf(road_from.x, road_to.x), minf(road_from.y, road_to.y)), Vector2(absf(road_to.x - road_from.x), absf(road_to.y - road_from.y))).grow(width * 0.5)
		if visible_rect.intersects(bounds):
			draw_line(road_from, road_to, Color("#222e2a"), width + 5.0)
			draw_line(road_from, road_to, Color("#3a4640"), width)

func _draw_dashed_circle(center: Vector2, radius: float, tint: Color, segments: int) -> void:
	for segment in range(0, segments, 2):
		var start_angle := TAU * float(segment) / float(segments)
		var end_angle := TAU * float(segment + 1) / float(segments)
		var start_point := center + Vector2(cos(start_angle), sin(start_angle)) * radius
		var end_point := center + Vector2(cos(end_angle), sin(end_angle)) * radius
		draw_line(start_point, end_point, tint, 2.0)

func _draw_evac_zone() -> void:
	var visible_rect: Rect2 = _camera_view_rect().grow(400.0)
	for zone in evacuation_zones:
		if not visible_rect.has_point(zone):
			continue
		draw_circle(zone, EVAC_RADIUS, Color(0.05, 0.55, 0.25, 0.18))
		draw_arc(zone, EVAC_RADIUS, 0.0, TAU, 48, Color("#48e58b"), 3.0)
		draw_arc(zone, EVAC_RADIUS - 12.0, 0.0, TAU, 48, Color(0.28, 0.85, 0.55, 0.35), 1.0)
		var zone_label: String = "PRIMARY HQ" if zone.distance_squared_to(primary_hq_position) < 1.0 else "FORWARD SAFE ZONE"
		_draw_text(zone_label, zone + Vector2(-45.0, 5.0), 13, Color("#8cf5b5"))
	for outpost in outposts:
		if not visible_rect.has_point(outpost["pos"]):
			continue
		draw_circle(outpost["pos"], float(outpost["safe_radius"]), Color(0.10, 0.65, 0.32, 0.035))
		draw_arc(outpost["pos"], float(outpost["vision_radius"]), 0.0, TAU, 48, Color(0.25, 0.85, 0.48, 0.16), 1.0)
		_draw_dashed_circle(outpost["pos"], OUTPOST_COMMAND_RADIUS, Color(0.35, 0.88, 0.55, 0.34), 48)

func _draw_satellite_backdrop() -> void:
	var size: Vector2 = viewport_size
	draw_rect(Rect2(Vector2.ZERO, size), Color("#050b0e"))
	var cell: float = maxf(42.0, size.x / 13.0)
	for y in range(-1, ceili(size.y / cell) + 1):
		for x in range(-1, ceili(size.x / cell) + 1):
			var seed_value: int = posmod(x * 73 + y * 137 + x * y * 19, 11)
			var rect := Rect2(Vector2(float(x) * cell + 5.0, float(y) * cell + 5.0), Vector2(cell - 11.0, cell - 11.0))
			var tint: float = 0.035 + float(seed_value) * 0.003
			draw_rect(rect, Color(0.16 + tint, 0.23 + tint, 0.22 + tint, 0.82))
			if seed_value % 4 == 0:
				draw_rect(Rect2(rect.position + Vector2(8.0, 8.0), rect.size * Vector2(0.30, 0.22)), Color(0.35, 0.48, 0.40, 0.22))
	for x in range(0, int(size.x) + 1, int(cell)):
		draw_line(Vector2(float(x), 0.0), Vector2(float(x), size.y), Color(0.34, 0.53, 0.43, 0.14), 2.0)
	for y in range(0, int(size.y) + 1, int(cell)):
		draw_line(Vector2(0.0, float(y)), Vector2(size.x, float(y)), Color(0.34, 0.53, 0.43, 0.14), 2.0)
	var beacon_points: Array[Vector2] = [Vector2(size.x * 0.17, size.y * 0.29), Vector2(size.x * 0.79, size.y * 0.34), Vector2(size.x * 0.64, size.y * 0.76), Vector2(size.x * 0.28, size.y * 0.83)]
	for index in range(beacon_points.size()):
		var point: Vector2 = beacon_points[index]
		var pulse: float = 0.5 + 0.5 * sin(title_animation_time * 2.2 + float(index) * 1.7)
		draw_circle(point, 13.0 + pulse * 10.0, Color(0.95, 0.12, 0.10, 0.06 + pulse * 0.08))
		draw_arc(point, 20.0 + pulse * 13.0, 0.0, TAU, 36, Color(1.0, 0.20, 0.16, 0.45), 1.5)
		draw_circle(point, 3.5 + pulse * 1.5, Color("#ff5147"))
	for signature in range(3):
		var t: float = title_animation_time * (0.035 + float(signature) * 0.009) + float(signature) * 2.1
		var infection := Vector2(size.x * (0.12 + fposmod(t, 0.78)), size.y * (0.24 + 0.19 * sin(t * 4.0 + float(signature))))
		draw_circle(infection, 18.0, Color(1.0, 0.08, 0.06, 0.08))
		draw_arc(infection, 11.0, 0.0, TAU, 24, Color(1.0, 0.16, 0.12, 0.55), 2.0)
		draw_circle(infection, 3.0, Color("#f0443d"))
	var scan_y: float = fposmod(title_animation_time * 72.0, maxf(1.0, size.y))
	draw_line(Vector2(0.0, scan_y), Vector2(size.x, scan_y), Color(0.34, 0.94, 0.65, 0.17), 2.0)
	for particle in range(30):
		var px: float = fposmod(float(particle * 97) + title_animation_time * (7.0 + float(particle % 5)), maxf(1.0, size.x))
		var py: float = fposmod(float(particle * 173) - title_animation_time * (11.0 + float(particle % 7)), maxf(1.0, size.y))
		var alpha: float = 0.10 + 0.12 * (0.5 + 0.5 * sin(title_animation_time * 1.8 + float(particle)))
		draw_circle(Vector2(px, py), 1.0 + float(particle % 3) * 0.45, Color(1.0, 0.48, 0.20, alpha))
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.005, 0.018, 0.022, 0.48))

func _draw_containment_emblem(center: Vector2, radius: float) -> void:
	var shield_points := PackedVector2Array([
		center + Vector2(0.0, -radius),
		center + Vector2(radius * 0.78, -radius * 0.58),
		center + Vector2(radius * 0.68, radius * 0.36),
		center + Vector2(0.0, radius),
		center + Vector2(-radius * 0.68, radius * 0.36),
		center + Vector2(-radius * 0.78, -radius * 0.58)
	])
	draw_colored_polygon(shield_points, Color(0.04, 0.16, 0.12, 0.92))
	for point_index in range(shield_points.size()):
		draw_line(shield_points[point_index], shield_points[(point_index + 1) % shield_points.size()], Color("#9be9b5"), 2.5)
	draw_arc(center, radius * 0.49, 0.0, TAU, 48, Color("#e9f6e8"), 2.0)
	draw_circle(center, radius * 0.13, Color("#e9f6e8"))
	for arm in range(3):
		var angle: float = -PI * 0.5 + float(arm) * TAU / 3.0
		var origin: Vector2 = center + Vector2(cos(angle), sin(angle)) * radius * 0.18
		var end: Vector2 = center + Vector2(cos(angle), sin(angle)) * radius * 0.43
		draw_line(origin, end, Color("#e9f6e8"), 3.0)
		draw_circle(end, radius * 0.10, Color("#e9f6e8"))

func _get_title_save_preview() -> Dictionary:
	if not _has_valid_save():
		return {}
	var file := FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Dictionary:
		return {}
	var state: Dictionary = parsed
	var clock_minutes: float = fposmod(float(state.get("world_clock_minutes", 450.0)), 1440.0)
	var clock_text: String = "%02d:%02d" % [int(clock_minutes / 60.0), int(fposmod(clock_minutes, 60.0))]
	var population: int = 0
	var saved_civilians: Variant = state.get("civilians", [])
	var saved_survivors: Variant = state.get("survivors", [])
	if saved_civilians is Array:
		population += saved_civilians.size()
	if saved_survivors is Array:
		population += saved_survivors.size()
	return {"day": int(state.get("survival_day", 1)), "clock": clock_text, "population": population}

func _title_ui_scale(title_size: Vector2) -> float:
	return clampf(title_size.x / 720.0, 0.82, 1.55)

func _get_title_manual_rect() -> Rect2:
	var title_size: Vector2 = _safe_viewport_size()
	var button_height: float = maxf(64.0, title_size.y * 0.058)
	return Rect2(title_size.x * 0.055, title_size.y * 0.815, title_size.x * 0.43, button_height)

func _get_title_update_rect() -> Rect2:
	var title_size: Vector2 = _safe_viewport_size()
	return Rect2(title_size.x * 0.055, title_size.y * 0.895, title_size.x * 0.89, maxf(42.0, title_size.y * 0.042))

func _get_title_sfx_rect() -> Rect2:
	var title_size: Vector2 = _safe_viewport_size()
	var button_height: float = maxf(64.0, title_size.y * 0.058)
	return Rect2(title_size.x * 0.515, title_size.y * 0.815, title_size.x * 0.43, button_height)

func _title_manual_panel_rect(title_size: Vector2) -> Rect2:
	var panel_size: Vector2 = Vector2(minf(title_size.x * 0.90, 680.0), minf(title_size.y * 0.62, 620.0))
	return Rect2((title_size - panel_size) * 0.5, panel_size)

func _title_manual_close_rect(title_size: Vector2) -> Rect2:
	var panel: Rect2 = _title_manual_panel_rect(title_size)
	return Rect2(panel.position.x + 20.0, panel.end.y - 78.0, panel.size.x - 40.0, 58.0)

func _title_sector_card_rect(title_size: Vector2, index: int) -> Rect2:
	var stack_top: float = title_size.y * 0.425
	var stack_height: float = title_size.y * 0.355
	var gap: float = 14.0
	var card_height: float = (stack_height - gap * 2.0) / 3.0
	return Rect2(title_size.x * 0.055, stack_top + float(index) * (card_height + gap), title_size.x * 0.89, card_height)

func _draw_field_manual(title_size: Vector2) -> void:
	if not title_manual_open:
		return
	var panel: Rect2 = _title_manual_panel_rect(title_size)
	var ui_scale: float = minf(_title_ui_scale(title_size), panel.size.y / 560.0)
	draw_rect(Rect2(Vector2.ZERO, title_size), Color(0.0, 0.01, 0.01, 0.84))
	draw_rect(panel.grow(5.0), Color("#37694e", 0.55))
	draw_rect(panel, Color("#0b1b19", 0.99))
	draw_rect(panel, Color("#91ddb0"), false, 2.5)
	_draw_text("QUICK FIELD MANUAL", panel.position + Vector2(24.0, 48.0 * ui_scale), roundi(25.0 * ui_scale), Color("#e8fff0"))
	var rules: Array[String] = [
		"1. ENCLOSE BUILDINGS FOR HQ",
		"Build a perimeter around an intact structure.",
		"2. ASSIGN INDOOR / OUTDOOR WORKERS",
		"Balance shelter, production and scavenging.",
		"3. LOOT / CRAFT WEAPONS FOR RAID SQUADS",
		"Equip survivors before sending squads beyond the walls.",
		"4. WATCH POPULATION NOISE & NIGHT SURGES",
		"Gunfire and dense settlements draw infected toward you."
	]
	for index in range(rules.size()):
		var y: float = panel.position.y + 104.0 * ui_scale + float(index) * 38.0 * ui_scale
		var heading: bool = index % 2 == 0
		_draw_text(rules[index], panel.position + Vector2(24.0, y - panel.position.y), roundi((13.0 if heading else 11.0) * ui_scale), Color("#baf2cb") if heading else Color("#a8c2b5"))
	var close_rect: Rect2 = _title_manual_close_rect(title_size)
	draw_rect(close_rect, Color("#24583c"))
	draw_rect(close_rect, Color("#8ce5ad"), false, 2.0)
	_draw_text("[CLOSE MANUAL]", close_rect.position + Vector2(18.0, close_rect.size.y * 0.65), roundi(16.0 * ui_scale), Color("#f0fff5"))

func _draw_title_screen() -> void:
	var title_size: Vector2 = _safe_viewport_size()
	var ui_scale: float = _title_ui_scale(title_size)
	var panel: Rect2 = Rect2(title_size.x * 0.025, title_size.y * 0.025, title_size.x * 0.95, title_size.y * 0.95)
	draw_rect(panel, Color(0.015, 0.045, 0.04, 0.94))
	draw_rect(panel, Color("#5c9273"), false, 2.0)

	# HERO: 14%-36% safe-area band.
	var emblem_radius: float = minf(title_size.x * 0.075, 58.0 * ui_scale)
	_draw_containment_emblem(Vector2(title_size.x * 0.5, title_size.y * 0.185), emblem_radius)
	_draw_text("CONTAINMENT PROTOCOL", Vector2(title_size.x * 0.07, title_size.y * 0.285), clampi(roundi(34.0 * ui_scale), 28, 36), Color("#f0fff5"))
	draw_rect(Rect2(title_size.x * 0.28, title_size.y * 0.315, title_size.x * 0.44, maxf(3.0, 3.0 * ui_scale)), Color("#75d99a"))
	_draw_text("STATE EXCLUSION ZONE // SURVIVAL COMMAND", Vector2(title_size.x * 0.12, title_size.y * 0.345), roundi(11.0 * ui_scale), Color("#a9c8b7"))
	var career_text: String = "CAREER RECORD  //  BEST DAY %d  |  SAVED %03d" % [best_days_survived, best_civilians_saved]
	var career_width: float = minf(title_size.x * 0.72, 520.0 * ui_scale)
	var career_rect: Rect2 = Rect2((title_size.x - career_width) * 0.5, title_size.y * 0.365, career_width, maxf(34.0, 34.0 * ui_scale))
	draw_rect(career_rect, Color("#243c30"))
	draw_rect(career_rect, Color("#927c42"), false, 1.0)
	_draw_text(career_text, career_rect.position + Vector2(12.0, career_rect.size.y * 0.68), roundi(10.0 * ui_scale), Color("#f0d98c"))

	# COMMAND / DISTRICT STACK: 39%-78% safe-area band.
	if game_state == "title":
		var preview: Dictionary = _get_title_save_preview()
		var command_rect: Rect2 = Rect2(title_size.x * 0.055, title_size.y * 0.405, title_size.x * 0.89, title_size.y * 0.30)
		draw_rect(command_rect, Color("#102a23", 0.97))
		draw_rect(command_rect, Color("#6fba8b"), false, 2.0)
		draw_rect(Rect2(command_rect.position, Vector2(7.0, command_rect.size.y)), Color("#63c88b"))
		_draw_text("FIELD COMMAND", command_rect.position + Vector2(22.0, 42.0 * ui_scale), clampi(roundi(20.0 * ui_scale), 18, 22), Color("#e8fff0"))
		if not preview.is_empty():
			_draw_text("RESUME OPERATION  //  DAY %02d  //  POPULATION %03d" % [int(preview["day"]), int(preview["population"])], command_rect.position + Vector2(22.0, 82.0 * ui_scale), roundi(13.0 * ui_scale), Color("#fff1bd"))
			_draw_text("LOCAL CLOCK  %s" % str(preview["clock"]), command_rect.position + Vector2(22.0, 112.0 * ui_scale), roundi(11.0 * ui_scale), Color("#c1d8c8"))
		var launch_rect: Rect2 = Rect2(command_rect.position.x + 18.0, command_rect.end.y - maxf(78.0, 78.0 * ui_scale), command_rect.size.x - 36.0, maxf(62.0, 62.0 * ui_scale))
		draw_rect(launch_rect, Color("#245b3c"))
		draw_rect(launch_rect, Color("#91ddb0"), false, 2.0)
		var launch_label: String = "[RESUME]" if not preview.is_empty() else "[LAUNCH]"
		_draw_text(launch_label, launch_rect.position + Vector2(launch_rect.size.x * 0.34, launch_rect.size.y * 0.66), roundi(20.0 * ui_scale), Color("#f0fff5"))
		if not preview.is_empty():
			_draw_text("NEW OPERATION", command_rect.position + Vector2(22.0, command_rect.size.y * 0.62), roundi(11.0 * ui_scale), Color("#a8c2b5"))
	else:
		_draw_text("SELECT OPERATIONAL DISTRICT", Vector2(title_size.x * 0.08, title_size.y * 0.395), roundi(18.0 * ui_scale), Color("#d8eee0"))
		var names: Array[String] = ["SUBURBAN OUTSKIRTS", "MEDICAL & URBAN CORE", "INDUSTRIAL HIGHWAY"]
		var resources: Array[String] = ["SUPPLIES HIGH  /  FOOD HIGH", "MEDICAL HIGH  /  SCRAP MEDIUM", "FUEL HIGH  /  MATERIALS HIGH"]
		var details: Array[String] = ["LOW-DENSITY STREETS  /  BALANCED THREAT", "DENSE BLOCKS  /  HOSPITALS  /  HIGH THREAT", "WAREHOUSES  /  HIGHWAY CHOKEPOINTS"]
		var threat: Array[int] = [2, 4, 3]
		for index in range(3):
			var card: Rect2 = _title_sector_card_rect(title_size, index)
			draw_rect(card, Color("#102a23", 0.97))
			draw_rect(card, Color("#6fba8b"), false, 2.0)
			draw_rect(Rect2(card.position, Vector2(7.0, card.size.y)), Color("#d18d62") if index == 1 else Color("#65c98b"))
			_draw_text("%02d  %s" % [index + 1, names[index]], card.position + Vector2(20.0, card.size.y * 0.28), clampi(roundi(20.0 * ui_scale), 18, 22), Color("#e8fff0"))
			_draw_text(resources[index], card.position + Vector2(20.0, card.size.y * 0.49), clampi(roundi(14.0 * ui_scale), 13, 15), Color("#b7d7c2"))
			_draw_text(details[index], card.position + Vector2(20.0, card.size.y * 0.66), clampi(roundi(13.0 * ui_scale), 13, 15), Color("#8eaa99"))
			_draw_text("THREAT", card.position + Vector2(20.0, card.size.y * 0.86), roundi(9.0 * ui_scale), Color("#e2b2a4"))
			for pip in range(5):
				var pip_color: Color = Color("#e45c50") if pip < threat[index] else Color("#46574f")
				draw_circle(card.position + Vector2(92.0 + float(pip) * 16.0, card.size.y * 0.84), 5.0 * ui_scale, pip_color)
			var launch_rect: Rect2 = Rect2(card.end.x - 150.0 * ui_scale, card.end.y - 58.0 * ui_scale, 132.0 * ui_scale, 44.0 * ui_scale)
			draw_rect(launch_rect, Color("#245b3c"))
			draw_rect(launch_rect, Color("#91ddb0"), false, 1.5)
			_draw_text("[LAUNCH]", launch_rect.position + Vector2(launch_rect.size.x * 0.20, launch_rect.size.y * 0.68), roundi(12.0 * ui_scale), Color("#f0fff5"))

	var manual_rect: Rect2 = _get_title_manual_rect()
	var sfx_rect: Rect2 = _get_title_sfx_rect()
	draw_rect(manual_rect, Color("#173b2b", 0.98))
	draw_rect(manual_rect, Color("#79c995"), false, 2.0)
	_draw_text("[FIELD MANUAL]", manual_rect.position + Vector2(18.0, manual_rect.size.y * 0.65), roundi(14.0 * ui_scale), Color("#c9e6d1"))
	draw_rect(sfx_rect, Color("#173b2b", 0.98))
	draw_rect(sfx_rect, Color("#79c995"), false, 2.0)
	_draw_text("[SFX: %s]" % ("ON" if sfx_enabled else "OFF"), sfx_rect.position + Vector2(18.0, sfx_rect.size.y * 0.65), roundi(14.0 * ui_scale), Color("#c9e6d1"))
	var update_rect: Rect2 = _get_title_update_rect()
	draw_rect(update_rect, Color("#183b2b"))
	draw_rect(update_rect, Color("#79c995") if update_available else Color("#527966"), false, 1.5)
	_draw_text(update_status, update_rect.position + Vector2(12.0, update_rect.size.y * 0.68), roundi(11.0 * ui_scale), Color("#e1f7e8"))
	_draw_text("TACTICAL RESPONSE COMMAND  //  SECURE THE EXCLUSION ZONE", Vector2(title_size.x * 0.07, title_size.y * 0.925), roundi(9.0 * ui_scale), Color("#6e9680"))
	_draw_field_manual(title_size)

func _draw_pause_overlay() -> void:
	draw_rect(Rect2(Vector2.ZERO, viewport_size), Color(0.01, 0.04, 0.03, 0.78))
	_draw_text("SIMULATION PAUSED", viewport_size * 0.5 + Vector2(-145.0, -50.0), 30, Color("#e8fff0"))
	draw_rect(Rect2(viewport_size * 0.5 - Vector2(210.0, -10.0), Vector2(420.0, 100.0)), Color("#244a38"))
	draw_rect(Rect2(viewport_size * 0.5 - Vector2(210.0, -10.0), Vector2(420.0, 100.0)), Color("#8ce5ad"), false, 3.0)
	_draw_text("RESUME  /  BACK", viewport_size * 0.5 + Vector2(-115.0, 70.0), 24, Color("#f0fff5"))

func _is_position_visible(world_position: Vector2) -> bool:
	for zone in evacuation_zones:
		if world_position.distance_squared_to(zone) <= 250.0 * 250.0:
			return true
	for unit in units:
		var unit_radius: float = (390.0 if str(unit["kind"]) == "sniper" else 205.0) * _night_vision_multiplier()
		if world_position.distance_squared_to(unit["pos"]) <= unit_radius * unit_radius:
			return true
	for outpost in outposts:
		var outpost_radius: float = float(outpost.get("vision_radius", 260.0)) * _night_vision_multiplier()
		if world_position.distance_squared_to(outpost["pos"]) <= outpost_radius * outpost_radius:
			return true
	for turret in turrets:
		var turret_radius: float = float(turret.get("vision_radius", TURRET_RANGE)) * _night_vision_multiplier()
		if world_position.distance_squared_to(turret["pos"]) <= turret_radius * turret_radius:
			return true
	for flare in flares:
		if world_position.distance_squared_to(flare["pos"]) <= 260.0 * 260.0:
			return true
	for building in constructed_buildings:
		if str(building.get("kind", "")) == "watchtower" and world_position.distance_squared_to(building["pos"]) <= 520.0 * 520.0:
			return true
	return false

func _draw_fog() -> void:
	var visible_rect := _camera_view_rect()
	var tile_size := 80.0
	var start_x := maxi(0, floori(visible_rect.position.x / tile_size) * int(tile_size))
	var end_x := mini(int(WORLD_SIZE.x), ceili(visible_rect.end.x / tile_size) * int(tile_size))
	var start_y := maxi(0, floori(visible_rect.position.y / tile_size) * int(tile_size))
	var end_y := mini(int(WORLD_SIZE.y), ceili(visible_rect.end.y / tile_size) * int(tile_size))
	for tile_y in range(start_y, end_y, int(tile_size)):
		for tile_x in range(start_x, end_x, int(tile_size)):
			var tile_center := Vector2(float(tile_x) + tile_size * 0.5, float(tile_y) + tile_size * 0.5)
			if not _is_position_visible(tile_center):
				draw_rect(Rect2(Vector2(tile_x, tile_y), Vector2(tile_size, tile_size)), Color(0.008, 0.022, 0.019, 0.82))

func _draw_entities() -> void:
	var visible_rect := _camera_view_rect().grow(80.0)
	for decal in tactical_decals:
		var decal_pos: Vector2 = decal.get("pos", Vector2.ZERO)
		if visible_rect.has_point(decal_pos):
			var decal_direction: Vector2 = decal.get("direction", Vector2.UP)
			var decal_alpha: float = clampf(float(decal.get("life", 1.0)) / 180.0, 0.0, 1.0)
			draw_line(decal_pos - decal_direction * 9.0, decal_pos + decal_direction * 9.0, Color(0.58, 0.62, 0.57, 0.28 * decal_alpha), 2.0)
	for tree in trees:
		var tree_pos: Vector2 = tree["pos"]
		if bool(tree.get("alive", false)) and visible_rect.has_point(tree_pos):
			draw_line(tree_pos + Vector2(0.0, 8.0), tree_pos + Vector2(0.0, -8.0), Color("#795c3b"), 4.0)
			draw_circle(tree_pos, 11.0, Color("#315f3e"))
			draw_circle(tree_pos + Vector2(-5.0, -4.0), 6.0, Color("#4d8b50"))
	for animal in wildlife:
		if bool(animal.get("alive", false)) and visible_rect.has_point(animal["pos"]):
			var animal_color: Color = Color("#b68d61") if str(animal.get("kind", "")) == "deer" else Color("#8d6d5d")
			draw_circle(animal["pos"], 7.0, animal_color)
			draw_circle(animal["pos"] + Vector2(6.0, -3.0), 3.0, animal_color.lightened(0.25))
	for camp in raider_camps:
		if visible_rect.has_point(camp["pos"]):
			draw_rect(Rect2(camp["pos"] - Vector2(20.0, 16.0), Vector2(40.0, 32.0)), Color("#6b4938") if not bool(camp.get("raided", false)) else Color("#393939"))
			_draw_text("RAIDERS" if not bool(camp.get("raided", false)) else "CLEARED", camp["pos"] + Vector2(-26.0, -24.0), 9, Color("#e7c69c"))
	for building in constructed_buildings:
		if not visible_rect.has_point(building["pos"]):
			continue
		var building_color: Color = Color("#68a85a") if str(building.get("kind", "")) == "farm" else (Color("#c58b4d") if str(building.get("kind", "")) == "bakery" else (Color("#a6a36a") if str(building.get("kind", "")) == "livestock" else (Color("#8c9caa") if str(building.get("kind", "")) == "watchtower" else Color("#65b9c9"))))
		draw_rect(Rect2(building["pos"] - Vector2(18.0, 18.0), Vector2(36.0, 36.0)), building_color)
		draw_rect(Rect2(building["pos"] - Vector2(18.0, 18.0), Vector2(36.0, 36.0)), Color("#e8fff0"), false, 2.0)
	for civilian in civilians:
		if not visible_rect.has_point(civilian):
			continue
		draw_circle(civilian, 5.5, Color("#8bdcff"))
		draw_circle(civilian, 2.0, Color("#e3f8ff"))
	for zombie in zombies:
		var p: Vector2 = zombie["pos"]
		if not visible_rect.has_point(p) or (game_state != "hq_placement" and not _is_position_visible(p)):
			continue
		var kind: String = str(zombie["kind"])
		if kind == "runner":
			draw_circle(p, 8.0, Color("#ff8a32"))
			draw_circle(p, 3.0, Color("#ffe0a8"))
		elif kind == "brute":
			draw_circle(p, 13.0, Color("#9b59d0"))
			draw_circle(p, 5.0, Color("#e5b7ff"))
		elif kind == "spitter":
			draw_circle(p, 7.5, Color("#50ff54"))
			draw_circle(p, 2.5, Color("#d4ffd0"))
		elif kind == "police_zed":
			draw_circle(p, 9.5, Color("#6e8198"))
			draw_circle(p, 4.0, Color("#d0e2f4"))
			draw_rect(Rect2(p + Vector2(-6.0, -2.0), Vector2(12.0, 6.0)), Color("#243b5a"))
			draw_rect(Rect2(p + Vector2(-6.0, -2.0), Vector2(12.0, 6.0)), Color("#a7c5e8"), false, 1.0)
		else:
			draw_circle(p, 7.0, Color("#f0444f"))
	for wall in barricades:
		var wall_pos: Vector2 = wall["pos"]
		var wall_rect: Rect2 = wall.get("rect", Rect2(wall_pos - Vector2(15.0, 15.0), Vector2(30.0, 30.0)))
		if not visible_rect.intersects(wall_rect):
			continue
		var wall_hp: float = float(wall["hp"]) / float(wall["max_hp"])
		draw_rect(wall_rect, Color("#9b8b70", 0.85))
		draw_rect(wall_rect, Color("#cbb99a", 0.35 + 0.65 * wall_hp), false, 2.5)
	for gate in gates:
		var gate_rect: Rect2 = gate["rect"]
		if visible_rect.intersects(gate_rect):
			draw_rect(gate_rect, Color("#5ad88b") if bool(gate.get("open", false)) else Color("#d8ad62"))
			draw_rect(gate_rect, Color("#eaf7db"), false, 2.0)
	for crate in supply_crates:
		if visible_rect.has_point(crate["pos"]):
			draw_circle(crate["pos"], 18.0, Color(0.9, 0.72, 0.24, 0.2))
			draw_rect(Rect2(crate["pos"] - Vector2(11.0, 11.0), Vector2(22.0, 22.0)), Color("#d8b65b"))
			draw_line(crate["pos"] + Vector2(-7.0, 0.0), crate["pos"] + Vector2(7.0, 0.0), Color("#fff0b0"), 2.0)
	for outpost in outposts:
		var outpost_rect: Rect2 = outpost.get("rect", Rect2(outpost["pos"] - Vector2(110.0, 110.0), Vector2(220.0, 220.0)))
		if visible_rect.intersects(outpost_rect):
			draw_rect(outpost_rect, Color("#43d77a", 0.08))
			draw_rect(outpost_rect, Color("#43d77a"), false, 3.0)
			draw_rect(Rect2(outpost["pos"] - Vector2(15.0, 15.0), Vector2(30.0, 30.0)), Color("#43d77a"))
	for turret in turrets:
		if visible_rect.has_point(turret["pos"]):
			draw_rect(Rect2(turret["pos"] - Vector2(11.0, 11.0), Vector2(22.0, 22.0)), Color("#e2bb63"))
	for building_index in range(buildings.size()):
		var state: Dictionary = building_archetypes[building_index]
		if bool(state.get("destroyed", false)):
			continue
		if not visible_rect.intersects(buildings[building_index]):
			continue
		var count: int = 0
		for garrison_unit in units:
			if bool(garrison_unit.get("garrisoned", false)) and int(garrison_unit.get("garrison_building", -1)) == building_index:
				count += 1
		if count > 0 and visible_rect.intersects(buildings[building_index]):
			var roof: Rect2 = buildings[building_index]
			draw_rect(roof.grow(-7.0), Color("#4de6a5"), false, 5.0)
			var roof_range: float = 390.0 if _building_type_at(building_index) == "HIGHRISE" else 276.75
			draw_arc(roof.get_center(), roof_range, 0.0, TAU, 48, Color("#4de6a5", 0.18), 2.0)
			_draw_text("GARRISON", roof.get_center() + Vector2(-30.0, -18.0), 10, Color("#a6f4d0"))
			var first_x: float = roof.get_center().x - float(count - 1) * 10.0
			for pip in range(count):
				draw_circle(Vector2(first_x + float(pip) * 20.0, roof.position.y + 30.0), 6.0, Color("#63f4cb"))
	for vehicle_index in range(vehicles.size()):
		var vehicle: Dictionary = vehicles[vehicle_index]
		var vehicle_pos: Vector2 = vehicle["pos"]
		if not visible_rect.has_point(vehicle_pos):
			continue
		var aircraft: bool = str(vehicle.get("kind", "")) == "helicopter"
		var vehicle_color := Color("#73c9d6") if aircraft else Color("#b6a36a")
		if aircraft:
			draw_circle(vehicle_pos + Vector2(0.0, 12.0), 48.0, Color("#8edce5", 0.07))
			draw_arc(vehicle_pos + Vector2(0.0, 12.0), 48.0, 0.0, TAU, 36, Color("#8edce5", 0.24), 2.0)
			draw_line(vehicle_pos + Vector2(-28.0, -24.0), vehicle_pos + Vector2(28.0, 24.0), vehicle_color, 4.0)
			draw_line(vehicle_pos + Vector2(-28.0, 24.0), vehicle_pos + Vector2(28.0, -24.0), vehicle_color, 4.0)
			draw_line(vehicle_pos + Vector2(-42.0, 0.0), vehicle_pos + Vector2(42.0, 0.0), Color("#d6f6f7"), 3.0)
			draw_line(vehicle_pos + Vector2(-48.0, -30.0), vehicle_pos + Vector2(48.0, -30.0), Color("#d6f6f7"), 3.0)
			draw_line(vehicle_pos + Vector2(-48.0, -34.0), vehicle_pos + Vector2(48.0, -34.0), Color("#d6f6f7"), 2.0)
		else:
			draw_rect(Rect2(vehicle_pos - Vector2(25.0, 14.0), Vector2(50.0, 28.0)), vehicle_color)
			draw_rect(Rect2(vehicle_pos - Vector2(12.0, 9.0), Vector2(24.0, 18.0)), Color("#26352e"))
			draw_circle(vehicle_pos, 5.0, Color("#202923"))
			draw_line(vehicle_pos, vehicle_pos + Vector2(0.0, -18.0), Color("#202923"), 4.0)
			if day_phase == "NIGHT":
				var headlight_direction: Vector2 = vehicle.get("facing", Vector2.RIGHT)
				var headlight_side: Vector2 = headlight_direction.orthogonal() * 38.0
				draw_colored_polygon(PackedVector2Array([vehicle_pos + headlight_direction * 16.0 - headlight_side * 0.25, vehicle_pos + headlight_direction * 150.0 - headlight_side, vehicle_pos + headlight_direction * 150.0 + headlight_side, vehicle_pos + headlight_direction * 16.0 + headlight_side * 0.25]), Color(1.0, 0.92, 0.58, 0.08))
				draw_line(vehicle_pos + headlight_direction * 16.0 - headlight_side * 0.25, vehicle_pos + headlight_direction * 150.0 - headlight_side, Color(1.0, 0.92, 0.58, 0.28), 5.0)
				draw_line(vehicle_pos + headlight_direction * 16.0 + headlight_side * 0.25, vehicle_pos + headlight_direction * 150.0 + headlight_side, Color(1.0, 0.92, 0.58, 0.28), 5.0)
		var health_ratio: float = clampf(float(vehicle.get("hp", 0.0)) / maxf(float(vehicle.get("max_hp", 1.0)), 1.0), 0.0, 1.0)
		draw_rect(Rect2(vehicle_pos + Vector2(-24.0, -25.0), Vector2(48.0 * health_ratio, 4.0)), Color("#67e89b"))
		if not bool(vehicle.get("active", false)):
			var salvage_remaining: float = float(vehicle.get("salvage_timer", 4.0))
			_draw_text("SALVAGE %d MATS + %.0f FUEL  %.1fS" % [int(vehicle.get("salvage_cost", 0)), float(vehicle.get("fuel_cost", 0.0)), salvage_remaining], vehicle_pos + Vector2(-48.0, -34.0), 10, Color("#f4d77b"))
		else:
			_draw_text("ONBOARD %d/6" % int(vehicle.get("onboard", 0)), vehicle_pos + Vector2(-34.0, 38.0), 10, Color("#b8f1df"))
	for unit_index in range(units.size()):
		var unit: Dictionary = units[unit_index]
		var p: Vector2 = unit["pos"]
		if bool(unit.get("garrisoned", false)) or not visible_rect.has_point(p):
			continue
		var unit_kind: String = str(unit["kind"])
		var sniper: bool = unit_kind == "sniper"
		var engineer: bool = unit_kind == "engineer"
		var militia: bool = unit_kind == "militia"
		var medic: bool = unit_kind == "medic"
		var heavy: bool = unit_kind == "heavy"
		var tint := Color("#6bdc9a")
		if engineer:
			tint = Color("#e0b66c")
		elif medic:
			tint = Color("#79d4e6")
		elif heavy:
			tint = Color("#cf6d58")
		elif militia:
			tint = Color("#c6d46b")
		elif sniper:
			tint = Color("#8ab6ff")
		draw_rect(Rect2(p - Vector2(9, 9), Vector2(18, 18)), tint)
		var veteran_rank: int = clampi(int(unit.get("rank", 0)), 0, 3)
		for chevron in range(veteran_rank):
			var chevron_y: float = p.y - 16.0 - float(chevron) * 5.0
			draw_line(Vector2(p.x - 5.0, chevron_y), Vector2(p.x, chevron_y - 4.0), Color("#ffd75e"), 2.0)
			draw_line(Vector2(p.x, chevron_y - 4.0), Vector2(p.x + 5.0, chevron_y), Color("#ffd75e"), 2.0)
		var unit_facing: Vector2 = unit.get("facing", Vector2.UP)
		draw_line(p, p + unit_facing * 18.0, Color("#f6f3d1"), 2.0)
		draw_line(p + unit_facing * 18.0, p + unit_facing.rotated(2.5) * 10.0, Color("#f6f3d1"), 2.0)
		draw_line(p + unit_facing * 18.0, p + unit_facing.rotated(-2.5) * 10.0, Color("#f6f3d1"), 2.0)
		if militia:
			_draw_text("M", p + Vector2(-4.0, 4.0), 11, Color("#1b2410"))
		elif engineer:
			_draw_text("E", p + Vector2(-4.0, 4.0), 11, Color("#1b2410"))
		elif medic:
			_draw_text("+", p + Vector2(-4.0, 4.0), 11, Color("#10252a"))
		elif heavy:
			_draw_text("H", p + Vector2(-4.0, 4.0), 11, Color("#2a1511"))
		var task_label: String = str(unit.get("ai_task", ""))
		if not task_label.is_empty():
			_draw_text(task_label, p + Vector2(-25.0, -15.0), 9, Color("#b5f3d2"))
		draw_arc(p, (390.0 if sniper else (MILITIA_RANGE if militia else 205.0)) * _night_vision_multiplier(), 0.0, TAU, 48, Color(tint.r, tint.g, tint.b, 0.10), 1.0)
		if unit_index == selected_unit_index:
			draw_arc(p, 24.0, 0.0, TAU, 32, Color("#fff28a"), 3.0)
	for tracer in bullet_tracers:
		if not visible_rect.has_point(tracer["from"]) and not visible_rect.has_point(tracer["to"]):
			continue
		var alpha: float = clampf(float(tracer["life"]) / float(tracer["max_life"]), 0.0, 1.0)
		draw_line(tracer["from"], tracer["to"], Color(1.0, 0.88, 0.48, alpha), 2.0)
	for callout_index in range(world_callouts.size() - 1, -1, -1):
		var callout: Dictionary = world_callouts[callout_index]
		if visible_rect.has_point(callout["pos"]):
			_draw_text(str(callout["text"]), callout["pos"] + Vector2(-24.0, -38.0), 14, Color("#ffe28a"))
	for flash in muzzle_flashes:
		if not visible_rect.has_point(flash["pos"]):
			continue
		var alpha: float = clampf(float(flash["life"]) / float(flash["max_life"]), 0.0, 1.0)
		draw_circle(flash["pos"], 8.0 * alpha, Color(1.0, 0.78, 0.35, alpha))

func _draw_minimap() -> void:
	var minimap_rect := Rect2(Vector2(viewport_size.x - safe_insets.z - MINIMAP_SIZE.x - HUD_EDGE_PADDING, safe_insets.y + HUD_EDGE_PADDING), MINIMAP_SIZE)
	draw_rect(minimap_rect, Color("#081713", 0.96))
	for building in buildings:
		var building_rect := Rect2(minimap_rect.position + building.position / WORLD_SIZE * minimap_rect.size, building.size / WORLD_SIZE * minimap_rect.size)
		draw_rect(building_rect, Color("#52685d"))
	for zone in evacuation_zones:
		draw_circle(minimap_rect.position + zone / WORLD_SIZE * minimap_rect.size, 2.2, Color("#54e98e"))
	for civilian in civilians:
		draw_circle(minimap_rect.position + civilian / WORLD_SIZE * minimap_rect.size, 1.5, Color("#65cfff"))
	for zombie in zombies:
		var zombie_pos: Vector2 = zombie["pos"]
		if _is_position_visible(zombie_pos):
			draw_circle(minimap_rect.position + zombie_pos / WORLD_SIZE * minimap_rect.size, 1.9, Color("#f34d58", 0.78))
	for outpost in outposts:
		draw_rect(Rect2(minimap_rect.position + outpost["pos"] / WORLD_SIZE * minimap_rect.size - Vector2(2.0, 2.0), Vector2(4.0, 4.0)), Color("#55f08b"))
	for crate in supply_crates:
		draw_circle(minimap_rect.position + crate["pos"] / WORLD_SIZE * minimap_rect.size, 2.0, Color("#e8ca69"))
	for turret in turrets:
		draw_rect(Rect2(minimap_rect.position + turret["pos"] / WORLD_SIZE * minimap_rect.size - Vector2(1.5, 1.5), Vector2(3.0, 3.0)), Color("#f1d071"))
	var camera_rect := _camera_view_rect()
	var mini_camera := Rect2(minimap_rect.position + camera_rect.position / WORLD_SIZE * minimap_rect.size, camera_rect.size / WORLD_SIZE * minimap_rect.size)
	draw_rect(mini_camera, Color("#f4e28a", 0.12))
	draw_rect(mini_camera, Color("#f4e28a"), false, 1.5)
	var zoom_x: float = viewport_size.x - safe_insets.z - 112.0
	var zoom_top: float = safe_insets.y + 220.0
	var zoom_bottom_top: float = zoom_top + touch_target_size + 6.0
	draw_rect(Rect2(Vector2(zoom_x, zoom_top), Vector2(94.0, touch_target_size)), Color("#183329"))
	draw_rect(Rect2(Vector2(zoom_x, zoom_top), Vector2(94.0, touch_target_size)), Color("#6ccf91"), false, 2.0)
	_draw_text("ZOOM +", Vector2(zoom_x + 11.0, zoom_top + touch_target_size * 0.62), 14, Color("#e5f8eb"))
	draw_rect(Rect2(Vector2(zoom_x, zoom_bottom_top), Vector2(94.0, touch_target_size)), Color("#183329"))
	draw_rect(Rect2(Vector2(zoom_x, zoom_bottom_top), Vector2(94.0, touch_target_size)), Color("#6ccf91"), false, 2.0)
	_draw_text("ZOOM -", Vector2(zoom_x + 11.0, zoom_bottom_top + touch_target_size * 0.62), 14, Color("#e5f8eb"))

func _draw_hud() -> void:
	var hud_left: float = safe_insets.x + HUD_EDGE_PADDING
	var hud_top: float = safe_insets.y + HUD_EDGE_PADDING
	draw_rect(Rect2(hud_left, hud_top, 500.0, 160.0), Color("#0b1b17", 0.94))
	_draw_text("CONTAINMENT PROTOCOL", Vector2(hud_left + 16.0, hud_top + 34.0), 22, Color("#e2f4e9"))
	if campaign_start_grace_timer > 0.0:
		_draw_text("PREP  %02d:%02d" % [int(ceil(campaign_start_grace_timer)) / 60, int(ceil(campaign_start_grace_timer)) % 60], Vector2(hud_left + 255.0, hud_top + 34.0), 14, Color("#80e8b1"))
	_draw_text("FOOD 🌾%d  WOOD 🪵%d  SCRAP ⚙%d  FUEL ⛽%.0f  R:%d S:%d H:%d M:%d" % [food, wood, scrap, fuel, int(weapons.get("rifles", 0)), int(weapons.get("snipers", 0)), int(weapons.get("heavy_mgs", 0)), int(weapons.get("medkits", 0))], Vector2(hud_left + 16.0, hud_top + 70.0), 10, Color("#f4d77b"))
	_draw_text("DAY %d  |  %s  |  WAVE %d" % [survival_day, _format_world_clock(), wave], Vector2(hud_left + 16.0, hud_top + 104.0), 15, Color("#ffad62"))
	_draw_text("SAVED %d  LOST %d  HORDE %d/%d" % [saved_count, lost_count, zombies.size(), MAX_ACTIVE_ZOMBIES], Vector2(hud_left + 16.0, hud_top + 124.0), 13, Color("#9cbcaf"))
	_draw_text("%s  |  POP %d  |  SAVED %d" % [day_phase, civilians.size() + _total_sheltered_civilians(), saved_count], Vector2(hud_left + 16.0, hud_top + 144.0), 12, Color("#a9c8b7"))
	var pause_rect := _pause_button_rect()
	draw_rect(pause_rect, Color("#472a2a") if not manual_paused else Color("#245a3c"))
	draw_rect(pause_rect, Color("#e4c66d"), false, 2.0)
	_draw_text("[PAUSE ||]" if not manual_paused else "[PLAY ▶]", pause_rect.position + Vector2(8.0, 29.0), 13, Color("#fff4c7"))
	var log_rect := _radio_log_button_rect()
	draw_rect(log_rect, Color("#183329"))
	draw_rect(log_rect, Color("#6cb8d1"), false, 2.0)
	_draw_text("[LOG %d]" % radio_log.size(), log_rect.position + Vector2(12.0, 29.0), 13, Color("#e4f4f6"))
	if message_timer > 0.0:
		_draw_text(message, Vector2(hud_left + 16.0, hud_top + 164.0), 14, Color("#ffbd76"))
	draw_rect(Rect2(hud_left, hud_top + 196.0, 172.0, touch_target_size), Color("#183329"))
	draw_rect(Rect2(hud_left, hud_top + 196.0, 172.0, touch_target_size), Color("#6ccf91"), false, 2.0)
	_draw_text("TIME  " + TIME_LABELS[time_scale_index], Vector2(hud_left + 15.0, hud_top + 196.0 + touch_target_size * 0.62), 17, Color("#e5f8eb"))
	var sfx_top: float = hud_top + 196.0 + touch_target_size + 6.0
	draw_rect(Rect2(hud_left, sfx_top, 172.0, touch_target_size), Color("#183329"))
	draw_rect(Rect2(hud_left, sfx_top, 172.0, touch_target_size), Color("#6ccf91") if sfx_enabled else Color("#8b6262"), false, 2.0)
	_draw_text("[SFX: ON]" if sfx_enabled else "[SFX: OFF]", Vector2(hud_left + 15.0, sfx_top + touch_target_size * 0.62), 16, Color("#e5f8eb"))
	var ai_rect := _ai_button_rect()
	draw_rect(ai_rect, Color("#183329"))
	draw_rect(ai_rect, Color("#6ccf91") if auto_ops_enabled else Color("#8b6262"), false, 2.0)
	_draw_text("[WORK: %s]" % ("OUTSIDE" if work_outside_enabled else "RECALL"), ai_rect.position + Vector2(8.0, touch_target_size * 0.62), 12, Color("#e5f8eb"))
	var inf_rect := _recruit_button_rect(0)
	var sniper_rect := _recruit_button_rect(1)
	for recruit_rect in [inf_rect, sniper_rect]:
		draw_rect(recruit_rect, Color("#183329"))
		draw_rect(recruit_rect, Color("#6ccf91"), false, 2.0)
	_draw_text("[ASSIGN INFANTRY]", inf_rect.position + Vector2(5.0, touch_target_size * 0.62), 10, Color("#e5f8eb"))
	_draw_text("[ASSIGN SNIPER]", sniper_rect.position + Vector2(4.0, touch_target_size * 0.62), 9, Color("#e5f8eb"))
	var engineer_rect := _engineer_button_rect()
	draw_rect(engineer_rect, Color("#183329"))
	draw_rect(engineer_rect, Color("#6ccf91"), false, 2.0)
	_draw_text("[ASSIGN ENGINEER]", engineer_rect.position + Vector2(4.0, touch_target_size * 0.62), 10, Color("#e5f8eb"))
	var beacon_rect := _rescue_broadcast_rect()
	draw_rect(beacon_rect, Color("#243b4c"))
	draw_rect(beacon_rect, Color("#75c9e8"), false, 2.0)
	_draw_text("[RESCUE BEACON MATS / ⚙25]", beacon_rect.position + Vector2(4.0, touch_target_size * 0.62), 9, Color("#e5f8eb"))
	var salvage_rect := _salvage_button_rect()
	draw_rect(salvage_rect, Color("#3a3420"))
	draw_rect(salvage_rect, Color("#e4c66d"), false, 2.0)
	_draw_text("[SALVAGE]", salvage_rect.position + Vector2(10.0, touch_target_size * 0.62), 13, Color("#fff4c7"))
	var diagnostic_rect := Rect2(Vector2(safe_insets.x + DIAGNOSTIC_BUTTON.position.x, safe_insets.y + DIAGNOSTIC_BUTTON.position.y), Vector2(DIAGNOSTIC_BUTTON.size.x, touch_target_size))
	draw_rect(diagnostic_rect, Color("#183329"))
	draw_rect(diagnostic_rect, Color("#6ccf91") if diagnostics_enabled else Color("#49645a"), false, 2.0)
	_draw_text("DIAG", diagnostic_rect.position + Vector2(20.0, 32.0), 16, Color("#e5f8eb"))
	if diagnostics_enabled:
		var entity_count := civilians.size() + zombies.size() + units.size() + barricades.size() + outposts.size() + turrets.size() + flares.size()
		draw_rect(Rect2(safe_insets.x + 210.0, safe_insets.y + 274.0, 210.0, 52.0), Color("#0b1b17", 0.94))
		_draw_text("FPS %d | ENT %d" % [fps_sample_value, entity_count], Vector2(safe_insets.x + 220.0, safe_insets.y + 306.0), 14, Color("#a9c8b7"))

func _draw_outpost_placement_hud(top: float) -> void:
	var confirm_color: Color = Color("#245a3c") if outpost_placement_valid else Color("#5a292b")
	var safe_left: float = safe_insets.x + HUD_EDGE_PADDING
	var safe_width: float = viewport_size.x - safe_insets.x - safe_insets.z - HUD_EDGE_PADDING * 2.0
	var half_width: float = safe_width * 0.5
	draw_rect(Rect2(safe_left, top, half_width - 6.0, touch_target_size), confirm_color)
	draw_rect(Rect2(safe_left, top, half_width - 6.0, touch_target_size), Color("#72d69a") if outpost_placement_valid else Color("#ff6868"), false, 2.0)
	var initial_convoy_hq: bool = outpost_placement_kind == "hq" and outposts.is_empty()
	var confirm_label: String = "[CLAIM TERRITORY — FREE]" if outpost_placement_kind == "expand" else ("[CONFIRM HQ — FREE]" if initial_convoy_hq else "[CONFIRM (W%d S%d)]" % [_outpost_placement_wood_cost(), _outpost_placement_cost()])
	_draw_text(confirm_label, Vector2(safe_left + 10.0, top + touch_target_size * 0.62), 14, Color("#f0fff5"))
	var cancel_left: float = safe_left + half_width + 6.0
	draw_rect(Rect2(cancel_left, top, half_width - 6.0, touch_target_size), Color("#472a2a"))
	draw_rect(Rect2(cancel_left, top, half_width - 6.0, touch_target_size), Color("#d77b7b"), false, 2.0)
	_draw_text("[CANCEL]", Vector2(cancel_left + 36.0, top + touch_target_size * 0.62), 16, Color("#fff0f0"))

func _draw_structure_actions() -> void:
	if selected_structure_type.is_empty() or selected_structure_index < 0:
		return
	var structure_label := selected_structure_type.to_upper()
	var can_upgrade := selected_structure_type == "outpost" or selected_structure_type == "turret"
	var structure_hp := 0.0
	var structure_max_hp := 1.0
	match selected_structure_type:
		"outpost":
			if selected_structure_index >= outposts.size():
				return
			structure_hp = float(outposts[selected_structure_index]["hp"])
			structure_max_hp = float(outposts[selected_structure_index]["max_hp"])
			structure_label = "OUTPOST  LV.%d" % int(outposts[selected_structure_index].get("level", 1))
		"turret":
			if selected_structure_index >= turrets.size():
				return
			structure_hp = float(turrets[selected_structure_index]["hp"])
			structure_max_hp = float(turrets[selected_structure_index]["max_hp"])
			structure_label = "SENTRY  LV.%d" % int(turrets[selected_structure_index].get("level", 1))
		"wall":
			if selected_structure_index >= barricades.size():
				return
			structure_hp = float(barricades[selected_structure_index]["hp"])
			structure_max_hp = float(barricades[selected_structure_index]["max_hp"])
			structure_label = "REINFORCED WALL"
		_:
			return
	var action_top: float = _structure_action_top()
	var action_panel_height: float = touch_target_size * (2.0 if selected_structure_type == "outpost" else 1.0) + 64.0
	draw_rect(Rect2(safe_insets.x + 18.0, action_top, 380.0, action_panel_height), Color("#0b1b17", 0.96))
	_draw_text("%s  HP %d/%d" % [structure_label, roundi(structure_hp), roundi(structure_max_hp)], Vector2(safe_insets.x + 30.0, action_top + 24.0), 14, Color("#dcefe4"))
	draw_rect(Rect2(safe_insets.x + 24.0, action_top + 42.0, 166.0, touch_target_size), Color("#254538"))
	draw_rect(Rect2(safe_insets.x + 24.0, action_top + 42.0, 166.0, touch_target_size), Color("#72d69a"), false, 2.0)
	_draw_text("REPAIR MATS", Vector2(safe_insets.x + 40.0, action_top + 42.0 + touch_target_size * 0.62), 16, Color("#f0fff5"))
	if can_upgrade:
		var level := 1
		if selected_structure_type == "outpost":
			level = int(outposts[selected_structure_index].get("level", 1))
		else:
			level = int(turrets[selected_structure_index].get("level", 1))
		if level < 2:
			draw_rect(Rect2(safe_insets.x + 204.0, action_top + 42.0, 166.0, touch_target_size), Color("#3a3420"))
			draw_rect(Rect2(safe_insets.x + 204.0, action_top + 42.0, 166.0, touch_target_size), Color("#e4c66d"), false, 2.0)
			_draw_text("UPGRADE MATS", Vector2(safe_insets.x + 213.0, action_top + 42.0 + touch_target_size * 0.62), 15, Color("#fff4c7"))
		if selected_structure_type == "outpost":
			var expand_rect := Rect2(safe_insets.x + 24.0, action_top + 48.0 + touch_target_size, 346.0, touch_target_size)
			draw_rect(expand_rect, Color("#244b3a"))
			draw_rect(expand_rect, Color("#72d69a"), false, 2.0)
			_draw_text("[EXPAND TERRITORY — FREE]", expand_rect.position + Vector2(8.0, touch_target_size * 0.62), 13, Color("#f0fff5"))

func _draw_milestone13_rooftop_bars() -> void:
	var visible_rect: Rect2 = _camera_view_rect().grow(80.0)
	for site in constructed_buildings:
		if not bool(site.get("constructing", false)):
			continue
		var site_pos: Vector2 = site.get("pos", Vector2.ZERO)
		if not visible_rect.has_point(site_pos):
			continue
		var progress: float = clampf(float(site.get("progress", 0.0)) / 100.0, 0.0, 1.0)
		var bar_rect := Rect2(site_pos + Vector2(-48.0, -34.0), Vector2(96.0, 9.0))
		draw_rect(bar_rect, Color("#101a17"))
		draw_rect(Rect2(bar_rect.position, Vector2(bar_rect.size.x * progress, bar_rect.size.y)), Color("#7de5a5"))
		draw_rect(bar_rect, Color("#e7fff0"), false, 1.5)
		_draw_text("CONSTRUCTING %d%%" % roundi(progress * 100.0), site_pos + Vector2(-48.0, -40.0), 10, Color("#f5f4c7"))

func _draw_deployment_bar() -> void:
	var panel_height: float = _deployment_panel_height()
	var top: float = _safe_bottom_y(panel_height)
	var safe_left: float = safe_insets.x
	var safe_width: float = viewport_size.x - safe_insets.x - safe_insets.z
	draw_rect(Rect2(safe_left, top, safe_width, panel_height), Color("#0b1715"))
	draw_line(Vector2(safe_left, top), Vector2(safe_left + safe_width, top), Color("#45665a"), 2.0)
	var tab_width: float = safe_width / 3.0
	var tab_labels: Array[String] = ["BUILD", "RECRUIT", "TACTICS"]
	for tab_index in range(3):
		var tab_rect := Rect2(safe_left + float(tab_index) * tab_width, top, tab_width, touch_target_size)
		draw_rect(tab_rect, Color("#254538") if command_tab == tab_index else Color("#12251f"))
		_draw_text(tab_labels[tab_index], Vector2(tab_rect.position.x + 12.0, top + touch_target_size * 0.62), 14, Color("#e8fff0"))
	var choices: Array = BASE_DEPLOYMENTS if command_tab == 0 else (RECRUIT_DEPLOYMENTS if command_tab == 1 else UNIT_DEPLOYMENTS)
	var button_width: float = safe_width / float(choices.size())
	var cards_top: float = top + touch_target_size + 6.0
	var card_height: float = panel_height - touch_target_size - 6.0
	var item_title_size: int = 9 if choices.size() > 6 else 13
	var item_detail_size: int = 8 if choices.size() > 6 else 12
	for i in range(choices.size()):
		var x: float = safe_left + float(i) * button_width
		var selected := i == selected_deployment
		draw_rect(Rect2(x + 3.0, cards_top, button_width - 6.0, card_height), Color("#254538") if selected else Color("#12251f"))
		draw_rect(Rect2(x + 3.0, cards_top, button_width - 6.0, card_height), Color("#72d69a") if selected else Color("#29443a"), false, 2.0)
		var deployment: Dictionary = choices[i]
		_draw_text(str(deployment["name"]), Vector2(x + 5.0, cards_top + card_height * 0.27), item_title_size, Color("#e8fff0") if selected else Color("#b2c7bc"))
		var detail := str(deployment["detail"])
		if str(deployment["kind"]) == "outpost":
			detail = "MATS %d" % _deployment_cost("outpost")
		_draw_text(detail, Vector2(x + 5.0, cards_top + card_height * 0.52), item_detail_size, Color("#f0cc77"))
		_draw_text("TAP MAP", Vector2(x + 5.0, cards_top + card_height * 0.78), 8 if choices.size() > 6 else 10, Color("#8da99a"))

func _select_structure_at(world_position: Vector2) -> bool:
	for index in range(outposts.size() - 1, -1, -1):
		if world_position.distance_to(outposts[index]["pos"]) <= 28.0:
			selected_structure_type = "outpost"
			selected_structure_index = index
			selected_unit_index = -1
			return true
	for index in range(turrets.size() - 1, -1, -1):
		if world_position.distance_to(turrets[index]["pos"]) <= 24.0:
			selected_structure_type = "turret"
			selected_structure_index = index
			selected_unit_index = -1
			return true
	for index in range(barricades.size() - 1, -1, -1):
		if world_position.distance_to(barricades[index]["pos"]) <= 26.0:
			selected_structure_type = "wall"
			selected_structure_index = index
			selected_unit_index = -1
			return true
	return false

func _repair_selected_structure() -> void:
	if scrap < STRUCTURE_REPAIR_COST or scrap < 8:
		message = "REPAIR REQUIRES MATS AND ⚙8"
		message_timer = 1.2
		return
	var repaired := false
	match selected_structure_type:
		"outpost":
			if selected_structure_index < outposts.size():
				var structure: Dictionary = outposts[selected_structure_index]
				var old_hp := float(structure["hp"])
				structure["hp"] = minf(float(structure["max_hp"]), old_hp + 100.0)
				outposts[selected_structure_index] = structure
				repaired = float(structure["hp"]) > old_hp
		"turret":
			if selected_structure_index < turrets.size():
				var structure: Dictionary = turrets[selected_structure_index]
				var old_hp := float(structure["hp"])
				structure["hp"] = minf(float(structure["max_hp"]), old_hp + 100.0)
				turrets[selected_structure_index] = structure
				repaired = float(structure["hp"]) > old_hp
		"wall":
			if selected_structure_index < barricades.size():
				var structure: Dictionary = barricades[selected_structure_index]
				var old_hp := float(structure["hp"])
				structure["hp"] = minf(float(structure["max_hp"]), old_hp + 100.0)
				barricades[selected_structure_index] = structure
				repaired = float(structure["hp"]) > old_hp
	if repaired:
		scrap -= STRUCTURE_REPAIR_COST
		scrap -= 8
		message = "STRUCTURE REPAIRED +100 HP"
	else:
		message = "STRUCTURE ALREADY AT FULL HP"
	message_timer = 1.3
	queue_redraw()

func _upgrade_selected_structure() -> void:
	if scrap < STRUCTURE_UPGRADE_COST or scrap < 15:
		message = "UPGRADE REQUIRES MATS AND ⚙15"
		message_timer = 1.2
		return
	var upgraded := false
	if selected_structure_type == "turret" and selected_structure_index < turrets.size():
		var turret: Dictionary = turrets[selected_structure_index]
		if int(turret.get("level", 1)) < 2:
			turret["level"] = 2
			turret["range"] = 280.0
			turret["damage"] = 32.0
			turret["fire_interval"] = 0.15
			turrets[selected_structure_index] = turret
			upgraded = true
	elif selected_structure_type == "outpost" and selected_structure_index < outposts.size():
		var outpost: Dictionary = outposts[selected_structure_index]
		if int(outpost.get("level", 1)) < 2:
			outpost["level"] = 2
			outpost["safe_radius"] = 230.0
			outpost["capacity"] = maxi(20, int(outpost.get("capacity", 12)))
			outposts[selected_structure_index] = outpost
			upgraded = true
	if upgraded:
		scrap -= STRUCTURE_UPGRADE_COST
		scrap -= 15
		message = "STRUCTURE UPGRADED TO LEVEL 2"
	else:
		message = "NO AVAILABLE UPGRADE"
	message_timer = 1.5
	queue_redraw()

func _update_preview_position(position: Vector2) -> void:
	preview_position = _screen_to_world(position)
	preview_active = true
	queue_redraw()

func _draw_placement_preview() -> void:
	if outpost_placement_active:
		var footprint_color: Color = Color("#55ef91") if outpost_placement_valid else Color("#ff5d62")
		draw_rect(outpost_placement_rect, Color(footprint_color.r, footprint_color.g, footprint_color.b, 0.14))
		draw_rect(outpost_placement_rect, footprint_color, false, 5.0)
		var handle_radius: float = touch_target_size * 0.5 / maxf(camera_zoom, 0.01)
		var handle_points: Array[Vector2] = [outpost_placement_rect.position, Vector2(outpost_placement_rect.end.x, outpost_placement_rect.position.y), outpost_placement_rect.end, Vector2(outpost_placement_rect.position.x, outpost_placement_rect.end.y)]
		for handle_point in handle_points:
			draw_circle(handle_point, handle_radius, Color(footprint_color.r, footprint_color.g, footprint_color.b, 0.18))
			draw_arc(handle_point, handle_radius, 0.0, TAU, 24, footprint_color, 3.0)
		return
	if not preview_active or game_state != "playing":
		return
	var choices: Array = BASE_DEPLOYMENTS if command_tab == 0 else (RECRUIT_DEPLOYMENTS if command_tab == 1 else UNIT_DEPLOYMENTS)
	if selected_deployment < 0 or selected_deployment >= choices.size():
		return
	var deployment: Dictionary = choices[selected_deployment]
	var kind: String = str(deployment["kind"])
	var radius := _deployment_range(kind)
	var deployment_cost := _deployment_cost(kind)
	var valid := _is_valid_street_position(preview_position) and scrap >= deployment_cost
	if kind == "outpost" and outposts.size() >= OUTPOST_MAX_COUNT + 1:
		valid = false
	if kind == "gate":
		valid = scrap >= GATE_COST and scrap >= 15
	elif kind == "turret":
		valid = scrap >= TURRET_COST and scrap >= 25
	elif kind == "wall":
		valid = wood >= WALL_COST
	var tint := Color(0.2, 1.0, 0.48, 0.18) if valid else Color(1.0, 0.18, 0.2, 0.20)
	var line_tint := Color("#56f58f") if valid else Color("#ff555d")
	draw_circle(preview_position, radius, tint)
	draw_arc(preview_position, radius, 0.0, TAU, 56, line_tint, 2.5)
	draw_circle(preview_position, 5.0, Color(line_tint.r, line_tint.g, line_tint.b, 0.8))

func _deployment_cost(kind: String) -> int:
	if kind == "outpost":
		return _outpost_build_cost(outpost_placement_rect.size)
	var choices: Array = BASE_DEPLOYMENTS if command_tab == 0 else (RECRUIT_DEPLOYMENTS if command_tab == 1 else UNIT_DEPLOYMENTS)
	return int(choices[selected_deployment]["cost"])

func _deployment_range(kind: String) -> float:
	match kind:
		"infantry":
			return 205.0
		"sniper":
			return 390.0
		"airstrike":
			return 112.0
		"flare":
			return FLARE_LURE_RADIUS
		"wall":
			return 30.0
		"outpost":
			return 175.0
		"turret":
			return TURRET_RANGE
	return 30.0

func _find_nearest_flare(position: Vector2) -> int:
	var best_index := -1
	var best_distance := FLARE_LURE_RADIUS * FLARE_LURE_RADIUS
	for index in range(flares.size()):
		var distance: float = position.distance_squared_to(flares[index]["pos"])
		if distance <= best_distance:
			best_distance = distance
			best_index = index
	return best_index

func _update_flares(delta: float) -> void:
	for index in range(flares.size() - 1, -1, -1):
		var flare: Dictionary = flares[index]
		flare["life"] = float(flare["life"]) - delta
		flare["phase"] = float(flare["phase"]) + delta
		if float(flare["life"]) <= 0.0:
			flares.remove_at(index)
		else:
			flares[index] = flare

func _damage_zombie(index: int, damage: float, attacker_unit_index: int = -1, projectile_origin: Vector2 = Vector2(-1.0, -1.0)) -> void:
	if index < 0 or index >= zombies.size():
		return
	var zombie: Dictionary = zombies[index]
	if projectile_origin != Vector2(-1.0, -1.0) and not _has_clear_building_line_of_sight(projectile_origin, zombie.get("pos", Vector2.ZERO)):
		return
	var final_damage: float = damage
	if day_phase == "NIGHT" and _is_position_illuminated(zombie["pos"]) and randf() < 0.15:
		final_damage *= 1.75
		world_callouts.append({"pos": zombie["pos"], "text": "CRITICAL", "life": 0.65})
	zombie["hp"] = maxf(0.0, float(zombie.get("hp", 30.0)) - final_damage)
	if float(zombie["hp"]) > 0.0:
		zombies[index] = zombie
		return
	var dead_position: Vector2 = zombie["pos"]
	var dead_kind: String = str(zombie["kind"])
	_milestone14_award_settlement_kill(dead_position)
	if dead_kind == "police_zed":
		var drop_roll: float = randf()
		if drop_roll < 0.30:
			weapons["rifles"] = int(weapons.get("rifles", 0)) + 1
			world_callouts.append({"pos": dead_position, "text": "+1 RIFLE", "life": 2.0})
		elif drop_roll < 0.48:
			weapons["snipers"] = int(weapons.get("snipers", 0)) + 1
			world_callouts.append({"pos": dead_position, "text": "+1 SNIPER", "life": 2.0})
		elif drop_roll < 0.58:
			weapons["heavy_mgs"] = int(weapons.get("heavy_mgs", 0)) + 1
			world_callouts.append({"pos": dead_position, "text": "+1 HEAVY MG", "life": 2.0})
		elif drop_roll < 0.76:
			weapons["medkits"] = int(weapons.get("medkits", 0)) + 1
			world_callouts.append({"pos": dead_position, "text": "+1 MEDKIT", "life": 2.0})
		else:
			scrap += 25
			world_callouts.append({"pos": dead_position, "text": "+25 MATS", "life": 2.0})
	if attacker_unit_index >= 0 and attacker_unit_index < units.size():
		var veteran: Dictionary = units[attacker_unit_index]
		var survivor_id: int = int(veteran.get("survivor_id", -1))
		for survivor_index in range(survivors.size()):
			if int(survivors[survivor_index].get("id", -2)) == survivor_id:
				survivors[survivor_index]["combat_xp"] = int(survivors[survivor_index].get("combat_xp", 0)) + 10
				break
		var kills: int = int(veteran.get("kills", 0)) + 1
		var old_rank: int = clampi(int(veteran.get("rank", 0)), 0, 3)
		var new_rank: int = mini(3, int(floor(float(kills) / 5.0)))
		veteran["kills"] = kills
		if new_rank > old_rank:
			veteran["rank"] = new_rank
			veteran["max_hp"] = float(veteran.get("max_hp", 100.0)) + 15.0
			veteran["hp"] = minf(float(veteran["max_hp"]), float(veteran.get("hp", 100.0)) + 15.0)
			message = "VETERAN PROMOTION — RANK %d" % new_rank
			message_timer = 2.0
			world_callouts.append({"pos": veteran["pos"], "text": "★ RANK %d" % new_rank, "life": 2.4})
		units[attacker_unit_index] = veteran
	zombies.remove_at(index)
	if dead_kind == "spitter":
		_spitter_burst(dead_position)
	_save_operation()

func _spitter_burst(center: Vector2) -> void:
	shockwaves.append({"pos": center, "radius": 45.0, "life": 0.35, "max_life": 0.35, "toxic": true})
	var infected := 0
	for index in range(civilians.size() - 1, -1, -1):
		if center.distance_to(civilians[index]) <= 45.0:
			var infected_position: Vector2 = civilians[index]
			civilians.remove_at(index)
			if index < civilian_steering.size():
				civilian_steering.remove_at(index)
			if zombies.size() < MAX_ACTIVE_ZOMBIES:
				zombies.append({"pos": infected_position, "kind": "shambler", "hp": 30.0, "max_hp": 30.0})
			infected += 1
	for unit_index in range(units.size()):
		var exposed_unit: Dictionary = units[unit_index]
		if center.distance_to(exposed_unit.get("pos", Vector2.ZERO)) <= 45.0:
			exposed_unit["hp"] = maxf(1.0, float(exposed_unit.get("hp", 100.0)) - 18.0)
			units[unit_index] = exposed_unit
			_milestone15_apply_pathogen_exposure(unit_index, "spitter")
	if infected > 0:
		lost_count += infected
		message = "TOXIC BURST — %d CIVILIANS INFECTED" % infected
		message_timer = 2.0
	else:
		message = "SPITTER TOXIC BURST"
		message_timer = 1.0
	_queue_sfx("infection")

func _setup_audio() -> void:
	audio_rng.randomize()
	var generator := AudioStreamGenerator.new()
	generator.mix_rate = AUDIO_SAMPLE_RATE
	generator.buffer_length = 0.25
	var player := AudioStreamPlayer.new()
	player.stream = generator
	player.volume_db = -7.0
	audio_player = player
	add_child(audio_player)
	audio_player.play()
	var playback: AudioStreamGeneratorPlayback = audio_player.get_stream_playback() as AudioStreamGeneratorPlayback
	if playback != null:
		pass

func _queue_sfx(effect: String) -> void:
	if not sfx_enabled:
		return
	if audio_queue.size() < 12:
		audio_queue.append(effect)

func _update_audio() -> void:
	if audio_player == null or not audio_player.playing:
		return
	var playback: AudioStreamGeneratorPlayback = audio_player.get_stream_playback() as AudioStreamGeneratorPlayback
	if playback == null:
		return
	if not sfx_enabled:
		while playback.get_frames_available() > 0:
			if playback != null:
				playback.push_frame(Vector2.ZERO)
		return
	while audio_samples_left <= 0 and not audio_queue.is_empty():
		audio_effect = audio_queue.pop_front()
		audio_phase = 0.0
		match audio_effect:
			"gunfire":
				audio_samples_left = 1500
			"airstrike":
				audio_samples_left = 11025
			"flare":
				audio_samples_left = 4400
			"infection":
				audio_samples_left = 3300
			"menu_click":
				audio_samples_left = 1800
			"radar":
				audio_samples_left = 4200
	while playback.get_frames_available() > 0:
		var sample := 0.0
		if audio_samples_left > 0:
			var progress := 1.0 - float(audio_samples_left) / 11025.0
			match audio_effect:
				"gunfire":
					sample = (audio_rng.randf_range(-1.0, 1.0) * 0.55 + sin(audio_phase * TAU) * 0.25) * (float(audio_samples_left) / 1500.0)
				"airstrike":
					sample = (audio_rng.randf_range(-1.0, 1.0) * 0.32 + sin(audio_phase * TAU * 48.0) * 0.35) * (1.0 - progress) * 0.8
				"flare":
					sample = (audio_rng.randf_range(-1.0, 1.0) * 0.10 + sin(audio_phase * TAU * 880.0) * 0.08) * (1.0 - progress)
				"infection":
					var beep_phase := fposmod(audio_phase, 0.11)
					sample = sin(audio_phase * TAU * 1040.0) * 0.22 if beep_phase < 0.055 else 0.0
				"menu_click":
					sample = sin(audio_phase * TAU * 1320.0) * (float(audio_samples_left) / 1800.0) * 0.20
				"radar":
					var radar_phase := fposmod(audio_phase, 0.19)
					sample = sin(audio_phase * TAU * 740.0) * 0.18 if radar_phase < 0.065 else 0.0
			audio_phase += 1.0 / AUDIO_SAMPLE_RATE
			audio_samples_left -= 1
		if playback != null:
			playback.push_frame(Vector2(sample, sample))

func _draw_end_screen() -> void:
	draw_rect(Rect2(Vector2.ZERO, viewport_size), Color(0.01, 0.04, 0.03, 0.88))
	var title := "30-WAVE OPERATION SECURED" if game_state == "victory" else "EVACUATION FAILED"
	var tint := Color("#72f0a2") if game_state == "victory" else Color("#ff6868")
	_draw_text(title, Vector2(viewport_size.x * 0.13, viewport_size.y * 0.40), 38, tint)
	_draw_text("SECTOR %02d — %s" % [sector_index + 1, sector_name.to_upper()], Vector2(viewport_size.x * 0.18, viewport_size.y * 0.44), 18, Color("#b9d9c6"))
	_draw_text("CIVILIANS SAVED: %d" % saved_count, Vector2(viewport_size.x * 0.26, viewport_size.y * 0.48), 22, Color("#e0eee5"))
	_draw_text("CIVILIANS LOST: %d" % lost_count, Vector2(viewport_size.x * 0.26, viewport_size.y * 0.52), 22, Color("#e0a0a0"))
	draw_rect(Rect2(viewport_size.x * 0.21, viewport_size.y * 0.57, viewport_size.x * 0.58, 90), Color("#244a38"))
	draw_rect(Rect2(viewport_size.x * 0.21, viewport_size.y * 0.57, viewport_size.x * 0.58, 90), Color("#8ce5ad"), false, 3.0)
	if wave >= 30 and game_state == "victory":
		draw_rect(Rect2(viewport_size.x * 0.21, viewport_size.y * 0.68, viewport_size.x * 0.58, 72.0), Color("#3a3420"))
		draw_rect(Rect2(viewport_size.x * 0.21, viewport_size.y * 0.68, viewport_size.x * 0.58, 72.0), Color("#e4c66d"), false, 2.0)
		_draw_text("CONTINUE ENDLESS CONTAINMENT", Vector2(viewport_size.x * 0.245, viewport_size.y * 0.725), 16, Color("#fff4c7"))
	_draw_text("RETURN TO SECTOR SELECT", Vector2(viewport_size.x * 0.25, viewport_size.y * 0.615), 20, Color("#f0fff5"))


func _on_viewport_size_changed() -> void:
	viewport_size = get_viewport_rect().size
	_refresh_safe_area()
	_clamp_camera()
	queue_redraw()

func _refresh_safe_area() -> void:
	var screen_size: Vector2i = DisplayServer.screen_get_size()
	var display_safe_area: Rect2i = DisplayServer.get_display_safe_area()
	if DisplayServer.get_name() == "headless" or screen_size.x <= 0 or screen_size.y <= 0 or display_safe_area.size.x <= 0 or display_safe_area.size.y <= 0:
		safe_insets = Vector4.ZERO
		safe_area_rect = Rect2(Vector2.ZERO, viewport_size)
		return
	var safe_left_px: int = clampi(display_safe_area.position.x, 0, screen_size.x)
	var safe_top_px: int = clampi(display_safe_area.position.y, 0, screen_size.y)
	var safe_right_px: int = clampi(screen_size.x - display_safe_area.end.x, 0, screen_size.x)
	var safe_bottom_px: int = clampi(screen_size.y - display_safe_area.end.y, 0, screen_size.y)
	var viewport_scale: Vector2 = viewport_size / Vector2(screen_size)
	var screen_dpi: int = maxi(DisplayServer.screen_get_dpi(), 160)
	touch_target_size = maxf(MIN_TOUCH_TARGET, 48.0 * float(screen_dpi) / 160.0 * maxf(viewport_scale.x, viewport_scale.y))
	safe_insets = Vector4(float(safe_left_px) * viewport_scale.x, float(safe_top_px) * viewport_scale.y, float(safe_right_px) * viewport_scale.x, float(safe_bottom_px) * viewport_scale.y)
	# Conservative logical minimums cover iOS Dynamic Island and Home Indicator
	# when a platform driver reports only the physical display safe rectangle.
	safe_insets.y = maxf(safe_insets.y, 62.0 * viewport_scale.y)
	safe_insets.w = maxf(safe_insets.w, 34.0 * viewport_scale.y)
	var max_horizontal_inset: float = viewport_size.x * 0.20
	var max_vertical_inset: float = viewport_size.y * 0.20
	safe_insets.x = minf(safe_insets.x, max_horizontal_inset)
	safe_insets.y = minf(safe_insets.y, max_vertical_inset)
	safe_insets.z = minf(safe_insets.z, max_horizontal_inset)
	safe_insets.w = minf(safe_insets.w, max_vertical_inset)
	safe_area_rect = Rect2(Vector2(safe_insets.x, safe_insets.y), Vector2(maxf(1.0, viewport_size.x - safe_insets.x - safe_insets.z), maxf(1.0, viewport_size.y - safe_insets.y - safe_insets.w)))

func _safe_viewport_size() -> Vector2:
	return safe_area_rect.size

func _safe_bottom_y(panel_height: float) -> float:
	return maxf(safe_insets.y, viewport_size.y - safe_insets.w - panel_height)

func _deployment_panel_height() -> float:
	return maxf(200.0, touch_target_size + 146.0)

func _structure_action_top() -> float:
	return safe_insets.y + maxf(STRUCTURE_ACTION_TOP, HUD_EDGE_PADDING + 196.0 + 3.0 * (touch_target_size + 6.0))

func _camera_view_rect() -> Rect2:
	# Derive the world-space culling rectangle from the same inverse transform
	# used by input. This keeps rendering and touch coordinates in lockstep.
	var top_left: Vector2 = _screen_to_world(Vector2.ZERO)
	var bottom_right: Vector2 = _screen_to_world(viewport_size)
	var rect_position := Vector2(minf(top_left.x, bottom_right.x), minf(top_left.y, bottom_right.y))
	var rect_end := Vector2(maxf(top_left.x, bottom_right.x), maxf(top_left.y, bottom_right.y))
	return Rect2(rect_position, rect_end - rect_position)

func _screen_to_world(screen_position: Vector2) -> Vector2:
	return camera_position + (screen_position - viewport_size * 0.5) / maxf(camera_zoom, 0.01)

func _clamp_camera() -> void:
	var half_view: Vector2 = viewport_size / maxf(camera_zoom, 0.01) * 0.5
	camera_position.x = clampf(camera_position.x, minf(half_view.x, WORLD_SIZE.x * 0.5), maxf(WORLD_SIZE.x - half_view.x, WORLD_SIZE.x * 0.5))
	camera_position.y = clampf(camera_position.y, minf(half_view.y, WORLD_SIZE.y * 0.5), maxf(WORLD_SIZE.y - half_view.y, WORLD_SIZE.y * 0.5))

func _zoom_camera(factor: float, screen_anchor: Vector2) -> void:
	var before: Vector2 = _screen_to_world(screen_anchor)
	camera_zoom = clampf(camera_zoom * factor, MIN_ZOOM, MAX_ZOOM)
	var after: Vector2 = _screen_to_world(screen_anchor)
	camera_position += before - after
	_clamp_camera()
	queue_redraw()

func _nearest_evac_zone(position: Vector2) -> Vector2:
	if evacuation_zones.is_empty():
		return primary_hq_position if primary_hq_position.x >= 0.0 else WORLD_SIZE * 0.5
	var nearest: Vector2 = evacuation_zones[0]
	var nearest_distance: float = position.distance_squared_to(nearest)
	for zone in evacuation_zones:
		var distance: float = position.distance_squared_to(zone)
		if distance < nearest_distance:
			nearest = zone
			nearest_distance = distance
	return nearest

func _night_vision_multiplier() -> float:
	return 0.8 if day_phase == "NIGHT" else 1.0

func _update_outpost_damage(delta: float) -> void:
	if outposts.is_empty() or zombies.is_empty():
		return
	for zombie_index in range(zombies.size() - 1, -1, -1):
		var zombie: Dictionary = zombies[zombie_index]
		var attack_cooldown: float = maxf(0.0, float(zombie.get("outpost_attack_cooldown", 0.0)) - delta)
		if attack_cooldown > 0.0:
			zombie["outpost_attack_cooldown"] = attack_cooldown
			zombies[zombie_index] = zombie
			continue
		var zombie_position: Vector2 = zombie["pos"]
		for outpost_index in range(outposts.size() - 1, -1, -1):
			var outpost: Dictionary = outposts[outpost_index]
			var outpost_rect: Rect2 = outpost.get("rect", Rect2(outpost["pos"] - Vector2(34.0, 34.0), Vector2(68.0, 68.0)))
			if not outpost_rect.grow(-20.0).has_point(zombie_position):
				continue
			var damage: float = 42.0 if str(zombie.get("kind", "shambler")) == "brute" else 18.0
			outpost["hp"] = maxf(0.0, float(outpost.get("hp", 500.0)) - damage)
			zombie["outpost_attack_cooldown"] = 1.0
			if float(outpost["hp"]) <= 0.0:
				recent_outpost_loss_timer = 180.0
				_eject_outpost_shelter(outpost)
				for wall_index in range(barricades.size() - 1, -1, -1):
					if int(barricades[wall_index].get("outpost_index", -1)) == outpost_index:
						barricades.remove_at(wall_index)
				for gate_index in range(gates.size() - 1, -1, -1):
					if int(gates[gate_index].get("outpost_index", -1)) == outpost_index:
						gates.remove_at(gate_index)
				outposts.remove_at(outpost_index)
				for remaining_wall in barricades:
					var wall_outpost_index: int = int(remaining_wall.get("outpost_index", -1))
					if wall_outpost_index > outpost_index:
						remaining_wall["outpost_index"] = wall_outpost_index - 1
				for remaining_gate in gates:
					var gate_outpost_index: int = int(remaining_gate.get("outpost_index", -1))
					if gate_outpost_index > outpost_index:
						remaining_gate["outpost_index"] = gate_outpost_index - 1
				message = "FORWARD OUTPOST DESTROYED — SHELTER EVACUATED"
			else:
				outposts[outpost_index] = outpost
				message = "FORWARD OUTPOST UNDER ATTACK"
			message_timer = 1.4
			break
		zombies[zombie_index] = zombie

func _nearest_walkable_building_exit(building_rect: Rect2, preferred_position: Vector2, occupied_positions: Array[Vector2]) -> Vector2:
	var search_rect: Rect2 = building_rect.grow(UNIT_SELECT_RADIUS + 14.0)
	var candidates: Array[Vector2] = []
	var horizontal_steps: int = maxi(1, ceili(search_rect.size.x / 32.0))
	var vertical_steps: int = maxi(1, ceili(search_rect.size.y / 32.0))
	for step_index in range(horizontal_steps + 1):
		var x_value: float = lerpf(search_rect.position.x, search_rect.end.x, float(step_index) / float(horizontal_steps))
		candidates.append(Vector2(x_value, search_rect.position.y))
		candidates.append(Vector2(x_value, search_rect.end.y))
	for step_index in range(vertical_steps + 1):
		var y_value: float = lerpf(search_rect.position.y, search_rect.end.y, float(step_index) / float(vertical_steps))
		candidates.append(Vector2(search_rect.position.x, y_value))
		candidates.append(Vector2(search_rect.end.x, y_value))
	var best_position: Vector2 = preferred_position
	var best_distance: float = INF
	for candidate in candidates:
		if building_rect.grow(UNIT_SELECT_RADIUS + 4.0).has_point(candidate) or not _is_valid_street_position(candidate):
			continue
		var occupied: bool = false
		for existing_position in occupied_positions:
			if candidate.distance_squared_to(existing_position) < 22.0 * 22.0:
				occupied = true
				break
		if occupied:
			continue
		var distance: float = preferred_position.distance_squared_to(candidate)
		if distance < best_distance:
			best_distance = distance
			best_position = candidate
	if best_distance < INF:
		return best_position
	for radius_step in range(1, 17):
		var radius: float = maxf(building_rect.size.x, building_rect.size.y) * 0.5 + 48.0 + float(radius_step) * 24.0
		for angle_index in range(24):
			var angle: float = TAU * float(angle_index) / 24.0
			var candidate: Vector2 = building_rect.get_center() + Vector2(cos(angle), sin(angle)) * radius
			if not _is_valid_street_position(candidate):
				continue
			var occupied: bool = false
			for existing_position in occupied_positions:
				if candidate.distance_squared_to(existing_position) < 22.0 * 22.0:
					occupied = true
					break
			if not occupied:
				return candidate
	return building_rect.get_center() + Vector2(0.0, -(maxf(building_rect.size.x, building_rect.size.y) * 0.5 + UNIT_SELECT_RADIUS + 16.0))

func _eject_building_garrison(building_index: int) -> void:
	if building_index < 0 or building_index >= buildings.size():
		return
	var building_rect: Rect2 = buildings[building_index]
	var occupied_positions: Array[Vector2] = []
	for unit_index in range(units.size()):
		var unit: Dictionary = units[unit_index]
		if not bool(unit.get("garrisoned", false)) or int(unit.get("garrison_building", -1)) != building_index:
			continue
		var exit_position: Vector2 = _nearest_walkable_building_exit(building_rect, building_rect.get_center(), occupied_positions)
		occupied_positions.append(exit_position)
		unit["garrisoned"] = false
		unit["garrison_building"] = -1
		unit["pos"] = exit_position
		unit["triage_timer"] = 2.5
		unit["status"] = "TRIAGE"
		unit["move_target"] = null
		unit["manual_order"] = false
		unit["hp"] = maxf(1.0, float(unit.get("hp", 100.0)) - 25.0)
		units[unit_index] = unit

func _update_triage(delta: float) -> void:
	if delta <= 0.0:
		return
	for unit_index in range(units.size()):
		var unit: Dictionary = units[unit_index]
		var triage_remaining: float = maxf(0.0, float(unit.get("triage_timer", 0.0)) - delta)
		unit["triage_timer"] = triage_remaining
		unit["status"] = "TRIAGE" if triage_remaining > 0.0 else ""
		if triage_remaining <= 0.0:
			units[unit_index] = unit
			continue
		var healing_rate: float = 0.0
		if food > 0:
			for building_index in range(building_archetypes.size()):
				var building_state: Dictionary = building_archetypes[building_index]
				if bool(building_state.get("destroyed", false)) or str(building_state.get("converted_to", "")) != "FIELD_CLINIC":
					continue
				if unit["pos"].distance_squared_to(buildings[building_index].get_center()) <= 180.0 * 180.0:
					healing_rate = maxf(healing_rate, 18.0 * _milestone14_facility_medical_multiplier())
					break
			if healing_rate <= 0.0:
				for clinic in constructed_buildings:
					if str(clinic.get("kind", "")) == "clinic" and unit["pos"].distance_squared_to(clinic.get("pos", Vector2.ZERO)) <= 150.0 * 150.0:
						healing_rate = maxf(healing_rate, 12.0 * _milestone14_facility_medical_multiplier())
						break
			if healing_rate <= 0.0:
				for medic_index in range(units.size()):
					if medic_index == unit_index:
						continue
					var medic: Dictionary = units[medic_index]
					if str(medic.get("kind", "")) == "medic" and not bool(medic.get("garrisoned", false)) and unit["pos"].distance_squared_to(medic.get("pos", Vector2.ZERO)) <= 120.0 * 120.0:
						healing_rate = maxf(healing_rate, 12.0 * _milestone14_proficiency_bonus(medic, "medical"))
						break
		if healing_rate > 0.0:
			unit["hp"] = minf(float(unit.get("max_hp", 100.0)), float(unit.get("hp", 100.0)) + healing_rate * delta)
		units[unit_index] = unit

func _eject_outpost_shelter(outpost: Dictionary) -> void:
	var sheltered: int = maxi(0, int(outpost.get("sheltered", 0)))
	if sheltered <= 0:
		return
	var affected: int = mini(sheltered, 8)
	var ejected: int = 0
	var outpost_rect: Rect2 = outpost.get("rect", Rect2(outpost.get("pos", Vector2.ZERO) - Vector2(110.0, 110.0), Vector2(220.0, 220.0)))
	var center: Vector2 = outpost_rect.get_center()
	var perimeter_radius: float = maxf(outpost_rect.size.x, outpost_rect.size.y) * 0.5 + 24.0
	for index in range(mini(affected, 4)):
		for attempt in range(16):
			var angle: float = TAU * float(index * 4 + attempt) / 16.0
			var candidate: Vector2 = center + Vector2(cos(angle), sin(angle)) * (perimeter_radius + float(attempt / 4) * 18.0)
			if _is_open_world_position(candidate, 8.0):
				civilians.append(candidate)
				civilian_steering.append({})
				ejected += 1
				break
	# The destroyed outpost is removed immediately after this call, so all
	# sheltered civilians not successfully ejected are recorded as casualties.
	outpost["sheltered"] = 0
	lost_count += sheltered - ejected
	if ejected > 0:
		message = "OUTPOST COLLAPSE — %d CIVILIANS EJECTED" % ejected
		message_timer = 1.5

func _total_sheltered_civilians() -> int:
	var total: int = 0
	for outpost in outposts:
		total += int(outpost.get("sheltered", 0))
	return total

func _shelter_flush_timer_step(delta: float) -> void:
	for index in range(outposts.size()):
		var outpost: Dictionary = outposts[index]
		var sheltered: int = int(outpost.get("sheltered", 0))
		if sheltered <= 0:
			continue
		var rect: Rect2 = outpost.get("rect", Rect2(outpost["pos"] - Vector2(110.0, 110.0), Vector2(220.0, 220.0)))
		var defended := false
		for defender in units:
			if not bool(defender.get("garrisoned", false)) and rect.grow(24.0).has_point(defender["pos"]):
				defended = true
				break
		var hospital_support: bool = _is_near_building_type(outpost["pos"], "HOSPITAL", HOSPITAL_REGEN_RADIUS)
		var overcrowded: bool = sheltered >= int(float(outpost.get("capacity", 12)) * 0.75)
		var interval: float = 11.25 if (defended or hospital_support) else (18.75 if overcrowded else 15.0)
		if food <= 0:
			interval /= 0.6
		if _has_constructed_building_near(outpost["pos"], "bakery", 180.0):
			interval *= 0.85
		outpost["evac_timer"] = float(outpost.get("evac_timer", interval)) - delta
		if float(outpost["evac_timer"]) <= 0.0:
			saved_count += sheltered
			scrap += sheltered * 35
			outpost["sheltered"] = 0
			outpost["evac_timer"] = interval
			message = "OUTPOST EVACUATION — %d CIVILIANS  +MATS %d" % [sheltered, sheltered * 35]
			message_timer = 2.0
		outposts[index] = outpost

func _spawn_refugee_wave() -> void:
	for district in spawn_districts:
		var recruitment_multiplier: float = 1.35 if faction_doctrine == "HUMANITARIAN SANCTUARY" else (0.8 if faction_doctrine == "MARTIAL LAW" else 1.0)
		for refugee_index in range(maxi(1, int(round(float(10 + int(wave / 5) * 2) * recruitment_multiplier)))):
			var refugee_position := Vector2(randf_range(district.position.x, district.end.x), randf_range(district.position.y, district.end.y))
			if _is_open_world_position(refugee_position, 18.0):
				civilians.append(refugee_position)
				civilian_steering.append({})
				_milestone14_add_refugee()
	message = "REFUGEE CONVOY ENTERING OUTER DISTRICTS"
	message_timer = 3.0

func _update_supply_drops(delta: float) -> void:
	supply_drop_timer -= delta
	if supply_drop_timer <= 0.0:
		supply_drop_timer = 150.0
		var candidate := Vector2(randf_range(120.0, WORLD_SIZE.x - 120.0), randf_range(120.0, WORLD_SIZE.y - 120.0))
		for attempt in range(12):
			if _is_open_world_position(candidate, 32.0):
				break
			candidate = Vector2(randf_range(120.0, WORLD_SIZE.x - 120.0), randf_range(120.0, WORLD_SIZE.y - 120.0))
		supply_crates.append({"pos": candidate})
	for crate_index in range(supply_crates.size() - 1, -1, -1):
		var crate_position: Vector2 = supply_crates[crate_index]["pos"]
		var secured := false
		for squad in units:
			if crate_position.distance_to(squad["pos"]) <= 52.0:
				secured = true
				break
		if secured:
			scrap += 120
			scrap += 15
			fuel = minf(300.0, fuel + 25.0)
			supply_crates.remove_at(crate_index)
			message = "TACTICAL SUPPLY SECURED  +MATS"
			message_timer = 2.0

func _draw_supply_crates() -> void:
	var view: Rect2 = _camera_view_rect().grow(80.0)
	for crate in supply_crates:
		var crate_position: Vector2 = crate["pos"]
		if view.has_point(crate_position):
			draw_circle(crate_position, 19.0, Color(0.9, 0.72, 0.24, 0.18))
			draw_rect(Rect2(crate_position - Vector2(11.0, 11.0), Vector2(22.0, 22.0)), Color("#d8b65b"))
			draw_line(crate_position + Vector2(-7.0, 0.0), crate_position + Vector2(7.0, 0.0), Color("#fff0b0"), 2.0)




func _add_tactical_decal(position: Vector2, direction: Vector2) -> void:
	tactical_decals.append({"pos": position, "direction": direction.normalized(), "life": 180.0})
	while tactical_decals.size() > MAX_TACTICAL_DECALS:
		tactical_decals.remove_at(0)

func _draw_selection_inspector() -> void:
	var inspector_text := ""
	if selected_unit_index >= 0 and selected_unit_index < units.size():
		var unit: Dictionary = units[selected_unit_index]
		inspector_text = "%s  |  RANK %d  |  KILLS %d\nHP %d / %d  |  TASK %s" % [str(unit.get("kind", "UNIT")).to_upper(), int(unit.get("rank", 0)), int(unit.get("kills", 0)), roundi(float(unit.get("hp", 0.0))), roundi(float(unit.get("max_hp", 1.0))), str(unit.get("ai_task", "HOLD"))]
	elif selected_vehicle_index >= 0 and selected_vehicle_index < vehicles.size():
		var vehicle: Dictionary = vehicles[selected_vehicle_index]
		inspector_text = "%s  |  FUEL %.0f\nPASSENGERS %d / 6  |  %s" % [str(vehicle.get("kind", "VEHICLE")).to_upper(), fuel, int(vehicle.get("onboard", 0)), "GROUNDED" if bool(vehicle.get("grounded", false)) else "OPERATIONAL"]
	if inspector_text.is_empty():
		return
	var card := Rect2(safe_insets.x + 18.0, safe_insets.y + 350.0, minf(330.0, viewport_size.x - safe_insets.x - safe_insets.z - 36.0), 68.0)
	draw_rect(card, Color("#0b1b17", 0.94))
	draw_rect(card, Color("#75c9e8"), false, 2.0)
	var rows: PackedStringArray = inspector_text.split("\n")
	_draw_text(rows[0], card.position + Vector2(10.0, 25.0), 12, Color("#e8fff0"))
	if rows.size() > 1:
		_draw_text(rows[1], card.position + Vector2(10.0, 49.0), 11, Color("#b8d6c8"))

func _rescue_broadcast_rect() -> Rect2:
	return Rect2(safe_insets.x + HUD_EDGE_PADDING + 180.0, safe_insets.y + HUD_EDGE_PADDING + 196.0, 200.0, touch_target_size)

func _activate_rescue_broadcast() -> void:
	if scrap < 75 or scrap < 25:
		message = "RESCUE BEACON REQUIRES MATS AND ⚙25"
		message_timer = 1.6
		return
	if outposts.is_empty():
		message = "NO ACTIVE OUTPOST CAN RECEIVE THE BEACON"
		message_timer = 1.6
		return
	var target_index: int = _nearest_outpost_index(camera_position)
	if target_index < 0:
		target_index = 0
	scrap -= 75
	scrap -= 25
	outposts[target_index]["rescue_beacon_timer"] = 30.0
	message = "RESCUE BEACON ACTIVE — CIVILIANS GUIDED TO OPEN GATE"
	message_timer = 2.4
	world_callouts.append({"pos": outposts[target_index]["pos"], "text": "SOS BEACON", "life": 2.5})

func _nearest_tree(position: Vector2, radius: float) -> int:
	var best_index := -1
	var best_distance: float = radius * radius
	for index in range(trees.size()):
		if not bool(trees[index].get("alive", false)):
			continue
		var distance: float = position.distance_squared_to(trees[index]["pos"])
		if distance <= best_distance:
			best_distance = distance
			best_index = index
	return best_index

func _nearest_wildlife(position: Vector2, radius: float) -> int:
	var best_index := -1
	var best_distance: float = radius * radius
	for index in range(wildlife.size()):
		if not bool(wildlife[index].get("alive", false)):
			continue
		var distance: float = position.distance_squared_to(wildlife[index]["pos"])
		if distance <= best_distance:
			best_distance = distance
			best_index = index
	return best_index

func _has_constructed_building_near(position: Vector2, kind: String, radius: float) -> bool:
	for building in constructed_buildings:
		if str(building.get("kind", "")) == kind and position.distance_squared_to(building["pos"]) <= radius * radius:
			return true
	return false

func _apply_daily_rations() -> void:
	var daily_consumption: int = units.size() + _total_sheltered_civilians()
	for building in constructed_buildings:
		var facility_output: float = 1.0 + minf(0.5, float(role_allocations.get("FACILITY", 0)) * 0.05)
		var facility_xp_total: int = 0
		var facility_staff_count: int = 0
		for staff in survivors:
			if str(staff.get("assignment_category", "")) == "FACILITY":
				facility_xp_total += int(staff.get("engineering_xp", 0)) + int(staff.get("gathering_xp", 0))
				facility_staff_count += 1
		if facility_staff_count > 0:
			facility_output *= 1.0 + minf(0.5, float(facility_xp_total) / float(facility_staff_count) / 2000.0)
		if faction_doctrine == "PRAGMATIC FREEHOLD":
			facility_output *= 1.2
		food += int(float(building.get("food_per_day", 0)) * facility_output)
	food = maxi(0, food - daily_consumption)
	message = "DAY %d RATIONS: -%d FOOD  |  STOCKPILE %d" % [survival_day, daily_consumption, food]
	message_timer = 3.0
	_save_operation()

func _update_wildlife(delta: float) -> void:
	for animal_index in range(wildlife.size()):
		var animal: Dictionary = wildlife[animal_index]
		if not bool(animal.get("alive", false)):
			continue
		var position: Vector2 = animal["pos"]
		var target_value: Variant = animal.get("wander_target", null)
		var target: Vector2 = position
		var has_target: bool = target_value is Vector2
		if has_target:
			target = target_value
		if not has_target or position.distance_to(target) <= 12.0:
			var flee_direction := Vector2.ZERO
			for unit in units:
				var distance_squared: float = position.distance_squared_to(unit["pos"])
				if distance_squared <= 110.0 * 110.0:
					flee_direction += (position - unit["pos"]).normalized()
			if flee_direction.length_squared() > 0.01:
				target = position + flee_direction.normalized() * 170.0
			else:
				target = position + Vector2(randf_range(-115.0, 115.0), randf_range(-115.0, 115.0))
			target.x = clampf(target.x, 24.0, WORLD_SIZE.x - 24.0)
			target.y = clampf(target.y, 24.0, WORLD_SIZE.y - 24.0)
		var speed: float = 16.0 if str(animal.get("kind", "")) == "deer" else 10.0
		var displacement: Vector2 = (target - position).normalized() * speed * delta
		animal["pos"] = _move_circle_with_buildings(position, displacement, 5.0, delta, target, animal)
		animal["wander_target"] = target
		wildlife[animal_index] = animal

func _update_work_orders(delta: float) -> void:
	for unit_index in range(units.size()):
		var unit: Dictionary = units[unit_index]
		var work_kind: String = str(unit.get("work_kind", ""))
		if work_kind.is_empty() or bool(unit.get("garrisoned", false)):
			continue
		var target_index: int = int(unit.get("work_target_index", -1))
		var work_target := Vector2(-1.0, -1.0)
		if work_kind == "chop" and target_index >= 0 and target_index < trees.size() and bool(trees[target_index].get("alive", false)):
			work_target = trees[target_index]["pos"]
		elif work_kind == "hunt" and target_index >= 0 and target_index < wildlife.size() and bool(wildlife[target_index].get("alive", false)):
			work_target = wildlife[target_index]["pos"]
		elif work_kind == "fuel" and target_index >= 0 and target_index < supply_crates.size():
			work_target = supply_crates[target_index].get("pos", Vector2(-1.0, -1.0))
		elif work_kind == "demolish" and target_index >= 0 and target_index < buildings.size() and not bool(building_archetypes[target_index].get("destroyed", false)):
			var rect: Rect2 = buildings[target_index]
			work_target = Vector2(clampf(unit["pos"].x, rect.position.x - 28.0, rect.end.x + 28.0), clampf(unit["pos"].y, rect.position.y - 28.0, rect.end.y + 28.0))
		if work_target.x < 0.0:
			unit["work_kind"] = ""
			unit["move_target"] = null
			units[unit_index] = unit
			continue
		if unit["pos"].distance_to(work_target) > 30.0:
			unit["move_target"] = work_target
			units[unit_index] = unit
			continue
		unit["move_target"] = null
		var work_speed: float = 2.0 if str(unit.get("kind", "")) == "engineer" else 1.0
		work_speed *= _milestone14_proficiency_bonus(unit, "gathering")
		if faction_doctrine == "PRAGMATIC FREEHOLD":
			work_speed *= 1.2
		unit["work_timer"] = maxf(0.0, float(unit.get("work_timer", 3.0)) - delta * work_speed)
		if float(unit["work_timer"]) <= 0.0:
			_milestone14_apply_harvest_reputation(unit["pos"])
			match work_kind:
				"chop":
					trees[target_index]["alive"] = false
					unit["cargo_type"] = "wood"
					unit["cargo_amount"] = 15
					world_callouts.append({"pos": work_target, "text": "WOOD SECURED — HAULING", "life": 2.0})
				"hunt":
					wildlife[target_index]["alive"] = false
					unit["cargo_type"] = "food"
					unit["cargo_amount"] = 30
					world_callouts.append({"pos": work_target, "text": "FOOD SECURED — HAULING", "life": 2.0})
				"fuel":
					unit["cargo_type"] = "fuel"
					unit["cargo_amount"] = int(supply_crates[target_index].get("fuel", 25))
					supply_crates.remove_at(target_index)
					world_callouts.append({"pos": work_target, "text": "FUEL SECURED — HAULING", "life": 2.0})
				"demolish":
					var salvage_amount: int = randi_range(40, 90)
					if faction_doctrine == "PRAGMATIC FREEHOLD":
						salvage_amount = int(round(float(salvage_amount) * 1.2))
					building_archetypes[target_index]["destroyed"] = true
					building_archetypes[target_index]["cache_available"] = false
					_rebuild_static_building_grid()
					_eject_building_garrison(target_index)
					unit["cargo_type"] = "scrap"
					unit["cargo_amount"] = salvage_amount
					world_callouts.append({"pos": buildings[target_index].get_center(), "text": "%d SCRAP — HAULING" % salvage_amount, "life": 2.5})
			unit["work_kind"] = ""
			unit["work_target_index"] = -1
			unit["manual_order"] = false
			if not str(unit.get("cargo_type", "")).is_empty():
				var haul_outpost: int = _nearest_outpost_index(unit["pos"])
				if haul_outpost >= 0:
					unit["move_target"] = _nearest_outpost_gate_position(haul_outpost, unit["pos"])
					unit["ai_task"] = "HAUL"
				else:
					unit["ai_task"] = ""
			else:
				unit["ai_task"] = ""
				unit["move_target"] = null
		units[unit_index] = unit

func _construct_survival_building(kind: String, position: Vector2) -> void:
	var owner_index := -1
	for index in range(outposts.size()):
		var rect: Rect2 = outposts[index].get("rect", Rect2(outposts[index]["pos"] - Vector2(110.0, 110.0), Vector2(220.0, 220.0)))
		if rect.grow(-30.0).has_point(position):
			owner_index = index
			break
	if owner_index < 0 and kind in ["farm", "livestock", "watchtower"]:
		message = "FARMS AND LIVESTOCK MUST BE ADJACENT TO AN OUTPOST"
		message_timer = 2.0
		return
	var cost_scrap: int = 0
	var cost_materials: int = 0 if kind in ["farm", "livestock"] else (70 if kind == "bakery" else (50 if kind == "watchtower" else (65 if kind == "clinic" else 90)))
	var cost_wood: int = 45 if kind == "farm" else (60 if kind == "livestock" else 0)
	if kind in ["farm", "livestock", "watchtower"]:
		for city_index in range(buildings.size()):
			if not bool(building_archetypes[city_index].get("destroyed", false)) and buildings[city_index].has_point(position):
				message = "FARM / PEN NEEDS OPEN GROUND"
				message_timer = 1.8
				return
	for existing in constructed_buildings:
		if position.distance_to(existing["pos"]) < 58.0:
			message = "CONSTRUCTION FOOTPRINT OCCUPIED"
			message_timer = 1.5
			return
	if scrap < cost_materials or wood < cost_wood:
		message = "REQUIRES %d WOOD / %d SCRAP" % [cost_wood, cost_materials]
		message_timer = 1.8
		return
	if kind == "bakery" or kind == "clinic" or kind == "workshop":
		var allowed_types: Array[String] = ["RESIDENTIAL", "SUPERMARKET"] if kind == "bakery" else (["HOSPITAL", "RESIDENTIAL"] if kind == "clinic" else ["ARMORY", "WAREHOUSE", "GUN_SHOP"])
		var indoor_index: int = _milestone13_nearest_building(position, 520.0)
		if indoor_index < 0 or bool(building_archetypes[indoor_index].get("destroyed", false)) or str(building_archetypes[indoor_index].get("type", "")) not in allowed_types:
			message = "FACILITY NEEDS INTACT BUILDING: " + " / ".join(allowed_types)
			message_timer = 2.0
			return
		building_archetypes[indoor_index]["converted_to"] = "WEAPONS_WORKSHOP" if kind == "workshop" else ("BAKERY" if kind == "bakery" else "FIELD_CLINIC")
		building_archetypes[indoor_index]["cache_available"] = false
		position = buildings[indoor_index].get_center()
	var food_yield: int = 18 if kind == "farm" else (32 if kind == "bakery" else (22 if kind == "livestock" else 0))
	constructed_buildings.append({"kind": kind, "pos": position, "outpost_index": owner_index, "food_per_day": food_yield, "hp": 500.0, "progress": 0.0, "constructing": true})
	
	scrap -= cost_materials
	wood -= cost_wood
	message = "%s ORDERED — %d WOOD / %d SCRAP" % [kind.to_upper(), cost_wood, cost_materials]
	message_timer = 2.0
	_save_operation()

func _interact_raider_camp(position: Vector2) -> void:
	for index in range(raider_camps.size()):
		var camp: Dictionary = raider_camps[index]
		if position.distance_squared_to(camp["pos"]) > 70.0 * 70.0:
			continue
		if bool(camp.get("raided", false)):
			message = "RAIDER CAMP ALREADY STRIPPED"
			message_timer = 1.6
			return
		var nearby_squad := false
		for unit in units:
			if unit["pos"].distance_squared_to(camp["pos"]) <= 150.0 * 150.0:
				nearby_squad = true
				break
		if nearby_squad:
			food += int(camp.get("food_stock", 0))
			scrap += int(camp.get("materials_stock", 0))
			fuel = minf(300.0, fuel + float(camp.get("fuel_stock", 0)))
			scrap += 150
			camp["raided"] = true
			raider_camps[index] = camp
			message = "RAIDER CACHE CAPTURED — FOOD / MATS / FUEL"
		elif scrap >= 30:
			scrap -= 30
			if fuel < 120.0:
				fuel = minf(300.0, fuel + 40.0)
				message = "BARTER COMPLETE — 30 MATS FOR +40 FUEL"
			else:
				food += 60
				message = "BARTER COMPLETE — 30 MATS FOR +60 FOOD"
		elif int(weapons.get("rifles", 0)) > 0:
			weapons["rifles"] = int(weapons.get("rifles", 0)) - 1
			if fuel < 120.0:
				fuel = minf(300.0, fuel + 40.0)
				message = "BARTER COMPLETE — 1 RIFLE FOR +40 FUEL"
			else:
				food += 60
				message = "BARTER COMPLETE — 1 RIFLE FOR +60 FOOD"
		else:
			message = "BARTER: 30 MATS OR 1 RIFLE FOR FOOD / FUEL; SQUAD CAN RAID"
		message_timer = 2.2
		return

func _milestone13_loot_weapons(building_index: int) -> void:
	var roll: float = randf()
	if roll < 0.38:
		weapons["rifles"] = int(weapons.get("rifles", 0)) + 1
	elif roll < 0.62:
		weapons["snipers"] = int(weapons.get("snipers", 0)) + 1
	elif roll < 0.76:
		weapons["heavy_mgs"] = int(weapons.get("heavy_mgs", 0)) + 1
	else:
		weapons["medkits"] = int(weapons.get("medkits", 0)) + 1
	if building_index >= 0 and building_index < building_archetypes.size():
		building_archetypes[building_index]["cache_available"] = false

func _milestone13_survivors() -> Array[Dictionary]:
	var names: Array[String] = ["Mara Vance", "Elias Chen", "Nadia Rostova", "Jonah Price", "Asha Patel", "Theo Brooks", "Mina Okafor", "Lucas Reed", "Iris Navarro", "Samir Haddad", "Grace Kim", "Owen Clarke", "Leah Morgan", "Rafael Costa", "Tess Walker", "Noah Bennett", "Yuki Tanaka", "Caleb Foster"]
	var roster: Array[Dictionary] = []
	for i in range(names.size()):
		var role: String = "ENGINEER" if i == 1 else ("MEDIC" if i == 2 else "WORKER")
		roster.append({"id": i + 1, "name": names[i], "role": role, "combat_xp": 0, "build_xp": 0, "medical_xp": 0, "veteran_rank": 1, "hp": 100.0, "max_hp": 100.0, "equipped_weapon": "", "traits": [], "ops_assignment": "", "ops_location": "IDLE", "infection_active": false, "infection_timer": 0.0, "infection_position": Vector2.ZERO, "infection_attacker": "", "infection_clinic_care_started": false})
	return roster

func _milestone13_nearest_building(position: Vector2, radius: float) -> int:
	var best := -1
	var best_distance: float = radius * radius
	for i in range(buildings.size()):
		if bool(building_archetypes[i].get("destroyed", false)):
			continue
		var distance: float = position.distance_squared_to(buildings[i].get_center())
		if distance <= best_distance:
			best_distance = distance
			best = i
	return best

func _milestone13_spawn_survivors(origin: Vector2, hq_building_index: int = -1) -> void:
	if not units.is_empty():
		return
	var hq_rect: Rect2 = buildings[hq_building_index] if hq_building_index >= 0 and hq_building_index < buildings.size() else Rect2(origin - Vector2(24.0, 24.0), Vector2(48.0, 48.0))
	var half_extent: Vector2 = hq_rect.size * 0.5
	var spawn_positions: Array[Vector2] = []
	var clearance_values: Array[float] = [44.0, 60.0, 80.0, 104.0, 136.0, 176.0, 224.0]
	for i in range(survivors.size()):
		var base_angle: float = TAU * float(i) / float(maxi(1, survivors.size()))
		var selected_spawn: Vector2 = origin + Vector2(cos(base_angle), sin(base_angle)) * (maxf(half_extent.x, half_extent.y) + 80.0)
		var found_spawn: bool = false
		for attempt in range(72):
			var angle: float = base_angle + TAU * float(attempt) / 72.0
			var direction: Vector2 = Vector2(cos(angle), sin(angle)).normalized()
			var boundary_distance: float = minf(half_extent.x / maxf(absf(direction.x), 0.001), half_extent.y / maxf(absf(direction.y), 0.001))
			for clearance in clearance_values:
				var candidate: Vector2 = origin + direction * (boundary_distance + clearance)
				if not _is_valid_street_position(candidate):
					continue
				var overlaps_spawn: bool = false
				for existing_spawn in spawn_positions:
					if candidate.distance_squared_to(existing_spawn) < 24.0 * 24.0:
						overlaps_spawn = true
						break
				if not overlaps_spawn:
					selected_spawn = candidate
					found_spawn = true
					break
			if found_spawn:
				break
		if not found_spawn:
			for fallback_radius in range(1, 13):
				var candidate_radius: float = maxf(half_extent.x, half_extent.y) + 40.0 + float(fallback_radius) * 24.0
				for angle_index in range(24):
					var fallback_angle: float = TAU * float(angle_index) / 24.0
					var candidate: Vector2 = origin + Vector2(cos(fallback_angle), sin(fallback_angle)) * candidate_radius
					if not _is_valid_street_position(candidate):
						continue
					var overlaps_spawn: bool = false
					for existing_spawn in spawn_positions:
						if candidate.distance_squared_to(existing_spawn) < 24.0 * 24.0:
							overlaps_spawn = true
							break
					if not overlaps_spawn:
						selected_spawn = candidate
						found_spawn = true
						break
				if found_spawn:
					break
				if found_spawn:
					break
		spawn_positions.append(selected_spawn)
		units.append({"id": _next_unit_id(), "survivor_id": int(survivors[i]["id"]), "pos": selected_spawn, "kind": str(survivors[i]["role"]).to_lower(), "cooldown": 0.2, "hp": 100.0, "max_hp": 100.0, "kills": 0, "rank": 0, "garrisoned": false, "garrison_building": -1, "move_target": null, "manual_order": false, "ai_task": "", "steering": {}, "triage_timer": 0.0, "status": ""})
	# Guaranteed final fallback: preserve the full convoy roster even when every
	# validated street spawn is blocked by map geometry.
	while units.size() < survivors.size():
		var survivor_index: int = units.size()
		var ring_index: int = survivor_index
		var fallback_radius: float = maxf(half_extent.x, half_extent.y) + 280.0 + float(ring_index / 8) * 48.0
		var fallback_angle: float = TAU * float(ring_index % 8) / 8.0
		var fallback_position: Vector2 = origin + Vector2(cos(fallback_angle), sin(fallback_angle)) * fallback_radius
		fallback_position.x = clampf(fallback_position.x, 32.0, WORLD_SIZE.x - 32.0)
		fallback_position.y = clampf(fallback_position.y, 32.0, WORLD_SIZE.y - 32.0)
		units.append({"id": _next_unit_id(), "survivor_id": int(survivors[survivor_index]["id"]), "pos": fallback_position, "kind": str(survivors[survivor_index]["role"]).to_lower(), "cooldown": 0.2, "hp": 100.0, "max_hp": 100.0, "kills": 0, "rank": 0, "garrisoned": false, "garrison_building": -1, "move_target": null, "manual_order": false, "ai_task": "", "steering": {}, "triage_timer": 0.0, "status": ""})

func _milestone13_assign_role(index: int, role: String) -> void:
	if index < 0 or index >= survivors.size():
		return
	var survivor: Dictionary = survivors[index]
	var old_weapon: String = str(survivor.get("equipped_weapon", ""))
	var required_weapon: String = ""
	match role:
		"INFANTRY": required_weapon = "rifles"
		"SNIPER": required_weapon = "snipers"
		"HEAVY": required_weapon = "heavy_mgs"
		"MEDIC": required_weapon = "medkits"
		"WORKER", "ENGINEER": pass
		_: return
	if not required_weapon.is_empty() and required_weapon != old_weapon and int(weapons.get(required_weapon, 0)) <= 0:
		message = "NO " + required_weapon.to_upper() + " IN STOCKPILE"
		message_timer = 2.0
		return
	if not old_weapon.is_empty():
		weapons[old_weapon] = int(weapons.get(old_weapon, 0)) + 1
	if not required_weapon.is_empty() and required_weapon != old_weapon:
		weapons[required_weapon] = int(weapons.get(required_weapon, 0)) - 1
	survivor["role"] = role
	survivor["equipped_weapon"] = required_weapon
	survivors[index] = survivor
	for unit_index in range(units.size()):
		if int(units[unit_index].get("survivor_id", -1)) == int(survivor["id"]):
			units[unit_index]["kind"] = role.to_lower()
	message = str(survivor["name"]) + " ASSIGNED " + role
	message_timer = 2.0
	_save_operation()

func _milestone13_tick_construction(delta: float) -> void:
	for i in range(constructed_buildings.size()):
		var site: Dictionary = constructed_buildings[i]
		if not bool(site.get("constructing", false)):
			continue
		if work_outside_enabled:
			var assigned_worker: bool = false
			for unit_index in range(units.size()):
				var candidate: Dictionary = units[unit_index]
				if str(candidate.get("kind", "")) in ["worker", "engineer"] and not bool(candidate.get("garrisoned", false)) and candidate.get("move_target") == null and str(candidate.get("ai_task", "")).is_empty():
					candidate["move_target"] = site.get("pos", Vector2.ZERO)
					candidate["ai_task"] = "CONSTRUCTION"
					units[unit_index] = candidate
					assigned_worker = true
					break
		var rate := 0.0
		for unit in units:
			var worker_kind: String = str(unit.get("kind", ""))
			if not bool(unit.get("garrisoned", false)) and unit["pos"].distance_to(site.get("pos", Vector2.ZERO)) <= 56.0 and worker_kind in ["worker", "engineer"]:
				rate += (2.0 if worker_kind == "engineer" else 1.0) * _milestone14_proficiency_bonus(unit, "engineering")
		if rate > 0.0:
			site["progress"] = minf(100.0, float(site.get("progress", 0.0)) + delta * rate * 4.0)
			if float(site["progress"]) >= 100.0:
				site["constructing"] = false
				_rebuild_static_building_grid()
				for survivor_index in range(survivors.size()):
					if str(survivors[survivor_index].get("role", "")) in ["WORKER", "ENGINEER"]:
						survivors[survivor_index]["build_xp"] = int(survivors[survivor_index].get("build_xp", 0)) + 5
		constructed_buildings[i] = site

func _milestone13_roster_top() -> float:
	return safe_insets.y + 268.0

func _milestone13_roster_row_height() -> float:
	var available_height: float = viewport_size.y - safe_insets.w - _milestone13_roster_top() - 70.0
	return clampf(available_height / maxf(1.0, float(survivors.size())), 14.0, 29.0)

func _draw_milestone13_roster_panel() -> void:
	var panel_left: float = safe_insets.x + 8.0
	var panel_top: float = _milestone13_roster_top()
	var panel_width: float = viewport_size.x - safe_insets.x - safe_insets.z - 16.0
	var row_height: float = _milestone13_roster_row_height()
	var panel_height: float = row_height * float(survivors.size()) + 92.0
	draw_rect(Rect2(panel_left, panel_top, panel_width, panel_height), Color("#071713", 0.96))
	draw_rect(Rect2(panel_left, panel_top, panel_width, panel_height), Color("#6ccf91"), false, 2.0)
	_draw_text("CREW ROSTER — TAP A SURVIVOR TO CYCLE ROLE", Vector2(panel_left + 8.0, panel_top + 18.0), 11, Color("#f2d98a"))
	for survivor_index in range(survivors.size()):
		var survivor: Dictionary = survivors[survivor_index]
		var row_rect := Rect2(panel_left + 5.0, panel_top + 25.0 + float(survivor_index) * row_height, panel_width - 10.0, row_height - 1.0)
		draw_rect(row_rect, Color("#254538") if survivor_index == selected_survivor_index else Color("#10221d"))
		var rank_text: String = ["I", "II", "III"][clampi(int(survivor.get("veteran_rank", 1)) - 1, 0, 2)]
		var weapon_text: String = str(survivor.get("equipped_weapon", "—")).to_upper()
		var traits: Array = survivor.get("traits", [])
		var health_tag: String = "IMMUNE" if traits.has("IMMUNE") else ("INFECTED %ds" % ceili(float(survivor.get("infection_timer", 0.0))) if bool(survivor.get("infection_active", false)) else "")
		var row_text: String = "%02d %s | %s | C%d B%d M%d | R%s | %s %s" % [survivor_index + 1, str(survivor.get("name", "SURVIVOR")), str(survivor.get("role", "WORKER")), int(survivor.get("combat_xp", 0)), int(survivor.get("build_xp", 0)), int(survivor.get("medical_xp", 0)), rank_text, weapon_text, health_tag]
		_draw_text(row_text, row_rect.position + Vector2(4.0, 19.0), 8, Color("#e4f4e9"))
	var craft_y: float = panel_top + 25.0 + row_height * float(survivors.size()) + 8.0
	var labels: Array[String] = ["RIFLE 25", "SNIPER 40", "HEAVY 55", "MEDKIT 20"]
	for craft_index in range(4):
		var craft_rect := Rect2(panel_left + float(craft_index) * (panel_width / 4.0), craft_y, panel_width / 4.0 - 4.0, 32.0)
		draw_rect(craft_rect, Color("#243b4c"))
		draw_rect(craft_rect, Color("#75c9e8"), false, 1.0)
		_draw_text(labels[craft_index], craft_rect.position + Vector2(4.0, 20.0), 9, Color("#e8f7ff"))

func _milestone13_queue_craft(weapon_key: String) -> void:
	var costs: Dictionary = {"rifles": 25, "snipers": 40, "heavy_mgs": 55, "medkits": 20}
	if not costs.has(weapon_key) or scrap < int(costs.get(weapon_key, 0)):
		message = "CRAFTING REQUIRES MORE MATS"
		message_timer = 1.8
		return
	var workshop_position := Vector2.ZERO
	var found_workshop := false
	for site in constructed_buildings:
		if str(site.get("kind", "")) == "workshop" and not bool(site.get("constructing", true)):
			workshop_position = site.get("pos", Vector2.ZERO)
			found_workshop = true
			break
	if not found_workshop:
		message = "COMPLETE A WEAPONS WORKSHOP FIRST"
		message_timer = 2.0
		return
	scrap -= int(costs[weapon_key])
	crafting_orders.append({"weapon": weapon_key, "pos": workshop_position, "remaining": 24.0})
	message = "CRAFT ORDER QUEUED: " + weapon_key.to_upper()
	message_timer = 2.0
	_save_operation()

func _milestone13_tick_crafting(delta: float) -> void:
	for order_index in range(crafting_orders.size() - 1, -1, -1):
		var order: Dictionary = crafting_orders[order_index]
		var speed := 0.0
		for unit in units:
			if bool(unit.get("garrisoned", false)) or unit["pos"].distance_to(order.get("pos", Vector2.ZERO)) > 56.0:
				continue
			var worker_kind: String = str(unit.get("kind", ""))
			if worker_kind == "engineer":
				speed = maxf(speed, 2.0)
			elif worker_kind == "worker":
				speed = maxf(speed, 1.0)
		if speed > 0.0:
			order["remaining"] = maxf(0.0, float(order.get("remaining", 24.0)) - delta * speed)
			for survivor_index in range(survivors.size()):
				if str(survivors[survivor_index].get("role", "")) in ["WORKER", "ENGINEER"]:
					survivors[survivor_index]["build_xp"] = int(survivors[survivor_index].get("build_xp", 0)) + 1
		if float(order.get("remaining", 1.0)) <= 0.0:
			var crafted_key: String = str(order.get("weapon", "rifles"))
			weapons[crafted_key] = int(weapons.get(crafted_key, 0)) + 1
			world_callouts.append({"pos": order.get("pos", Vector2.ZERO), "text": "CRAFTED " + crafted_key.to_upper(), "life": 2.0})
			crafting_orders.remove_at(order_index)
		else:
			crafting_orders[order_index] = order

func _pause_button_rect() -> Rect2:
	return Rect2(safe_insets.x + HUD_EDGE_PADDING + 350.0, safe_insets.y + HUD_EDGE_PADDING + 104.0, 130.0, 42.0)

func _radio_log_button_rect() -> Rect2:
	return Rect2(safe_insets.x + HUD_EDGE_PADDING + 350.0, safe_insets.y + HUD_EDGE_PADDING + 58.0, 130.0, 40.0)

func _draw_radio_log() -> void:
	if not radio_log_open:
		return
	var panel := Rect2(safe_insets.x + 22.0, safe_insets.y + 220.0, viewport_size.x - safe_insets.x - safe_insets.z - 44.0, minf(440.0, viewport_size.y * 0.48))
	draw_rect(panel, Color("#0b171b", 0.97))
	draw_rect(panel, Color("#6cb8d1"), false, 2.0)
	_draw_text("THE LAZARUS FILES  //  COMMAND LOG", panel.position + Vector2(14.0, 28.0), 15, Color("#83d8ef"))
	var visible_count: int = mini(7, radio_log.size())
	for entry_index in range(visible_count):
		var source_index: int = radio_log.size() - visible_count + entry_index
		_draw_text(radio_log[source_index], panel.position + Vector2(14.0, 66.0 + float(entry_index) * 48.0), 11, Color("#e4f4f6"))
	_draw_text("TAP ANYWHERE TO CLOSE", panel.position + Vector2(14.0, panel.size.y - 18.0), 10, Color("#83d8ef"))

func _update_day_phase() -> void:
	var minute_of_day: float = fposmod(world_clock_minutes, 1440.0)
	if minute_of_day >= 1260.0 or minute_of_day < 300.0:
		day_phase = "NIGHT"
	elif minute_of_day >= 1080.0:
		day_phase = "DUSK"
	elif minute_of_day < 420.0:
		day_phase = "DAWN"
	else:
		day_phase = "DAY"

func _format_world_clock() -> String:
	var minute_of_day: int = int(floor(fposmod(world_clock_minutes, 1440.0)))
	return "%02d:%02d" % [int(minute_of_day / 60), minute_of_day % 60]

func _refresh_light_source_cache() -> void:
	cached_light_sources.clear()
	for outpost in outposts:
		var radius: float = float(outpost.get("floodlight_radius", 300.0))
		cached_light_sources.append({"pos": outpost["pos"], "radius_squared": radius * radius})
	for flare in flares:
		cached_light_sources.append({"pos": flare["pos"], "radius_squared": FLARE_LURE_RADIUS * FLARE_LURE_RADIUS})
	for vehicle in vehicles:
		if bool(vehicle.get("active", false)) and str(vehicle.get("kind", "")) != "helicopter":
			cached_light_sources.append({"pos": vehicle["pos"], "radius_squared": 140.0 * 140.0})

func _is_position_illuminated(position: Vector2) -> bool:
	for light in cached_light_sources:
		if position.distance_squared_to(light["pos"]) <= float(light["radius_squared"]):
			return true
	return false

func _update_radio_transmission() -> void:
	if survival_day <= radio_day_announced:
		return
	radio_day_announced = survival_day
	match survival_day:
		2:
			radio_banner_text = "COMMANDER VANCE: DR. ROSTOVA AT ST. MARROW HOSPITAL — BLACKWOOD RAIDERS ARE CLOSING IN."
		3:
			radio_banner_text = "DR. ROSTOVA: THE ARMORY HAS RATIONS. KEEP AN ENGINEER FREE FOR SALVAGE."
		4:
			radio_banner_text = "LAZARUS FILE 02: BLACKWOOD RAIDERS HAVE BEEN MOVING INFECTED SPECIMENS."
		6:
			radio_banner_text = "COMMANDER VANCE: BUILD FARMS BEFORE YOUR SETTLERS OUTNUMBER YOUR FOOD STOCKPILE."
		9:
			radio_banner_text = "DR. ROSTOVA: THE QUARANTINE WAS NOT BUILT TO KEEP THE DEAD OUT."
		14:
			radio_banner_text = "LAZARUS FILE 07: BLACKWOOD WAS FUNDED BY THE CONTINUITY DIRECTORATE."
		_:
			radio_banner_text = "COMMAND LOG — DAY %d. VANCE REPORTS THE OUTER DEFENSE LINE IS FAILING." % survival_day
	radio_log.append("DAY %d — %s" % [survival_day, radio_banner_text])
	while radio_log.size() > 64:
		radio_log.remove_at(0)
	radio_banner_timer = 7.0

func _draw_radio_banner() -> void:
	if radio_banner_timer <= 0.0 or radio_banner_text.is_empty():
		return
	var width: float = minf(viewport_size.x - safe_insets.x - safe_insets.z - 28.0, 600.0)
	var rect := Rect2((viewport_size.x - width) * 0.5, safe_insets.y + 12.0, width, 58.0)
	draw_rect(rect, Color("#101d28", 0.94))
	draw_rect(rect, Color("#6cb8d1"), false, 2.0)
	_draw_text("COMMAND RADIO  //  TAP TO DISMISS", rect.position + Vector2(12.0, 19.0), 10, Color("#83d8ef"))
	_draw_text(radio_banner_text, rect.position + Vector2(12.0, 42.0), 12, Color("#e4f4f6"))

func _load_persistent_records() -> void:
	var records := ConfigFile.new()
	if records.load("user://containment_records.cfg") != OK:
		return
	best_days_survived = maxi(0, int(records.get_value("records", "best_days_survived", 0)))
	best_civilians_saved = maxi(0, int(records.get_value("records", "best_civilians_saved", 0)))

func _update_persistent_records() -> void:
	best_days_survived = maxi(best_days_survived, survival_day)
	best_civilians_saved = maxi(best_civilians_saved, saved_count)
	var records := ConfigFile.new()
	records.set_value("records", "best_days_survived", best_days_survived)
	records.set_value("records", "best_civilians_saved", best_civilians_saved)
	records.save("user://containment_records.cfg")

func _save_variant(value: Variant) -> Variant:
	if value is Vector2i:
		return {"__vector2i": [value.x, value.y]}
	if value is Vector2:
		return {"__vector2": [value.x, value.y]}
	if value is Rect2:
		return {"__rect2": [value.position.x, value.position.y, value.size.x, value.size.y]}
	if value is Dictionary:
		var converted: Dictionary = {}
		for key in value.keys():
			converted[str(key)] = _save_variant(value[key])
		return converted
	if value is Array:
		var converted_array: Array = []
		for item in value:
			converted_array.append(_save_variant(item))
		return converted_array
	return value

func _restore_variant(value: Variant) -> Variant:
	if value is Dictionary:
		var dictionary: Dictionary = value
		if dictionary.has("__vector2i"):
			var integer_coordinates: Array = dictionary["__vector2i"]
			return Vector2i(int(integer_coordinates[0]), int(integer_coordinates[1]))
		if dictionary.has("__vector2"):
			var coordinates: Array = dictionary["__vector2"]
			return Vector2(float(coordinates[0]), float(coordinates[1]))
		if dictionary.has("__rect2"):
			var rect_values: Array = dictionary["__rect2"]
			return Rect2(float(rect_values[0]), float(rect_values[1]), float(rect_values[2]), float(rect_values[3]))
		var restored: Dictionary = {}
		for key in dictionary.keys():
			restored[key] = _restore_variant(dictionary[key])
		return restored
	if value is Array:
		var restored_array: Array = []
		for item in value:
			restored_array.append(_restore_variant(item))
		return restored_array
	return value

func _has_valid_save() -> bool:
	if not FileAccess.file_exists(save_path):
		return false
	var save_file := FileAccess.open(save_path, FileAccess.READ)
	if save_file == null:
		return false
	var parsed: Variant = JSON.parse_string(save_file.get_as_text())
	save_file.close()
	if not parsed is Dictionary:
		return false
	var state: Dictionary = parsed
	if int(state.get("version", 0)) < 2 or int(state.get("version", 0)) > SAVE_VERSION:
		return false
	if int(state.get("sector_index", -1)) < 0 or int(state.get("sector_index", -1)) > 2:
		return false
	if int(state.get("wave", -1)) < 0:
		return false
	var required_arrays: Array[String] = ["evacuation_zones", "civilians", "zombies", "units", "outposts", "turrets", "barricades", "gates", "building_archetypes", "district_regions", "zombie_grid_serialized", "civilian_grid_serialized"]
	for key in required_arrays:
		if not state.has(key) or not state[key] is Array:
			return false
	var saved_hq: Variant = state.get("primary_hq_position")
	var saved_camera: Variant = state.get("camera_position")
	return saved_hq is Dictionary and saved_hq.has("__vector2") and saved_camera is Dictionary and saved_camera.has("__vector2")

func _serialize_spatial_grid(grid: Dictionary) -> Array[Dictionary]:
	var serialized: Array[Dictionary] = []
	for key in grid.keys():
		var bucket: Array = grid[key]
		if bucket.is_empty():
			continue
		var cell: Vector2i = key
		serialized.append({"cell": cell, "indices": bucket.duplicate()})
	return serialized

func _restore_spatial_grid(grid: Dictionary, serialized: Array) -> void:
	grid.clear()
	for entry in serialized:
		if not entry is Dictionary:
			continue
		var cell_value: Variant = entry.get("cell", Vector2i.ZERO)
		var indices: Variant = entry.get("indices", [])
		if cell_value is Vector2i and indices is Array:
			grid[cell_value] = indices.duplicate()

func _save_operation() -> void:
	# Never replace a prior valid campaign with an incomplete HQ-placement state.
	if not campaign_started or game_state == "hq_placement":
		return
	var state: Dictionary = {"version": SAVE_VERSION, "faction_doctrine": faction_doctrine, "doctrine_change_day": doctrine_change_day, "doctrine_morale_shock_days": doctrine_morale_shock_days, "doctrine_morale_recovery_day": doctrine_morale_recovery_day, "faction_settlements": faction_settlements, "faction_foundation_timer": faction_foundation_timer, "outpost_morale": outpost_morale, "weapons": weapons, "survivors": survivors, "citizens": citizens, "role_allocations": role_allocations, "raid_squads": raid_squads, "work_zones": work_zones, "wood": wood, "scrap": scrap, "food": food, "last_upkeep_day": last_upkeep_day, "trees": trees, "wildlife": wildlife, "raider_camps": raider_camps, "constructed_buildings": constructed_buildings, "radio_log": radio_log, "radio_day_announced": radio_day_announced, "radio_banner_text": radio_banner_text, "radio_banner_timer": radio_banner_timer, "fuel": fuel, "world_clock_minutes": world_clock_minutes, "survival_day": survival_day, "best_days_survived": best_days_survived, "best_civilians_saved": best_civilians_saved, "initial_civilian_count": initial_civilian_count, "campaign_map_seed": campaign_map_seed, "starting_district_index": starting_district_index, "district_seed_points": district_seed_points, "sector_index": sector_index, "wave": wave, "saved_count": saved_count, "lost_count": lost_count, "primary_hq_position": primary_hq_position, "evacuation_zones": evacuation_zones, "civilians": civilians, "zombies": zombies, "units": units, "vehicles": vehicles, "auto_ops_enabled": auto_ops_enabled, "highway_segments": highway_segments, "secondary_road_segments": secondary_road_segments, "world_callouts": world_callouts, "outposts": outposts, "turrets": turrets, "barricades": barricades, "flares": flares, "camera_position": camera_position, "camera_zoom": camera_zoom, "elapsed": elapsed, "wave_timer": wave_timer, "shelter_flush_timer": shelter_flush_timer, "supply_drop_timer": supply_drop_timer, "supply_crates": supply_crates, "civilian_steering": civilian_steering, "endless_containment": endless_containment, "buildings": buildings, "spawn_districts": spawn_districts, "building_archetypes": building_archetypes, "district_regions": district_regions, "gates": gates, "warehouse_hold_timers": warehouse_hold_timers, "zombie_grid_serialized": _serialize_spatial_grid(zombie_grid), "civilian_grid_serialized": _serialize_spatial_grid(civilian_grid), "time_scale_index": time_scale_index, "day_phase": day_phase, "pending_wave_spawns": pending_wave_spawns, "pending_wave_spawn_timer": pending_wave_spawn_timer, "tactical_decals": tactical_decals, "ops_monitor_open": ops_monitor_open, "recent_gunfire": recent_gunfire}
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(_save_variant(state)))
		file.close()

func _resume_operation() -> void:
	if not FileAccess.file_exists(save_path):
		return
	var file := FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Dictionary:
		return
	var state: Dictionary = _restore_variant(parsed)
	if int(state.get("version", 2)) < 7:
		state["weapons"] = {"rifles": 6, "snipers": 2, "heavy_mgs": 1, "medkits": 3}
		state["survivors"] = _milestone13_survivors()
		state["crafting_orders"] = []
		state["version"] = 7
	if int(state.get("version", 7)) < 8:
		var legacy_materials: int = maxi(0, int(state.get("materials", state.get("scrap", 120))))
		state["wood"] = int(floor(float(legacy_materials) * 0.4))
		state["scrap"] = legacy_materials - int(state["wood"])
		state["citizens"] = []
		state["role_allocations"] = {"GATHERERS": 0, "ENGINEERS": 0, "FACILITY": 0, "SQUAD": 0}
		state["raid_squads"] = []
		state["work_zones"] = []
		state["version"] = 8
	if int(state.get("version", 8)) < 9:
		state["faction_doctrine"] = "PRAGMATIC FREEHOLD"
		state["doctrine_change_day"] = int(state.get("survival_day", 1))
		state["doctrine_morale_shock_days"] = 0
		state["faction_settlements"] = []
		state["faction_foundation_timer"] = 720.0
		state["version"] = 9
	if int(state.get("version", 9)) < 10:
		var legacy_survivors: Array = state.get("survivors", [])
		for survivor_index in range(legacy_survivors.size()):
			var legacy_survivor: Dictionary = legacy_survivors[survivor_index]
			legacy_survivor["max_hp"] = float(legacy_survivor.get("max_hp", 100.0))
			legacy_survivor["traits"] = legacy_survivor.get("traits", [])
			legacy_survivor["ops_assignment"] = str(legacy_survivor.get("ops_assignment", ""))
			legacy_survivor["ops_location"] = str(legacy_survivor.get("ops_location", "IDLE"))
			legacy_survivor["infection_active"] = bool(legacy_survivor.get("infection_active", false))
			legacy_survivor["infection_timer"] = float(legacy_survivor.get("infection_timer", 0.0))
			legacy_survivor["infection_position"] = legacy_survivor.get("infection_position", Vector2.ZERO)
			legacy_survivor["infection_attacker"] = str(legacy_survivor.get("infection_attacker", ""))
			legacy_survivor["infection_clinic_care_started"] = bool(legacy_survivor.get("infection_clinic_care_started", false))
			legacy_survivors[survivor_index] = legacy_survivor
		state["survivors"] = legacy_survivors
		state["ops_monitor_open"] = false
		state["version"] = 10
	if int(state.get("version", 10)) < 11:
		state["recent_gunfire"] = []
		state["version"] = 11
	faction_doctrine = str(state.get("faction_doctrine", "PRAGMATIC FREEHOLD"))
	doctrine_change_day = int(state.get("doctrine_change_day", 1))
	doctrine_morale_shock_days = int(state.get("doctrine_morale_shock_days", 0))
	doctrine_morale_recovery_day = int(state.get("doctrine_morale_recovery_day", 0))
	faction_settlements.assign(state.get("faction_settlements", []))
	faction_foundation_timer = float(state.get("faction_foundation_timer", 720.0))
	outpost_morale = clampf(float(state.get("outpost_morale", 70.0)), 0.0, 100.0)
	if faction_settlements.is_empty():
		_milestone14_seed_factions()
	_configure_sector(int(state.get("sector_index", 0)))
	sector_index = int(state.get("sector_index", 0))
	campaign_map_seed = int(state.get("campaign_map_seed", campaign_map_seed))
	starting_district_index = clampi(int(state.get("starting_district_index", starting_district_index)), 0, maxi(0, district_regions.size() - 1))
	if state.has("district_seed_points"):
		district_seed_points.assign(state["district_seed_points"])
	wave = int(state.get("wave", 0))
	scrap = 0
	weapons = state.get("weapons", {"rifles": 6, "snipers": 2, "heavy_mgs": 1, "medkits": 3})
	survivors.assign(state.get("survivors", _milestone13_survivors()))
	ops_monitor_open = false
	for survivor_index in range(survivors.size()):
		var loaded_survivor: Dictionary = survivors[survivor_index]
		loaded_survivor["traits"] = loaded_survivor.get("traits", [])
		loaded_survivor["ops_assignment"] = str(loaded_survivor.get("ops_assignment", ""))
		loaded_survivor["ops_location"] = str(loaded_survivor.get("ops_location", "IDLE"))
		loaded_survivor["infection_active"] = bool(loaded_survivor.get("infection_active", false))
		loaded_survivor["infection_timer"] = float(loaded_survivor.get("infection_timer", 0.0))
		loaded_survivor["infection_clinic_care_started"] = bool(loaded_survivor.get("infection_clinic_care_started", false))
		survivors[survivor_index] = loaded_survivor
	crafting_orders.assign(state.get("crafting_orders", []))
	scrap = maxi(0, int(state.get("scrap", state.get("materials", 120))))
	wood = maxi(0, int(state.get("wood", 0)))
	food = maxi(0, int(state.get("food", 120)))
	citizens.assign(state.get("citizens", []))
	role_allocations = state.get("role_allocations", {"GATHERERS": 0, "ENGINEERS": 0, "FACILITY": 0, "SQUAD": 0})
	raid_squads.assign(state.get("raid_squads", []))
	work_zones.assign(state.get("work_zones", []))
	if citizens.is_empty():
		citizen_name_seed = int(state.get("campaign_map_seed", campaign_map_seed))
		_milestone14_initialize_citizens()
	last_upkeep_day = maxi(1, int(state.get("last_upkeep_day", int(state.get("survival_day", 1)))))
	if state.has("trees"):
		trees.assign(state["trees"])
	if state.has("wildlife"):
		wildlife.assign(state["wildlife"])
	if state.has("raider_camps"):
		raider_camps.assign(state["raider_camps"])
	if state.has("constructed_buildings"):
		constructed_buildings.assign(state["constructed_buildings"])
	if state.has("radio_log"):
		radio_log.assign(state["radio_log"])
	radio_day_announced = int(state.get("radio_day_announced", int(state.get("survival_day", 1))))
	radio_banner_text = str(state.get("radio_banner_text", ""))
	radio_banner_timer = maxf(0.0, float(state.get("radio_banner_timer", 0.0)))
	fuel = maxf(0.0, float(state.get("fuel", 300.0)))
	initial_civilian_count = maxi(int(state.get("initial_civilian_count", 0)), civilians.size() + int(state.get("saved_count", 0)) + int(state.get("lost_count", 0)))
	saved_count = int(state.get("saved_count", 0))
	lost_count = int(state.get("lost_count", 0))
	primary_hq_position = state.get("primary_hq_position", Vector2.ZERO)
	evacuation_zones.assign(state.get("evacuation_zones", []))
	civilians.assign(state.get("civilians", []))
	zombies.assign(state.get("zombies", []))
	units.assign(state.get("units", []))
	vehicles.assign(state.get("vehicles", []))
	if state.has("highway_segments"):
		highway_segments.assign(state["highway_segments"])
	if state.has("secondary_road_segments"):
		secondary_road_segments.assign(state["secondary_road_segments"])
	if state.has("world_callouts"):
		world_callouts.assign(state["world_callouts"])
	if int(state.get("version", SAVE_VERSION)) == 2:
		vehicles.clear()
		for unit_index in range(units.size()):
			var migrated_unit: Dictionary = units[unit_index]
			migrated_unit["manual_order"] = bool(migrated_unit.get("manual_order", false))
			migrated_unit["ai_task"] = str(migrated_unit.get("ai_task", ""))
			units[unit_index] = migrated_unit
	auto_ops_enabled = bool(state.get("auto_ops_enabled", true))
	outposts.assign(state.get("outposts", []))
	turrets.assign(state.get("turrets", []))
	barricades.assign(state.get("barricades", []))
	flares.assign(state.get("flares", []))
	camera_position = state.get("camera_position", WORLD_SIZE * 0.5)
	camera_zoom = float(state.get("camera_zoom", 0.62))
	elapsed = float(state.get("elapsed", 0.0))
	wave_timer = float(state.get("wave_timer", 180.0))
	shelter_flush_timer = float(state.get("shelter_flush_timer", 15.0))
	supply_drop_timer = float(state.get("supply_drop_timer", 150.0))
	supply_crates.assign(state.get("supply_crates", []))
	civilian_steering.assign(state.get("civilian_steering", []))
	if state.has("buildings"):
		buildings.assign(state["buildings"])
	if state.has("spawn_districts"):
		spawn_districts.assign(state["spawn_districts"])
	if state.has("building_archetypes"):
		building_archetypes.assign(state["building_archetypes"])
	for building_index in range(building_archetypes.size()):
		var building_state: Dictionary = building_archetypes[building_index]
		var default_hp: float = 1800.0 if str(building_state.get("type", "")) == "HIGHRISE" else 900.0
		building_state["hp"] = float(building_state.get("hp", default_hp))
		building_state["max_hp"] = float(building_state.get("max_hp", default_hp))
		building_state["destroyed"] = bool(building_state.get("destroyed", false))
		building_state["fortified"] = bool(building_state.get("fortified", false))
		building_state["secured"] = bool(building_state.get("secured", false))
		building_archetypes[building_index] = building_state
	if state.has("district_regions"):
		district_regions.assign(state["district_regions"])
	if not state.has("trees"):
		_populate_ecology()
	if state.has("gates"):
		gates.assign(state["gates"])
	if state.has("recent_gunfire"):
		recent_gunfire.assign(state["recent_gunfire"])
	if state.has("tactical_decals"):
		tactical_decals.assign(state["tactical_decals"])
	if tactical_decals.size() > MAX_TACTICAL_DECALS:
		tactical_decals = tactical_decals.slice(tactical_decals.size() - MAX_TACTICAL_DECALS)
	for outpost_index in range(outposts.size()):
		var migrated_outpost: Dictionary = outposts[outpost_index]
		migrated_outpost["evac_timer"] = float(migrated_outpost.get("evac_timer", 15.0))
		migrated_outpost["rescue_beacon_timer"] = float(migrated_outpost.get("rescue_beacon_timer", 0.0))
		outposts[outpost_index] = migrated_outpost
	if state.has("warehouse_hold_timers"):
		warehouse_hold_timers = state["warehouse_hold_timers"]
	if state.has("zombie_grid_serialized"):
		_restore_spatial_grid(zombie_grid, state["zombie_grid_serialized"])
	if state.has("civilian_grid_serialized"):
		_restore_spatial_grid(civilian_grid, state["civilian_grid_serialized"])
	pending_wave_spawns = maxi(0, int(state.get("pending_wave_spawns", 0)))
	if zombies.size() > MAX_ACTIVE_ZOMBIES:
		pending_wave_spawns += zombies.size() - MAX_ACTIVE_ZOMBIES
		zombies.resize(MAX_ACTIVE_ZOMBIES)
	pending_wave_spawn_timer = maxf(0.0, float(state.get("pending_wave_spawn_timer", 0.0)))
	time_scale_index = clampi(int(state.get("time_scale_index", 0)), 0, TIME_SCALES.size() - 1)
	world_clock_minutes = maxf(0.0, float(state.get("world_clock_minutes", 450.0 + float(wave) * 30.0)))
	survival_day = maxi(1, int(state.get("survival_day", floor(world_clock_minutes / 1440.0) + 1)))
	best_days_survived = maxi(best_days_survived, int(state.get("best_days_survived", 0)))
	best_civilians_saved = maxi(best_civilians_saved, int(state.get("best_civilians_saved", 0)))
	last_upkeep_day = maxi(last_upkeep_day, survival_day)
	_update_day_phase()
	endless_containment = bool(state.get("endless_containment", false))
	while civilian_steering.size() < civilians.size():
		civilian_steering.append({})
	_rebuild_zombie_spatial_grid()
	_rebuild_spatial_grid(civilian_grid, civilians)
	_rebuild_static_building_grid()
	campaign_started = not outposts.is_empty()
	campaign_start_grace_timer = 1.0
	manual_paused = false
	lifecycle_paused = false
	game_state = "playing"
	_clamp_camera()
	message = "SAVED OPERATION RESTORED — WAVE %d" % wave
	message_timer = 3.0
	queue_redraw()

func _draw_dashed_territory_edge(from_point: Vector2, to_point: Vector2, line_color: Color) -> void:
	var edge_length: float = from_point.distance_to(to_point)
	if edge_length <= 0.1:
		return
	var direction: Vector2 = (to_point - from_point) / edge_length
	var offset: float = 0.0
	while offset < edge_length:
		var dash_end: float = minf(edge_length, offset + 18.0)
		draw_line(from_point + direction * offset, from_point + direction * dash_end, line_color, 3.0, true)
		offset += 30.0

func _draw_outpost_territory_bounds() -> void:
	var visible_rect: Rect2 = _camera_view_rect().grow(24.0)
	for outpost in outposts:
		var territory_rect: Rect2 = outpost.get("territory_rect", outpost.get("rect", Rect2(outpost.get("pos", Vector2.ZERO) - Vector2(110.0, 110.0), Vector2(220.0, 220.0))))
		if not visible_rect.intersects(territory_rect):
			continue
		var boundary_color: Color = Color(0.36, 0.92, 0.62, 0.92) if bool(outpost.get("is_hq", false)) else Color(0.40, 0.74, 0.94, 0.82)
		_draw_dashed_territory_edge(territory_rect.position, Vector2(territory_rect.end.x, territory_rect.position.y), boundary_color)
		_draw_dashed_territory_edge(Vector2(territory_rect.end.x, territory_rect.position.y), territory_rect.end, boundary_color)
		_draw_dashed_territory_edge(territory_rect.end, Vector2(territory_rect.position.x, territory_rect.end.y), boundary_color)
		_draw_dashed_territory_edge(Vector2(territory_rect.position.x, territory_rect.end.y), territory_rect.position, boundary_color)

func _draw_world_scene() -> void:
	var origin: Vector2 = viewport_size * 0.5 - camera_position * camera_zoom
	draw_set_transform(origin, 0.0, Vector2(camera_zoom, camera_zoom))
	draw_rect(Rect2(Vector2.ZERO, WORLD_SIZE), Color("#07110f"))
	_draw_grid()
	_draw_roads()
	_draw_buildings()
	_draw_outpost_territory_bounds()
	for district_index in range(district_regions.size()):
		var district_rect: Rect2 = district_regions[district_index]
		if _camera_view_rect().intersects(district_rect):
			var district_labels: Array[String] = ["URBAN CORE", "SUBURBS", "INDUSTRIAL ZONE", "MEDICAL DISTRICT", "RURAL HIGHWAYS", "LOGISTICS HUB", "CIVIC CENTER", "OUTER CORRIDOR"]
			var district_label: String = district_labels[district_index] if district_index < district_labels.size() else "REGIONAL DISTRICT"
			_draw_text(district_label, Vector2(70.0, district_rect.position.y + 62.0), 24, Color(0.45, 0.75, 0.62, 0.6))
	_draw_evac_zone()
	_draw_entities()
	_milestone14_draw_work_zones()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	_milestone14_draw_hud_panel()


func _draw_text(value: String, position: Vector2, size: int, color: Color) -> void:
	if screen_font != null:
		draw_string(screen_font, position, value, HORIZONTAL_ALIGNMENT_LEFT, -1.0, size, color)


const CITIZEN_FIRST_NAMES: Array[String] = ["Aaron", "Abigail", "Adam", "Aiden", "Alice", "Amelia", "Andre", "Angela", "Anika", "Aria", "Arthur", "Asha", "Audrey", "Benjamin", "Bianca", "Caleb", "Camila", "Carter", "Claire", "Daniel", "David", "Dean", "Devon", "Elena", "Elias", "Elise", "Ethan", "Evelyn", "Felix", "Fiona", "Gabriel", "Grace", "Hannah", "Harper", "Isaac", "Isabel", "Isaiah", "Jade", "James", "Jonah", "Jordan", "Joseph", "Julia", "Kai", "Kendra", "Kevin", "Leah", "Leo", "Liam", "Lina", "Lucas", "Lucia", "Marcus", "Maria", "Mateo", "Maya", "Micah", "Mina", "Nadia", "Naomi", "Nathan", "Nora", "Oliver", "Olivia", "Omar", "Owen", "Paige", "Peter", "Rafael", "Rebecca", "Riley", "Rowan", "Samuel", "Sarah", "Sofia", "Stella", "Talia", "Theo", "Thomas", "Tobias", "Victor", "Violet", "William", "Yara", "Yuki", "Zoe", "Adrian", "Alina", "Amara", "Ansel", "Asher", "Beatrice", "Bennett", "Briar", "Bruno", "Celeste", "Cesar", "Colin", "Damian", "Darius", "Delia", "Dominic", "Edith", "Emmett", "Esme", "Estelle", "Farah", "Finn", "Francesca", "Gideon", "Helena", "Hugo", "Imogen", "Imani", "Ingrid", "Javier", "Josiah", "Kieran", "Layla", "Leona"]
const CITIZEN_LAST_NAMES: Array[String] = ["Ashford", "Alvarez", "Bennett", "Brooks", "Chen", "Clarke", "Costa", "Delgado", "Ellis", "Foster", "Garcia", "Haddad", "Hayes", "Ibrahim", "Kim", "Laurent", "Morales", "Navarro", "Okafor", "Patel", "Price", "Reyes", "Rivera", "Rostova", "Santos", "Shah", "Singh", "Tanaka", "Vance", "Walker", "Young", "Adams", "Anderson", "Bailey", "Baker", "Bell", "Bishop", "Carter", "Castillo", "Chavez", "Collins", "Cooper", "Cruz", "Davis", "Edwards", "Flores", "Ford", "Franklin", "Gomez", "Gonzalez", "Gray", "Green", "Griffin", "Hall", "Harris", "Howard", "Hughes", "Jackson", "Jenkins", "Johnson", "Kelly", "King", "Lee", "Lewis", "Long", "Martin", "Mason", "Mitchell", "Morgan", "Morris", "Murphy", "Nelson", "Ortiz", "Parker", "Perry", "Phillips", "Powell", "Ramirez", "Reed", "Richardson", "Roberts", "Robinson", "Rogers", "Ross", "Russell", "Scott", "Simmons", "Stewart", "Sullivan", "Taylor", "Thomas", "Thompson", "Torres", "Turner", "Ward", "Washington", "Watson", "White", "Williams", "Wilson", "Wood", "Wright", "Zhang", "Abbott", "Acosta", "Aguirre", "Alexander", "Allen", "Arias", "Armstrong", "Arnold", "Atkinson", "Austin", "Banks", "Barnes", "Barrett", "Bates", "Beck", "Becker", "Benson"]

func _milestone14_gcd(a: int, b: int) -> int:
	var left: int = absi(a)
	var right: int = absi(b)
	while right != 0:
		var remainder: int = left % right
		left = right
		right = remainder
	return maxi(1, left)

func _milestone14_name_for_id(_citizen_id: int) -> String:
	# A randomized coprime stride permutes all 14,400 combinations without replacement.
	var combination_count: int = CITIZEN_FIRST_NAMES.size() * CITIZEN_LAST_NAMES.size()
	for attempt in range(combination_count):
		var combination_index: int = posmod(citizen_name_permutation_offset + citizen_name_permutation_cursor * citizen_name_permutation_stride, combination_count)
		citizen_name_permutation_cursor += 1
		var first_index: int = combination_index % CITIZEN_FIRST_NAMES.size()
		var last_index: int = int(combination_index / CITIZEN_FIRST_NAMES.size())
		var candidate: String = CITIZEN_FIRST_NAMES[first_index] + " " + CITIZEN_LAST_NAMES[last_index]
		if used_citizen_names.has(candidate):
			continue
		var already_present: bool = false
		for person in citizens:
			if str(person.get("name", "")) == candidate:
				already_present = true
				break
		if already_present:
			used_citizen_names[candidate] = true
			continue
		used_citizen_names[candidate] = true
		return candidate
	return "Survivor %05d" % citizen_name_permutation_cursor

func _milestone14_proficiency_bonus(unit: Dictionary, skill: String) -> float:
	var survivor_id: int = int(unit.get("survivor_id", -1))
	for person in survivors:
		if int(person.get("id", -2)) == survivor_id:
			var xp_key: String = "combat_xp" if skill == "combat" else ("medical_xp" if skill == "medical" else ("gathering_xp" if skill == "gathering" else "engineering_xp"))
			var xp: int = int(person.get(xp_key, 0))
			var multiplier: float = 1.0 + minf(0.75, float(xp) / 1000.0)
			if skill == "combat" and faction_doctrine == "MARTIAL LAW":
				multiplier *= 1.2
			return multiplier
	return 1.0

func _milestone14_expertise_for_id(citizen_id: int) -> String:
	var expertise: Array[String] = ["Marksman", "Builder", "Medic", "Lumberjack", "Scavenger", "Mechanic"]
	return expertise[posmod(citizen_id * 17 + citizen_name_seed, expertise.size())]

func _milestone14_initialize_citizens() -> void:
	citizens.clear()
	var used_names: Dictionary = {}
	for i in range(survivors.size()):
		var person: Dictionary = survivors[i]
		var citizen_id: int = int(person.get("id", i))
		var candidate_name: String = _milestone14_name_for_id(citizen_id)
		while used_names.has(candidate_name):
			citizen_id = posmod(citizen_id + 1, 10000)
			candidate_name = _milestone14_name_for_id(citizen_id)
		used_names[candidate_name] = true
		person["name"] = candidate_name
		person["expertise"] = _milestone14_expertise_for_id(citizen_id)
		person["engineering_xp"] = int(person.get("build_xp", 0))
		person["gathering_xp"] = 0
		person["hp"] = float(person.get("hp", 100.0))
		survivors[i] = person
		citizens.append(person.duplicate(true))

func _milestone14_add_refugee(expertise_hint: String = "", recruit_to_workforce: bool = true) -> void:
	var next_id: int = 1
	for existing_person in citizens:
		next_id = maxi(next_id, int(existing_person.get("id", 0)) + 1)
	if next_id >= 10000:
		next_id = posmod(next_id, 10000)
	var full_name: String = _milestone14_name_for_id(next_id)
	for attempt in range(10000):
		var exists := false
		for person in citizens:
			if str(person.get("name", "")) == full_name:
				exists = true
				break
		if not exists:
			break
		next_id = posmod(next_id + 1, 10000)
		full_name = _milestone14_name_for_id(next_id)
	var expertise: String = expertise_hint if not expertise_hint.is_empty() else _milestone14_expertise_for_id(next_id)
	var refugee: Dictionary = {"id": next_id, "name": full_name, "role": "WORKER", "expertise": expertise, "combat_xp": 0, "engineering_xp": 0, "build_xp": 0, "medical_xp": 0, "gathering_xp": 0, "veteran_rank": 1, "hp": 100.0, "max_hp": 100.0, "equipped_weapon": "", "traits": [], "ops_assignment": "", "ops_location": "IDLE", "infection_active": false, "infection_timer": 0.0, "infection_position": Vector2.ZERO, "infection_attacker": "", "infection_clinic_care_started": false}
	citizens.append(refugee)
	if recruit_to_workforce:
		survivors.append(refugee.duplicate(true))
		if not outposts.is_empty():
			var recruit_origin: Vector2 = _outpost_recruit_spawn(0, outposts[0]["pos"])
			units.append({"id": _next_unit_id(), "survivor_id": next_id, "pos": recruit_origin, "kind": "worker", "cooldown": 0.2, "hp": 100.0, "max_hp": 100.0, "kills": 0, "rank": 0, "garrisoned": false, "garrison_building": -1, "move_target": null, "manual_order": false, "ai_task": "", "steering": {}})

func _milestone14_adjust_allocation(category: String, delta: int) -> void:
	if not role_allocations.has(category):
		return
	var candidates: Array[int] = []
	for i in range(survivors.size()):
		var role: String = str(survivors[i].get("role", "WORKER"))
		if role in ["WORKER", "ENGINEER"] or (category == "SQUAD" and role in ["INFANTRY", "SNIPER", "HEAVY", "MEDIC"]):
			candidates.append(i)
	candidates.sort_custom(func(a: int, b: int) -> bool:
		var score_a: int = int(survivors[a].get("engineering_xp", 0)) + int(survivors[a].get("gathering_xp", 0)) + int(survivors[a].get("combat_xp", 0)) + int(survivors[a].get("medical_xp", 0))
		var score_b: int = int(survivors[b].get("engineering_xp", 0)) + int(survivors[b].get("gathering_xp", 0)) + int(survivors[b].get("combat_xp", 0)) + int(survivors[b].get("medical_xp", 0))
		return score_a > score_b
	)
	var current_count: int = int(role_allocations[category])
	if delta > 0 and not candidates.is_empty():
		if category == "SQUAD":
			_milestone14_create_raid_squad()
			return
		var chosen: Dictionary = survivors[candidates[0]]
		if category == "ENGINEERS":
			chosen["role"] = "ENGINEER"
			chosen["assignment_category"] = "ENGINEERS"
		elif category == "GATHERERS" or category == "FACILITY":
			chosen["role"] = "WORKER"
			chosen["assignment_category"] = category
		elif category == "SQUAD" and int(weapons.get("rifles", 0)) > 0:
			chosen["role"] = "INFANTRY"
			chosen["equipped_weapon"] = "rifles"
			weapons["rifles"] = int(weapons.get("rifles", 0)) - 1
		survivors[candidates[0]] = chosen
		for unit_index in range(units.size()):
			if int(units[unit_index].get("survivor_id", -1)) == int(chosen.get("id", -2)):
				units[unit_index]["kind"] = str(chosen.get("role", "WORKER")).to_lower()
				units[unit_index]["assignment_category"] = category
		role_allocations[category] = current_count + 1
	elif delta < 0 and current_count > 0:
		role_allocations[category] = current_count - 1
		for i in range(survivors.size() - 1, -1, -1):
			if category == "ENGINEERS" and str(survivors[i].get("role", "")) == "ENGINEER":
				survivors[i]["role"] = "WORKER"
				break
	_save_operation()
	queue_redraw()

func _milestone14_create_raid_squad() -> void:
	if raid_squads.size() >= 20:
		message = "MAXIMUM 20 RAID SQUADS"
		message_timer = 1.5
		return
	var already_assigned: Array[int] = []
	for squad in raid_squads:
		for member_id in squad.get("members", []):
			already_assigned.append(int(member_id))
	var candidates: Array[int] = []
	for i in range(survivors.size()):
		var person: Dictionary = survivors[i]
		var role: String = str(person.get("role", ""))
		var citizen_id: int = int(person.get("id", i))
		if role in ["INFANTRY", "SNIPER", "HEAVY", "MEDIC"] and not already_assigned.has(citizen_id):
			candidates.append(i)
	candidates.sort_custom(func(a: int, b: int) -> bool:
		var person_a: Dictionary = survivors[a]
		var person_b: Dictionary = survivors[b]
		var xp_a: int = int(person_a.get("combat_xp", 0)) + int(person_a.get("medical_xp", 0))
		var xp_b: int = int(person_b.get("combat_xp", 0)) + int(person_b.get("medical_xp", 0))
		var role_a: String = str(person_a.get("role", ""))
		var role_b: String = str(person_b.get("role", ""))
		var expert_a: String = str(person_a.get("expertise", ""))
		var expert_b: String = str(person_b.get("expertise", ""))
		var bonus_a: int = 200 if ((role_a == "MEDIC" and expert_a == "Medic") or (role_a != "MEDIC" and expert_a == "Marksman")) else 0
		var bonus_b: int = 200 if ((role_b == "MEDIC" and expert_b == "Medic") or (role_b != "MEDIC" and expert_b == "Marksman")) else 0
		return xp_a + bonus_a > xp_b + bonus_b
	)
	var members: Array[int] = []
	for candidate_index in candidates:
		if members.size() >= 8:
			break
		members.append(int(survivors[candidate_index].get("id", candidate_index)))
	if members.is_empty():
		message = "NO UNASSIGNED ARMED SURVIVORS AVAILABLE"
	else:
		raid_squads.append({"id": raid_squads.size() + 1, "members": members, "name": "RAID SQUAD %02d" % (raid_squads.size() + 1), "morale": 100, "status": "READY"})
		role_allocations["SQUAD"] = raid_squads.size()
		message = "RAID SQUAD FORMED — %d XP-PRIORITIZED MEMBERS" % members.size()
	message_timer = 1.8
	_save_operation()

func _milestone14_commit_work_zone(zone_rect: Rect2) -> void:
	var estimates: Dictionary = {"wood": 0, "scrap": 0, "food": 0, "fuel": 0}
	for tree in trees:
		if bool(tree.get("alive", false)) and zone_rect.has_point(tree["pos"]):
			estimates["wood"] = int(estimates["wood"]) + 15
	for i in range(buildings.size()):
		if zone_rect.intersects(buildings[i]) and not bool(building_archetypes[i].get("destroyed", false)):
			estimates["scrap"] = int(estimates["scrap"]) + 45
			if str(building_archetypes[i].get("type", "")) in ["SUPERMARKET", "RESIDENTIAL"]:
				estimates["food"] = int(estimates["food"]) + 12
	for crate in supply_crates:
		if zone_rect.has_point(crate["pos"]):
			estimates["fuel"] = int(estimates["fuel"]) + 15
	work_zones.append({"rect": zone_rect, "estimates": estimates, "active": true})
	message = "WORK ZONE: %d WOOD / %d SCRAP / %d FOOD / %d FUEL" % [int(estimates["wood"]), int(estimates["scrap"]), int(estimates["food"]), int(estimates["fuel"])]
	message_timer = 3.0
	_save_operation()

func _milestone14_tick_workforce(_delta: float) -> void:
	for unit_index in range(units.size()):
		var worker: Dictionary = units[unit_index]
		var role: String = str(worker.get("kind", ""))
		if role not in ["worker", "engineer"] or bool(worker.get("garrisoned", false)):
			continue
		var cargo_type: String = str(worker.get("cargo_type", ""))
		if not cargo_type.is_empty():
			var cargo_outpost: int = _nearest_outpost_index(worker["pos"])
			if cargo_outpost >= 0:
				var gate_position: Vector2 = _nearest_outpost_gate_position(cargo_outpost, worker["pos"])
				if worker["pos"].distance_to(gate_position) <= 38.0:
					var amount: int = int(worker.get("cargo_amount", 0))
					if cargo_type == "wood":
						wood += amount
					elif cargo_type == "scrap":
						scrap += amount
					elif cargo_type == "food":
						food += amount
					elif cargo_type == "fuel":
						fuel += float(amount)
					worker["cargo_type"] = ""
					worker["cargo_amount"] = 0
					worker["ai_task"] = ""
					worker["move_target"] = null
					units[unit_index] = worker
				else:
					worker["move_target"] = gate_position
					worker["ai_task"] = "HAUL"
					units[unit_index] = worker
			continue
		if not work_outside_enabled:
			var nearest_outpost: int = _nearest_outpost_index(worker["pos"])
			if nearest_outpost >= 0:
				worker["move_target"] = _nearest_outpost_gate_position(nearest_outpost, worker["pos"])
				worker["ai_task"] = "RECALL"
				units[unit_index] = worker
			continue
		if worker.get("move_target") is Vector2 or not str(worker.get("ai_task", "")).is_empty():
			continue
		var fuel_crate_index: int = -1
		var fuel_crate_distance: float = INF
		for crate_index in range(supply_crates.size()):
			var crate_position: Vector2 = supply_crates[crate_index].get("pos", Vector2.ZERO)
			var in_work_zone: bool = false
			for zone in work_zones:
				if bool(zone.get("active", true)) and zone.get("rect", Rect2()).has_point(crate_position):
					in_work_zone = true
					break
			if in_work_zone and worker["pos"].distance_squared_to(crate_position) < fuel_crate_distance:
				fuel_crate_distance = worker["pos"].distance_squared_to(crate_position)
				fuel_crate_index = crate_index
		if fuel_crate_index >= 0:
			worker["work_kind"] = "fuel"
			worker["work_target_index"] = fuel_crate_index
			worker["work_timer"] = 2.0
			worker["move_target"] = supply_crates[fuel_crate_index].get("pos", Vector2.ZERO)
			worker["ai_task"] = "WORK_ZONE"
			units[unit_index] = worker
			continue
		var best_tree: int = -1
		var best_distance: float = INF
		for tree_index in range(trees.size()):
			if not bool(trees[tree_index].get("alive", false)):
				continue
			var tree_pos: Vector2 = trees[tree_index]["pos"]
			for zone in work_zones:
				if bool(zone.get("active", true)) and zone.get("rect", Rect2()).has_point(tree_pos):
					var distance: float = worker["pos"].distance_squared_to(tree_pos)
					if distance < best_distance:
						best_distance = distance
						best_tree = tree_index
		if best_tree >= 0:
			worker["work_kind"] = "chop"
			worker["work_target_index"] = best_tree
			worker["work_timer"] = 3.0
			worker["move_target"] = trees[best_tree]["pos"]
			worker["ai_task"] = "WORK_ZONE"
			units[unit_index] = worker
			continue
		var target_building: int = -1
		var target_distance: float = INF
		for building_index in range(buildings.size()):
			if bool(building_archetypes[building_index].get("destroyed", false)) or not bool(building_archetypes[building_index].get("cache_available", true)):
				continue
			var center: Vector2 = buildings[building_index].get_center()
			var in_zone := false
			for zone in work_zones:
				if bool(zone.get("active", true)) and zone.get("rect", Rect2()).has_point(center):
					in_zone = true
					break
			if in_zone:
				var distance: float = worker["pos"].distance_squared_to(center)
				if distance < target_distance:
					target_distance = distance
					target_building = building_index
		if target_building >= 0:
			worker["move_target"] = buildings[target_building].get_center()
			worker["ai_task"] = "SCAVENGE"
			units[unit_index] = worker

func _milestone14_draw_work_zones() -> void:
	for zone in work_zones:
		var zone_rect: Rect2 = zone.get("rect", Rect2())
		draw_rect(zone_rect, Color(0.25, 0.85, 0.55, 0.10))
		draw_rect(zone_rect, Color("#65e6a2"), false, 3.0)
	if work_zone_dragging:
		var preview_rect := Rect2(work_zone_start, work_zone_current - work_zone_start).abs()
		draw_rect(preview_rect, Color(0.35, 0.85, 0.95, 0.14))
		draw_rect(preview_rect, Color("#83e6f2"), false, 3.0)
		var wood_estimate: int = 0
		var scrap_estimate: int = 0
		var food_estimate: int = 0
		var fuel_estimate: int = 0
		for tree in trees:
			if bool(tree.get("alive", false)) and preview_rect.has_point(tree["pos"]):
				wood_estimate += 15
		for i in range(buildings.size()):
			if preview_rect.intersects(buildings[i]) and not bool(building_archetypes[i].get("destroyed", false)):
				scrap_estimate += 45
				if str(building_archetypes[i].get("type", "")) in ["SUPERMARKET", "RESIDENTIAL"]:
					food_estimate += 12
		for crate in supply_crates:
			if preview_rect.has_point(crate["pos"]):
				fuel_estimate += 15
		var badge_rect := Rect2(safe_insets.x + 12.0, safe_insets.y + 280.0, viewport_size.x - safe_insets.x - safe_insets.z - 24.0, 54.0)
		draw_rect(badge_rect, Color("#0a1b18", 0.96))
		draw_rect(badge_rect, Color("#83e6f2"), false, 2.0)
		_draw_text("ZONE ESTIMATE  WOOD %d  SCRAP %d  FOOD %d  FUEL %d" % [wood_estimate, scrap_estimate, food_estimate, fuel_estimate], badge_rect.position + Vector2(8.0, 32.0), 10, Color("#e7fff5"))

func _milestone14_draw_hud_panel() -> void:
	if game_state != "playing" or command_tab != 1:
		return
	var panel_top: float = safe_insets.y + 286.0
	var panel_bottom: float = viewport_size.y - safe_insets.w - 8.0
	var panel_height: float = maxf(180.0, minf(244.0, panel_bottom - panel_top))
	var panel_rect := Rect2(safe_insets.x + 8.0, panel_top, viewport_size.x - safe_insets.x - safe_insets.z - 16.0, panel_height)
	draw_rect(panel_rect, Color("#091713", 0.96))
	draw_rect(panel_rect, Color("#5ecf91"), false, 2.0)
	var population: int = citizens.size()
	var idle_count: int = 0
	for person in survivors:
		if str(person.get("role", "WORKER")) in ["WORKER", "IDLE"]:
			idle_count += 1
	_draw_text("POP %d  IDLE %d   GATHERERS %d   ENGINEERS %d" % [population, idle_count, int(role_allocations.get("GATHERERS", 0)), int(role_allocations.get("ENGINEERS", 0))], panel_rect.position + Vector2(8.0, 18.0), 10, Color("#e7fff5"))
	var labels: Array[String] = ["GATHERERS", "ENGINEERS", "FACILITY", "SQUAD"]
	for i in range(4):
		var x: float = panel_rect.position.x + 8.0 + float(i) * ((panel_rect.size.x - 16.0) / 4.0)
		_draw_text(labels[i] + "  [-] " + str(int(role_allocations.get(labels[i], 0))) + " [+]", Vector2(x, panel_rect.position.y + 42.0), 8, Color("#f2d98a"))
	_draw_text("DRAG MAP TO BOX A WORK ZONE  |  " + ("WORK OUTSIDE" if work_outside_enabled else "RECALL TO OUTPOST"), panel_rect.position + Vector2(8.0, 60.0), 8, Color("#83e6f2"))
	_draw_text("DOCTRINE: " + faction_doctrine + "  |  READY IN %dD" % _milestone14_doctrine_cooldown(), panel_rect.position + Vector2(8.0, 86.0), 9, Color("#f2d98a"))
	_draw_text("[DOCTRINE]   [SPECIALISTS]   [OPS MONITOR]", panel_rect.position + Vector2(8.0, 110.0), 9, Color("#83e6f2"))
	_draw_text("SQUAD %d/%d  %s  MEMBERS %d" % [selected_raid_squad + 1, maxi(1, raid_squads.size()), str(raid_squads[selected_raid_squad].get("status", "EMPTY")) if selected_raid_squad < raid_squads.size() else "EMPTY", raid_squads[selected_raid_squad].get("members", []).size() if selected_raid_squad < raid_squads.size() else 0], panel_rect.position + Vector2(8.0, 136.0), 9, Color("#f2d98a"))
	var squad_labels: Array[String] = ["[CREATE]", "[DEPLOY]", "[RECALL]", "[DISBAND]"]
	for squad_button in range(4):
		var squad_rect := Rect2(panel_rect.position.x + 4.0 + float(squad_button) * ((panel_rect.size.x - 8.0) / 4.0), panel_rect.position.y + 146.0, (panel_rect.size.x - 12.0) / 4.0, 52.0)
		draw_rect(squad_rect, Color("#1c3c30") if squad_button < 3 else Color("#4b2923"))
		draw_rect(squad_rect, Color("#75c9e8"), false, 1.5)
		_draw_text(squad_labels[squad_button], squad_rect.position + Vector2(5.0, 31.0), 9, Color("#ffffff"))
	if specialists_panel_open:
		_milestone14_draw_specialists(panel_rect)

func _milestone14_handle_panel_tap(position: Vector2) -> bool:
	if game_state != "playing" or command_tab != 1:
		return false
	var panel_top: float = safe_insets.y + 286.0
	var panel_bottom: float = viewport_size.y - safe_insets.w - 8.0
	var panel_height: float = maxf(180.0, minf(244.0, panel_bottom - panel_top))
	var panel_rect := Rect2(safe_insets.x + 8.0, panel_top, viewport_size.x - safe_insets.x - safe_insets.z - 16.0, panel_height)
	if not panel_rect.has_point(position):
		return false
	var keys: Array[String] = ["GATHERERS", "ENGINEERS", "FACILITY", "SQUAD"]
	var cell_width: float = (panel_rect.size.x - 16.0) / 4.0
	var cell_index: int = clampi(floori((position.x - panel_rect.position.x - 8.0) / cell_width), 0, 3)
	var local_x: float = fposmod(position.x - panel_rect.position.x - 8.0, cell_width)
	if position.y >= panel_rect.position.y + 24.0 and position.y <= panel_rect.position.y + 52.0:
		_milestone14_adjust_allocation(keys[cell_index], -1 if local_x < cell_width * 0.5 else 1)
		return true
	if position.y >= panel_rect.position.y + 146.0 and position.y <= panel_rect.position.y + 198.0:
		var squad_cell: float = panel_rect.size.x / 4.0
		var squad_action: int = clampi(floori((position.x - panel_rect.position.x) / squad_cell), 0, 3)
		_milestone14_squad_ui_action(squad_action)
		return true
	if position.y >= panel_rect.position.y + 84.0 and position.y <= panel_rect.position.y + 138.0:
		var panel_ratio: float = (position.x - panel_rect.position.x) / panel_rect.size.x
		if panel_ratio < 0.34:
			_milestone14_cycle_doctrine()
		elif panel_ratio < 0.67:
			specialists_panel_open = not specialists_panel_open
		else:
			ops_monitor_open = not ops_monitor_open
		return true
	return true


func _milestone15_ops_panel_rect() -> Rect2:
	var panel_top: float = safe_insets.y + 270.0
	var panel_bottom: float = _safe_bottom_y(_deployment_panel_height()) - 8.0
	var panel_height: float = minf(430.0, maxf(380.0, panel_bottom - panel_top))
	var panel_width: float = viewport_size.x - safe_insets.x - safe_insets.z - 16.0
	return Rect2(safe_insets.x + 8.0, panel_top, panel_width, panel_height)

func _milestone15_inside_outpost(position: Vector2) -> bool:
	for outpost in outposts:
		var outpost_rect: Rect2 = outpost.get("rect", Rect2(outpost.get("pos", Vector2.ZERO) - Vector2(110.0, 110.0), Vector2(220.0, 220.0)))
		if outpost_rect.has_point(position):
			return true
	return false

func _milestone15_find_unit_index(survivor_id: int) -> int:
	for unit_index in range(units.size()):
		if int(units[unit_index].get("survivor_id", -1)) == survivor_id:
			return unit_index
	return -1

func _milestone15_squad_member_ids() -> Array[int]:
	var member_ids: Array[int] = []
	for squad in raid_squads:
		for raw_id in squad.get("members", []):
			var member_id: int = int(raw_id)
			if not member_ids.has(member_id):
				member_ids.append(member_id)
	return member_ids

func _milestone15_ops_metrics() -> Dictionary:
	var indoors: int = 0
	var outdoors: int = 0
	var deployed: int = 0
	var infected: int = 0
	var idle: int = 0
	var squad_members: Array[int] = _milestone15_squad_member_ids()
	for survivor in survivors:
		var survivor_id: int = int(survivor.get("id", -1))
		var unit_index: int = _milestone15_find_unit_index(survivor_id)
		if bool(survivor.get("infection_active", false)):
			infected += 1
			continue
		var is_deployed: bool = false
		if squad_members.has(survivor_id):
			for squad in raid_squads:
				var members: Array = squad.get("members", [])
				if members.has(survivor_id) and str(squad.get("status", "")) == "DEPLOYED":
					is_deployed = true
					deployed += 1
					break
		if is_deployed:
			continue
		if unit_index < 0:
			idle += 1
			continue
		var unit: Dictionary = units[unit_index]
		var is_indoors: bool = bool(unit.get("garrisoned", false)) or _milestone15_inside_outpost(unit.get("pos", Vector2.ZERO))
		if is_indoors:
			indoors += 1
		elif squad_members.has(survivor_id) or not str(survivor.get("ops_assignment", "")).is_empty() or unit.get("move_target", null) is Vector2 or not str(unit.get("ai_task", "")).is_empty():
			outdoors += 1
		else:
			idle += 1
	return {"indoors": indoors, "outdoors": outdoors, "deployed": deployed, "infected": infected, "idle": idle}

func _milestone15_ops_count(key: String) -> int:
	if key == "OUTDOOR_SQUADS":
		var squad_count: int = 0
		for squad in raid_squads:
			if str(squad.get("status", "")) == "DEPLOYED":
				squad_count += 1
		return squad_count
	var count: int = 0
	for survivor in survivors:
		if str(survivor.get("ops_assignment", "")) == key:
			count += 1
	return count

func _milestone15_adjust_ops_allocation(key: String, amount: int) -> void:
	if key == "OUTDOOR_SQUADS":
		if amount > 0:
			var previous_count: int = raid_squads.size()
			_milestone14_create_raid_squad()
			if raid_squads.size() > previous_count:
				var squad: Dictionary = raid_squads[raid_squads.size() - 1]
				for member_id in squad.get("members", []):
					var unit_index: int = _milestone15_find_unit_index(int(member_id))
					if unit_index >= 0:
						units[unit_index]["move_target"] = camera_position
						units[unit_index]["manual_order"] = true
						units[unit_index]["garrisoned"] = false
				squad["status"] = "DEPLOYED"
				raid_squads[raid_squads.size() - 1] = squad
		else:
			for squad_index in range(raid_squads.size()):
				var squad: Dictionary = raid_squads[squad_index]
				if str(squad.get("status", "")) == "DEPLOYED":
					for member_id in squad.get("members", []):
						var unit_index: int = _milestone15_find_unit_index(int(member_id))
						if unit_index >= 0:
							var outpost_index: int = _nearest_outpost_index(units[unit_index].get("pos", camera_position))
							if outpost_index >= 0:
								units[unit_index]["move_target"] = _nearest_outpost_gate_position(outpost_index, units[unit_index].get("pos", camera_position))
							units[unit_index]["manual_order"] = true
					squad["status"] = "RECALLING"
					raid_squads[squad_index] = squad
					break
		_save_operation()
		queue_redraw()
		return
	if amount > 0:
		var candidates: Array[int] = []
		var squad_ids: Array[int] = _milestone15_squad_member_ids()
		for survivor_index in range(survivors.size()):
			var person: Dictionary = survivors[survivor_index]
			var person_id: int = int(person.get("id", -1))
			if squad_ids.has(person_id) or bool(person.get("infection_active", false)) or not str(person.get("ops_assignment", "")).is_empty():
				continue
			var candidate_role: String = str(person.get("role", "WORKER"))
			var role_allowed: bool = false
			if key == "INDOOR_GUARD":
				role_allowed = candidate_role in ["INFANTRY", "SNIPER", "HEAVY", "MEDIC"]
			elif key == "INDOOR_CLINIC":
				role_allowed = candidate_role in ["MEDIC", "WORKER", "ENGINEER"]
			else:
				role_allowed = candidate_role in ["WORKER", "ENGINEER"]
			if role_allowed:
				candidates.append(survivor_index)
		candidates.sort_custom(func(a: int, b: int) -> bool:
			var score_a: int = int(survivors[a].get("medical_xp", 0)) + int(survivors[a].get("engineering_xp", 0)) + int(survivors[a].get("gathering_xp", 0))
			var score_b: int = int(survivors[b].get("medical_xp", 0)) + int(survivors[b].get("engineering_xp", 0)) + int(survivors[b].get("gathering_xp", 0))
			if key == "INDOOR_CLINIC":
				if str(survivors[a].get("role", "")) == "MEDIC": score_a += 100000
				if str(survivors[b].get("role", "")) == "MEDIC": score_b += 100000
			elif key == "INDOOR_WORKSHOP":
				if str(survivors[a].get("role", "")) == "ENGINEER": score_a += 100000
				if str(survivors[b].get("role", "")) == "ENGINEER": score_b += 100000
			elif key == "INDOOR_GUARD":
				if str(survivors[a].get("role", "")) in ["INFANTRY", "SNIPER", "HEAVY"]: score_a += 100000
				if str(survivors[b].get("role", "")) in ["INFANTRY", "SNIPER", "HEAVY"]: score_b += 100000
			return score_a > score_b
		)
		if candidates.is_empty():
			message = "NO UNASSIGNED PERSONNEL AVAILABLE"
			message_timer = 1.8
			return
		var chosen_index: int = candidates[0]
		var chosen: Dictionary = survivors[chosen_index]
		chosen["ops_assignment"] = key
		var indoors: bool = key.begins_with("INDOOR_")
		chosen["ops_location"] = "INDOORS" if indoors else "OUTDOORS"
		chosen["assignment_category"] = ("FACILITY" if key != "INDOOR_GUARD" else "") if indoors else ("FACILITY" if key == "OUTDOOR_FARM" else "GATHERERS")
		survivors[chosen_index] = chosen
		var unit_index: int = _milestone15_find_unit_index(int(chosen.get("id", -1)))
		if unit_index >= 0:
			var unit: Dictionary = units[unit_index]
			unit["garrisoned"] = false
			unit["garrison_building"] = -1
			unit["manual_order"] = false
			unit["ai_task"] = ""
			if indoors:
				var outpost_index: int = _nearest_outpost_index(unit.get("pos", camera_position))
				if outpost_index >= 0:
					unit["move_target"] = outposts[outpost_index].get("pos", camera_position)
			else:
				unit["move_target"] = null
			units[unit_index] = unit
		message = "%s ALLOCATION +1" % key.replace("_", " ")
	else:
		for survivor_index in range(survivors.size() - 1, -1, -1):
			var person: Dictionary = survivors[survivor_index]
			if str(person.get("ops_assignment", "")) != key:
				continue
			person["ops_assignment"] = ""
			person["ops_location"] = "IDLE"
			person["assignment_category"] = ""
			survivors[survivor_index] = person
			var unit_index: int = _milestone15_find_unit_index(int(person.get("id", -1)))
			if unit_index >= 0:
				units[unit_index]["garrisoned"] = false
				units[unit_index]["garrison_building"] = -1
				units[unit_index]["move_target"] = null
				units[unit_index]["manual_order"] = false
				units[unit_index]["ai_task"] = ""
			break
		message = "%s ALLOCATION -1" % key.replace("_", " ")
	message_timer = 1.5
	_save_operation()
	queue_redraw()

func _milestone15_dispatch_recall_all(dispatch: bool) -> void:
	work_outside_enabled = dispatch
	for survivor_index in range(survivors.size()):
		var person: Dictionary = survivors[survivor_index]
		var assignment: String = str(person.get("ops_assignment", ""))
		if assignment.is_empty():
			continue
		var unit_index: int = _milestone15_find_unit_index(int(person.get("id", -1)))
		if unit_index < 0:
			continue
		var unit: Dictionary = units[unit_index]
		if dispatch and assignment.begins_with("OUTDOOR_"):
			person["ops_location"] = "OUTDOORS"
			unit["garrisoned"] = false
			if str(unit.get("kind", "")) in ["worker", "engineer"]:
				unit["move_target"] = null
				unit["ai_task"] = ""
			else:
				unit["move_target"] = camera_position
				unit["ai_task"] = "OPS_DISPATCH"
		elif not dispatch:
			var outpost_index: int = _nearest_outpost_index(unit.get("pos", camera_position))
			if outpost_index >= 0:
				person["ops_location"] = "INDOORS"
				unit["garrisoned"] = false
				unit["move_target"] = outposts[outpost_index].get("pos", camera_position)
				unit["ai_task"] = ""
		survivors[survivor_index] = person
		units[unit_index] = unit
	message = "FIELD TEAMS DISPATCHED" if dispatch else "PERSONNEL RECALLED TO OUTPOSTS"
	message_timer = 2.0
	_save_operation()
	queue_redraw()

func _milestone15_draw_ops_monitor() -> void:
	if not ops_monitor_open or game_state != "playing" or command_tab != 1:
		return
	var panel: Rect2 = _milestone15_ops_panel_rect()
	draw_rect(panel, Color("#071713", 0.985))
	draw_rect(panel, Color("#78dba3"), false, 2.0)
	_draw_text("[OPS MONITOR]  INDOOR / OUTDOOR PERSONNEL", panel.position + Vector2(10.0, 22.0), 12, Color("#e9fff0"))
	var close_rect := Rect2(panel.end.x - 58.0, panel.position.y + 4.0, 52.0, 48.0)
	draw_rect(close_rect, Color("#542b2b"))
	draw_rect(close_rect, Color("#f08c80"), false, 1.5)
	_draw_text("CLOSE", close_rect.position + Vector2(5.0, 29.0), 9, Color("#ffffff"))
	var metrics: Dictionary = _milestone15_ops_metrics()
	_draw_text("INDOORS %d   OUTDOORS %d   RAID %d" % [int(metrics["indoors"]), int(metrics["outdoors"]), int(metrics["deployed"])], panel.position + Vector2(10.0, 52.0), 10, Color("#91e5b2"))
	_draw_text("INFECTED / QUARANTINE %d   IDLE %d" % [int(metrics["infected"]), int(metrics["idle"])], panel.position + Vector2(10.0, 72.0), 10, Color("#ff9b83") if int(metrics["infected"]) > 0 else Color("#b9d4c4"))
	var infected_summary: String = "BIOHAZARD CLEAR"
	for survivor in survivors:
		if bool(survivor.get("infection_active", false)):
			infected_summary = "BIOHAZARD: %s  %ds TO TURN" % [str(survivor.get("name", "SURVIVOR")), ceili(float(survivor.get("infection_timer", 0.0)))]
			break
	_draw_text(infected_summary, panel.position + Vector2(10.0, 94.0), 9, Color("#ff7777") if int(metrics["infected"]) > 0 else Color("#75d99a"))
	_draw_text("INDOOR OUTPOST ALLOCATIONS", panel.position + Vector2(10.0, 116.0), 9, Color("#91e5b2"))
	_draw_text("OUTDOOR FIELD ALLOCATIONS", panel.position + Vector2(panel.size.x * 0.5 + 8.0, 116.0), 9, Color("#83e6f2"))
	var labels: Array[String] = ["Bakery Staff", "Field Clinic Medics", "Workshop Crafters", "Perimeter Guards", "Lumber / Demo Crew", "Scavengers / Haulers", "Farm / Livestock Hands", "Deployed Raid Squads"]
	var keys: Array[String] = ["INDOOR_BAKERY", "INDOOR_CLINIC", "INDOOR_WORKSHOP", "INDOOR_GUARD", "OUTDOOR_LUMBER", "OUTDOOR_SCAVENGER", "OUTDOOR_FARM", "OUTDOOR_SQUADS"]
	var row_height: float = 50.0
	var start_y: float = panel.position.y + 132.0
	var column_gap: float = 8.0
	var column_width: float = (panel.size.x - 24.0) * 0.5
	for item_index in range(8):
		var column: int = floori(float(item_index) / 4.0)
		var row: int = item_index % 4
		var row_rect := Rect2(panel.position.x + 8.0 + float(column) * (column_width + column_gap), start_y + float(row) * row_height, column_width, 48.0)
		draw_rect(row_rect, Color("#102820"))
		draw_rect(row_rect, Color("#355d4b"), false, 1.0)
		_draw_text(labels[item_index], row_rect.position + Vector2(5.0, 18.0), 9, Color("#e7f7ec"))
		_draw_text("N %d" % _milestone15_ops_count(keys[item_index]), row_rect.position + Vector2(5.0, 37.0), 9, Color("#f2d98a"))
		var minus_rect := Rect2(row_rect.end.x - 104.0, row_rect.position.y, 48.0, 48.0)
		var plus_rect := Rect2(row_rect.end.x - 52.0, row_rect.position.y, 48.0, 48.0)
		draw_rect(minus_rect, Color("#4a302c"))
		draw_rect(plus_rect, Color("#24563b"))
		draw_rect(minus_rect, Color("#e58c7c"), false, 1.0)
		draw_rect(plus_rect, Color("#79dfa1"), false, 1.0)
		_draw_text("-", minus_rect.position + Vector2(19.0, 32.0), 22, Color("#ffffff"))
		_draw_text("+", plus_rect.position + Vector2(16.0, 32.0), 22, Color("#ffffff"))
	var action_y: float = panel.position.y + 340.0
	var action_width: float = (panel.size.x - 24.0) * 0.5
	var dispatch_rect := Rect2(panel.position.x + 8.0, action_y, action_width, 48.0)
	var recall_rect := Rect2(panel.position.x + 16.0 + action_width, action_y, action_width, 48.0)
	draw_rect(dispatch_rect, Color("#244d37"))
	draw_rect(recall_rect, Color("#3e3b2a"))
	draw_rect(dispatch_rect, Color("#79dfa1"), false, 1.5)
	draw_rect(recall_rect, Color("#e4c66d"), false, 1.5)
	_draw_text("[DISPATCH FIELD]", dispatch_rect.position + Vector2(8.0, 30.0), 11, Color("#ffffff"))
	_draw_text("[RECALL TO HQ]", recall_rect.position + Vector2(8.0, 30.0), 11, Color("#fff4c7"))

func _milestone15_handle_ops_tap(position: Vector2) -> bool:
	if not ops_monitor_open or game_state != "playing" or command_tab != 1:
		return false
	var panel: Rect2 = _milestone15_ops_panel_rect()
	if not panel.has_point(position):
		return false
	var close_rect := Rect2(panel.end.x - 58.0, panel.position.y + 4.0, 52.0, 48.0)
	if close_rect.has_point(position):
		ops_monitor_open = false
		return true
	var action_y: float = panel.position.y + 340.0
	if position.y >= action_y and position.y <= action_y + 48.0:
		_milestone15_dispatch_recall_all(position.x < panel.position.x + panel.size.x * 0.5)
		return true
	var start_y: float = panel.position.y + 132.0
	if position.y >= start_y and position.y < start_y + 200.0:
		var column_width: float = (panel.size.x - 24.0) * 0.5
		var column: int = 0 if position.x < panel.position.x + 8.0 + column_width else 1
		var row: int = clampi(floori((position.y - start_y) / 50.0), 0, 3)
		var item_index: int = column * 4 + row
		var row_right: float = panel.position.x + 8.0 + float(column) * (column_width + 8.0) + column_width
		var keys: Array[String] = ["INDOOR_BAKERY", "INDOOR_CLINIC", "INDOOR_WORKSHOP", "INDOOR_GUARD", "OUTDOOR_LUMBER", "OUTDOOR_SCAVENGER", "OUTDOOR_FARM", "OUTDOOR_SQUADS"]
		if position.x >= row_right - 104.0 and position.x <= row_right - 56.0:
			_milestone15_adjust_ops_allocation(keys[item_index], -1)
		elif position.x >= row_right - 52.0 and position.x <= row_right - 4.0:
			_milestone15_adjust_ops_allocation(keys[item_index], 1)
		return true
	return true

func _milestone15_apply_pathogen_exposure(unit_index: int, attacker_kind: String) -> void:
	if unit_index < 0 or unit_index >= units.size():
		return
	var unit: Dictionary = units[unit_index]
	var survivor_id: int = int(unit.get("survivor_id", -1))
	for survivor_index in range(survivors.size()):
		var survivor: Dictionary = survivors[survivor_index]
		if int(survivor.get("id", -2)) != survivor_id:
			continue
		var traits: Array = survivor.get("traits", [])
		if traits.has("IMMUNE") or bool(survivor.get("infection_active", false)):
			return
		var max_hp: float = maxf(1.0, float(unit.get("max_hp", 100.0)))
		var remaining_hp: float = clampf(float(unit.get("hp", max_hp)) / max_hp, 0.0, 1.0)
		var natural_immunity_roll: bool = randf() < 0.08
		var turn_risk: float = 0.75 if attacker_kind == "brute" else (0.40 if remaining_hp > 0.65 else (0.50 if remaining_hp >= 0.30 else 0.65))
		if not natural_immunity_roll and randf() > turn_risk:
			return
		if natural_immunity_roll:
			traits.append("IMMUNE")
			survivor["traits"] = traits
			survivor["max_hp"] = float(survivor.get("max_hp", max_hp)) * 1.15
			survivor["hp"] = minf(float(survivor["max_hp"]), float(survivor.get("hp", max_hp)) + max_hp * 0.15)
			unit["max_hp"] = max_hp * 1.15
			unit["hp"] = minf(float(unit["max_hp"]), float(unit.get("hp", max_hp)) + max_hp * 0.15)
			units[unit_index] = unit
			for citizen_index in range(citizens.size()):
				if int(citizens[citizen_index].get("id", -2)) == survivor_id:
					citizens[citizen_index]["traits"] = traits.duplicate()
					citizens[citizen_index]["max_hp"] = float(citizens[citizen_index].get("max_hp", max_hp)) * 1.15
					citizens[citizen_index]["hp"] = float(citizens[citizen_index].get("hp", max_hp)) + max_hp * 0.15
			survivors[survivor_index] = survivor
			var immune_alert: String = "GENETIC IMMUNITY: %s — IMMUNE TRAIT / +15%% MAX HP" % str(survivor.get("name", "SURVIVOR"))
			radio_banner_text = immune_alert
			radio_banner_timer = 7.0
			radio_log.append("DAY %d — %s" % [survival_day, immune_alert])
			message = immune_alert
			message_timer = 4.0
			_queue_sfx("infection")
		else:
			survivor["infection_active"] = true
			survivor["infection_timer"] = 180.0
			survivor["infection_position"] = unit.get("pos", Vector2.ZERO)
			survivor["infection_attacker"] = attacker_kind
			survivor["infection_clinic_care_started"] = false
			survivors[survivor_index] = survivor
			var infection_alert: String = "PATHOGEN EXPOSURE: %s — 180S INCUBATION" % str(survivor.get("name", "SURVIVOR"))
			radio_banner_text = infection_alert
			radio_banner_timer = 6.0
			radio_log.append("DAY %d — %s" % [survival_day, infection_alert])
			message = infection_alert
			message_timer = 3.0
			_queue_sfx("infection")
		return

func _milestone15_tick_infections(delta: float) -> void:
	var clinic_staff_count: int = 0
	for staff in survivors:
		if str(staff.get("ops_assignment", "")) == "INDOOR_CLINIC":
			clinic_staff_count += 1
	for survivor_index in range(survivors.size() - 1, -1, -1):
		var survivor: Dictionary = survivors[survivor_index]
		if not bool(survivor.get("infection_active", false)):
			continue
		var survivor_id: int = int(survivor.get("id", -1))
		var unit_index: int = _milestone15_find_unit_index(survivor_id)
		var infection_position: Vector2 = survivor.get("infection_position", Vector2.ZERO)
		if unit_index >= 0:
			infection_position = units[unit_index].get("pos", infection_position)
			survivor["infection_position"] = infection_position
		var staffed_clinic_nearby: bool = false
		if clinic_staff_count > 0 and _milestone15_inside_outpost(infection_position):
			for clinic in constructed_buildings:
				if str(clinic.get("kind", "")) == "clinic" and infection_position.distance_to(clinic.get("pos", Vector2.ZERO)) <= 150.0:
					staffed_clinic_nearby = true
					break
		var infection_rate: float = 1.0
		if staffed_clinic_nearby:
			infection_rate = 0.5
			if not bool(survivor.get("infection_clinic_care_started", false)):
				if int(weapons.get("medkits", 0)) > 0:
					weapons["medkits"] = int(weapons.get("medkits", 0)) - 1
				survivor["infection_clinic_care_started"] = true
				if randf() < 0.35:
					survivor["infection_active"] = false
					survivor["infection_timer"] = 0.0
					survivors[survivor_index] = survivor
					var stabilized_alert: String = "CLINIC STABILIZED %s — INFECTION CLEARED" % str(survivor.get("name", "SURVIVOR"))
					radio_banner_text = stabilized_alert
					radio_banner_timer = 6.0
					radio_log.append("DAY %d — %s" % [survival_day, stabilized_alert])
					message = stabilized_alert
					message_timer = 3.0
					continue
		survivor["infection_timer"] = maxf(0.0, float(survivor.get("infection_timer", 180.0)) - delta * infection_rate)
		survivors[survivor_index] = survivor
		if float(survivor["infection_timer"]) <= 0.0:
			zombies.append({"pos": infection_position, "kind": "shambler", "hp": 45.0, "max_hp": 45.0, "wall_cooldown": 0.0, "turned_inside_outpost": _milestone15_inside_outpost(infection_position), "turned_survivor_id": survivor_id})
			if unit_index >= 0:
				units.remove_at(unit_index)
				if selected_unit_index == unit_index:
					selected_unit_index = -1
				elif selected_unit_index > unit_index:
					selected_unit_index -= 1
			_milestone14_remove_casualty({"survivor_id": survivor_id})
			var turned_alert: String = "%s TURNED — HOSTILE INSIDE THE PERIMETER" % str(survivor.get("name", "SURVIVOR"))
			radio_banner_text = turned_alert
			radio_banner_timer = 7.0
			radio_log.append("DAY %d — %s" % [survival_day, turned_alert])
			message = turned_alert
			message_timer = 4.0
			_save_operation()

func _milestone14_return_squad_equipment(person: Dictionary) -> void:
	var equipped: String = str(person.get("equipped_weapon", ""))
	if equipped in ["rifles", "snipers", "heavy_mgs", "medkits"]:
		weapons[equipped] = int(weapons.get(equipped, 0)) + 1
	person["equipped_weapon"] = ""

func _milestone14_facility_medical_multiplier() -> float:
	var medical_xp_total: int = 0
	var facility_staff_count: int = 0
	for staff in survivors:
		if str(staff.get("assignment_category", "")) == "FACILITY":
			medical_xp_total += int(staff.get("medical_xp", 0))
			facility_staff_count += 1
	if facility_staff_count <= 0:
		return 1.0
	var average_medical_xp: float = float(medical_xp_total) / float(facility_staff_count)
	return 1.0 + minf(0.75, average_medical_xp / 1000.0)

func _milestone14_update_raider_warbands(delta: float) -> void:
	for faction_index in range(faction_settlements.size()):
		var warband: Dictionary = faction_settlements[faction_index]
		if str(warband.get("faction", "")) != "RAIDER" or int(warband.get("relation", 0)) > -20 or bool(warband.get("warband_defeated", false)):
			continue
		var warband_pos: Vector2 = warband.get("warband_pos", warband.get("pos", Vector2.ZERO))
		var target_unit_index: int = -1
		var target_outpost_index: int = -1
		var nearest_distance: float = 420.0 * 420.0
		for squad in raid_squads:
			for member_id in squad.get("members", []):
				for unit_index in range(units.size()):
					var candidate: Dictionary = units[unit_index]
					if int(candidate.get("survivor_id", -1)) != int(member_id) or bool(candidate.get("garrisoned", false)):
						continue
					var distance: float = warband_pos.distance_squared_to(candidate.get("pos", Vector2.ZERO))
					if distance <= nearest_distance:
						nearest_distance = distance
						target_unit_index = unit_index
						target_outpost_index = -1
		for outpost_index in range(outposts.size()):
			var distance: float = warband_pos.distance_squared_to(outposts[outpost_index].get("pos", Vector2.ZERO))
			if distance <= nearest_distance:
				nearest_distance = distance
				target_outpost_index = outpost_index
				target_unit_index = -1
		if target_unit_index < 0 and target_outpost_index < 0:
			faction_settlements[faction_index] = warband
			continue
		var target_pos: Vector2 = units[target_unit_index].get("pos", Vector2.ZERO) if target_unit_index >= 0 else outposts[target_outpost_index].get("pos", Vector2.ZERO)
		var distance_to_target: float = warband_pos.distance_to(target_pos)
		if distance_to_target > 34.0:
			var step: Vector2 = (target_pos - warband_pos).normalized() * minf(distance_to_target - 34.0, 42.0 * delta)
			warband_pos = _move_circle_with_buildings(warband_pos, step, 10.0, delta, target_pos, warband)
			warband["warband_pos"] = warband_pos
		else:
			var attack_cooldown: float = float(warband.get("warband_attack_cooldown", 0.0))
			if attack_cooldown <= 0.0:
				if target_unit_index >= 0 and target_unit_index < units.size():
					var target_unit: Dictionary = units[target_unit_index]
					target_unit["hp"] = maxf(0.0, float(target_unit.get("hp", 100.0)) - 24.0)
					if float(target_unit["hp"]) <= 0.0:
						_milestone14_remove_casualty(target_unit)
						units.remove_at(target_unit_index)
						message = "RAIDER WARBAND KILLED A SQUAD MEMBER"
					else:
						units[target_unit_index] = target_unit
						message = "RAIDER WARBAND ENGAGING PLAYER SQUAD"
				else:
					var defended_outpost: Dictionary = outposts[target_outpost_index]
					defended_outpost["hp"] = maxf(1.0, float(defended_outpost.get("hp", 500.0)) - 22.0)
					outposts[target_outpost_index] = defended_outpost
					message = "RAIDER WARBAND ATTACKING OUTPOST"
				message_timer = 1.0
				warband["warband_attack_cooldown"] = 1.0
		# Player squads and perimeter turrets return fire against the active warband.
		var incoming_damage: float = 0.0
		for squad in raid_squads:
			for member_id in squad.get("members", []):
				for unit in units:
					if int(unit.get("survivor_id", -1)) == int(member_id) and not bool(unit.get("garrisoned", false)) and warband_pos.distance_to(unit.get("pos", Vector2.ZERO)) <= 420.0:
						incoming_damage += 12.0 * delta
		for turret in turrets:
			if warband_pos.distance_to(turret.get("pos", Vector2.ZERO)) <= minf(420.0, float(turret.get("range", TURRET_RANGE))):
				incoming_damage += 22.0 * delta
		if incoming_damage > 0.0:
			warband["warband_hp"] = maxf(0.0, float(warband.get("warband_hp", 180.0)) - incoming_damage)
		if float(warband.get("warband_hp", 180.0)) <= 0.0:
			warband["warband_defeated"] = true
			warband["strength"] = 0
			food += randi_range(25, 55)
			scrap += randi_range(30, 65)
			fuel = minf(300.0, fuel + float(randi_range(10, 25)))
			var loot_weapon: String = ["rifles", "snipers", "heavy_mgs"][randi_range(0, 2)]
			weapons[loot_weapon] = int(weapons.get(loot_weapon, 0)) + 1
			message = "RAIDER WARBAND ELIMINATED — FOOD / SCRAP / FUEL / %s LOOTED" % loot_weapon.to_upper()
			message_timer = 3.0
			_save_operation()
		faction_settlements[faction_index] = warband

func _milestone14_citizen_multiplier(citizen_id: int, skill: String) -> float:
	for person in survivors:
		if int(person.get("id", -1)) == citizen_id:
			var key: String = "combat_xp" if skill == "combat" else ("medical_xp" if skill == "medical" else ("gathering_xp" if skill == "gathering" else "engineering_xp"))
			return 1.0 + minf(0.75, float(person.get(key, 0)) / 1000.0)
	return 1.0

func _milestone14_doctrine_cooldown() -> int:
	return maxi(0, 14 - (survival_day - doctrine_change_day))

func _milestone14_cycle_doctrine() -> void:
	if _milestone14_doctrine_cooldown() > 0:
		message = "DOCTRINE LOCKED — %d DAYS REMAIN" % _milestone14_doctrine_cooldown()
		message_timer = 2.0
		return
	var doctrines: Array[String] = ["HUMANITARIAN SANCTUARY", "MARTIAL LAW", "PRAGMATIC FREEHOLD"]
	var index: int = doctrines.find(faction_doctrine)
	faction_doctrine = doctrines[(index + 1) % doctrines.size()]
	doctrine_change_day = survival_day
	doctrine_morale_shock_days = 3 if faction_doctrine == "MARTIAL LAW" else 0
	doctrine_morale_recovery_day = survival_day + 3 if faction_doctrine == "MARTIAL LAW" else 0
	for faction_index in range(faction_settlements.size()):
		var faction: Dictionary = faction_settlements[faction_index]
		var faction_type: String = str(faction.get("faction", "NEUTRAL"))
		var change: int = 0
		if faction_doctrine == "HUMANITARIAN SANCTUARY":
			change = 25 if faction_type == "NEUTRAL" else (-15 if faction_type == "MILITARISTIC" else 0)
		elif faction_doctrine == "MARTIAL LAW":
			change = 25 if faction_type == "MILITARISTIC" else (-20 if faction_type == "NEUTRAL" else 0)
		else:
			change = 10 if faction_type in ["NEUTRAL", "MILITARISTIC"] else 0
		faction["relation"] = clampi(int(faction.get("relation", 0)) + change, -100, 100)
		faction_settlements[faction_index] = faction
	if faction_doctrine == "MARTIAL LAW":
		outpost_morale = maxf(0.0, outpost_morale - 15.0)
	elif faction_doctrine == "HUMANITARIAN SANCTUARY":
		outpost_morale = minf(100.0, outpost_morale + 15.0)
	message = "FACTION DOCTRINE: " + faction_doctrine
	message_timer = 3.0
	_save_operation()

func _milestone151_update_population_heat(delta: float) -> void:
	for i in range(recent_gunfire.size() - 1, -1, -1):
		var noise: Dictionary = recent_gunfire[i]
		noise["life"] = float(noise.get("life", 0.0)) - delta
		if float(noise["life"]) <= 0.0:
			recent_gunfire.remove_at(i)
		else:
			recent_gunfire[i] = noise
	population_heat_refresh_timer -= delta
	if population_heat_refresh_timer > 0.0:
		return
	population_heat_refresh_timer = 3.0
	population_heat_targets.clear()
	for outpost_index in range(outposts.size()):
		var outpost: Dictionary = outposts[outpost_index]
		var rect: Rect2 = outpost.get("rect", Rect2(outpost.get("pos", Vector2.ZERO) - Vector2(110.0, 110.0), Vector2(220.0, 220.0)))
		var stationed: int = int(outpost.get("sheltered", 0))
		for unit in units:
			if rect.grow(120.0).has_point(unit.get("pos", Vector2.ZERO)):
				stationed += 1
		var facilities: int = 0
		for building_index in range(buildings.size()):
			if not rect.encloses(buildings[building_index]):
				continue
			if building_index < building_archetypes.size() and not bool(building_archetypes[building_index].get("destroyed", false)):
				var kind: String = _building_type_at(building_index)
				if kind in ["FACTORY", "WAREHOUSE", "SUPERMARKET", "HOSPITAL", "FARM", "INDUSTRIAL"]:
					facilities += 1
		var gunfire_score: float = 0.0
		for noise in recent_gunfire:
			var distance: float = rect.get_center().distance_to(noise.get("pos", Vector2.ZERO))
			if distance < 1800.0:
				gunfire_score += float(noise.get("life", 0.0)) / 12.0 * maxf(0.0, 1.0 - distance / 1800.0)
		var heat: float = float(stationed) + float(facilities) * 7.0 + gunfire_score * 12.0
		outpost["population_heat"] = heat
		outposts[outpost_index] = outpost
		population_heat_targets.append({"pos": rect.get_center(), "heat": heat + 1.0, "kind": "PLAYER OUTPOST"})
	for faction_index in range(faction_settlements.size()):
		var faction: Dictionary = faction_settlements[faction_index]
		var faction_pos: Vector2 = faction.get("pos", Vector2.ZERO)
		var troop_count: float = float(int(faction.get("strength", 1))) * (9.0 if str(faction.get("faction", "")) == "MILITARISTIC" else 5.0)
		var faction_noise: float = 0.0
		for noise in recent_gunfire:
			var distance: float = faction_pos.distance_to(noise.get("pos", Vector2.ZERO))
			if distance < 1800.0:
				faction_noise += float(noise.get("life", 0.0)) / 12.0 * maxf(0.0, 1.0 - distance / 1800.0)
		var faction_facilities: int = 0
		for building_index in range(buildings.size()):
			if faction_pos.distance_to(buildings[building_index].get_center()) > 650.0 or building_index >= building_archetypes.size():
				continue
			if bool(building_archetypes[building_index].get("destroyed", false)):
				continue
			var facility_kind: String = _building_type_at(building_index)
			if facility_kind in ["FACTORY", "WAREHOUSE", "SUPERMARKET", "HOSPITAL", "FARM", "INDUSTRIAL"]:
				faction_facilities += 1
		var faction_heat: float = troop_count + float(faction_facilities) * 5.0 + faction_noise * 12.0
		faction["population_heat"] = faction_heat
		faction_settlements[faction_index] = faction
		if not bool(faction.get("warband_defeated", false)):
			population_heat_targets.append({"pos": faction_pos, "heat": faction_heat + 1.0, "kind": str(faction.get("faction", "SETTLEMENT"))})
	for district in district_regions:
		var density: float = 0.0
		for building in buildings:
			if district.encloses(building):
				density += 1.0
		if density > 0.0:
			population_heat_targets.append({"pos": district.get_center(), "heat": density * 1.4, "kind": "URBAN DISTRICT"})

func _milestone151_hottest_target(position: Vector2) -> Vector2:
	# Blend attraction from every meaningful settlement instead of snapping
	# roaming infected toward one winner and ignoring nearby population centers.
	var weighted_position := Vector2.ZERO
	var total_weight: float = 0.0
	for target in population_heat_targets:
		var target_pos: Vector2 = target.get("pos", Vector2.ZERO)
		var distance: float = position.distance_to(target_pos)
		if distance > 5200.0:
			continue
		var heat: float = maxf(0.0, float(target.get("heat", 0.0)))
		var distance_weight: float = 1.0 / pow(1.0 + distance / 1800.0, 2.0)
		var weight: float = heat * distance_weight
		if weight <= 0.01:
			continue
		weighted_position += target_pos * weight
		total_weight += weight
	if total_weight <= 0.01:
		return Vector2.ZERO
	return weighted_position / total_weight

func _milestone14_seed_factions() -> void:
	faction_settlements.clear()
	var types: Array[String] = ["NEUTRAL", "MILITARISTIC", "RAIDER"]
	for i in range(3):
		var region: Rect2 = district_regions[posmod(i + 1, district_regions.size())]
		var pos := region.position + region.size * 0.5
		faction_settlements.append({"id": i + 1, "faction": types[i], "name": ["WAYFARER ENCLAVE", "STATE GUARD GARRISON", "IRON JACKALS"][i], "pos": pos, "relation": 0 if i == 0 else (-35 if i == 2 else 10), "strength": 1, "banner": true})

func _milestone14_update_factions(delta: float) -> void:
	faction_foundation_timer -= delta
	if faction_foundation_timer <= 0.0:
		faction_foundation_timer = 720.0
		if faction_settlements.size() < 12 and not district_regions.is_empty():
			var index: int = randi_range(0, district_regions.size() - 1)
			var region: Rect2 = district_regions[index]
			var kinds: Array[String] = ["NEUTRAL", "MILITARISTIC", "RAIDER"]
			var kind: String = kinds[randi_range(0, 2)]
			var pos := region.position + Vector2(randf_range(0.25, 0.75) * region.size.x, randf_range(0.25, 0.75) * region.size.y)
			faction_settlements.append({"id": faction_settlements.size() + 1, "faction": kind, "name": kind + " SETTLEMENT %02d" % (faction_settlements.size() + 1), "pos": pos, "relation": -25 if kind == "RAIDER" else 0, "strength": 1, "banner": true})
	for faction_index in range(faction_settlements.size()):
		var faction: Dictionary = faction_settlements[faction_index]
		if str(faction.get("faction", "")) == "RAIDER":
			if not faction.has("warband_pos"):
				faction["warband_pos"] = faction.get("pos", Vector2.ZERO)
			faction["warband_hp"] = float(faction.get("warband_hp", 180.0))
			faction["warband_max_hp"] = float(faction.get("warband_max_hp", 180.0))
			faction["warband_attack_cooldown"] = maxf(0.0, float(faction.get("warband_attack_cooldown", 0.0)) - delta)
			faction["warband_defeated"] = bool(faction.get("warband_defeated", false))
		elif str(faction.get("faction", "")) == "MILITARISTIC" and int(faction.get("relation", 0)) >= 25:
			faction["patrol_support"] = true
		faction_settlements[faction_index] = faction
	_milestone14_update_raider_warbands(delta)



func _milestone14_award_rescue_standing(rescue_position: Vector2) -> void:
	for i in range(faction_settlements.size()):
		var settlement: Dictionary = faction_settlements[i]
		if str(settlement.get("faction", "")) == "NEUTRAL" and rescue_position.distance_to(settlement.get("pos", Vector2.ZERO)) <= 500.0:
			_milestone14_change_relation(i, 8)

func _milestone14_relation_tier(standing: int) -> String:
	if standing >= 60: return "ALLIED"
	if standing >= 20: return "FRIENDLY"
	if standing <= -20: return "HOSTILE"
	return "CAUTIOUS"

func _milestone14_change_relation(index: int, amount: int) -> void:
	if index < 0 or index >= faction_settlements.size(): return
	var settlement: Dictionary = faction_settlements[index]
	settlement["relation"] = clampi(int(settlement.get("relation", 0)) + amount, -100, 100)
	faction_settlements[index] = settlement

func _milestone14_award_settlement_kill(position: Vector2) -> void:
	for i in range(faction_settlements.size()):
		if position.distance_to(faction_settlements[i].get("pos", Vector2.ZERO)) <= 450.0:
			_milestone14_change_relation(i, 10)

func _milestone14_apply_harvest_reputation(position: Vector2) -> void:
	for i in range(faction_settlements.size()):
		var settlement: Dictionary = faction_settlements[i]
		if str(settlement.get("faction", "")) != "RAIDER" and int(settlement.get("relation", 0)) < 20 and position.distance_to(settlement.get("pos", Vector2.ZERO)) <= 300.0:
			_milestone14_change_relation(i, -8)

func _milestone14_remove_casualty(unit: Dictionary) -> void:
	var survivor_id: int = int(unit.get("survivor_id", -1))
	for i in range(survivors.size() - 1, -1, -1):
		if int(survivors[i].get("id", -2)) == survivor_id:
			var weapon: String = str(survivors[i].get("equipped_weapon", ""))
			if not weapon.is_empty(): weapons[weapon] = int(weapons.get(weapon, 0)) + 1
			survivors.remove_at(i)
			break
	for i in range(citizens.size() - 1, -1, -1):
		if int(citizens[i].get("id", -2)) == survivor_id: citizens.remove_at(i)
	for i in range(raid_squads.size() - 1, -1, -1):
		var squad: Dictionary = raid_squads[i]
		var members: Array = squad.get("members", [])
		members.erase(survivor_id)
		squad["members"] = members
		if members.is_empty(): raid_squads.remove_at(i)
		else: raid_squads[i] = squad
	role_allocations["SQUAD"] = raid_squads.size()
	message = "CASUALTY CONFIRMED — PERSONNEL RECORD CLOSED"
	message_timer = 2.0

func _milestone14_settlement_action(index: int, action: String) -> void:
	if index < 0 or index >= faction_settlements.size(): return
	var settlement: Dictionary = faction_settlements[index]
	var kind: String = str(settlement.get("faction", "NEUTRAL"))
	if action == "BARTER":
		var cost: int = 25 if faction_doctrine == "HUMANITARIAN SANCTUARY" else (35 if faction_doctrine == "MARTIAL LAW" else 30)
		if kind != "NEUTRAL":
			cost = 30
		elif faction_doctrine == "MARTIAL LAW":
			cost = 35
		if scrap >= cost:
			scrap -= cost
			var barter_yield: int = 54 if faction_doctrine == "HUMANITARIAN SANCTUARY" else 45
			food += barter_yield
			_milestone14_change_relation(index, 6)
			message = "BARTER COMPLETE — +45 FOOD / +6 STANDING"
		else: message = "BARTER NEEDS %d SCRAP" % cost
	elif action == "SEND AID":
		if food >= 25:
			food -= 25
			_milestone14_change_relation(index, 8 if kind == "NEUTRAL" else 4)
			message = "AID DELIVERED — RELATIONS IMPROVED"
		else: message = "AID REQUIRES 25 FOOD"
	elif action == "RAID":
		if kind == "RAIDER":
			settlement["strength"] = maxi(0, int(settlement.get("strength", 1)) - 1)
			if int(settlement["strength"]) == 0:
				_milestone14_change_relation(index, 8)
				for i in range(faction_settlements.size()):
					if i != index and str(faction_settlements[i].get("faction", "")) == "MILITARISTIC": _milestone14_change_relation(i, 12)
					elif i != index and str(faction_settlements[i].get("faction", "")) == "NEUTRAL": _milestone14_change_relation(i, 8)
				message = "RAIDER WARBAND DEFEATED"
			else:
				settlement["relation"] = clampi(int(settlement.get("relation", 0)) - 10, -100, 100)
				faction_settlements[index] = settlement
				message = "RAIDER STRONGHOLD DAMAGED"
		else:
			_milestone14_change_relation(index, -65)
			for i in range(faction_settlements.size()):
				if i != index and str(faction_settlements[i].get("faction", "")) == "NEUTRAL" and faction_settlements[i].get("pos", Vector2.ZERO).distance_to(settlement.get("pos", Vector2.ZERO)) <= 1800.0:
					_milestone14_change_relation(i, -15)
			message = "SETTLEMENT RAID — REGIONAL STANDING COLLAPSED"
	message_timer = 2.4
	_save_operation()

func _milestone14_handle_settlement_tap(screen_position: Vector2) -> bool:
	var world_position: Vector2 = _screen_to_world(screen_position)
	for i in range(faction_settlements.size() - 1, -1, -1):
		var settlement: Dictionary = faction_settlements[i]
		var banner := Rect2(settlement.get("pos", Vector2.ZERO) + Vector2(-142.0, -74.0), Vector2(284.0, 104.0))
		if banner.has_point(world_position):
			var offset: float = world_position.x - banner.position.x
			_milestone14_settlement_action(i, "BARTER" if offset < 94.0 else ("SEND AID" if offset < 190.0 else "RAID"))
			return true
	return false

func _milestone14_draw_faction_banners() -> void:
	for settlement in faction_settlements:
		var center: Vector2 = settlement.get("pos", Vector2.ZERO)
		if not _camera_view_rect().grow(240.0).has_point(center): continue
		var kind: String = str(settlement.get("faction", "NEUTRAL"))
		var standing: int = int(settlement.get("relation", 0))
		var panel := Rect2(center + Vector2(-142.0, -74.0), Vector2(284.0, 104.0))
		var accent: Color = Color("#6fc9a0") if kind == "NEUTRAL" else (Color("#78a9df") if kind == "MILITARISTIC" else Color("#db765e"))
		draw_rect(panel, Color("#091713", 0.96))
		draw_rect(panel, accent, false, 3.0)
		_draw_text(str(settlement.get("name", kind)), panel.position + Vector2(8.0, 18.0), 11, Color("#f3fff6"))
		_draw_text("%s  %s  %d" % [kind, _milestone14_relation_tier(standing), standing], panel.position + Vector2(8.0, 38.0), 9, accent)
		var labels: Array[String] = ["BARTER", "SEND AID", "RAID"]
		for j in range(3):
			var rect := Rect2(panel.position.x + 4.0 + float(j) * 94.0, panel.position.y + 48.0, 90.0, 42.0)
			draw_rect(rect, Color("#1c3c30") if j < 2 else Color("#4b2923"))
			draw_rect(rect, accent, false, 1.5)
			_draw_text(labels[j], rect.position + Vector2(5.0, 26.0), 9, Color("#ffffff"))


func _milestone17_resolve_formation_slot(candidate: Vector2) -> Vector2:
	var resolved: Vector2 = candidate
	resolved.x = clampf(resolved.x, 24.0, WORLD_SIZE.x - 24.0)
	resolved.y = clampf(resolved.y, 24.0, WORLD_SIZE.y - 24.0)
	if _milestone17_is_formation_slot_clear(resolved):
		return resolved
	var best_position: Vector2 = resolved
	var best_distance_squared: float = INF
	for ring in range(1, 9):
		var search_radius: float = float(ring) * 18.0
		for direction_index in range(16):
			var angle: float = TAU * float(direction_index) / 16.0
			var candidate_position: Vector2 = resolved + Vector2(cos(angle), sin(angle)) * search_radius
			candidate_position.x = clampf(candidate_position.x, 24.0, WORLD_SIZE.x - 24.0)
			candidate_position.y = clampf(candidate_position.y, 24.0, WORLD_SIZE.y - 24.0)
			if not _milestone17_is_formation_slot_clear(candidate_position):
				continue
			var distance_squared: float = resolved.distance_squared_to(candidate_position)
			if distance_squared < best_distance_squared:
				best_distance_squared = distance_squared
				best_position = candidate_position
		if best_distance_squared < INF:
			break
	return best_position

func _milestone17_is_formation_slot_clear(candidate: Vector2) -> bool:
	var clearance_rect: Rect2 = Rect2(candidate - Vector2(10.0, 10.0), Vector2(20.0, 20.0))
	for building_index in _building_indices_for_rect(clearance_rect):
		if building_index >= buildings.size() or building_index >= building_archetypes.size():
			continue
		if bool(building_archetypes[building_index].get("destroyed", false)):
			continue
		if buildings[building_index].grow(10.0).has_point(candidate):
			return false
	return true

func _milestone14_squad_ui_action(action: int) -> void:
	if action == 0:
		_milestone14_create_raid_squad()
		selected_raid_squad = maxi(0, raid_squads.size() - 1)
	elif selected_raid_squad < 0 or selected_raid_squad >= raid_squads.size():
		message = "SELECT A VALID SQUAD — CREATE FIRST"
	elif action == 1 or action == 2:
		var squad: Dictionary = raid_squads[selected_raid_squad]
		var members: Array = squad.get("members", [])
		var target: Vector2 = camera_position
		if action == 2:
			var outpost_index: int = _nearest_outpost_index(camera_position)
			if outpost_index >= 0:
				target = _nearest_outpost_gate_position(outpost_index, camera_position)
		var formation_forward: Vector2 = (target - camera_position).normalized()
		if formation_forward.length_squared() < 0.001:
			formation_forward = Vector2.DOWN
		var formation_right: Vector2 = formation_forward.orthogonal()
		for member_index in range(members.size()):
			var member_id: int = int(members[member_index])
			var formation_column: int = member_index % 4
			var formation_row: int = int(member_index / 4)
			var lateral_offset: float = (float(formation_column) - 1.5) * 34.0
			var depth_offset: float = (float(formation_row) - 0.5) * 42.0
			var member_target: Vector2 = target + formation_right * lateral_offset - formation_forward * depth_offset
			member_target.x = clampf(member_target.x, 24.0, WORLD_SIZE.x - 24.0)
			member_target.y = clampf(member_target.y, 24.0, WORLD_SIZE.y - 24.0)
			member_target = _milestone17_resolve_formation_slot(member_target)
			for unit_index in range(units.size()):
				var unit: Dictionary = units[unit_index]
				if int(unit.get("survivor_id", -1)) == member_id:
					unit["move_target"] = member_target
					unit["move_velocity"] = Vector2.ZERO
					unit["manual_order"] = true
					unit["ai_task"] = "SQUAD_DEPLOY" if action == 1 else "SQUAD_RECALL"
					units[unit_index] = unit
					break
		squad["status"] = "DEPLOYED" if action == 1 else "RECALLING"
		raid_squads[selected_raid_squad] = squad
		message = "SQUAD DEPLOYED" if action == 1 else "SQUAD RECALL ORDERED"
	elif action == 3:
		var squad: Dictionary = raid_squads[selected_raid_squad]
		for member_id in squad.get("members", []):
			for person_index in range(survivors.size()):
				var person: Dictionary = survivors[person_index]
				if int(person.get("id", -1)) == int(member_id):
					_milestone14_return_squad_equipment(person)
					person["role"] = "WORKER"
					person["assignment_category"] = ""
					survivors[person_index] = person
					break
		raid_squads.remove_at(selected_raid_squad)
		selected_raid_squad = clampi(selected_raid_squad, 0, maxi(0, raid_squads.size() - 1))
		role_allocations["SQUAD"] = raid_squads.size()
		message = "SQUAD DISBANDED — EQUIPMENT RETURNED"
	message_timer = 2.0
	_save_operation()
	queue_redraw()

func _milestone14_draw_specialists(panel_rect: Rect2) -> void:
	var categories: Array[String] = ["combat", "engineering", "medical", "gathering"]
	for i in range(categories.size()):
		var best: Dictionary = {}
		var best_xp: int = -1
		var xp_key: String = categories[i] + "_xp"
		for person in survivors:
			var xp: int = int(person.get(xp_key, 0))
			if xp > best_xp:
				best_xp = xp
				best = person
		if not best.is_empty():
			var multiplier: float = 1.0 + minf(0.75, float(best_xp) / 1000.0)
			var y: float = panel_rect.position.y + 132.0 + float(i) * 15.0
			_draw_text(categories[i].to_upper() + ": " + str(best.get("name", "UNKNOWN")) + " / " + str(best.get("expertise", "GENERALIST")) + " / " + str(best.get("role", "WORKER")) + " / %.2fx" % multiplier, Vector2(panel_rect.position.x + 8.0, y), 8, Color("#d7f4e4"))
