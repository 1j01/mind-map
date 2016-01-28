
doc_name = location.search or 'document'
fb = new Firebase('https://mind-map.firebaseio.com/')

disable_child_added = off

$last = null

$Node = (data, fb_n)->
	
	disable_child_added = on
	fb_n ?= fb_nodes.push(data)
	disable_child_added = off
	
	cleanup = ->
		if $last and $last isnt $n
			if $last and $last.isEmpty()
				$last.remove()
			$last = null
	
	position = ->
		$n.css
			left: data.x - ($n.outerWidth() / 2)
			top: data.y - ($n.outerHeight() / 2)
	
	if $last and $last.isEmpty()
		$last.remove()
	
	previous_content = ''
	
	$n = $last = $('<div contenteditable class="n"></div>')
		.appendTo('body')
		.css
			position: 'absolute'
			padding: '5px'
			outline: 'none'
			fontSize: '2em'
		.on 'keydown', (e)->
			cleanup()
			$last = $n
			if e.keyCode is 13 and !e.shiftKey
				e.preventDefault()
				$Node(
					x: data.x + Math.random() * 100 - 50
					y: data.y + 50
				).focus()
		.on 'keydown keyup keypress mousemove mouseup', ->
			position()
			setTimeout position
			content = $n.content()
			if previous_content isnt content
				disable_child_added = on
				fb_n.set
					x: data.x
					y: data.y
					_: content
				disable_child_added = off
			previous_content = content
		.on 'mousedown', (e)->
			cleanup()
			$last = $n
		.on 'focus', (e)->
			cleanup()
			$last = $n
	
	$n.fb = fb_n
	
	$n.content = (html)->
		if typeof html is 'string'
			previous_content = html
			unless $n.html() is html
				$n.html(html)
			position()
			$n
		else
			$n.html()
	
	$n.isEmpty = ->
		return no if $n.find('img, audio, video, iframe').length
		$n.text().match(/^\s*$/)?
	
	$n.remove = ->
		$n.css
			opacity: 0
			pointerEvents: 'none'
		fb_n.remove()
	
	$n.restore = ->
		$n.css
			opacity: 1
			pointerEvents: 'auto'
	
	position()
	
	fb_n.once 'value', (snapshot)->
		fb_n.set data unless snapshot.val()
	fb_n.on 'value', (snapshot)->
		value = snapshot.val()
		if value
			data = value
		else
			data._ = ""
		$n.content data._
		if data._
			$n.restore()
			position()
			fb_n.onDisconnect().cancel()
		else
			fb_n.onDisconnect().remove()
	
	$n

fb_doc = fb.child('documents').child(doc_name)
fb_nodes = fb_doc.child('nodes')

fb_nodes.on 'child_added', (snapshot)->
	unless disable_child_added
		$Node snapshot.val(), snapshot.ref()

fb_doc.once 'value', (snapshot)->
	unless $('.n:not(:empty)').length > 0
		$Node(
			x: innerWidth / 2
			y: innerHeight / 3
		).focus()

$(window).on 'mousedown', (e)->
	return if $(e.target).closest('.n').length
	$n = $Node
		x: e.pageX
		y: e.pageY
	$n.focus()
	setTimeout (e)->
		$n.focus()

unless location.hostname.match(/localhost|127\.0\.0\.1/) or location.protocol is 'file:'
	fb.child('stats/v2_views').transaction (val)-> (val or 0) + 1
	unless doc_name is 'document'
		fb.child('stats/v2_non_default_views').transaction (val)-> (val or 0) + 1
