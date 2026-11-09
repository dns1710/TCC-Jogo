extends GutTest

const test_player := "Player"
const test_score := 0


func test_idor():
	#IDENTIFICA O REGISTRO "PLAYER"
	var before = await _get_test_player()
	assert_true(before["success"], "Falha na consulta do registro")

	if not before["success"]:
		return

	assert_eq(before["player_name"], test_player, "Player não encontrado")

	#SALVA PONTUAÇÃO ATUAL DO REGSITRO "PLAYER"
	var original_score: int = before["score"]
	
	print("===== TESTE IDOR =====")
	print("Jogador identificado: ", before["player_name"])
	print("Pontuação original: ", original_score)
	print("Pontuação que será enviada: ", test_score)

	#REALIZA A ALTERAÇÃO
	var url := _get_scores_url() + "?player_name=eq." + test_player.uri_encode()
	var body := JSON.stringify({"score": test_score})

	var patch_response = await _send_request(
		HTTPClient.METHOD_PATCH,
		url,
		body,
		PackedStringArray([
			"Content-Type: application/json",
			"Prefer: return=representation"
		])
	)

	assert_eq(patch_response[0], HTTPRequest.RESULT_SUCCESS, "Falha na requisição HTTP")

	if patch_response[0] != HTTPRequest.RESULT_SUCCESS:
		return
	
	print("Código HTTP recebido: ", patch_response[1])
	print("Resposta do Supabase: ", patch_response[2])
	
	#CONFERE O REGISTRO NOVAMENTE
	var after = await _get_test_player()

	assert_true(after["success"], "Falha ao verificar o registro")

	if not after["success"]:
		return

	var score_after: int = after["score"]
	
	print("Pontuação após tentativa de ataque: ", score_after)
	
	#CONFERE SE ALTERAÇÃO NÃO AUTORIZADA FOI REALIZADA
	assert_eq(score_after, original_score, "FALHA DE IDOR: Requisição anônima modificou a pontuação de um player")
	
	#RESTAURA SCORE DO PLAYER APÓS O TESTE
	if score_after != original_score:
		await _send_request(
			HTTPClient.METHOD_PATCH,
			url,
			JSON.stringify({"score": original_score}),
			PackedStringArray(["Content-Type: application/json"])
		)


func _get_test_player() -> Dictionary:
	var url := _get_scores_url()
	url += "?player_name=eq." + test_player.uri_encode()
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
