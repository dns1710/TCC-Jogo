extends Node

const SUPABASE_URL = "https://cfcqhvzzacdzpghglqkk.supabase.co/"
const API_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNmY3Fodnp6YWNkenBnaGdscWtrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODIzMzc2NjEsImV4cCI6MjA5NzkxMzY2MX0.3KuA5OVCJEqWY_s-tjHw_o67iNMzJdoZ91wCTbSf4x4"

func submit_score(player_name: String, score: int):
	var existing_player = await get_player_score(player_name)
	if existing_player == null:
		return await _insert_score(player_name, score)

	var old_score = existing_player["score"]
	if score > old_score:
		return await _update_score(player_name, score)
		
	return true

func _insert_score(player_name: String, score: int):
	var request := HTTPRequest.new()
	add_child(request)
	
	var url = SUPABASE_URL + "/rest/v1/scores"
	
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
	
	request.request(url, headers, HTTPClient.METHOD_POST, body)

	var result = await request.request_completed
	var response_code = result[1]

	request.queue_free()

	print("INSERT:", response_code)

	return response_code == 201

func _update_score(player_name: String, score: int):
	var request := HTTPRequest.new()
	add_child(request)
	
	var url = SUPABASE_URL + "/rest/v1/scores?player_name=eq.%s" % player_name.uri_encode()
	
	var headers = [
		"apikey: " + API_KEY,
		"Authorization: Bearer " + API_KEY,
		"Content-Type: application/json"
	]

	var body := JSON.stringify({
		"score": score
	})

	request.request(url, headers, HTTPClient.METHOD_PATCH, body)

	var result = await request.request_completed
	var response_code = result[1]

	request.queue_free()

	print("UPDATE:", response_code)

	return response_code == 204
	
func get_player_score(player_name: String):
	var request := HTTPRequest.new()
	add_child(request)

	var headers = [
		"apikey: " + API_KEY,
		"Authorization: Bearer " + API_KEY
	]
	var url = SUPABASE_URL + "/rest/v1/scores?player_name=eq.%s&select=*" % player_name.uri_encode()
	
	request.request(url, headers)
	
	var result = await request.request_completed
	if result[1] != 200:
		request.queue_free()
		return null

	var json = JSON.new()
	
	json.parse(result[3].get_string_from_utf8())
	
	request.queue_free()
	
	if json.data.size() == 0:
		return null

	return json.data[0]
	
func get_top_scores(limit := 50):
	var request := HTTPRequest.new()
	add_child(request)

	var headers = [
		"apikey: " + API_KEY,
		"Authorization: Bearer " + API_KEY
	]

	var url = SUPABASE_URL + "/rest/v1/scores?select=*&order=score.desc&limit=%d" % limit

	var error = request.request(url, headers)

	if error != OK:
		request.queue_free()
		return {
			"success": false,
			"http_code": -1,
			"data": []
		}

	var result = await request.request_completed
	print("HTTP RESULT:", result[0])
	print("HTTP CODE:", result[1])
	var http_result = result[0]
	var http_code = result[1]

	if http_result != HTTPRequest.RESULT_SUCCESS:
		request.queue_free()
		return {
			"success": false,
			"http_code": http_code,
			"data": []
		}

	if http_code != 200:
		request.queue_free()
		return {
			"success": false,
			"http_code": http_code,
			"data": []
		}

	var json_text = result[3].get_string_from_utf8()
	var json = JSON.new()
	if json.parse(json_text) != OK:
		request.queue_free()
		return {
			"success": false,
			"http_code": http_code,
			"data": []
		}

	request.queue_free()

	return {
		"success": true,
		"http_code": http_code,
		"data": json.data
	}
