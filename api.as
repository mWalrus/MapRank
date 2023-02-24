namespace Api {
	const string MAP_MONITOR_URL = "https://trackmania.io/api/leaderboard/map/";

	uint GetPlayerCount(const string &in map_uid) {
		auto url = MAP_MONITOR_URL + map_uid + "?length=1&utm_source=maprank-plugin";
		auto req = Net::HttpRequest();

		req.Url = url;
		req.Headers['User-Agent'] = 'MapRank/Openplanet-Plugin/contact=@mWalrus';
		req.Method = Net::HttpMethod::Get;

		req.Start();

		while(!req.Finished()) yield();

		const Json::Value@ json = Json::Parse(req.String());
		uint player_count = json.Get('playercount', 0);
		return player_count;
	}

	int GetPlayerPosition(const string &in map_uid, const uint &in score) {
		string url = NadeoServices::BaseURL()
				+ "/api/token/leaderboard/group/Personal_Best/map/"
				+ map_uid
				+ "/surround/0/0?score="
				+ score;
		Net::HttpRequest@ req = NadeoServices::Get("NadeoLiveServices", url);

		req.Start();

		while(!req.Finished()) yield();

		Json::Value json = Json::Parse(req.String());

		Json::Value tops = json['tops'];

		if (Json::Type::Array != tops.GetType()) {
			trace("Failed to get world tops");
			return -1;
		}

		Json::Value world_top = tops[0]['top'];

		if (Json::Type::Array != world_top.GetType()) {
			trace("Failed to get player's world position");
			return -1;
		}

		int position = world_top[0].Get('position', -1);

		return position;
	}	
}
