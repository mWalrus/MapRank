[Setting name="Show window" description="Show or hide the window"]
bool show = true;

string Purple = "\\$96F";
string Blue = "\\$06C";
string ResetColor = "\\$z";

string GlobeIcon = Blue + Icons::Globe + ResetColor + " ";
string ListIcon = Purple + Icons::ThList + ResetColor + " ";

string InitMessage = Icons::PlayCircle + " Initializing!";
string Message = InitMessage;

void RenderMenu() {
	if (UI::MenuItem(ListIcon + "Player Count", "", show)) {
		show = !show;
	}
}

void Render() {
	// draw window
	auto app = cast<CTrackMania>(GetApp());

	auto map = app.RootMap;

	if (
		!UI::IsGameUIVisible()
		|| !show
		|| map is null
		|| map.MapInfo.MapUid == ""
		|| app.Editor !is null
	) return;

	int windowFlags = UI::WindowFlags::NoTitleBar | UI::WindowFlags::NoCollapse | UI::WindowFlags::AlwaysAutoResize | UI::WindowFlags::NoDocking;
	if (!UI::IsOverlayShown()) windowFlags |= UI::WindowFlags::NoInputs;

	UI::Begin("Player Count", windowFlags);
	UI::Text(Message);
	UI::End();
}

void Main() {
	NadeoServices::AddAudience("NadeoLiveServices");
	while(!NadeoServices::IsAuthenticated("NadeoLiveServices")) yield();

	trace("Initialized!");
	
	auto app = cast<CTrackMania>(GetApp());
	auto network = cast<CTrackManiaNetwork>(app.Network);

	string currentMapUid = "";

	while (true) {
		auto map = app.RootMap;

		if (map is null) Message = InitMessage;

		if (show && map !is null && map.MapInfo.MapUid != currentMapUid && app.Editor is null) {
			auto map_uid = map.MapInfo.MapUid;
			trace("Entered map: " + map_uid);

			// we dont handle online cases as of yet.
			// reference for the future:
			// https://github.com/Phlarx/tm-ultimate-medals/blob/147055b748332ddaa99cfbc2534e1ff835bdff29/UltimateMedals.as#L593-L599
			int score = -1;
			if (network.ClientManiaAppPlayground !is null) {
				auto userMgr = network.ClientManiaAppPlayground.UserMgr;
				MwId userId;
				if (userMgr.Users.Length > 0) {
					userId = userMgr.Users[0].Id;
				} else {
					userId.Value = uint(-1);
				}

				auto scoreMgr = network.ClientManiaAppPlayground.ScoreMgr;

				score = scoreMgr.Map_GetRecord_v2(userId, map_uid, "PersonalBest", "", "TimeAttack", "");
				trace("Fetched player's map score: " + score);

				Message = Icons::CloudDownload + " Fetching leaderboard info...";
			}

			uint player_count = Api::GetPlayerCount(map_uid);
			trace("Fetched total player count: " + player_count);

			// no need to keep going for this iteration since we can't find a score
			if (score < 0) {
				trace("No leaderboard position found!");
				Message = GlobeIcon + "Total: ~" + player_count + " players";
				continue;
			}

			int position = Api::GetPlayerPosition(map_uid, score);
			trace("Fetched player's position: " + position);

			auto percentage = CalcPositionPercentage(position, player_count);

			Message = GlobeIcon + "Rank " + position + "/~" + player_count + " (Top " + percentage + "%)";

			currentMapUid = map_uid;
		}
		sleep(500);
	}
}

float CalcPositionPercentage(const int &in pos, const uint &in total) {
	return float(int(((float(pos) / float(total)) * 100.0) * 100.0)) / 100.0;
}
