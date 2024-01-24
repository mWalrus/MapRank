class MapRank {
	// plugin settings
	bool settings_show_plugin = true;
	bool settings_show_time_lookup = false;

	// UI related state
	bool ui_display_lookup = false;
	bool ui_pos_button_pressed = false;
	string ui_message = Helpers::init_message;

	// maprank state
	int map_player_count = 0;
	string current_map_uid = "";
	bool should_refetch_leaderboard = false;
	int current_player_score = -1;
	string time_input = "";
	string pos_lookup_result = "";
	// prevent map rank from updating unnecessarily
	bool is_idle = true;

	// trackmania state
	CTrackMania@ app = cast<CTrackMania>(GetApp());
	CTrackManiaNetwork@ network = cast<CTrackManiaNetwork>(app.Network);

	MapRank() {}

	void restore_default() {
		current_player_score = -1;
		should_refetch_leaderboard = false;
		ui_message = Helpers::init_message;
		time_input = "";
		pos_lookup_result = "";
		settings_show_time_lookup = false;
	}

	void render_menu() {
		if (UI::BeginMenu(Style::ListIcon + "Map Rank")) {
			string show_plugin_string =
				Helpers::option_to_human(settings_show_plugin) + " window";
			if (UI::MenuItem(show_plugin_string)) {
				settings_show_plugin = !settings_show_plugin;
			}

			string show_time_lookup_string =
				Helpers::option_to_human(settings_show_time_lookup) + " time lookup";
			if (UI::MenuItem(show_time_lookup_string)) {
				settings_show_time_lookup = !settings_show_time_lookup;
			}

			UI::EndMenu();
		}
	}

	void render() {
		// exit rendering early if the player is not in a map
		if (player_in_menu()) {
			return;
		}

		// handle window flags
		int window_flags = UI::WindowFlags::NoTitleBar | UI::WindowFlags::NoCollapse | UI::WindowFlags::AlwaysAutoResize | UI::WindowFlags::NoDocking;
		if (!UI::IsOverlayShown()) window_flags |= UI::WindowFlags::NoInputs;

		UI::Begin("Map Rank", window_flags);
		UI::Text(ui_message);

		if (!settings_show_time_lookup) {
			UI::End();
			return;
		}

		UI::Separator();
		ui_display_lookup = UI::CollapsingHeader("Time lookup");
		if (ui_display_lookup) {
			UI::Text(Style::Gray + "Format: HH:MM:SS.mmm");

			string input = UI::InputText("##TimeInput", time_input);
			if (time_input != input && input != "") {
				time_input = input;
			}

			bool pressed = UI::Button("Submit", vec2(70, 30));
			if (!ui_pos_button_pressed && pressed) {
				ui_pos_button_pressed = pressed;
			}
			if (pos_lookup_result.Length > 0) {
				UI::Text(pos_lookup_result);
			}
		}
		UI::End();
	}

	bool player_in_menu() {
		return !UI::IsGameUIVisible()
			|| !settings_show_plugin
			|| app.RootMap is null
			|| app.RootMap.MapInfo.MapUid == ""
			|| app.Editor !is null;
	}

	bool entered_new_map() {
		return app.RootMap !is null && app.RootMap.MapInfo.MapUid != current_map_uid && app.Editor is null;
	}

	void enter_main_loop() {
		while (true) {
			auto map = app.RootMap;

			if (entered_new_map()) {
				restore_default();
				current_map_uid = map.MapInfo.MapUid;
				should_refetch_leaderboard = true;
				is_idle = false;
				continue;
			} else if (map is null && !is_idle) {
				restore_default();
				is_idle = true;
			} else if (map !is null && !entered_new_map()) {
				int new_player_score = get_player_score();
				if (ui_pos_button_pressed) {
					fetch_position_lookup(map);
				}

				if (new_player_score > 0 && (current_player_score == -1 || new_player_score < current_player_score)) {
					trace("Got player score: " + new_player_score);
					current_player_score = new_player_score;
					should_refetch_leaderboard = true;
				}

				if (should_refetch_leaderboard) {
					fetch_leaderboard_info(map);
				}
			}
			sleep(500);
		}
	}

	void fetch_leaderboard_info(CGameCtnChallenge@ &in map) {
		ui_message = Helpers::refetch_message;

		int player_count = Api::get_player_count(current_map_uid);
		trace("Fetched total player count: " + player_count);

		if (player_count == -1) {
			trace("Failed to fetch total player count");
			ui_message = Helpers::error_message;
			should_refetch_leaderboard = false;
			return;
		}

		// no need to keep going since we can't find a score
		if (current_player_score < 0) {
			trace("No player score found!");
			ui_message = Helpers::total_message(player_count);
			should_refetch_leaderboard = false;
			return;
		}

		int position = Api::get_player_position(current_map_uid , current_player_score);
		trace("Fetched player's leaderboard position: " + position);

		if (position > player_count) {
			trace("Adjusted faulty total player count");
			player_count = position;
		}

		if (position == 1) {
			ui_message = Helpers::wr_message(player_count);
		} else if (player_count == 0) {
			ui_message = Helpers::no_players_message;
		} else {
			ui_message = Helpers::rank_message(position, player_count);
		}

		map_player_count = player_count;
		should_refetch_leaderboard = false;
	}

	void fetch_position_lookup(CGameCtnChallenge@ &in map) {
		int parsed_time = Helpers::parse_time_input(time_input);
		trace("Parsed time input: " + parsed_time);

		int position = Api::get_position_from_time(map.MapInfo.MapUid, parsed_time);

		int diff_ms = Math::Abs(current_player_score - parsed_time);

		string formatted_diff = Time::Format(diff_ms);
		pos_lookup_result = Style::NextIcon + "Rank " + position + " ";
		if (map_player_count > 0) {
			float percentage = Helpers::calc_position_percentage(position, map_player_count);
			pos_lookup_result += "(Top " + percentage + "%) ";
		}
		if (parsed_time < current_player_score) {
			pos_lookup_result += Style::LightBlue + "-" + formatted_diff;
		} else {
			pos_lookup_result += Style::LightRed + "+" + formatted_diff;
		}

		ui_pos_button_pressed = false;
	}

	int get_player_score() {
		// we dont handle online cases as of yet.
		// reference for the future:
		// https://github.com/Phlarx/tm-ultimate-medals/blob/147055b748332ddaa99cfbc2534e1ff835bdff29/UltimateMedals.as#L593-L599
		if (network.ClientManiaAppPlayground is null) return -1;
		if (network.ClientManiaAppPlayground.UserMgr is null) return -1;
		if (network.ClientManiaAppPlayground.ScoreMgr is null) return -1;

		auto userMgr = network.ClientManiaAppPlayground.UserMgr;

		MwId userId;
		if (userMgr.Users.Length > 0) {
			userId = userMgr.Users[0].Id;
		} else {
			userId.Value = uint(-1);
		}

		auto scoreMgr = network.ClientManiaAppPlayground.ScoreMgr;

		return scoreMgr.Map_GetRecord_v2(userId, current_map_uid, "PersonalBest", "", "TimeAttack", "");
	}
}
