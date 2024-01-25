namespace Helpers {
	const string init_message = Icons::PlayCircle + " Initializing!";
	const string refetch_message = Icons::CloudDownload + " Fetching leaderboard info...";
	const string error_message = Style::ErrorIcon + "Something went wrong!";
	const string no_players_message = Style::GlobeIcon + "Total: No players yet";
	string total_message(const int &in player_count) {
		return Style::GlobeIcon + "Total: ~" + player_count + " players";
	}
	string wr_message(const int &in player_count) {
		return Style::GlobeIcon + "Rank 1/~" + player_count + " (WR)";
	}
	string rank_message(const int &in pos, const int &in player_count) {
		auto percentage = calc_position_percentage(pos, player_count);
		return Style::GlobeIcon + "Rank " + pos + "/~" + player_count + " (Top " + percentage + "%)";
	}

	string option_to_human(const bool &in toggle) {
		if (toggle) {
			return "Hide";
		} else {
			return "Show";
		}
	}

	float calc_position_percentage(const int &in pos, const int &in player_count) {
		return float(int(((float(pos) / float(player_count)) * 100.0) * 100.0)) / 100.0;
	}

	int parse_time_input(const string &in time_input) {
		if (time_input.Length == 0) {
			return 0;
		}

		auto ms_split = time_input.Split(".");

		string time = time_input;

		// This is so that partial millisecond inputs arent parsed incorrectly.
		// Otherwise "40.6" would become "40006" when parsed, instead of "40600" which is correct.
		if (ms_split.Length > 1) {
			auto ms = Text::ParseInt(ms_split[1]);

			if (ms < 10) {
				ms *= 100;
			}
			else if (ms > 10 && ms < 100) {
				ms *= 10;
			}

			time = ms_split[0] + "." + ms;
		}

		return Time::ParseRelativeTime(time);
	}

}
