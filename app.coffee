
doc_name = (location.search or 'document').replace("?", "")
db = getDatabase()
fb = ref(db)
fb_docs = child(fb, 'documents')
fb_doc = child(fb_docs, doc_name)
fb_nodes = child(fb_doc, 'nodes')

auth = getAuth()
provider = new GoogleAuthProvider()

onAuthStateChanged getAuth(), (user)->
	if user
		{ displayName, photoURL } = user
		for profile in user.providerData
			displayName ?= profile.displayName
			photoURL ?= profile.photoURL
		
		$('#sign-in').hide()
		$('#signed-in').show()
		$('#user-name').text displayName ? ""
		$('#user-image').attr(src: photoURL)
	else
		$('#signed-in').hide()
		$('#sign-in').show()

sign_in = (signed_in_callback)->
	signInWithPopup(getAuth(), provider)
		.then (auth_data)->
			signed_in_callback?()
			console?.log? "Authenticated successfully with payload:", auth_data
		.catch (err)->
			console?.log? "Sign in failed", err

sign_in_if_needed = (signed_in_callback)->
	if auth.currentUser?
		signed_in_callback()
	else
		sign_in(signed_in_callback)

$('#sign-in').on 'click', (e)->
	sign_in()

$('#sign-out').on 'click', (e)->
	auth.signOut()

$doc_title_input = $('#document-title-input')
fb_doc_title = child(fb_doc, 'title')

$doc_title_input.on 'input', (e)->
	set(fb_doc_title, $doc_title_input.val())

onValue fb_doc_title, (snapshot)->
	unless $doc_title_input.val() is snapshot.val()
		$doc_title_input.val(snapshot.val())
		$doc_title_input.parent().addClass('is-dirty') if $doc_title_input.val()

for formatting_option in ['bold', 'italic', 'underline', 'strikethrough']
	do (formatting_option)->
		$button =
			$("<button id='#{formatting_option}'><i class='icon-#{formatting_option}'></i><span>#{formatting_option}</span></button>")
				.appendTo '#formatting'
				.addClass 'mdl-button mdl-button--icon mdl-js-button mdl-js-ripple-effect'
				.on 'click', (e)->
					document.execCommand formatting_option
		
		componentHandler.upgradeElement($button.get(0))

byte_to_hex = (byte)-> "0#{byte.toString(16)}".slice(-2)

generate_id = (len=40)->
	# len must be an even number (default: 40)
	arr = new Uint8Array(len / 2)
	crypto.getRandomValues(arr)
	[].map.call(arr, byte_to_hex).join("")

create_new_document = (uid)->
	new_doc_id = generate_id()
	fb_new_doc = child(fb_docs, new_doc_id)
	# claimeth thine document!
	user = auth.currentUser
	set(child(fb_new_doc, 'owner_uid'), user.uid)
	.then ->
		# and go to it!
		location.search = new_doc_id
		# in the future, once the editor is a component, we can use the history API to switch documents
	.catch (err)->
		# TODO: visible notifications for these sorts of errors
		console.error "Failed to create new document", err

$('#new-document').on 'click', (e)->
	sign_in_if_needed(create_new_document)


$last = null
$nodes_by_key = {}

$Node = (data, fb_n)->
	
	data._ ?= ""
	fb_n ?= push(fb_nodes, data)
	
	return if $nodes_by_key[fb_n.key]
	
	cleanup = ->
		if $last and ($last isnt $node)
			if $last.isEmpty()
				$last.remove() # overridden to delete the node from firebase
			$last = null
	
	previous_content = ''
	
	$node = $('<div contenteditable class="node"></div>')
		.appendTo('#document-content')
		.css
			position: 'absolute'
			padding: '5px'
		.on 'keydown', (e)->
			if e.keyCode is 13 and not e.shiftKey
				e.preventDefault()
				$Node(
					x: data.x + Math.random() * 100 - 50
					y: data.y + 50
				).focus()
		.on 'input', ->
			$node.reposition()
			setTimeout $node.reposition
			content = $node.content()
			if previous_content isnt content
				set(fb_n, {
					x: data.x
					y: data.y
					_: content
				})
			previous_content = content
		.on 'mousedown', (e)->
			cleanup()
			$last = $node
		.on 'focus', (e)->
			cleanup()
			$last = $node
	
	$nodes_by_key[fb_n.key] = $node
	
	$node.reposition = ->
		$node.css
			left: data.x - ($node.outerWidth() / 2)
			top: data.y - ($node.outerHeight() / 2)
	
	$node.content = (html)->
		if typeof html is 'string'
			html = DOMPurify.sanitize(html)
			previous_content = html
			unless $node.html() is html
				$node.html(html)
			$node.reposition()
			$node
		else
			$node.html()
	
	$node.isEmpty = ->
		return no if $node.find('img, audio, video, iframe').length
		$node.text().match(/^\s*$/)?
	
	$node.remove = ->
		# $node.remove() would cause infinite recursion; deleting the node from firebase will cause it to be removed from the DOM
		# delete $nodes_by_key[fb_n.key] wouldn't let the firebase listener remove it from the DOM (I think?)
		remove(fb_n)
	
	$node.hide = ->
		$node.css
			opacity: 0
			pointerEvents: 'none'
	
	$node.show = ->
		$node.css
			opacity: ''
			pointerEvents: ''
	
	onValue fb_n, (snapshot)->
		value = snapshot.val()
		if value
			data = value
		else
			data._ = ""
		$node.content data._
		$node.reposition()
		if data._
			$node.show()
			onDisconnect(fb_n).cancel()
		else
			$node.hide() unless value?
			onDisconnect(fb_n).remove()
	
	$node

onChildAdded fb_nodes, (snapshot)->
	# setTimeout needed for deduplication logic
	setTimeout ->
		$Node snapshot.val(), snapshot.ref

onValue(fb_doc, (snapshot)->
	# setTimeout needed because of the above one
	setTimeout ->
		unless $('.node:not(:empty)').length
			$Node(
				x: innerWidth / 2
				y: innerHeight / 3
			).focus()
		# What about when two people open up a new document?
		# Should we focus an existing sole empty node?
, { onlyOnce: true })

$doc_content = $('#document-content')

drag_start_offset = x: 0, y: 0
end_drag_velocity = vx: 0, vy: 0
view_offset =
	x: 0, y: 0
	vx: 0, vy: 0
	animating: no
	start_animating: ->
		unless view_offset.animating
			view_offset.animate()
	animate: ->
		view_offset.x += view_offset.vx
		view_offset.y += view_offset.vy
		view_offset.vx *= 0.9
		view_offset.vy *= 0.9
		end_drag_velocity.vx *= 0.5
		end_drag_velocity.vy *= 0.5
		if (
			Math.abs(view_offset.vx) > 0.001 or
			Math.abs(view_offset.vy) > 0.001 or
			Math.abs(end_drag_velocity.vx) > 0.001 or
			Math.abs(end_drag_velocity.vy) > 0.001
		)
			requestAnimationFrame view_offset.animate
			view_offset.animating = yes
		else
			view_offset.animating = no
		$doc_content.css
			transform: "translate(#{view_offset.x.toFixed(3)}px, #{view_offset.y.toFixed(3)}px)"
			# transform: "translate3d(#{view_offset.x.toFixed(3)}px, #{view_offset.y.toFixed(3)}px, 0px)"
			# backfaceVisibility: "hidden"

mmb_panning = no
$('#document-background, #document-content').on 'mousedown', (e)->
	outside_any_node = $(e.target).closest('.node').length is 0
	if outside_any_node or e.button is 1 # MMB
		e.preventDefault()
		unless e.button is 1 # MMB
			$Node(
				x: e.pageX - view_offset.x
				y: e.pageY - view_offset.y
			).focus()
		view_offset.start_animating()
		drag_start_offset.x = view_offset.x - e.pageX
		drag_start_offset.y = view_offset.y - e.pageY
		end_drag_velocity.vx = 0
		end_drag_velocity.vy = 0
		$(window).on 'mousemove', mousemove = (e)->
			prev_view_offset_x = view_offset.x
			prev_view_offset_y = view_offset.y
			view_offset.x = e.pageX + drag_start_offset.x
			view_offset.y = e.pageY + drag_start_offset.y
			end_drag_velocity.vx *= 0.9
			end_drag_velocity.vy *= 0.9
			end_drag_velocity.vx += (view_offset.x - prev_view_offset_x) * 0.3
			end_drag_velocity.vy += (view_offset.y - prev_view_offset_y) * 0.3
			view_offset.start_animating()
			mmb_panning = yes if e.buttons & 4 # MMB (e.button is not applicable to mousemove)
		$(window).on 'mouseup', mouseup = (e)->
			$(window).off 'mousemove', mousemove
			$(window).off 'mouseup', mouseup
			setTimeout((-> mmb_panning = no), 1) # time for paste to happen on Linux
			unless e.button is 2 # RMB
				view_offset.vx = end_drag_velocity.vx
				view_offset.vy = end_drag_velocity.vy
				view_offset.start_animating()

$('#document-content').on 'paste', (e)->
	if mmb_panning
		e.preventDefault()

if location.hostname.match(/localhost|127\.0\.0\.1/) or location.protocol is 'file:'
	if localStorage.debug
		document.body.classList.add('debug')
else
	runTransaction(child(fb, 'stats/v3_views'), (val)-> (val or 0) + 1)
	unless doc_name is 'document'
		runTransaction(child(fb, 'stats/v3_non_default_views'), (val)-> (val or 0) + 1)
