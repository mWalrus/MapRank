// RELEVANT:
// - https://openplanet.dev/docs/reference/nadeoservices
// - https://openplanet.dev/docs/api/UI

[Setting name="Show window" description="Show or hide the window"]
bool show = true;

void RenderMenu() {
	if (UI::MenuItem("\\$96F" + Icons::ThList + "\\$z " + "Player Count", "", show)) {
		show = !show;
	}
}

void Render() {
	// draw window
}

void Main() {
	NadeoServices::AddAudience("NadeoLiveServices");
	while(!NadeoServices::IsAuthenticated("NadeoLiveServices")) yield();
	
	auto app = cast<CTrackMania>(GetApp());
	auto network = cast<CTrackManiaNetwork>(app.Network);

	string currentMapUid = "";

	while (true) {
		auto map = app.RootMap;

		if (show && map !is null && map.MapInfo.MapUid != currentMapUid && app.Editor is null) {
			auto map_uid = map.MapInfo.MapUid;
			print("Entered map: " + map_uid);

			int score;
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
			} else {
				// we dont handle online cases as of yet.
				// reference for the future:
				// https://github.com/Phlarx/tm-ultimate-medals/blob/147055b748332ddaa99cfbc2534e1ff835bdff29/UltimateMedals.as#L593-L599
				score = 0;
			}

			uint position = Api::GetPlayerPosition(map_uid, score);
			uint player_count = Api::GetPlayerCount(map_uid);
			
			print("Position: " + position + "/" + player_count);

			currentMapUid = map_uid;
		}
		sleep(500);
	}
}
