$(function(){
	
	var top_level_nodes = [];
	
	var doc_name = location.search || "document";
	
	var fb = new Firebase("https://mind-map.firebaseio.com/");
	fb.child("stats/v").transaction(function(val){
		return (val||0) + 1;
	});
	var fb_doc = fb.child("documents").child(doc_name);
	var fb_nodes = fb_doc.child("nodes");
	/*fb_doc.once("value", function(snapshot){
		var doc = snapshot.val();
		function load_node(node, i){
			$Node(node, fb_nodes.child(i)).content(node._);
			//if(node.c){
			//	$.each(node.c, load_node);
			//}
		}
		if(doc && doc.nodes){
			$.map(doc.nodes, load_node);
		}
		if($(".n").length === 0){
			$Node({
				x: innerWidth / 2,
				y: innerHeight / 3,
			}).focus();
		}
	});*/
	fb_nodes.on('child_added', function(snapshot){
		var already_got_that_one = false;
		$.each(top_level_nodes, function(i, node){
			if(node.fb.name() === snapshot.ref().name()){
				already_got_that_one = true;
			}
		});
		if(!already_got_that_one){
			$Node(snapshot.val(), snapshot.ref());
		}
	});
	
	
	//load();
	
	function load(){
		function load_node(node){
			$Node(node).content(node._);
			if(node.c){
				$.each(node.c, load_node);
			}
		}
		load_doc(doc_name, function(doc){
			if(doc){
				$.map(doc.nodes, load_node);
			}
			if($(".n").length === 0){
				$Node({
					x: innerWidth / 2,
					y: innerHeight / 3,
				}).focus();
			}
		});
	}
	function save(){
		function serialize($node){
			if($node.isEmpty()){
				return;
			}
			var node = {
				x: $node.x,
				y: $node.y,
				_: $node.content()
			};
			if($node.$children){
				node.c = $.map($node.$children, serialize);
			}
			return node;
		}
		//serialize the document
		documents[doc_name] = 
		documents[doc_name] || {};
		documents[doc_name].nodes = $.map(top_level_nodes, serialize);
		//save
		save_doc(doc_name);
	}
	
	$(window).on("mousedown", function(e){
		var $n = $Node({
			x: e.pageX,
			y: e.pageY,
		}).focus();
		
		setTimeout(function(e){
			$n.focus();
		});
	});
	
	var $last;
	function $Node(o, fb_n){
		fb_n = fb_n || fb_nodes.push(o);
		
		if($last && $last.isEmpty()){
			var idx = top_level_nodes.indexOf($last);
			top_level_nodes.splice(idx, 1);
			$last.remove();
		}
		function cleanup(){
			if($n.isEmpty()){
				if($last && $last !== $n){
					if($last && $last.isEmpty()){
						var idx = top_level_nodes.indexOf($last);
						top_level_nodes.splice(idx, 1);
						$last.remove();
					}
					$last = null;
				}
			}
		}
		
		var previous_content = "";
		var $n = $last = $("<div contenteditable class='n'></div>")
		.appendTo("body")
		.css({
			position: "absolute",
			padding: "5px",
			outline: "none",
			fontSize: "2em"
		})
		.on("keydown", function(e){
			cleanup();
			$last = $n;
			if(e.keyCode === 13 && !e.shiftKey){
				e.preventDefault();
				$Node({
					x: $n.x + Math.random()*100-50,
					y: $n.y + 50,
				}).focus();
			}
		})
		.on("keydown keyup keypress mousemove mouseup", function(){
			position();
			setTimeout(position);
			
			var content = $n.content();
			if(previous_content !== content){
				save();
				if(content){
					fb_n.set({x:$n.x, y:$n.y, _:content});
				}else{
					fb_n.remove();
				}
			}
			previous_content = content;
		})
		.on("mousedown", function(e){
			e.stopPropagation();
			cleanup();
			$last = $n;
		});
		
		$n.fb = fb_n;
		$n.content = function(html){
			if(typeof html === "string"){
				previous_content = html;
				$n.html() !== html && $n.html(html);
				position();
				setTimeout(position);
				setTimeout(position);
				return $n;
			}else{
				return $n.html();
			}
		};
		$n.isEmpty = function(){
			if($n.find("img, audio, video, iframe").length){
				return false;
			}
			return $n.text().match(/^\s*$/);
		};
		$n.rem = function(){
			$n.remove();
			fb_n.remove();
		};
		
		$n.x = o.x;
		$n.y = o.y;
		position(true);
		
		top_level_nodes.push($n);
		
		fb_n.once('value', function(snapshot){
			var v = snapshot.val();
			if(!v){
				fb_n.set(o);
			}
		});
		fb_n.on('value', function(snapshot){
			var v = snapshot.val();
			if(v){
				$n.x = v.x;
				$n.y = v.y;
				$n.content(v._);
				position(true);
				$n.show();
			}else{
				//if($n !== $last)
				$n.hide();
			}
		});
		
		return $n;
		
		function position(instantly){
			$n.css({
				left: $n.x - $n.outerWidth()/2,
				top: $n.y - $n.outerHeight()/2,
			});
		}
	}
	
});