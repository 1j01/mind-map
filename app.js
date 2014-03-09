$(function(){
	
	var top_level_nodes = [];
	
	var doc_name = location.search || "document";
	load();
	
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
	
	$("body").on("mousedown", function(e){
		var $n = $Node({
			x: e.clientX,
			y: e.clientY,
		}).focus();
		
		setTimeout(function(e){
			$n.focus();
		});
	});
	
	var $last;
	function cleanup(){
		if($last && $last.isEmpty()){
			var idx = top_level_nodes.indexOf($last);
			top_level_nodes.splice(idx, 1);
			$last.remove();
		}
		$last = null;
	}
	function $Node(o){
		cleanup();
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
			if($n.isEmpty()){
				if($last && $last !== $n){
					cleanup();
				}
				$last = $n;
			}
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
			}
			previous_content = content;
		})
		.on("mousedown", function(e){
			e.stopPropagation();
		});
		
		$n.content = function(html){
			if(html){
				previous_content = html;
				$n.html(html);
				position();
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
		
		$n.x = o.x;
		$n.y = o.y;
		position(true);
		
		top_level_nodes.push($n);
		
		return $n;
		
		function position(instantly){
			$n.css({
				left: $n.x - $n.outerWidth()/2,
				top: $n.y - $n.outerHeight()/2,
			});
		}
	}
	
});