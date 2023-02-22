namespace Api {
	const string MAP_MONITOR_URL = "https://trackmania.io/api/leaderboard/map/";

	uint GetPlayerCount(const string &in map_uid) {
		auto url = MAP_MONITOR_URL + map_uid + "?length=1&utm_source=playercount-plugin";
		auto req = Net::HttpRequest();

		// set up request
		req.Url = url;
		req.Headers['User-Agent'] = 'PlayerCount/Openplanet-Plugin/contact=@mWalrus';
		req.Method = Net::HttpMethod::Get;

		// init request
		req.Start();

		// wait for response
		while(!req.Finished()) yield();

		const Json::Value@ json = Json::Parse(req.String());
		uint player_count = json.Get('playercount', 0);
		return player_count;
	}

	uint GetPlayerPosition(const string &in map_uid, const uint &in score) {
		Net::HttpRequest@ req = NadeoServices::Get(
			"NadeoLiveServices",
			NadeoServices::BaseURL()
				+ "/api/token/leaderboard/group/Personal_Best/map/"
				+ map_uid
				+ "/surround/0/0?score"
				+ score
		);

		req.Start();
		while(!req.Finished()) yield();

		Json::Value json = Json::Parse(req.String());
		Json::Value pos = json['tops'][0]['top'][0];

		uint position = pos.Get('position', 0);

		return position;
	}	
}
