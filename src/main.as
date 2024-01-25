MapRank@ map_rank = MapRank();

void RenderMenu() {
	map_rank.render_menu();
}

void Render() {
	map_rank.render();
}

void Main() {
	NadeoServices::AddAudience("NadeoLiveServices");
	while(!NadeoServices::IsAuthenticated("NadeoLiveServices")) yield();

	trace("Initialized!");
	map_rank.enter_main_loop();
}
