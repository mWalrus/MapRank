MapRank@ map_rank = MapRank();

void RenderMenu() {
	if (map_rank is null) return;
	map_rank.render_menu();
}

void Render() {
	if (map_rank is null) return;
	map_rank.render();
}

void Main() {
	while (map_rank is null) {
		yield();
	}

	NadeoServices::AddAudience("NadeoLiveServices");
	while(!NadeoServices::IsAuthenticated("NadeoLiveServices")) yield();

	trace("Initialized!");
	map_rank.enter_main_loop();
}
