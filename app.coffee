
doc_name = location.search or 'document'
fb = new Firebase('https://mind-map.firebaseio.com/')

$last = null
$nodes_by_key = {}

$Node = (data, fb_n)->
	
	fb_n ?= fb_nodes.push(data)
	
	return if $nodes_by_key[fb_n.key()]
	
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
		.appendTo('#document-content')
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
		# there probably shouldn't be "mousemove" here and should probably be some other input events
		.on 'keydown keyup keypress mousemove mouseup', ->
			position()
			setTimeout position
			content = $node.content()
			if previous_content isnt content
				fb_n.set
					x: data.x
					y: data.y
					_: content
			previous_content = content
		.on 'mousedown', (e)->
			cleanup()
			$last = $node
		.on 'focus', (e)->
			cleanup()
			$last = $node
	
	$nodes_by_key[fb_n.key()] = $node
	
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
		fb_n.remove()
	
	$node.hide = ->
		$node.css
			opacity: 0
			pointerEvents: 'none'
	
	$node.show = ->
		$node.css
			opacity: 1
			pointerEvents: 'auto'
	
	fb_n.on 'value', (snapshot)->
		value = snapshot.val()
		if value
			data = value
		else
			data._ = ""
		$node.content data._
		position()
		if data._
			$node.show()
			fb_n.onDisconnect().cancel()
		else
			$node.hide() unless value?
			fb_n.onDisconnect().remove()
	
	$node

fb_doc = fb.child('documents').child(doc_name)
fb_nodes = fb_doc.child('nodes')

fb_nodes.on 'child_added', (snapshot)->
	setTimeout ->
		$Node snapshot.val(), snapshot.ref()

fb_doc.once 'value', (snapshot)->
	unless $('.node:not(:empty)').length
		$Node(
			x: innerWidth / 2
			y: innerHeight / 3
		).focus()

$('#document-content').on 'mousedown', (e)->
	unless $(e.target).closest('.node').length
		e.preventDefault()
		$Node(
			x: e.pageX
			y: e.pageY
		).focus()

if location.hostname.match(/localhost|127\.0\.0\.1/) or location.protocol is 'file:'
	if localStorage.debug
		document.body.classList.add('debug')
else
	fb.child('stats/v2_views').transaction (val)-> (val or 0) + 1
	unless doc_name is 'document'
		fb.child('stats/v2_non_default_views').transaction (val)-> (val or 0) + 1
