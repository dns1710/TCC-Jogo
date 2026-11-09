extends GutTest

const player := "Player"
const injection := "'; UPDATE scores SET score = 0 WHERE player_name = 'Player'; --"
const injection_score := 0


func test_sql_injection():
	#CONSULTA REGISTRO "PLAYER"
	var before = await _get_player(player)

	assert_true(before["success"], "Falha ao consultar registro")

	if not before["success"]:
		return

	var original_score: int = before["score"]

	#ENVIA POST COM OS DADOS DA INJECTION
	var body := JSON.stringify({
		"player_name": injection,
		"score": injection_score
	})

	var insert_response = await _send_request(
		HTTPClient.METHOD_POST,
		_get_scores_url(),
		body,
		PackedStringArray([
			"Content-Type: application/json",
			"Prefer: return=representation"
		])
	)

	assert_eq(insert_response[0], HTTPRequest.RESULT_SUCCESS, "Falha na comunicação com o Supabase")

	if insert_response[0] != HTTPRequest.RESULT_SUCCESS:
		return
	
	print("===== TESTE SQL INJECTION =====")
	print("Status da ijection: ", insert_response[1])
	print("Resposta: ", insert_response[2])

	assert_true(insert_response[1] == 201 or insert_response[1] == 200, "Falha no registro")

	if insert_response[1] != 201 and insert_response[1] != 200:
		return

	#CONSULTA REGISTRO PLAYER NOVAMENTE
	var after = await _get_player(player)

	assert_true(after["success"], "Falha ao consultar registro Player")

	if not after["success"]:
		return

	var score_after: int = after["score"]

	#VERIFICA PONTUAÇÃO DO PLAYER
	assert_eq(score_after, original_score, "FALHA DE SQL INJECTION: Score do Player alterado por injeção")

	print("Pontuação original: ", original_score)
	print("Pontuação após o teste: ", score_after)


func _get_player(player_name: String) -> Dictionary:
	var url := _get_scores_url()
	url += "?player_name=eq." + player_name.uri_encode()
	url += "&select=player_name,score"

	var response = await _send_request(HTTPClient.METHOD_GET, url)

	if response[0] != HTTPRequest.RESULT_SUCCESS or response[1] != 200:
		return {"success": false}

	var data = JSON.parse_string(response[2])

	if not data is Array or data.size() != 1:
		return {"success": false}

	return {
		"success": true,
		"player_name": data[0]["player_name"],
		"score": int(data[0]["score"])
	}


func _get_scores_url() -> String:
	return SupabaseService.SUPABASE_URL.trim_suffix("/") + "/rest/v1/scores"


func _send_request(method: int, url: String, body: String = "", extra_headers: PackedStringArray = PackedStringArray()) -> Array:
	var request := HTTPRequest.new()
	add_child(request)

	var headers := PackedStringArray([
		"apikey: " + SupabaseService.API_KEY,
		"Authorization: Bearer " + SupabaseService.API_KEY
	])

	headers.append_array(extra_headers)

	var error = request.request(url, headers, method, body)

	if error != OK:
		request.queue_free()
		return [error, -1, ""]

	var result = await request.request_completed
	var response_body = result[3].get_string_from_utf8()

	request.queue_free()

	return [result[0], result[1], response_body]
