MapRank@ map_rank;

void RenderMenu() {
	map_rank.render_menu();
}

void Render() {
	map_rank.render();
}

void Main() {
	NadeoServices::AddAudience("NadeoLiveServices");
	while(!NadeoServices::IsAuthenticated("NadeoLiveServices")) yield();

	@map_rank = MapRank();
	trace("Initialized!");
	map_rank.enter_main_loop();
}
