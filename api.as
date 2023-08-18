namespace Api {
	const string TRACKMANIA_IO_URL = "https://tm.waalrus.xyz/np/map/";

	uint GetPlayerCount(const string &in map_uid) {
		auto url = TRACKMANIA_IO_URL + map_uid;
		auto req = Net::HttpRequest();

		req.Url = url;
		req.Method = Net::HttpMethod::Get;

		req.Start();

		while(!req.Finished()) yield();

		if (req.ResponseCode() != 200) {
			return -1;
		}

		const Json::Value@ json = Json::Parse(req.String());
		uint player_count = json.Get('player_count', 0);
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
			trace("Failed to get leaderboards");
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
