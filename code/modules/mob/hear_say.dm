// At minimum every mob has a hear_say proc.

/mob/proc/hear_say(var/message, var/verb = "says", var/datum/language/language = null, var/alt_name = "", var/italics = 0, var/mob/speaker = null, var/sound/speech_sound, var/sound_vol)
	if(!client)
		return 0

	if(isobserver(src) && client.prefs.toggles & CHAT_GHOSTEARS)
		if(speaker && !speaker.client && !(speaker in view(src)))
			//Does the speaker have a client?  It's either random stuff that observers won't care about (Experiment 97B says, 'EHEHEHEHEHEHEHE')
			//Or someone snoring.  So we make it where they won't hear it.
			return 0

	//make sure the air can transmit speech - hearer's side
	var/turf/T = get_turf(src)
	if(T && !isobserver(src))
		var/datum/gas_mixture/environment = T.return_air()
		var/pressure = environment ? environment.return_pressure() : 0
		if(pressure < SOUND_MINIMUM_PRESSURE && get_dist(speaker, src) > 1)
			return 0

		if(pressure < ONE_ATMOSPHERE * 0.4) //sound distortion pressure, to help clue people in that the air is thin, even if it isn't a vacuum yet
			italics = 1
			sound_vol *= 0.5

	if(sleeping || stat == UNCONSCIOUS)
		hear_sleep(message)
		return 0

	//non-verbal languages are garbled if you can't see the speaker. Yes, this includes if they are inside a closet.
	if(language && (language.flags & NONVERBAL))
		if(!has_vision()) //blind people can't see dumbass
			message = stars(message)

		if(!speaker || !(speaker in view(src)))
			message = stars(message)

	if(!say_understands(speaker, language))
		if(isanimal(speaker))
			var/mob/living/simple_animal/S = speaker
			if(S.speak.len)
				message = pick(S.speak)
			else
				message = stars(message)
		else
			if(language)
				message = language.scramble(message)
			else
				message = stars(message)

	var/speaker_name = speaker.name
	if(ishuman(speaker))
		var/mob/living/carbon/human/H = speaker
		speaker_name = H.GetVoice()

	if(italics)
		message = "<i>[message]</i>"

	var/track = null
	if(isobserver(src))
		if(italics && client.prefs.toggles & CHAT_GHOSTRADIO)
			return
		if(speaker_name != speaker.real_name && speaker.real_name)
			speaker_name = "[speaker.real_name] ([speaker_name])"
		track = "([ghost_follow_link(speaker, ghost=src)]) "
		if(client.prefs.toggles & CHAT_GHOSTEARS && speaker in view(src))
			message = "<b>[message]</b>"

	if(!can_hear())
		if(!language || !(language.flags & INNATE)) // INNATE is the flag for audible-emote-language, so we don't want to show an "x talks but you cannot hear them" message if it's set
			if(speaker == src)
				to_chat(src, "<span class='warning'>You cannot hear yourself speak!</span>")
			else
				to_chat(src, "<span class='name'>[speaker_name]</span>[alt_name] talks but you cannot hear them.")
	else
		if(language)
			to_chat(src, "<span class='game say'><span class='name'>[speaker_name]</span>[alt_name] [track][language.format_message(message, verb)]</span>")
		else
			to_chat(src, "<span class='game say'><span class='name'>[speaker_name]</span>[alt_name] [track][verb], <span class='message'><span class='body'>\"[message]\"</span></span></span>")
		if(speech_sound && (get_dist(speaker, src) <= world.view && src.z == speaker.z))
			var/turf/source = speaker? get_turf(speaker) : get_turf(src)
			src.playsound_local(source, speech_sound, sound_vol, 1)


/mob/proc/hear_radio(var/message, var/verb = "says", var/datum/language/language = null, var/part_a, var/part_b, var/mob/speaker = null, var/hard_to_hear = 0, var/vname = "", var/atom/follow_target)
	if(!client)
		return

	if(sleeping || stat == UNCONSCIOUS) //If unconscious or sleeping
		hear_sleep(message)
		return

	var/track = null
	if(!follow_target)
		follow_target = speaker

	//non-verbal languages are garbled if you can't see the speaker. Yes, this includes if they are inside a closet.
	if(language && (language.flags & NONVERBAL))
		if(!has_vision()) //blind people can't see dumbass
			message = stars(message)

		if(!speaker || !(speaker in view(src)))
			message = stars(message)

	if(!say_understands(speaker, language))
		if(isanimal(speaker))
			var/mob/living/simple_animal/S = speaker
			if(S.speak && S.speak.len)
				message = pick(S.speak)
			else
				return
		else
			if(language)
				message = language.scramble(message)
			else
				message = stars(message)

	if(hard_to_hear)
		message = stars(message)

	var/speaker_name = handle_speaker_name(speaker, vname, hard_to_hear)
	track = handle_track(message, verb, language, speaker, speaker_name, follow_target, hard_to_hear)

	var/formatted
	if(language)
		formatted = language.format_message_radio(message, verb)
	else
		formatted = "[verb], <span class=\"body\">\"[message]\"</span>"
	if(!can_hear())
		if(prob(20))
			to_chat(src, "<span class='warning'>You feel your headset vibrate but can hear nothing from it!</span>")
	else if(track)
		to_chat(src, "[part_a][track][part_b][formatted]</span></span>")
	else
		to_chat(src, "[part_a][speaker_name][part_b][formatted]</span></span>")

/mob/proc/handle_speaker_name(var/mob/speaker = null, var/vname, var/hard_to_hear)
	var/speaker_name = "unknown"
	if(speaker)
		speaker_name = speaker.name

	if(vname)
		speaker_name = vname

	if(hard_to_hear)
		speaker_name = "unknown"

	return speaker_name

/mob/proc/handle_track(var/message, var/verb = "says", var/datum/language/language, var/mob/speaker = null, var/speaker_name, var/atom/follow_target, var/hard_to_hear)
	return

/mob/proc/hear_signlang(var/message, var/verb = "gestures", var/datum/language/language, var/mob/speaker = null)
	if(!client)
		return

	if(say_understands(speaker, language))
		message = "<B>[src]</B> [verb], \"[message]\""
	else
		message = "<B>[src]</B> [verb]."

	if(src.status_flags & PASSEMOTES)
		for(var/obj/item/holder/H in src.contents)
			H.show_message(message)
		for(var/mob/living/M in src.contents)
			M.show_message(message)
	src.show_message(message)

/mob/proc/hear_sleep(var/message)
	var/heard = ""
	if(prob(15))
		message = strip_html_properly(message)
		var/list/punctuation = list(",", "!", ".", ";", "?")
		var/list/messages = splittext(message, " ")
		var/R = rand(1, messages.len)
		var/heardword = messages[R]
		if(copytext(heardword,1, 1) in punctuation)
			heardword = copytext(heardword,2)
		if(copytext(heardword,-1) in punctuation)
			heardword = copytext(heardword,1,length(heardword))
		heard = "<span class = 'game_say'>...You hear something about...[heardword]</span>"

	else
		heard = "<span class = 'game_say'>...<i>You almost hear someone talking</i>...</span>"

	to_chat(src, heard)
