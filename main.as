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
	// required steps using the unofficial undocumented trackmania.io API
	// 1. get relevant IDs by official means
	//    1.1 campaign ID
	//	  1.2 club ID
	// 2. make a request to https://trackmania.io/api/campaign/{CLUB_ID}/{CAMPAIGN_ID}
	// 3. take the leaderboarduid from the response
	// 4. format a request URL for getting player count
	// 	  - https://trackmania.io/api/leaderboard/{LEADERBOARDUID}/{MAP_UID}?offset=0&length=1
	// 5. profit
	
	NadeoServices::AddAudience("NadeoLiveServices");
	while(!NadeoServices::IsAuthenticated("NadeoLiveServices")) yield();
	
	auto app = cast<CTrackMania>(GetApp());

	string currentMapUid = "";

	while (true) {
		auto map = app.RootMap;

		if (show && map !is null && map.MapInfo.MapUid != currentMapUid && app.Editor is null) {
			print("Entered a new map! (" + map.MapInfo.MapUid + ")");
			currentMapUid = map.MapInfo.MapUid;
		}
		sleep(500);
	}
}