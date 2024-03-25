## The Supabase authentication end-point at /auth/v1.
extends "endpoint.gd"

## The Supabase authentication admin end-point at /auth/v1/admin.
class Admin extends "endpoint.gd":

	## Gets a list of all users.
	func get_users():
		return GET("/users")


	## Gets a user by their UUID in the database.
	func get_user(uid: StringName):
		return GET("/users/%s" % uid)


	## Deletes a user by their UUID in the database.
	func delete_user(uid: StringName):
		return DELETE("/users/%s" % uid)


	## Updates a user by their UUID in the database.
	func update_user(uid, data: Dictionary):
		return PUT("/users/%s" % uid, data)


## The type of user verification.
enum VerifyType { SIGNUP, RECOVERY, INVITE }

## The authentication admin end-point.
var admin : Admin

func _init(p_client, p_endpoint: String, p_identity):
	super(p_client, p_endpoint, p_identity)
	admin = Admin.new(p_client, p_endpoint + "/admin", p_identity)


func _login(p_type: String, p_data: Dictionary):
	return POST("/token?grant_type=%s" % p_type, p_data).then(func(result):
		if result.is_error():
			return result
		identity.set_access_token(result.access_token.as_string())
		return result
	)


## Gets the authentication settings from Supabase.
func get_settings():
	return GET("/settings")


## Signup for a new user account using e-mail and password.
func signup_email(p_email: String, p_password: String):
	return POST("/signup", {
		"email": p_email,
		"password": p_password
	}).then(func (result):
		if result.is_error() or not result.as_dict().has("access_token"):
			return result
		identity.set_access_token(result.access_token.as_string())
		return result
	)


## Login to a user account using e-mail and password.
func login_email(p_email: String, p_password: String):
	return _login("password", {
		"email": p_email,
		"password": p_password
	})


## Begin SSO authentication for the given SAML domain.
func begin_sso(domain):
	return POST("/sso", {
		"domain": domain,
		"skip_http_redirect": true,
	})


## Begin SSO authentication for the given SAML provider id.
func begin_sso_id(provider_id):
	return POST("/sso", {
		"provider_id": provider_id,
		"skip_http_redirect": true,
	})


## Complete SSO authentication using the given SAML response.
func login_sso(saml_response: Dictionary):
	return POST("/sso/saml/acs", client.query_from_dict(saml_response), {}, {
		"Content-Type": "application/x-www-form-urlencoded"
	}).then(func (result: PolyResult):
		if result.is_error():
			return result
		var loc : String = result.get_headers().get("location", "")
		if loc == "":
			return result
		var split := loc.split("#")
		if split.size() < 2:
			return result
		var query := split[1]
		var response = client.dict_from_query(query)
		identity.set_access_token(response.access_token)
		return PolyResult.new(response, result.get_http_result())
	)


## Logout from the current authenticated user.
func logout():
	return POST("/logout").then(func(result):
		identity.reset_access_token()
		return result
	)


## Start the password recover process for a user account registered with the given e-mail.
func recover(p_email: String):
	return POST("/recover", {
		"email": p_email
	})


## Send an invitation to sign-up for a new user account to the given e-mail address.
func send_invite(p_email: String):
	return POST("/invite", {
		"email": p_email
	})


## Verify a signup, password recovery or invite.
func verify(p_type : int, p_token : String):
	var type = ""
	if p_type == VerifyType.SIGNUP:
		type = "signup"
	elif p_type == VerifyType.RECOVERY:
		type = "recovery"
	elif p_type == VerifyType.INVITE:
		type = "invite"
	return POST("/verify", {
		"type": type,
		"token": p_token,
	})


## Gets the current user (if authenticated).
func get_user():
	return GET("/user")


## Updates the current user (if authenticated).
func update_user(p_data: Dictionary):
	return PUT("/user", p_data)
