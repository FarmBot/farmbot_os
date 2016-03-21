Ongoing list of MeshBlu coupling points:

 * `meshblu_url` in config.
 * MeshRuby in gemfile
 * `mesh` object in `FBPi::TelemetryMessage.publish`
 * `FarmBotPi#mesh`
 * References to `mesh` in `FarmBotPi` esp. constructor.
 * References to `mesh` in `bot_decorator`.

# Changes Required

 * Get rid of token/UUID.
 * Replace it with "bot name".
 * Need to add bot device to JWT token to determine user's permissions.
   * Right now, I'm just posting to `bot/user_email`. Not good.
 * See if we can have a response AND notification channel (emit vs. reply)
