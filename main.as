// Plugin option variables
bool Show = true;
bool ShowTimeLookup = true;
string ShowWindowSettingText = "Hide";
string ShowTimeLookupSettingText = "Hide";

string Purple = "\\$96F";
string Blue = "\\$06C";
string Red = "\\$f00";
string LightBlue = "\\$ADE";
string Gray = "\\$888";
string Green = "\\$0d0";
string ResetColor = "\\$z";

string GlobeIcon = Blue + Icons::Globe + ResetColor + " ";
string ListIcon = Purple + Icons::ThList + ResetColor + " ";
string ErrorIcon = Red + Icons::TimesCircle + ResetColor + " ";
string NextIcon = Green + Icons::Kenney::NextAlt + ResetColor + " ";

string InitMessage = Icons::PlayCircle + " Initializing!";
string Message = InitMessage;

int MapPlayerCount = 0;

string CurrentMapUid = "";
bool ShouldRefetchLeaderboard = false;
int PlayerScore = -1;

bool DisplayLookup = false;
bool PosButtonPressed = false;
string TimeInput = "";
string PosLookupResult = "";

void RenderMenu() {
	if (UI::BeginMenu(ListIcon + "Map Rank")) {
		if (UI::MenuItem(ShowWindowSettingText + " window")) {
			if (Show) {
				ShowWindowSettingText = "Show";
			} else {
				ShowWindowSettingText = "Hide";
			}
			Show = !Show;
		}

		if (UI::MenuItem(ShowTimeLookupSettingText + " time lookup")) {
			if (ShowTimeLookup) {
				ShowTimeLookupSettingText = "Show";
			} else {
				ShowTimeLookupSettingText = "Hide";
			}
			ShowTimeLookup = !ShowTimeLookup;
		}

		UI::EndMenu();
	}
}

void Render() {
	auto app = cast<CTrackMania>(GetApp());

	auto map = app.RootMap;

	if (
		!UI::IsGameUIVisible()
		|| !Show
		|| map is null
		|| map.MapInfo.MapUid == ""
		|| app.Editor !is null
	) return;

	int windowFlags = UI::WindowFlags::NoTitleBar | UI::WindowFlags::NoCollapse | UI::WindowFlags::AlwaysAutoResize | UI::WindowFlags::NoDocking;
	if (!UI::IsOverlayShown()) windowFlags |= UI::WindowFlags::NoInputs;

	UI::Begin("Map Rank", windowFlags);
	UI::Text(Message);
	if (ShowTimeLookup) {
		UI::Separator();
		DisplayLookup = UI::CollapsingHeader("Time lookup");
		if (DisplayLookup) {
			UI::Text(Gray + "Format: HH:MM:SS.mm");

			string input = UI::InputText("", TimeInput);
			if (TimeInput != input && input != "") {
				TimeInput = input;
			}

			bool pressed = UI::Button("Submit", vec2(70, 30));
			if (!PosButtonPressed && pressed) {
				PosButtonPressed = pressed;
			}
			if (PosLookupResult.Length > 0) {
				UI::Text(PosLookupResult);
			}
		}
	}

	UI::End();
}

void Main() {
	NadeoServices::AddAudience("NadeoLiveServices");
	while(!NadeoServices::IsAuthenticated("NadeoLiveServices")) yield();

	trace("Initialized!");
	
	auto app = cast<CTrackMania>(GetApp());
	auto network = cast<CTrackManiaNetwork>(app.Network);

	while (true) {
		auto map = app.RootMap;

		bool enteredNewMap = map !is null && map.MapInfo.MapUid != CurrentMapUid && app.Editor is null;

		if (map is null || enteredNewMap) {
			PlayerScore = -1;
			ShouldRefetchLeaderboard = false;
			Message = InitMessage;
			if (map !is null) {
				CurrentMapUid = map.MapInfo.MapUid;
				ShouldRefetchLeaderboard = true;
			}
		} else if (map !is null && !enteredNewMap) {
			int score = GetPlayerScore(network, map.MapInfo.MapUid);

			if (PosButtonPressed) {
				int parsed_time = ParseTimeInput();
				trace("Parsed time input: " + parsed_time);

				int position = Api::GetPositionFromTime(map.MapInfo.MapUid, parsed_time);

				int diff_ms = score - parsed_time;

				string formatted_diff = Time::Format(diff_ms);
				PosLookupResult = NextIcon + "Rank " + position + " ";
				if (MapPlayerCount > 0) {
					float percentage = CalcPositionPercentage(position, MapPlayerCount);
					PosLookupResult += "(Top " + percentage + "%) ";
				}
				if (diff_ms > 0) {
					PosLookupResult += LightBlue + "-" + formatted_diff;
				} else {
					PosLookupResult += Red + "+" + formatted_diff;
				}

				PosButtonPressed = false;
			}
	
			if (score > 0 && (PlayerScore == -1 || score < PlayerScore)) {
				trace("Got player score: " + score);
				PlayerScore = score;
				ShouldRefetchLeaderboard = true;
			}

			if (ShouldRefetchLeaderboard) {
				GetLeaderboardInfo(map, network);
			}
		}
		
		sleep(500);
	}
}

int ParseTimeInput() {
	if (TimeInput.Length == 0) {
		return 0;
	}

	auto ms_split = TimeInput.Split(".");
	auto hhmmss_split = ms_split[0].Split(":");

	string formatted = "";
	for (uint i = 0; i < hhmmss_split.Length; i++) {
		formatted += tostring(Text::ParseInt(hhmmss_split[i]));
	}

	if (ms_split.Length >= 2) {
		auto ms = FormatMS(ms_split[1]);
		formatted += ms;
	} else {
		formatted += "000";
	}

	// trim whitespaces
	formatted = formatted.Trim();

	// replace the time input with a correctly formatted one
	int formatted_int = Text::ParseInt(formatted);
	TimeInput = Time::Format(formatted_int);

	return Text::ParseInt(formatted);
}

void GetLeaderboardInfo(CGameCtnChallenge@ &in map, CTrackManiaNetwork@ &in network) {
	Message = Icons::CloudDownload + " Fetching leaderboard info...";

	auto map_uid = map.MapInfo.MapUid;

	int player_count = Api::GetPlayerCount(map_uid);
	trace("Fetched total player count: " + player_count);

	// no need to keep going for this iteration since we can't find a score
	if (PlayerScore < 0) {
		trace("No leaderboard position found!");
		Message = GlobeIcon + "Total: ~" + player_count + " players";
	} else {
		int position = Api::GetPlayerPosition(map_uid, PlayerScore);
		trace("Fetched player's leaderboard position: " + position);

		if (player_count == -1) {
			Message = ErrorIcon + "Something went wrong!";
		} else if (position == 1) {
			Message = GlobeIcon + "Rank " + position + "/~" + player_count + " (WR)";
		} else if (player_count == 0) {
			Message = GlobeIcon + "Total: No players yet";
		} else {
			auto percentage = CalcPositionPercentage(position, player_count);
			Message = GlobeIcon + "Rank " + position + "/~" + player_count + " (Top " + percentage + "%)";
		}
		MapPlayerCount = player_count;
	}

	ShouldRefetchLeaderboard = false;
}

int GetPlayerScore(CTrackManiaNetwork@ &in network, const string &in map_uid) {
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

	return scoreMgr.Map_GetRecord_v2(userId, map_uid, "PersonalBest", "", "TimeAttack", "");
}

string FormatMS(const string &in ms) {
	uint ms_num = Text::ParseUInt(ms);
	trace(ms_num);
	if (ms_num < 10) {
		ms_num = ms_num * 100;
	} else if (ms_num < 100) {
		ms_num = ms_num * 10;
	} else if (ms_num > 999) {
		ms_num = 000;
	}

	if (ms_num == 0) {
		return "000";
	} else {
		return tostring(ms_num);
	}
}

float CalcPositionPercentage(const int &in pos, const int &in player_count) {
	return float(int(((float(pos) / float(player_count)) * 100.0) * 100.0)) / 100.0;
}
