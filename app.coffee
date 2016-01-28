
doc_name = location.search or 'document'
fb = new Firebase('https://mind-map.firebaseio.com/')

disable_child_added = off

$last = null

$Node = (data, fb_n)->
	
	disable_child_added = on
	fb_n ?= fb_nodes.push(data)
	disable_child_added = off
	
	cleanup = ->
		if $last and $last isnt $node
			if $last and $last.isEmpty()
				$last.remove()
			$last = null
	
	position = ->
		$node.css
			left: data.x - ($node.outerWidth() / 2)
			top: data.y - ($node.outerHeight() / 2)
	
	if $last and $last.isEmpty()
		$last.remove()
	
	previous_content = ''
	
	$node = $last = $('<div contenteditable class="node"></div>')
		.appendTo('body')
		.css
			position: 'absolute'
			padding: '5px'
			outline: 'none'
			fontSize: '2em'
		.on 'keydown', (e)->
			cleanup()
			$last = $node
			if e.keyCode is 13 and not e.shiftKey
				e.preventDefault()
				$Node(
					x: data.x + Math.random() * 100 - 50
					y: data.y + 50
				).focus()
		.on 'keydown keyup keypress mousemove mouseup', ->
			position()
			setTimeout position
			content = $node.content()
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
			$last = $node
		.on 'focus', (e)->
			cleanup()
			$last = $node
	
	$node.fb = fb_n
	
	$node.content = (html)->
		if typeof html is 'string'
			previous_content = html
			unless $node.html() is html
				$node.html(html)
			position()
			$node
		else
			$node.html()
	
	$node.isEmpty = ->
		return no if $node.find('img, audio, video, iframe').length
		$node.text().match(/^\s*$/)?
	
	$node.remove = ->
		$node.css
			opacity: 0
			pointerEvents: 'none'
		fb_n.remove()
	
	$node.restore = ->
		$node.css
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
		$node.content data._
		if data._
			$node.restore()
			position()
			fb_n.onDisconnect().cancel()
		else
			fb_n.onDisconnect().remove()
	
	$node

fb_doc = fb.child('documents').child(doc_name)
fb_nodes = fb_doc.child('nodes')

fb_nodes.on 'child_added', (snapshot)->
	unless disable_child_added
		$Node snapshot.val(), snapshot.ref()

fb_doc.once 'value', (snapshot)->
	unless $('.node:not(:empty)').length
		$Node(
			x: innerWidth / 2
			y: innerHeight / 3
		).focus()

$(window).on 'mousedown', (e)->
	unless $(e.target).closest('.node').length
		$node = $Node
			x: e.pageX
			y: e.pageY
		$node.focus()
		setTimeout (e)->
			$node.focus()

unless location.hostname.match(/localhost|127\.0\.0\.1/) or location.protocol is 'file:'
	fb.child('stats/v2_views').transaction (val)-> (val or 0) + 1
	unless doc_name is 'document'
		fb.child('stats/v2_non_default_views').transaction (val)-> (val or 0) + 1
