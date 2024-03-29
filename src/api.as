namespace Api {
	const string TM_API_URL = "https://tm.waalrus.xyz";

	int get_player_count(const string &in map_uid) {
		auto url = TM_API_URL + "/np/map/" + map_uid;
		auto req = Net::HttpRequest();

		req.Url = url;
		req.Method = Net::HttpMethod::Get;

		req.Start();

		while(!req.Finished()) yield();

		if (req.ResponseCode() != 200) {
			return -1;
		}

		const Json::Value@ json = Json::Parse(req.String());

		if (json["player_count"].GetType() == Json::Type::Null) {
			return -1;
		}

		return json.Get("player_count", 0);
	}

	int get_player_position(const string &in map_uid, int &in score) {
		string url = NadeoServices::BaseURLLive()
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

	int get_position_from_time(const string &in map_uid, int &in score) {
		auto url = TM_API_URL + "/pos/" + map_uid + "/" + score;
		auto req = Net::HttpRequest();

		req.Url = url;
		req.Method = Net::HttpMethod::Get;

		req.Start();

		while(!req.Finished()) yield();

		if (req.ResponseCode() != 200) {
			return -1;
		}

		const Json::Value@ json = Json::Parse(req.String());
		uint pos = json.Get('position', 0);
		return pos;
	}
}
