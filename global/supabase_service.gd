extends Node

const SUPABASE_URL = "https://cfcqhvzzacdzpghglqkk.supabase.co/"
const API_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNmY3Fodnp6YWNkenBnaGdscWtrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODIzMzc2NjEsImV4cCI6MjA5NzkxMzY2MX0.3KuA5OVCJEqWY_s-tjHw_o67iNMzJdoZ91wCTbSf4x4"

func submit_score(player_name: String, score: int):

	var request := HTTPRequest.new()
	add_child(request)

	var headers = [
		"apikey: " + API_KEY,
		"Authorization: Bearer " + API_KEY,
		"Content-Type: application/json",
        "Prefer: return=representation"
	]

	var body := JSON.stringify({
		"player_name": player_name,
		"score": score
	})

	var url = SUPABASE_URL + "/rest/v1/scores"

	request.request(
		url,
		headers,
		HTTPClient.METHOD_POST,
		body
	)

	var result = await request.request_completed
	var response_code = result[1]

	request.queue_free()

	print("Supabase:", response_code)

	return response_code == 201
