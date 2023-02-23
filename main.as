[Setting name="Show window" description="Show or hide the window"]
bool Show = true;

string Purple = "\\$96F";
string Blue = "\\$06C";
string ResetColor = "\\$z";

string GlobeIcon = Blue + Icons::Globe + ResetColor + " ";
string ListIcon = Purple + Icons::ThList + ResetColor + " ";

string InitMessage = Icons::PlayCircle + " Initializing!";
string Message = InitMessage;

string CurrentMapUid = "";
bool ShouldRefetchLeaderboard = false;
int PlayerScore = -1;

void RenderMenu() {
	if (UI::MenuItem(ListIcon + "Map Rank", "", Show)) {
		Show = !Show;
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

		if (map is null) {
			// set everything back to default
			Message = InitMessage;
			PlayerScore = -1;
			ShouldRefetchLeaderboard = false;
		} else {
			int score = GetPlayerScore(network, map.MapInfo.MapUid);
			if ((score > 0 && score < PlayerScore) || (PlayerScore == -1 && score > 0)) {
				UpdatePlayerScore(score);
			}
		}

		if (Show && map !is null && map.MapInfo.MapUid != CurrentMapUid && app.Editor is null) {
			trace("Entered map: " + map_uid);
			GetLeaderboardInfo(map, network);
		} else if (ShouldRefetchLeaderboard) {
			GetLeaderboardInfo(map, network);
		}
		sleep(500);
	}
}

void GetLeaderboardInfo(CGameCtnChallenge@ &in map, CTrackManiaNetwork@ &in network) {
	Message = Icons::CloudDownload + " Fetching leaderboard info...";

	auto map_uid = map.MapInfo.MapUid;

	uint player_count = Api::GetPlayerCount(map_uid);
	trace("Fetched total player count: " + player_count);

	// no need to keep going for this iteration since we can't find a score
	if (PlayerScore < 0) {
		trace("No leaderboard position found!");
		Message = GlobeIcon + "Total: ~" + player_count + " players";
	} else {
		int position = Api::GetPlayerPosition(map_uid, PlayerScore);
		trace("Fetched player's leaderboard position: " + position);

		auto percentage = CalcPositionPercentage(position, player_count);

		Message = GlobeIcon + "Rank " + position + "/~" + player_count + " (Top " + percentage + "%)";
	}

	CurrentMapUid = map_uid;
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

void UpdatePlayerScore(const int &in score) {
	ShouldRefetchLeaderboard = true;
	PlayerScore = score;
}

float CalcPositionPercentage(const int &in pos, const uint &in total) {
	return float(int(((float(pos) / float(total)) * 100.0) * 100.0)) / 100.0;
}
